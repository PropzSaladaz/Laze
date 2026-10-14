//! Versioned, authentication-only LAN sessions. Secrets never travel in network handshakes.
use crate::actions::Action;
use base64::{engine::general_purpose::URL_SAFE_NO_PAD as B64, Engine};
use hkdf::Hkdf;
use hmac::{Hmac, Mac};
use rand::{rngs::OsRng, RngCore};
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use std::{
    collections::HashMap,
    fs,
    io::Write,
    path::PathBuf,
    sync::Mutex,
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

pub const VERSION: u8 = 2;
pub const MAX_INPUT: usize = 1024;
pub const FRAME_OVERHEAD: usize = 16 + 8 + 32;
pub const EVENT_READY: u8 = 253;
pub const EVENT_REVOKED: u8 = 252;
pub const EVENT_DISCONNECTED: u8 = 254;
pub const EVENT_STOPPED: u8 = 255;
pub type SessionId = [u8; 16];
pub type AuthResult<T> = Result<T, String>;
type Hmac256 = Hmac<Sha256>;

pub fn random_bytes<const N: usize>() -> [u8; N] {
    let mut value = [0; N];
    OsRng.fill_bytes(&mut value);
    value
}
pub fn encode(value: &[u8]) -> String {
    B64.encode(value)
}
pub fn decode<const N: usize>(value: &str) -> AuthResult<[u8; N]> {
    B64.decode(value)
        .map_err(|_| "Invalid authentication data".to_owned())?
        .try_into()
        .map_err(|_| "Invalid authentication data".to_owned())
}
pub fn transcript(label: &str, fields: &[&[u8]]) -> Vec<u8> {
    let mut out = Vec::new();
    for field in std::iter::once(label.as_bytes()).chain(fields.iter().copied()) {
        out.extend_from_slice(&(field.len() as u32).to_be_bytes());
        out.extend_from_slice(field);
    }
    out
}
pub fn tag(key: &[u8; 32], message: &[u8]) -> [u8; 32] {
    let mut mac = Hmac256::new_from_slice(key).expect("fixed HMAC key");
    mac.update(message);
    mac.finalize().into_bytes().into()
}
fn verify(key: &[u8; 32], message: &[u8], expected: &[u8]) -> bool {
    let mut mac = Hmac256::new_from_slice(key).expect("fixed HMAC key");
    mac.update(message);
    mac.verify_slice(expected).is_ok()
}
fn valid_id(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 64
        && value
            .bytes()
            .all(|v| v.is_ascii_alphanumeric() || v == b'-' || v == b'_')
}
fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct StoredDevice {
    pub device_id: String,
    pub device_name: String,
    pub paired_at: u64,
    credential_id: String,
}
#[derive(Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct StoredState {
    version: u8,
    server_id: String,
    devices: Vec<StoredDevice>,
}
#[derive(Clone, Serialize)]
pub struct TrustedDevice {
    pub device_id: String,
    pub device_name: String,
    pub paired_at: u64,
}
pub trait PairStorage: Send + Sync {
    fn load(&self) -> AuthResult<Option<StoredState>>;
    fn save(&self, state: &StoredState) -> AuthResult<()>;
    fn read_key(&self, credential: &str) -> AuthResult<[u8; 32]>;
    fn write_key(&self, credential: &str, key: &[u8; 32]) -> AuthResult<()>;
    fn delete_key(&self, credential: &str);
}

