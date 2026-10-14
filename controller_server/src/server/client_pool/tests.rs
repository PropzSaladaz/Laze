use super::*;
use crate::security::tests::{invitation, manager};
use crate::security::{
    challenge_bytes, decode, derive_keys, encode, make_record, tag, transcript, ServerChallenge,
};
use std::{io::Write, net::TcpListener, time::Instant};

#[derive(Default)]
struct Recorder(Vec<Vec<u8>>);
impl Application for Recorder {
    fn dispatch_to_device(&mut self, payload: &[u8]) -> ConnectionStatus {
        self.0.push(payload.to_vec());
        ConnectionStatus::Connected
    }
}
fn frame(bytes: &[u8]) -> Vec<u8> {
    let mut out = (bytes.len() as u32).to_be_bytes().to_vec();
    out.extend(bytes);
    out
}
fn read(stream: &mut TcpStream) -> Vec<u8> {
    match wire::read_frame(stream, 4096).unwrap() {
        ReadFrame::Data(data) => data,
        _ => panic!("Expected frame"),
    }
}
fn wait_until(check: impl Fn() -> bool) {
    let deadline = Instant::now() + Duration::from_secs(3);
    while !check() {
        assert!(Instant::now() < deadline, "Timed out waiting for pool");
        thread::sleep(Duration::from_millis(5));
    }
}
#[test]
fn fragmented_handshake_coalesced_input_eof_and_rejected_client_are_isolated() {
    let auth = manager();
    let (hello, key) = invitation(&auth, "socket-phone");
    let (events, _) = broadcast::channel(32);
    let pool = ClientPool::new(10, events, auth.clone());
    let app = Arc::new(Mutex::new(Recorder::default()));
    let listener = TcpListener::bind(("127.0.0.1", 0)).unwrap();
    let mut client = TcpStream::connect(listener.local_addr().unwrap()).unwrap();
    client.set_nodelay(true).unwrap();
    let (stream, addr) = listener.accept().unwrap();
    pool.admit(stream, addr, app.clone(), 0);
    let data = frame(&serde_json::to_vec(&hello).unwrap());
    client.write_all(&data[..1]).unwrap();
    client.write_all(&data[1..7]).unwrap();
    client.write_all(&data[7..]).unwrap();
    let challenge: ServerChallenge = serde_json::from_slice(&read(&mut client)).unwrap();
    assert_eq!(
        challenge.proof,
        encode(&tag(&key, &challenge_bytes(&hello, &challenge).unwrap()))
    );
    let finish = ClientFinish {
        proof: encode(&tag(
            &key,
            &transcript(
                "laze-v2/client-finish",
                &[&challenge_bytes(&hello, &challenge).unwrap()],
            ),
        )),
    };
    client
        .write_all(&frame(&serde_json::to_vec(&finish).unwrap()))
        .unwrap();
    let id = decode::<16>(&challenge.session_id).unwrap();
    let keys = derive_keys(&key, &hello, &challenge).unwrap();
    assert_eq!(
        read(&mut client),
        make_record(&id, 0, &[EVENT_READY], &keys.server_tcp)
    );
    let combined = [
        frame(&make_record(&id, 0, &[4, 0, 2, 1], &keys.client_tcp)),
        frame(&make_record(&id, 1, &[3, 1, 255], &keys.client_tcp)),
    ]
    .concat();
    client.write_all(&combined[..2]).unwrap();
    client.write_all(&combined[2..]).unwrap();
    wait_until(|| app.lock().unwrap().0.len() == 2);
    assert_eq!(app.lock().unwrap().0[0], vec![4, 0, 2, 1]);
    // Another socket cannot reuse this valid session's record without completing its own handshake.
    let mut intruder = TcpStream::connect(listener.local_addr().unwrap()).unwrap();
    let (stream, addr) = listener.accept().unwrap();
    pool.admit(stream, addr, app.clone(), 0);
    intruder
        .write_all(&frame(&make_record(&id, 2, &[6], &keys.client_tcp)))
        .unwrap();
    assert!(wire::read_frame(&mut intruder, 4096)
        .map(|r| matches!(r, ReadFrame::Eof))
        .unwrap_or(true));
    assert!(auth.is_live(&id));
    client.shutdown(Shutdown::Write).unwrap();
    wait_until(|| pool.connected_clients().is_empty() && !auth.is_live(&id));
    assert_eq!(app.lock().unwrap().0.len(), 2);
}
#[test]
fn malformed_authenticated_input_disconnects_only_its_owner() {
    let auth = manager();
    let (hello, key) = invitation(&auth, "bad-phone");
    let (events, _) = broadcast::channel(32);
    let pool = ClientPool::new(10, events, auth.clone());
    let app = Arc::new(Mutex::new(Recorder::default()));
    let listener = TcpListener::bind(("127.0.0.1", 0)).unwrap();
    let mut client = TcpStream::connect(listener.local_addr().unwrap()).unwrap();
    let (stream, addr) = listener.accept().unwrap();
    pool.admit(stream, addr, app.clone(), 0);
    wire::write_json(&mut client, &hello).unwrap();
    let challenge: ServerChallenge = wire::read_json(&mut client).unwrap();
    let finish = ClientFinish {
        proof: encode(&tag(
            &key,
            &transcript(
                "laze-v2/client-finish",
                &[&challenge_bytes(&hello, &challenge).unwrap()],
            ),
        )),
    };
    wire::write_json(&mut client, &finish).unwrap();
    read(&mut client);
    let id = decode::<16>(&challenge.session_id).unwrap();
    let keys = derive_keys(&key, &hello, &challenge).unwrap();
    wire::write_frame(
        &mut client,
        &make_record(&id, 0, &[4, 0, 3, 1], &keys.client_tcp),
    )
    .unwrap();
    wait_until(|| !auth.is_live(&id));
    assert!(app.lock().unwrap().0.is_empty());
    assert!(!app.is_poisoned());
    let (_, _, other, other_keys) = crate::security::tests::pair(&auth, "good-phone");
    assert!(auth
        .with_input(
            Some(&other),
            Transport::Tcp,
            &make_record(&other, 0, &[4, 0], &other_keys.client_tcp),
            |payload| app.lock().unwrap().dispatch_to_device(payload)
        )
        .is_ok());
    assert_eq!(app.lock().unwrap().0, vec![vec![4, 0]]);
}

