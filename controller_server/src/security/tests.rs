use super::*;
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

#[derive(Clone, Default)]
pub(crate) struct MemoryStorage {
    state: Arc<Mutex<Option<StoredState>>>,
    keys: Arc<Mutex<HashMap<String, [u8; 32]>>>,
    fail_save: Arc<AtomicBool>,
}
impl PairStorage for MemoryStorage {
    fn load(&self) -> AuthResult<Option<StoredState>> {
        Ok(self.state.lock().unwrap().clone())
    }
    fn save(&self, value: &StoredState) -> AuthResult<()> {
        if self.fail_save.load(Ordering::SeqCst) {
            return Err("Simulated storage failure".into());
        }
        *self.state.lock().unwrap() = Some(value.clone());
        Ok(())
    }
    fn read_key(&self, id: &str) -> AuthResult<[u8; 32]> {
        self.keys
            .lock()
            .unwrap()
            .get(id)
            .copied()
            .ok_or("Missing test credential".into())
    }
    fn write_key(&self, id: &str, key: &[u8; 32]) -> AuthResult<()> {
        self.keys.lock().unwrap().insert(id.into(), *key);
        Ok(())
    }
    fn delete_key(&self, id: &str) {
        self.keys.lock().unwrap().remove(id);
    }
}
pub(crate) fn manager() -> Arc<AuthManager> {
    let manager = Arc::new(AuthManager::with_storage(Box::new(MemoryStorage::default())).unwrap());
    manager.enable();
    manager
}
pub(crate) fn invitation(auth: &AuthManager, device: &str) -> (ClientHello, [u8; 32]) {
    let invite = auth
        .create_invite(vec!["127.0.0.1".into()], 7878, "Test desktop".into())
        .unwrap();
    let json: serde_json::Value = serde_json::from_slice(
        &B64.decode(invite.code.strip_prefix("laze://pair/").unwrap())
            .unwrap(),
    )
    .unwrap();
    let key = decode::<32>(json["secret"].as_str().unwrap()).unwrap();
    let mut hello = ClientHello {
        version: VERSION,
        server_id: auth.server_id(),
        device_id: device.into(),
        device_name: "Test phone".into(),
        invite_id: invite.id,
        client_nonce: encode(&random_bytes::<32>()),
        proof: String::new(),
    };
    hello.proof = encode(&tag(&key, &hello_bytes(&hello).unwrap()));
    (hello, key)
}
pub(crate) fn finish_message(context: &Handshake, key: &[u8; 32]) -> ClientFinish {
    ClientFinish {
        proof: encode(&tag(
            key,
            &transcript(
                "laze-v2/client-finish",
                &[&challenge_bytes(&context.hello, &context.challenge).unwrap()],
            ),
        )),
    }
}
pub(crate) fn pair(
    auth: &AuthManager,
    device: &str,
) -> (ClientHello, [u8; 32], SessionId, SessionKeys) {
    let (hello, key) = invitation(auth, device);
    let context = auth.begin(hello.clone(), "windows", 7876).unwrap();
    let id = auth
        .finish(&context, finish_message(&context, &key), 10)
        .unwrap();
    let keys = derive_keys(&key, &hello, &context.challenge).unwrap();
    (hello, key, id, keys)
}
pub(crate) fn reconnect(auth: &AuthManager, mut hello: ClientHello, key: &[u8; 32]) -> Handshake {
    hello.invite_id.clear();
    hello.client_nonce = encode(&random_bytes::<32>());
    hello.proof = encode(&tag(key, &hello_bytes(&hello).unwrap()));
    auth.begin(hello, "windows", 7876).unwrap()
}
#[test]
fn fixed_vectors_match_independent_oracle() {
    let data: serde_json::Value =
        serde_json::from_str(include_str!("../../../tools/protocol/auth-v2-vectors.json")).unwrap();
    let key = decode::<32>(data["secret"].as_str().unwrap()).unwrap();
    let hello: ClientHello = serde_json::from_value(data["hello"].clone()).unwrap();
    let challenge: ServerChallenge = serde_json::from_value(data["challenge"].clone()).unwrap();
    assert_eq!(encode(&hello_bytes(&hello).unwrap()), data["hello_bytes"]);
    assert_eq!(
        encode(&challenge_bytes(&hello, &challenge).unwrap()),
        data["challenge_bytes"]
    );
    assert_eq!(
        encode(&tag(&key, &hello_bytes(&hello).unwrap())),
        hello.proof
    );
    assert_eq!(
        encode(&tag(&key, &challenge_bytes(&hello, &challenge).unwrap())),
        challenge.proof
    );
    let keys = derive_keys(&key, &hello, &challenge).unwrap();
    for (label, key) in [
        ("client-tcp", keys.client_tcp),
        ("client-udp", keys.client_udp),
        ("server-tcp", keys.server_tcp),
    ] {
        assert_eq!(encode(&key), data["keys"][label]);
    }
    let id = decode::<16>(&challenge.session_id).unwrap();
    assert_eq!(
        encode(&make_record(&id, 0, &[4, 0], &keys.client_tcp)),
        data["tcp_record"]
    );
    assert_eq!(
        encode(&make_record(&id, 0, &[3, 1, 255], &keys.client_udp)),
        data["udp_record"]
    );
    assert_eq!(
        encode(&make_record(&id, 0, &[EVENT_READY], &keys.server_tcp)),
        data["ready_record"]
    );
}
#[test]
fn strangers_bad_proofs_and_partial_handshakes_never_get_sessions() {
    let auth = manager();
    let (hello, key) = invitation(&auth, "phone");
    let mut stranger = hello.clone();
    stranger.invite_id.clear();
    assert!(auth.begin(stranger, "windows", 7876).is_err());
    let mut bad = hello.clone();
    bad.proof = encode(&[0; 32]);
    assert!(auth.begin(bad, "windows", 7876).is_err());
    let context = auth.begin(hello, "windows", 7876).unwrap();
    let id = decode::<16>(&context.challenge.session_id).unwrap();
    let keys = derive_keys(&key, &context.hello, &context.challenge).unwrap();
    assert!(!auth.is_live(&id));
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 0, &[6], &keys.client_tcp),
            |_| panic!("unpaired dispatch")
        )
        .is_err());
    assert!(auth
        .finish(
            &context,
            ClientFinish {
                proof: encode(&[0; 32])
            },
            10
        )
        .is_err());
    assert!(auth.trusted_devices().is_empty());
    assert!(auth
        .finish(&context, finish_message(&context, &key), 10)
        .is_ok());
}
#[test]
fn invitation_is_single_use_expiring_and_cancelable() {
    let auth = manager();
    let (hello, key) = invitation(&auth, "phone");
    let first = auth.begin(hello.clone(), "windows", 0).unwrap();
    let competing = auth.begin(hello.clone(), "windows", 0).unwrap();
    auth.finish(&first, finish_message(&first, &key), 10)
        .unwrap();
    assert!(auth
        .finish(&competing, finish_message(&competing, &key), 10)
        .is_err());
    assert!(auth.begin(hello, "windows", 0).is_err());
    let (hello, key) = invitation(&auth, "next");
    let context = auth.begin(hello.clone(), "windows", 0).unwrap();
    auth.state
        .lock()
        .unwrap()
        .invitation
        .as_mut()
        .unwrap()
        .deadline = Instant::now();
    assert!(auth.begin(hello, "windows", 0).is_err());
    assert!(auth
        .finish(&context, finish_message(&context, &key), 10)
        .is_err());
    let (hello, _) = invitation(&auth, "next");
    auth.cancel_invite(&hello.invite_id);
    assert!(auth.begin(hello, "windows", 0).is_err());
}
#[test]
fn tampering_replays_cross_transport_and_bad_payloads_never_dispatch() {
    let auth = manager();
    let (_, _, id, keys) = pair(&auth, "phone");
    let tcp = make_record(&id, 0, &[4, 0], &keys.client_tcp);
    let mut bad = tcp.clone();
    bad[24] ^= 1;
    assert!(auth
        .with_input(Some(&id), Transport::Tcp, &bad, |_| panic!("tampered"))
        .is_err());
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 0, &[4, 2], &keys.client_tcp),
            |_| panic!("malformed")
        )
        .is_err());
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 0, &[4, 0, 7, 2, 255], &keys.client_tcp),
            |_| panic!("partial dispatch")
        )
        .is_err());
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 1, &[4, 0], &keys.client_tcp),
            |_| panic!("out of order")
        )
        .is_err());
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 0, &[4, 0], &keys.server_tcp),
            |_| panic!("wrong direction")
        )
        .is_err());
    assert!(auth
        .with_input(Some(&[0; 16]), Transport::Tcp, &tcp, |_| panic!(
            "different socket"
        ))
        .is_err());
    assert_eq!(
        auth.with_input(Some(&id), Transport::Tcp, &tcp, |p| p.to_vec())
            .unwrap(),
        vec![4, 0]
    );
    assert!(auth
        .with_input(Some(&id), Transport::Tcp, &tcp, |_| panic!("replay"))
        .is_err());
    let udp = make_record(&id, 0, &[3, 1, 255], &keys.client_udp);
    assert!(auth
        .with_input(Some(&id), Transport::Tcp, &udp, |_| panic!(
            "UDP reflected to TCP"
        ))
        .is_err());
    assert_eq!(
        auth.with_input(None, Transport::Udp, &udp, |p| p.to_vec())
            .unwrap(),
        vec![3, 1, 255]
    );
    assert!(auth
        .with_input(None, Transport::Udp, &udp, |_| panic!("UDP replay"))
        .is_err());
    assert!(auth
        .with_input(
            None,
            Transport::Udp,
            &make_record(&id, 2, &[6], &keys.client_udp),
            |_| panic!("UDP shutdown")
        )
        .is_err());
    let newer = make_record(&id, 2, &[2, 255], &keys.client_udp);
    assert!(auth
        .with_input(None, Transport::Udp, &newer, |_| ())
        .is_ok());
    assert!(auth
        .with_input(
            None,
            Transport::Udp,
            &make_record(&id, 1, &[2, 1], &keys.client_udp),
            |_| panic!("stale UDP")
        )
        .is_err());
    assert!(auth
        .with_input(
            None,
            Transport::Udp,
            &make_record(&id, 3, &[3, 1, 1], &keys.client_tcp),
            |_| panic!("wrong key")
        )
        .is_err());
    let unicode = "echo café".as_bytes();
    let mut command = vec![7, unicode.len() as u8];
    command.extend(unicode);
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 1, &command, &keys.client_tcp),
            |_| ()
        )
        .is_ok());
}
#[test]
fn reconnect_replaces_sessions_and_stop_rejects_pending_handshake() {
    let auth = manager();
    let (hello, key, old, keys) = pair(&auth, "phone");
    let context = reconnect(&auth, hello.clone(), &key);
    let next = auth
        .finish(&context, finish_message(&context, &key), 10)
        .unwrap();
    assert_ne!(old, next);
    assert!(!auth.is_live(&old));
    assert!(auth
        .with_input(
            None,
            Transport::Udp,
            &make_record(&old, 0, &[3, 1, 1], &keys.client_udp),
            |_| panic!("old session")
        )
        .is_err());
    let context = reconnect(&auth, hello, &key);
    auth.stop();
    auth.enable();
    assert!(!auth.is_live(&next));
    assert!(auth
        .finish(&context, finish_message(&context, &key), 10)
        .is_err());
}
#[test]
fn persistence_reconnect_offline_revocation_and_failed_save_are_fail_closed() {
    let store = MemoryStorage::default();
    let auth = AuthManager::with_storage(Box::new(store.clone())).unwrap();
    auth.enable();
    let (hello, key, _, _) = pair(&auth, "phone");
    let restarted = AuthManager::with_storage(Box::new(store.clone())).unwrap();
    restarted.enable();
    assert_eq!(auth.server_id(), restarted.server_id());
    let context = reconnect(&restarted, hello.clone(), &key);
    store.fail_save.store(true, Ordering::SeqCst);
    assert!(restarted.revoke("phone").is_err());
    assert_eq!(restarted.trusted_devices().len(), 1);
    store.fail_save.store(false, Ordering::SeqCst);
    restarted.revoke("phone").unwrap();
    assert!(restarted
        .finish(&context, finish_message(&context, &key), 10)
        .is_err());
    assert!(AuthManager::with_storage(Box::new(store.clone()))
        .unwrap()
        .trusted_devices()
        .is_empty());
    let (hello, key) = invitation(&restarted, "other");
    let context = restarted.begin(hello, "windows", 0).unwrap();
    store.fail_save.store(true, Ordering::SeqCst);
    assert!(restarted
        .finish(&context, finish_message(&context, &key), 10)
        .is_err());
    assert!(restarted.trusted_devices().is_empty());
    assert!(store.keys.lock().unwrap().is_empty());
}
#[test]
fn revocation_waits_for_accepted_dispatch_then_rejects_all_input() {
    use std::{sync::mpsc, thread, time::Duration};
    let auth = manager();
    let (_, _, id, keys) = pair(&auth, "phone");
    let (entered, arrived) = mpsc::channel();
    let (release, wait) = mpsc::channel();
    let input_auth = auth.clone();
    let record = make_record(&id, 0, &[4, 0], &keys.client_tcp);
    let input = thread::spawn(move || {
        input_auth
            .with_input(Some(&id), Transport::Tcp, &record, |_| {
                entered.send(()).unwrap();
                wait.recv().unwrap();
            })
            .unwrap()
    });
    arrived.recv_timeout(Duration::from_secs(2)).unwrap();
    let revoke_auth = auth.clone();
    let (done, completed) = mpsc::channel();
    let revoker = thread::spawn(move || {
        let result = revoke_auth.revoke("phone").unwrap();
        done.send(result).unwrap();
    });
    assert!(completed.recv_timeout(Duration::from_millis(50)).is_err());
    release.send(()).unwrap();
    input.join().unwrap();
    revoker.join().unwrap();
    assert_eq!(
        completed.recv_timeout(Duration::from_secs(2)).unwrap()[&id][24],
        EVENT_REVOKED
    );
    assert!(auth
        .with_input(
            Some(&id),
            Transport::Tcp,
            &make_record(&id, 1, &[4, 0], &keys.client_tcp),
            |_| panic!("revoked TCP")
        )
        .is_err());
    assert!(auth
        .with_input(
            None,
            Transport::Udp,
            &make_record(&id, 0, &[3, 1, 1], &keys.client_udp),
            |_| panic!("revoked UDP")
        )
        .is_err());
}
#[test]
fn malformed_action_classes_do_not_panic_or_poison_a_later_valid_session() {
    let auth = manager();
    let (_, _, id, keys) = pair(&auth, "phone");
    for kind in 0..=255u8 {
        for data in [
            vec![kind],
            vec![kind, 255],
            vec![kind, 255, 255],
            vec![4, 0, kind],
        ] {
            let record = make_record(&id, 0, &data, &keys.client_tcp);
            let _ = auth.with_input(Some(&id), Transport::Tcp, &record, |_| ());
        }
    }
    let (_, _, next, keys) = pair(&auth, "second");
    assert!(auth
        .with_input(
            Some(&next),
            Transport::Tcp,
            &make_record(&next, 0, &[3, 1, 1], &keys.client_tcp),
            |_| ()
        )
        .is_ok());
}
#[cfg(target_os = "windows")]
#[test]
fn windows_credential_store_round_trip_isolated_and_cleaned_up() {
    let id = format!("test-{}", encode(&random_bytes::<16>()));
    struct Cleanup(String);
    impl Drop for Cleanup {
        fn drop(&mut self) {
            FilePairStorage::new(PathBuf::new()).delete_key(&self.0);
        }
    }
    let _cleanup = Cleanup(id.clone());
    let directory = tempfile::tempdir().unwrap();
    let storage = FilePairStorage::new(directory.path().join("phones.json"));
    let key = random_bytes::<32>();
    storage.write_key(&id, &key).unwrap();
    assert_eq!(storage.read_key(&id).unwrap(), key);
    let state = StoredState {
        version: VERSION,
        server_id: "test-desktop".into(),
        devices: vec![StoredDevice {
            device_id: "test-phone".into(),
            device_name: "Test phone".into(),
            paired_at: 0,
            credential_id: id.clone(),
        }],
    };
    storage.save(&state).unwrap();
    assert_eq!(storage.load().unwrap().unwrap().server_id, "test-desktop");
    storage
        .save(&StoredState {
            devices: vec![],
            ..state
        })
        .unwrap();
    storage.delete_key(&id);
    assert!(storage.read_key(&id).is_err());
}