/// Public device metadata on disk; per-device secrets only in the native OS credential store.
pub struct FilePairStorage {
    path: PathBuf,
}
impl FilePairStorage {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }
    fn entry(id: &str) -> AuthResult<keyring::Entry> {
        keyring::Entry::new("com.propzsaladaz.laze.authentication", id)
            .map_err(|_| "Secure credential storage is unavailable".into())
    }
}
impl PairStorage for FilePairStorage {
    fn load(&self) -> AuthResult<Option<StoredState>> {
        match fs::metadata(&self.path) {
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(_) => Err("Unable to read paired-phone metadata".into()),
            Ok(meta) => {
                if meta.len() > 65536 {
                    return Err("Paired-phone metadata is too large".into());
                }
                serde_json::from_slice(
                    &fs::read(&self.path).map_err(|_| "Unable to read paired-phone metadata")?,
                )
                .map(Some)
                .map_err(|_| "Paired-phone metadata is invalid".into())
            }
        }
    }
    fn save(&self, state: &StoredState) -> AuthResult<()> {
        let parent = self.path.parent().ok_or("Invalid credential directory")?;
        fs::create_dir_all(parent).map_err(|_| "Unable to create credential directory")?;
        let mut file =
            tempfile::NamedTempFile::new_in(parent).map_err(|_| "Unable to save paired phones")?;
        serde_json::to_writer(&mut file, state).map_err(|_| "Unable to save paired phones")?;
        file.flush().map_err(|_| "Unable to save paired phones")?;
        file.as_file()
            .sync_all()
            .map_err(|_| "Unable to save paired phones")?;
        file.persist(&self.path)
            .map_err(|_| "Unable to save paired phones")?;
        Ok(())
    }
    fn read_key(&self, credential: &str) -> AuthResult<[u8; 32]> {
        let secret = Self::entry(credential)?
            .get_password()
            .map_err(|_| "A paired-phone credential is unavailable")?;
        decode(&secret)
    }
    fn write_key(&self, credential: &str, key: &[u8; 32]) -> AuthResult<()> {
        Self::entry(credential)?
            .set_password(&encode(key))
            .map_err(|_| "Unable to save the phone credential".into())
    }
    fn delete_key(&self, credential: &str) {
        if let Ok(entry) = Self::entry(credential) {
            let _ = entry.delete_credential();
        }
    }
}

struct Device {
    record: StoredDevice,
    key: [u8; 32],
}
struct Invitation {
    id: String,
    key: [u8; 32],
    deadline: Instant,
}
#[derive(Serialize)]
pub struct PairingInvite {
    pub id: String,
    pub code: String,
    pub expires_at: u64,
}
#[derive(Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ClientHello {
    pub version: u8,
    pub server_id: String,
    pub device_id: String,
    pub device_name: String,
    pub invite_id: String,
    pub client_nonce: String,
    pub proof: String,
}
#[derive(Clone, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ServerChallenge {
    pub version: u8,
    pub session_id: String,
    pub server_nonce: String,
    pub server_os: String,
    pub udp_port: u16,
    pub proof: String,
}
#[derive(Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ClientFinish {
    pub proof: String,
}
pub struct Handshake {
    pub hello: ClientHello,
    pub challenge: ServerChallenge,
    key: [u8; 32],
    epoch: u64,
    credential: Option<String>,
    challenge_bytes: Vec<u8>,
}
#[derive(Clone)]
pub struct SessionKeys {
    pub client_tcp: [u8; 32],
    pub client_udp: [u8; 32],
    pub server_tcp: [u8; 32],
}
pub fn hello_bytes(hello: &ClientHello) -> AuthResult<Vec<u8>> {
    let nonce = decode::<32>(&hello.client_nonce)?;
    Ok(transcript(
        "laze-v2/client-hello",
        &[
            hello.server_id.as_bytes(),
            hello.device_id.as_bytes(),
            hello.device_name.as_bytes(),
            hello.invite_id.as_bytes(),
            &nonce,
        ],
    ))
}
pub fn challenge_bytes(hello: &ClientHello, challenge: &ServerChallenge) -> AuthResult<Vec<u8>> {
    let hello_data = hello_bytes(hello)?;
    let nonce = decode::<32>(&challenge.server_nonce)?;
    let session = decode::<16>(&challenge.session_id)?;
    Ok(transcript(
        "laze-v2/server-challenge",
        &[
            &hello_data,
            &nonce,
            &session,
            challenge.server_os.as_bytes(),
            &challenge.udp_port.to_be_bytes(),
        ],
    ))
}
pub fn derive_keys(
    key: &[u8; 32],
    hello: &ClientHello,
    challenge: &ServerChallenge,
) -> AuthResult<SessionKeys> {
    let mut salt = decode::<32>(&hello.client_nonce)?.to_vec();
    salt.extend(decode::<32>(&challenge.server_nonce)?);
    let session = decode::<16>(&challenge.session_id)?;
    let hkdf = Hkdf::<Sha256>::new(Some(&salt), key);
    let derive = |label: &str| -> AuthResult<[u8; 32]> {
        let mut out = [0; 32];
        let info = transcript(
            "laze-v2/session-key",
            &[
                hello.server_id.as_bytes(),
                hello.device_id.as_bytes(),
                &session,
                label.as_bytes(),
            ],
        );
        hkdf.expand(&info, &mut out)
            .map_err(|_| "Unable to derive session keys")?;
        Ok(out)
    };
    Ok(SessionKeys {
        client_tcp: derive("client-tcp")?,
        client_udp: derive("client-udp")?,
        server_tcp: derive("server-tcp")?,
    })
}
pub fn make_record(session: &SessionId, sequence: u64, payload: &[u8], key: &[u8; 32]) -> Vec<u8> {
    let mut record = session.to_vec();
    record.extend(sequence.to_be_bytes());
    record.extend(payload);
    record.extend(tag(key, &record));
    record
}
struct Session {
    device_id: String,
    keys: SessionKeys,
    tcp_next: u64,
    udp_last: Option<u64>,
    server_next: u64,
}
struct State {
    server_id: String,
    devices: HashMap<String, Device>,
    invitation: Option<Invitation>,
    sessions: HashMap<SessionId, Session>,
    enabled: bool,
    epoch: u64,
}
#[derive(Clone, Copy)]
pub enum Transport {
    Tcp,
    Udp,
}
pub struct AuthManager {
    state: Mutex<State>,
    storage: Box<dyn PairStorage>,
}

