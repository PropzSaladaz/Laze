use super::{
    application::{Application, ConnectionStatus},
    core::{ClientInfo, ServerEvent},
    wire::{self, ReadFrame},
};
use crate::security::{
    AuthManager, ClientFinish, ClientHello, SessionId, Transport, EVENT_DISCONNECTED, EVENT_READY,
    FRAME_OVERHEAD, MAX_INPUT,
};
use std::{
    collections::HashMap,
    net::{Shutdown, SocketAddr, TcpStream},
    sync::{
        atomic::{AtomicUsize, Ordering},
        Arc, Mutex,
    },
    thread,
    time::Duration,
};
use tokio::sync::broadcast;

struct Client {
    info: ClientInfo,
    session: SessionId,
    tx: Mutex<TcpStream>,
}
struct Pool {
    clients: Mutex<HashMap<usize, Arc<Client>>>,
    next: AtomicUsize,
    pending: AtomicUsize,
    max: usize,
    auth: Arc<AuthManager>,
    events: broadcast::Sender<ServerEvent>,
}
#[derive(Clone)]
pub struct ClientPool {
    inner: Arc<Pool>,
}
struct Pending(Arc<Pool>);
impl Drop for Pending {
    fn drop(&mut self) {
        self.0.pending.fetch_sub(1, Ordering::SeqCst);
    }
}
impl ClientPool {
    pub fn new(max: usize, events: broadcast::Sender<ServerEvent>, auth: Arc<AuthManager>) -> Self {
        Self {
            inner: Arc::new(Pool {
                clients: Mutex::new(HashMap::new()),
                next: AtomicUsize::new(1),
                pending: AtomicUsize::new(0),
                max,
                auth,
                events,
            }),
        }
    }
    /// Handshakes are bounded and unprivileged. No dedicated unauthenticated listener is allocated.
    pub fn admit<A: Application + 'static>(
        &self,
        stream: TcpStream,
        addr: SocketAddr,
        app: Arc<Mutex<A>>,
        udp_port: u16,
    ) {
        if self.inner.pending.fetch_add(1, Ordering::SeqCst) >= 16 {
            self.inner.pending.fetch_sub(1, Ordering::SeqCst);
            return;
        }
        let pool = self.clone();
        thread::spawn(move || {
            let pending = Pending(Arc::clone(&pool.inner));
            let mut stream = stream;
            // Windows accepts inherit the listener's nonblocking mode. The framed
            // reader uses blocking I/O with deadlines; WouldBlock here would reject
            // a phone before it has a chance to send ClientHello.
            if stream.set_nonblocking(false).is_err() {
                let _ = stream.shutdown(Shutdown::Both);
                return;
            }
            let _ = stream.set_nodelay(true);
            let _ = stream.set_write_timeout(Some(Duration::from_secs(2)));
            let result = pool.handshake(&mut stream, udp_port);
            drop(pending);
            let (session, name) = match result {
                Ok(value) => value,
                Err(error) => {
                    log::debug!("Pairing handshake rejected for {addr}: {error}");
                    let _ = stream.shutdown(Shutdown::Both);
                    return;
                }
            };
            let tx = match stream.try_clone() {
                Ok(tx) => tx,
                Err(_) => {
                    pool.inner.auth.disconnect(&session, EVENT_DISCONNECTED);
                    return;
                }
            };
            let id = pool.inner.next.fetch_add(1, Ordering::SeqCst);
            let client = Arc::new(Client {
                session,
                info: ClientInfo {
                    id,
                    addr: addr.to_string(),
                    device_name: Some(name),
                },
                tx: Mutex::new(tx),
            });
            // Every server frame uses this writer lock, including READY. Teardown may
            // invalidate the session concurrently, but cannot interleave or precede
            // an already generated READY with its later event sequence.
            let ready_sent = {
                let mut tx = client.tx.lock().unwrap();
                pool.inner
                    .clients
                    .lock()
                    .unwrap()
                    .insert(id, Arc::clone(&client));
                let _ = pool
                    .inner
                    .events
                    .send(ServerEvent::ClientAdded(client.info.clone()));
                pool.inner
                    .auth
                    .event(&session, EVENT_READY)
                    .is_some_and(|frame| wire::write_frame(&mut tx, &frame).is_ok())
            };
            if ready_sent {
                pool.receive(&mut stream, &session, app);
            }
            pool.inner.auth.disconnect(&session, EVENT_DISCONNECTED);
            pool.remove(id, None);
        });
    }
    fn handshake(
        &self,
        stream: &mut TcpStream,
        udp_port: u16,
    ) -> Result<(SessionId, String), String> {
        let hello: ClientHello = wire::read_json(stream)?;
        let context = self
            .inner
            .auth
            .begin(hello, std::env::consts::OS, udp_port)?;
        wire::write_json(stream, &context.challenge)?;
        let finish: ClientFinish = wire::read_json(stream)?;
        let session = self.inner.auth.finish(&context, finish, self.inner.max)?;
        Ok((session, context.hello.device_name))
    }
    fn receive<A: Application>(
        &self,
        stream: &mut TcpStream,
        session: &SessionId,
        app: Arc<Mutex<A>>,
    ) {
        while self.inner.auth.is_live(session) {
            match wire::read_frame(stream, FRAME_OVERHEAD + MAX_INPUT) {
                Ok(ReadFrame::Idle) => continue,
                Ok(ReadFrame::Eof) | Err(_) => break,
                Ok(ReadFrame::Data(frame)) => {
                    let result = self.inner.auth.with_input(
                        Some(session),
                        Transport::Tcp,
                        &frame,
                        |payload| match app.lock() {
                            Ok(mut app) => app.dispatch_to_device(payload),
                            Err(_) => ConnectionStatus::Disconnected,
                        },
                    );
                    if !matches!(result, Ok(ConnectionStatus::Connected)) {
                        break;
                    }
                }
            }
        }
    }
    fn remove(&self, id: usize, frame: Option<Vec<u8>>) {
        let client = self.inner.clients.lock().unwrap().remove(&id);
        if let Some(client) = client {
            if let Ok(mut tx) = client.tx.lock() {
                if let Some(frame) = frame {
                    let _ = wire::write_frame(&mut tx, &frame);
                }
                let _ = tx.shutdown(Shutdown::Both);
            }
            let _ = self
                .inner
                .events
                .send(ServerEvent::ClientRemoved(client.info.clone()));
        }
    }
    pub fn terminate_client(&self, id: usize) -> Result<(), String> {
        let session = self
            .inner
            .clients
            .lock()
            .unwrap()
            .get(&id)
            .map(|v| v.session)
            .ok_or("Client is no longer connected")?;
        let frame = self.inner.auth.disconnect(&session, EVENT_DISCONNECTED);
        self.remove(id, frame);
        Ok(())
    }
    pub fn close_sessions(&self, frames: HashMap<SessionId, Vec<u8>>) {
        let clients: Vec<_> = self
            .inner
            .clients
            .lock()
            .unwrap()
            .iter()
            .filter(|(_, v)| {
                frames.contains_key(&v.session) || !self.inner.auth.is_live(&v.session)
            })
            .map(|(id, v)| (*id, v.session))
            .collect();
        for (id, session) in clients {
            self.remove(id, frames.get(&session).cloned());
        }
    }
    pub fn connected_clients(&self) -> Vec<ClientInfo> {
        self.inner
            .clients
            .lock()
            .unwrap()
            .values()
            .map(|v| v.info.clone())
            .collect()
    }
}
#[cfg(test)]
mod tests;
