use super::{
    application::Application,
    client_pool::ClientPool,
    command_listener::{CommandListener, ProcessError},
    command_sender::CommandSender,
    commands::{
        ClientTerminated, ServerRequest, ServerResponse, ServerStarted, ServerStopped,
        ServerTerminated,
    },
    discovery::{start_discovery_listener, DiscoveryHandle},
    udp_input::{start_udp_input_listener, UdpInputHandle, UDP_INPUT_PORT},
    utils,
};
use crate::{
    logger::Loggable,
    security::{AuthManager, PairingInvite, TrustedDevice},
};
use serde::Serialize;
use std::{
    marker::PhantomData,
    sync::{
        atomic::{AtomicBool, Ordering},
        mpsc::channel,
        Arc, Mutex,
    },
    thread,
    time::Duration,
};
use tokio::sync::broadcast;

pub struct ServerConfig {
    starting_port: usize,
    max_clients: usize,
}
impl ServerConfig {
    pub fn new(starting_port: usize, max_clients: usize) -> Self {
        Self {
            starting_port,
            max_clients,
        }
    }
}
#[derive(Debug, Clone)]
pub enum ServerEvent {
    ClientAdded(ClientInfo),
    ClientRemoved(ClientInfo),
    ClientUpdated(ClientInfo),
}
#[derive(Debug, Clone, Serialize)]
pub struct ClientInfo {
    pub id: usize,
    pub addr: String,
    pub device_name: Option<String>,
}
pub struct ServerHandler {
    event_pub: broadcast::Sender<ServerEvent>,
    command_sender: CommandSender,
    discovery_handle: Option<DiscoveryHandle>,
    udp_input_handle: Option<UdpInputHandle>,
    auth: Arc<AuthManager>,
    clients: ClientPool,
}
impl ServerHandler {
    pub fn subscribe_events(&self) -> broadcast::Receiver<ServerEvent> {
        self.event_pub.subscribe()
    }
    pub fn start_server(&self) -> Result<(), std::sync::mpsc::SendError<ServerRequest>> {
        self.command_sender.send_request(ServerRequest::InitServer)
    }
    pub fn stop_server(&self) -> Result<(), std::sync::mpsc::SendError<ServerRequest>> {
        self.command_sender.send_request(ServerRequest::StopServer)
    }
    pub fn terminate_server(&self) -> Result<(), std::sync::mpsc::SendError<ServerRequest>> {
        self.command_sender
            .send_request(ServerRequest::TerminateServer)
    }
    pub fn terminate_client(
        &self,
        id: usize,
    ) -> Result<(), std::sync::mpsc::SendError<ServerRequest>> {
        self.command_sender
            .send_request(ServerRequest::TerminateClient(id))
    }
    pub fn receive_response(&mut self) -> Result<ServerResponse, std::sync::mpsc::RecvError> {
        self.command_sender.receive_response()
    }
    pub fn create_pairing_invite(
        &self,
        hosts: Vec<String>,
        port: u16,
        name: String,
    ) -> Result<PairingInvite, String> {
        self.auth.create_invite(hosts, port, name)
    }
    pub fn cancel_pairing_invite(&self, id: &str) {
        self.auth.cancel_invite(id);
    }
    pub fn trusted_devices(&self) -> Vec<TrustedDevice> {
        self.auth.trusted_devices()
    }
    pub fn revoke_phone(&self, id: &str) -> Result<(), String> {
        self.clients.revoke_phone(id)
    }
    pub fn connected_clients(&self) -> Vec<ClientInfo> {
        self.clients.connected_clients()
    }
}
impl Drop for ServerHandler {
    fn drop(&mut self) {
        self.clients.stop_sessions();
        let _ = self
            .command_sender
            .send_request(ServerRequest::TerminateServer);
        if let Some(handle) = self.discovery_handle.take() {
            handle.shutdown();
        }
        if let Some(handle) = self.udp_input_handle.take() {
            handle.shutdown();
        }
    }
}
pub struct Server<A: Application> {
    _app: PhantomData<A>,
}
impl<A: Application + 'static> Server<A> {
    /// The single TCP listener requires v2 mutual authentication before allocating a live client.
    pub fn start(
        config: ServerConfig,
        app: A,
        auth: Arc<AuthManager>,
    ) -> std::io::Result<ServerHandler> {
        let _ = env_logger::try_init();
        let socket = utils::create_socket(config.starting_port)?;
        socket.set_nonblocking(true)?;
        let (event_pub, _) = broadcast::channel(100);
        let clients = ClientPool::new(config.max_clients, event_pub.clone(), Arc::clone(&auth));
        let app = Arc::new(Mutex::new(app));
        let udp_input_handle = start_udp_input_listener(Arc::clone(&app), Arc::clone(&auth)).ok();
        let udp_port = if udp_input_handle.is_some() {
            UDP_INPUT_PORT
        } else {
            0
        };
        let discovery_handle =
            start_discovery_listener(config.starting_port as u16, auth.server_id()).ok();
        let (request_tx, request_rx) = channel();
        let (response_tx, response_rx) = channel();
        let terminated = Arc::new(AtomicBool::new(false));
        let listener = CommandListener::new(response_tx, request_rx);
        listener.set_command_processor({
            let clients = clients.clone();
            let auth = Arc::clone(&auth);
            let terminated = Arc::clone(&terminated);
            move |request| match request {
                ServerRequest::InitServer => {
                    auth.enable();
                    Ok(ServerResponse::ServerStarted(ServerStarted {}))
                }
                ServerRequest::StopServer => {
                    clients.stop_sessions();
                    Ok(ServerResponse::ServerStopped(ServerStopped {}))
                }
                ServerRequest::TerminateServer => {
                    clients.stop_sessions();
                    terminated.store(true, Ordering::SeqCst);
                    Ok(ServerResponse::ServerTerminated(ServerTerminated {}))
                }
                ServerRequest::TerminateClient(id) => clients
                    .terminate_client(id)
                    .map(|_| ServerResponse::ClientTerminated(ClientTerminated { client_id: id }))
                    .map_err(|message| ProcessError { message }),
            }
        });
        let command_handle = listener.listen(Duration::ZERO);
        thread::spawn({
            let clients = clients.clone();
            let auth = Arc::clone(&auth);
            move || {
                while !terminated.load(Ordering::SeqCst) {
                    match socket.accept() {
                        Ok((stream, addr)) if auth.enabled() => {
                            clients.admit(stream, addr, Arc::clone(&app), udp_port)
                        }
                        Ok((stream, _)) => {
                            let _ = stream.shutdown(std::net::Shutdown::Both);
                        }
                        Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                            thread::sleep(Duration::from_millis(10))
                        }
                        Err(e) => {
                            Self::static_log_error(&format!("Connection listener error: {e}"));
                            thread::sleep(Duration::from_millis(100));
                        }
                    }
                }
                command_handle.schedule_shutdown();
                command_handle.wait_for_exit();
            }
        });
        Ok(ServerHandler {
            event_pub,
            command_sender: CommandSender::new(request_tx, response_rx),
            discovery_handle,
            udp_input_handle,
            auth,
            clients,
        })
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn server_config() {
        let config = ServerConfig::new(8000, 10);
        assert_eq!(config.starting_port, 8000);
        assert_eq!(config.max_clients, 10);
    }
    #[test]
    fn client_info_serialization() {
        let info = ClientInfo {
            id: 1,
            addr: "127.0.0.1:8080".into(),
            device_name: Some("Test Device".into()),
        };
        let text = serde_json::to_string(&info).unwrap();
        assert!(text.contains("127.0.0.1:8080"));
        assert!(text.contains("\"id\":1"));
    }
    #[test]
    fn server_event_variants() {
        let info = ClientInfo {
            id: 1,
            addr: "127.0.0.1:8080".into(),
            device_name: None,
        };
        assert!(matches!(
            ServerEvent::ClientAdded(info.clone()),
            ServerEvent::ClientAdded(_)
        ));
        assert!(matches!(
            ServerEvent::ClientRemoved(info),
            ServerEvent::ClientRemoved(_)
        ));
    }
}