#[cfg(test)]
pub(crate) mod tests;
impl AuthManager {
    pub fn load(path: PathBuf) -> AuthResult<Self> {
        Self::with_storage(Box::new(FilePairStorage::new(path)))
    }
    pub fn with_storage(storage: Box<dyn PairStorage>) -> AuthResult<Self> {
        let stored = storage.load()?.unwrap_or_else(|| StoredState {
            version: VERSION,
            server_id: encode(&random_bytes::<16>()),
            devices: vec![],
        });
        if stored.version != VERSION || !valid_id(&stored.server_id) || stored.devices.len() > 64 {
            return Err("Paired-phone metadata is invalid".into());
        }
        let mut devices = HashMap::new();
        for record in &stored.devices {
            if !valid_id(&record.device_id)
                || !valid_id(&record.credential_id)
                || record.device_name.len() > 256
                || devices.contains_key(&record.device_id)
            {
                return Err("Paired-phone metadata is invalid".into());
            }
            let key = storage.read_key(&record.credential_id)?;
            devices.insert(
                record.device_id.clone(),
                Device {
                    record: record.clone(),
                    key,
                },
            );
        }
        storage.save(&stored)?;
        Ok(Self {
            state: Mutex::new(State {
                server_id: stored.server_id,
                devices,
                invitation: None,
                sessions: HashMap::new(),
                enabled: false,
                epoch: 0,
            }),
            storage,
        })
    }
    fn snapshot(state: &State) -> StoredState {
        StoredState {
            version: VERSION,
            server_id: state.server_id.clone(),
            devices: state.devices.values().map(|v| v.record.clone()).collect(),
        }
    }
    pub fn server_id(&self) -> String {
        self.state.lock().unwrap().server_id.clone()
    }
    pub fn trusted_devices(&self) -> Vec<TrustedDevice> {
        let state = self.state.lock().unwrap();
        let mut devices: Vec<_> = state
            .devices
            .values()
            .map(|v| TrustedDevice {
                device_id: v.record.device_id.clone(),
                device_name: v.record.device_name.clone(),
                paired_at: v.record.paired_at,
            })
            .collect();
        devices.sort_by_key(|v| v.paired_at);
        devices
    }
    pub fn enable(&self) {
        let mut state = self.state.lock().unwrap();
        if !state.enabled {
            state.epoch += 1;
            state.enabled = true;
        }
    }
    pub fn enabled(&self) -> bool {
        self.state.lock().unwrap().enabled
    }
    pub fn create_invite(
        &self,
        hosts: Vec<String>,
        port: u16,
        name: String,
    ) -> AuthResult<PairingInvite> {
        let mut state = self.state.lock().unwrap();
        if !state.enabled {
            return Err("Start the server before pairing a phone".into());
        }
        if state.devices.len() >= 64 {
            return Err("Forget an unused phone before pairing another".into());
        }
        let id = encode(&random_bytes::<16>());
        let key = random_bytes::<32>();
        let expires_at = now() + 180;
        let data = serde_json::json!({"version": VERSION, "server_id": state.server_id, "invite_id": id,
            "secret": encode(&key), "hosts": hosts, "port": port, "name": name, "expires_at": expires_at});
        let code = format!(
            "laze://pair/{}",
            encode(&serde_json::to_vec(&data).map_err(|_| "Unable to create pairing code")?)
        );
        state.invitation = Some(Invitation {
            id: id.clone(),
            key,
            deadline: Instant::now() + Duration::from_secs(180),
        });
        Ok(PairingInvite {
            id,
            code,
            expires_at,
        })
    }
    pub fn cancel_invite(&self, id: &str) {
        let mut state = self.state.lock().unwrap();
        if state.invitation.as_ref().is_some_and(|v| v.id == id) {
            state.invitation = None;
        }
    }
    pub fn begin(&self, hello: ClientHello, os: &str, udp_port: u16) -> AuthResult<Handshake> {
        if hello.version != VERSION
            || !valid_id(&hello.server_id)
            || !valid_id(&hello.device_id)
            || (!hello.invite_id.is_empty() && !valid_id(&hello.invite_id))
            || hello.device_name.is_empty()
            || hello.device_name.len() > 256
            || hello.device_name.chars().any(char::is_control)
        {
            return Err("Invalid authentication data".into());
        }
        let state = self.state.lock().unwrap();
        if !state.enabled || hello.server_id != state.server_id {
            return Err("Pair this phone with the running desktop app".into());
        }
        let (key, credential) = if hello.invite_id.is_empty() {
            let device = state
                .devices
                .get(&hello.device_id)
                .ok_or("Pair this phone with the desktop app")?;
            (device.key, Some(device.record.credential_id.clone()))
        } else {
            let invitation = state
                .invitation
                .as_ref()
                .filter(|v| v.id == hello.invite_id && Instant::now() < v.deadline)
                .ok_or("Pairing code has expired or was already used")?;
            (invitation.key, None)
        };
        if !verify(&key, &hello_bytes(&hello)?, &decode::<32>(&hello.proof)?) {
            return Err("Authentication failed".into());
        }
        let mut challenge = ServerChallenge {
            version: VERSION,
            session_id: encode(&random_bytes::<16>()),
            server_nonce: encode(&random_bytes::<32>()),
            server_os: os.into(),
            udp_port,
            proof: String::new(),
        };
        let bytes = challenge_bytes(&hello, &challenge)?;
        challenge.proof = encode(&tag(&key, &bytes));
        Ok(Handshake {
            hello,
            challenge,
            key,
            epoch: state.epoch,
            credential,
            challenge_bytes: bytes,
        })
    }
    pub fn finish(
        &self,
        handshake: &Handshake,
        finish: ClientFinish,
        max_clients: usize,
    ) -> AuthResult<SessionId> {
        let finish_bytes = transcript("laze-v2/client-finish", &[&handshake.challenge_bytes]);
        if !verify(&handshake.key, &finish_bytes, &decode::<32>(&finish.proof)?) {
            return Err("Authentication failed".into());
        }
        let keys = derive_keys(&handshake.key, &handshake.hello, &handshake.challenge)?;
        let id = decode::<16>(&handshake.challenge.session_id)?;
        let mut state = self.state.lock().unwrap();
        if !state.enabled || state.epoch != handshake.epoch {
            return Err("Server session changed; reconnect".into());
        }
        let device_id = &handshake.hello.device_id;
        if state
            .sessions
            .values()
            .filter(|v| &v.device_id != device_id)
            .count()
            >= max_clients
        {
            return Err("Server reached max clients".into());
        }
        if let Some(credential) = &handshake.credential {
            if state
                .devices
                .get(device_id)
                .is_none_or(|v| &v.record.credential_id != credential)
            {
                return Err("Phone access was revoked; pair again".into());
            }
        } else {
            if state.devices.contains_key(device_id)
                || !state.invitation.as_ref().is_some_and(|v| {
                    v.id == handshake.hello.invite_id && Instant::now() < v.deadline
                })
            {
                return Err("Pairing code has expired or was already used".into());
            }
            let record = StoredDevice {
                device_id: device_id.clone(),
                device_name: handshake.hello.device_name.clone(),
                paired_at: now(),
                credential_id: encode(&random_bytes::<16>()),
            };
            self.storage
                .write_key(&record.credential_id, &handshake.key)?;
            let mut snapshot = Self::snapshot(&state);
            snapshot.devices.push(record.clone());
            if let Err(error) = self.storage.save(&snapshot) {
                self.storage.delete_key(&record.credential_id);
                return Err(error);
            }
            state.devices.insert(
                device_id.clone(),
                Device {
                    record,
                    key: handshake.key,
                },
            );
            state.invitation = None;
        }
        state.sessions.retain(|_, v| &v.device_id != device_id);
        state.sessions.insert(
            id,
            Session {
                device_id: device_id.clone(),
                keys,
                tcp_next: 0,
                udp_last: None,
                server_next: 0,
            },
        );
        Ok(id)
    }
    pub fn is_live(&self, id: &SessionId) -> bool {
        let state = self.state.lock().unwrap();
        state.enabled && state.sessions.contains_key(id)
    }
    /// Lock order: auth state, then application. Stop/revoke cannot finish before an accepted dispatch finishes.
    pub fn with_input<T>(
        &self,
        expected: Option<&SessionId>,
        transport: Transport,
        record: &[u8],
        dispatch: impl FnOnce(&[u8]) -> T,
    ) -> AuthResult<T> {
        if record.len() <= FRAME_OVERHEAD || record.len() > FRAME_OVERHEAD + MAX_INPUT {
            return Err("Invalid input frame".into());
        }
        let id: SessionId = record[..16].try_into().map_err(|_| "Invalid session")?;
        if expected.is_some_and(|v| v != &id) {
            return Err("Session mismatch".into());
        }
        let sequence = u64::from_be_bytes(record[16..24].try_into().unwrap());
        let payload = &record[24..record.len() - 32];
        if matches!(transport, Transport::Udp)
            && !((payload.len() == 2 && payload[0] == 2) || (payload.len() == 3 && payload[0] == 3))
        {
            return Err("Invalid motion frame".into());
        }
        Action::validate_batch(payload).map_err(|_| "Invalid input payload")?;
        let mut state = self.state.lock().unwrap();
        if !state.enabled {
            return Err("Server stopped".into());
        }
        let session = state.sessions.get_mut(&id).ok_or("Unknown session")?;
        let key = match transport {
            Transport::Tcp => &session.keys.client_tcp,
            Transport::Udp => &session.keys.client_udp,
        };
        if !verify(
            key,
            &record[..record.len() - 32],
            &record[record.len() - 32..],
        ) {
            return Err("Invalid input authentication".into());
        }
        match transport {
            Transport::Tcp => {
                if sequence != session.tcp_next {
                    return Err("Repeated or out-of-order TCP input".into());
                }
                session.tcp_next = sequence
                    .checked_add(1)
                    .ok_or("Reconnect before sequence exhaustion")?;
            }
            Transport::Udp => {
                if session.udp_last.is_some_and(|last| sequence <= last) {
                    return Err("Repeated or stale motion".into());
                }
                session.udp_last = Some(sequence);
            }
        }
        Ok(dispatch(payload))
    }
    pub fn event(&self, id: &SessionId, code: u8) -> Option<Vec<u8>> {
        let mut state = self.state.lock().unwrap();
        Self::event_locked(&mut state, id, code)
    }
    fn event_locked(state: &mut State, id: &SessionId, code: u8) -> Option<Vec<u8>> {
        let session = state.sessions.get_mut(id)?;
        let next = session.server_next.checked_add(1)?;
        let out = make_record(id, session.server_next, &[code], &session.keys.server_tcp);
        session.server_next = next;
        Some(out)
    }
    pub fn disconnect(&self, id: &SessionId, code: u8) -> Option<Vec<u8>> {
        let mut state = self.state.lock().unwrap();
        let frame = Self::event_locked(&mut state, id, code);
        state.sessions.remove(id);
        frame
    }
    pub fn stop(&self) -> HashMap<SessionId, Vec<u8>> {
        let mut state = self.state.lock().unwrap();
        state.enabled = false;
        state.epoch += 1;
        state.invitation = None;
        let ids: Vec<_> = state.sessions.keys().copied().collect();
        let frames = ids
            .iter()
            .filter_map(|id| {
                Self::event_locked(&mut state, id, EVENT_STOPPED).map(|frame| (*id, frame))
            })
            .collect();
        state.sessions.clear();
        frames
    }
    pub fn revoke(&self, device: &str) -> AuthResult<HashMap<SessionId, Vec<u8>>> {
        let mut state = self.state.lock().unwrap();
        let credential = state
            .devices
            .get(device)
            .ok_or("Phone is not paired")?
            .record
            .credential_id
            .clone();
        let mut snapshot = Self::snapshot(&state);
        snapshot.devices.retain(|v| v.device_id != device);
        // Persist the removal before reporting success. Orphaned native secrets cannot restore trust.
        self.storage.save(&snapshot)?;
        state.devices.remove(device);
        let ids: Vec<_> = state
            .sessions
            .iter()
            .filter(|(_, v)| v.device_id == device)
            .map(|(id, _)| *id)
            .collect();
        let frames = ids
            .iter()
            .filter_map(|id| {
                Self::event_locked(&mut state, id, EVENT_REVOKED).map(|frame| (*id, frame))
            })
            .collect();
        for id in ids {
            state.sessions.remove(&id);
        }
        self.storage.delete_key(&credential);
        Ok(frames)
    }
}