#[test]
fn disconnect_racing_ready_keeps_complete_authenticated_frames_in_sequence() {
    for _ in 0..50 {
        let auth = manager();
        let (hello, key) = invitation(&auth, "racing-phone");
        let (events, mut notices) = broadcast::channel(32);
        let pool = ClientPool::new(10, events, auth.clone());
        let app = Arc::new(Mutex::new(Recorder::default()));
        let listener = TcpListener::bind(("127.0.0.1", 0)).unwrap();
        let mut client = TcpStream::connect(listener.local_addr().unwrap()).unwrap();
        let (stream, addr) = listener.accept().unwrap();
        pool.admit(stream, addr, app.clone(), 0);
        wire::write_json(&mut client, &hello).unwrap();
        let challenge: ServerChallenge = wire::read_json(&mut client).unwrap();
        let id = decode::<16>(&challenge.session_id).unwrap();
        let keys = derive_keys(&key, &hello, &challenge).unwrap();
        let finish = ClientFinish {
            proof: encode(&tag(
                &key,
                &transcript(
                    "laze-v2/client-finish",
                    &[&challenge_bytes(&hello, &challenge).unwrap()],
                ),
            )),
        };
        wire::write_json(&mut client, &finish).unwrap();
        let deadline = Instant::now() + Duration::from_secs(3);
        let info = loop {
            if let Ok(ServerEvent::ClientAdded(info)) = notices.try_recv() {
                break info;
            }
            assert!(Instant::now() < deadline);
            thread::yield_now();
        };
        pool.terminate_client(info.id).unwrap();
        let first = read(&mut client);
        if first[24] == EVENT_READY {
            assert_eq!(first, make_record(&id, 0, &[EVENT_READY], &keys.server_tcp));
            assert_eq!(
                read(&mut client),
                make_record(&id, 1, &[EVENT_DISCONNECTED], &keys.server_tcp)
            );
        } else {
            assert_eq!(
                first,
                make_record(&id, 0, &[EVENT_DISCONNECTED], &keys.server_tcp)
            );
        }
        assert!(!auth.is_live(&id));
        assert!(app.lock().unwrap().0.is_empty());
    }
}
