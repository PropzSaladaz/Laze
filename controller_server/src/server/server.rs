use std::{io::Write, net::{SocketAddr, TcpStream}, sync::{mpsc::channel, Arc, Mutex}, thread, time::Duration};

use serde::{Deserialize, Serialize};

use crate::server::{command_listener::{CommandListener, ProcessError}, ClientTerminated, ServerStarted, ServerTerminated};

use super::{
    application::Application,
    client_pool::ClientPool,
    server_communicator::{ServerCommunicator, ServerRequest, ServerResponse},
    utils
};

const SERVER_REACHED_MAX_CONCURRENT_CLIENTS: i32 = -1;

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

    /// Indicates whether the server is currently listening to client requests.
    /// If false, the server will only accept requests from the server controller (tauri app).
    listening_to_clients: bool,

    /// Indicates whether the server is currently terminating.
    terminate_signal: bool,
}

impl<A: Application + 'static> Server<A> {

    /// Runs the server.
    ///
    /// This call is non-blocking, and allows the server to wait for
    /// new client connection requests at port 7878.
    /// It also creates a thread that listens for server commands at port 7878 - 1 = 7877
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

        // Unidirectional channel from ServerController (client) -> Server
        let (send_to_server, receive_from_client) = channel::<ServerRequest>();
        // Unidirectional channel from Server -> ServerController (client)
        let (send_to_client, receive_from_server) = channel::<ServerResponse>();

        // will listen for commands from server controller and will parse them.
        let command_listener = CommandListener::new(send_to_client, receive_from_client);

        thread::spawn(move || {

            let server = Arc::new(Mutex::new(Server {
                clients, 
                config,
                app: Arc::new(Mutex::new(app)),
                listening_to_clients: false,
                terminate_signal: false,
            }));

            // set command listener callback before starting command listener thread
            command_listener.set_command_processor({
                let server = Arc::clone(&server);
                move |req| {
                    Self::command_parser(server.clone(), req)
                }
            });

            // non blocking - starts
            let delay = Duration::from_millis(1000);
            let handler = command_listener.listen(delay);
            
            // blocking
            Self::start_client_listener(server);

            // await for non-blocking thread
            handler.wait_for_exit();
        });

        // return channel endpoints to send messages and also receive messages to / from the server
        ServerCommunicator::new(
            send_to_server,
            receive_from_server
        )

    }

    /// Main loop.
    /// Waits on a new client connection.
    fn start_client_listener(server: Arc<Mutex<Self>>) {
        let starting_port = {
            let lock = server.lock().unwrap();
            lock.config.starting_port
        };
        let socket = utils::create_socket(starting_port);
        log::info!("Starting client listener: {}", socket.local_addr().unwrap());
        loop {
            let connection = socket.accept();
            Self::handle_new_client(&server, connection);
        }
    }

    // Upon receiving a new connection request, create a new client
    // waiting on a new port and send the new socket's port dedicated
    // to that connection to the client
    fn handle_new_client(server: &Arc<Mutex<Self>>, connection: Result<(TcpStream, SocketAddr), std::io::Error>) {
        let label = "[ClientListener]:";
        match connection {
            Ok((mut stream, addr)) => {
                log::info!("{label} Received client connection");
                let mut lock = server.lock().unwrap();

                if lock.listening_to_clients {
                    log::debug!("{label} Received connection from non-local address: {:?}", addr);
                    // try adding new client to pool
                    let app = Arc::clone(&lock.app);
                    let port = match lock.clients.add(addr, app) {
                        Ok(connection_port) => {
                            log::info!("{label} Opened socket for new client at {connection_port}");
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

                    log::debug!("{label} Sent new client response: {:?}", data);
                }
                else {
                    log::warn!("{label} Received connection from non-local address: {:?}, but server is not listening to clients!", addr);
                }
            }
            Err(e) => log::error!("{label} Could not accept connection! {}", e)
        }
    }


    /// Parses a command from the server.
    /// Should be passed as callback function to the `command_listener` struct when constructing the server.
    fn command_parser(server: Arc<Mutex<Self>>, req: ServerRequest) -> Result<ServerResponse, ProcessError> {
        let mut lock = server.lock().unwrap();

        match req {
            ServerRequest::InitServer => {
                // send response to the server
                lock.listening_to_clients = true;
                Ok(ServerResponse::ServerStarted(ServerStarted { }))
            }
            ServerRequest::TerminateServer => {
                lock.terminate_signal = true;
                Ok(ServerResponse::ServerTerminated(ServerTerminated {}))
            }
            ServerRequest::TerminateClient(client_id) => {
                lock.clients.terminate_client(client_id);
                Ok(ServerResponse::ClientTerminated(ClientTerminated { client_id }))
            }
        }
    }
}