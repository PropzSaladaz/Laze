use std::{io::Write, net::{SocketAddr, TcpListener, TcpStream}, sync::{mpsc::{channel, Receiver, Sender}, Arc, Mutex}, thread};

use serde::{Deserialize, Serialize};

use crate::server::{ClientTerminated, ServerStarted, ServerTerminated};

use super::{
    application::Application,
    client_pool::ClientPool,
    server_communicator::{ServerCommunicator, ServerRequest, ServerResponse},
    internal_communicator::{InternalServerCommSender, InternalServerCommReceiver},
    utils
};

/// Represents the server configuration.
///
/// All new connections will start from the specified port
/// increasing by 1 for each new connection until reaching
/// the max_clients.
pub struct ServerConfig {
    starting_port: usize,
    max_clients: usize,
}

impl ServerConfig {
    pub fn new(starting_port: usize, max_clients: usize) -> Self {
        Self {
            starting_port, max_clients
        }
    }
}

#[derive(Debug)]
pub enum ServerError {}

const SERVER_REACHED_MAX_CONCURRENT_CLIENTS: i32 = -1;

/// Data sent to a brand new client specifying both:
/// 1) The new port to which the client should connect.
/// 2) The server's OS type
#[derive(Debug, Serialize, Deserialize)]
pub struct NewClientResponse {
    port: i32,
    server_os: String,
}


pub struct Server<A: Application> {
    clients: ClientPool,
    config: ServerConfig,
    /// The application that will handle all client's requests.
    app: Arc<Mutex<A>>,

    listening_to_clients: bool,
    terminate_signal: bool,
}

impl<A: Application + 'static> Server<A> {

    /// Runs the server.
    ///
    /// This call is non-blocking, and allows the server to wait for
    /// new client connection requests at port 7878.
    /// It also creates a thread that listens for server commands
    /// 
    /// Once a new connection to a new client is established, that client is assigned a new
    /// isolated socket with its own port. Each client then connects to the server through its own
    /// assigned socket.
    /// 
    /// The port 7878 is only used as a common ground to establish new connections with new clients.
    pub fn start(config: ServerConfig, app: A) -> ServerCommunicator {
        // Initialize logger with default settings
        env_logger::init(); 
        let clients = ClientPool::new(config.max_clients);

        let (send_to_server, receive_from_client) = channel::<ServerRequest>();
        let (send_to_client, receive_from_server) = channel::<ServerResponse>();
        let starting_port = config.starting_port;

        let mut server = Server {
            clients, 
            config,
            app: Arc::new(Mutex::new(app)),
            listening_to_clients: false,
            terminate_signal: false,
        };

        thread::spawn(move || {
            let socket = utils::create_socket(starting_port);
            // non blocking
            server.start_commands_listener(send_to_client, receive_from_client);
            // blocking
            server.start_client_listener(socket);
        });

        // return channel endpoints to send messages and also receive messages to / from the server
        ServerCommunicator::new(
            send_to_server,
            receive_from_server
        )
    }

    /// Creates a new thread that listens for server commands.
    fn start_commands_listener(&self, sender: Sender<ServerResponse>, receiver: Receiver<ServerRequest>) {
        let mut internal_comm = InternalServerCommSender::new(self.config.starting_port);

        thread::spawn( move || {
            loop {
                match receiver.recv() {
                    Ok(ServerRequest::InitServer) => {
                        log::info!("Server initialized successfully.");
                        
                        match internal_comm.send_and_receive::<ServerRequest, ServerResponse, ServerStarted>(&ServerRequest::InitServer) { // blocking - sends & awaits for response
                            Ok(addr) => {
                                log::info!("Server started at address: {}", addr.addr);
                                // send response back to the client
                                let response = ServerResponse::ServerStarted(addr);
                                sender.send(response).unwrap();
                            },
                            Err(e) => {
                                log::error!("Failed to initialize server: {}", e);
                                // send error response back to the client
                                let response = ServerResponse::Error(e.to_string());
                                sender.send(response).unwrap();
                                continue;
                            }
                        }
                    }
                    Ok(ServerRequest::TerminateServer) => {
                        log::info!("Server terminated successfully.");
                        sender.send(ServerResponse::ServerTerminated(ServerTerminated{})).unwrap();
                    }
                    Ok(ServerRequest::TerminateClient(client_id)) => {
                        log::info!("Terminating client with id: {}", client_id);
                        sender.send(ServerResponse::ClientTerminated(ClientTerminated{client_id})).unwrap();
                    }
                    Err(e) => log::error!("Error receiving server request: {}", e),
                }
            }
        });
    }

    /// Main loop.
    /// Waits on a new client connection.
    fn start_client_listener(&mut self, socket: TcpListener) {
        loop {
            let connection = socket.accept();
            self.handle_new_client(connection);
        }
    }

    // Upon receiving a new connection request, create a new client
    // waiting on a new port and send the new socket's port dedicated
    // to that connection to the client
    fn handle_new_client(&mut self, connection: Result<(TcpStream, SocketAddr), std::io::Error>) {
        match connection {
            Ok((mut stream, addr)) => {
                log::info!("Received client connection");

                if let Some(req) = InternalServerCommReceiver::try_parse_request(&stream, &addr).unwrap() {
                    // if the request is from the server itself, handle it
                    let response = self.apply_request(req, addr);
                    stream.write_all(&serde_json::to_vec(&response).unwrap()).unwrap();
                }
                else if self.listening_to_clients {
                    log::debug!("Received connection from non-local address: {:?}", addr);
                    // try adding new client to pool
                    let port = match self.clients.add(addr, Arc::clone(&self.app)) {
                        Ok(connection_port) => {
                            log::info!("Opened socket for new client at {connection_port}");
                            connection_port as i32
                        },
                        Err(reason) => {
                            log::error!("{reason}");
                            SERVER_REACHED_MAX_CONCURRENT_CLIENTS
                        }
                    };

                    let data = serde_json::to_vec(&NewClientResponse { 
                        port,
                        server_os: std::env::consts::OS.to_owned(), // send the server OS to client
                    }).unwrap();

                    stream.write_all(&data).unwrap();

                    log::debug!("Sent new client response: {:?}", data);
                }
                else {
                    log::warn!("Received connection from non-local address: {:?}, but server is not listening to clients!", addr);
                }


            }
            Err(e) => log::error!("Could not accept connection! {}", e)
        }
    }


    fn apply_request(&mut self, req: ServerRequest, addr: SocketAddr) -> ServerResponse {
        match req {
            ServerRequest::InitServer => {
                log::info!("Received InitServer request from server at {addr}");
                // send response to the server
                self.listening_to_clients = true;
                ServerResponse::ServerStarted(ServerStarted { addr: format!("{}:{}", addr.ip(), addr.port()) })
            }
            ServerRequest::TerminateServer => {
                log::info!("Received TerminateServer request from server at {addr}");
                self.terminate_signal = true;
                ServerResponse::ServerTerminated(ServerTerminated {})
            }
            ServerRequest::TerminateClient(client_id) => {
                log::info!("Received TerminateClient request for client {client_id} from server at {addr}");
                self.clients.terminate_client(client_id);
                ServerResponse::ClientTerminated(ClientTerminated { client_id } )
            }
        }
    }
}