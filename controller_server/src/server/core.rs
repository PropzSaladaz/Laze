use std::{io::Write, net::{SocketAddr, TcpStream}, sync::{mpsc::channel, Arc, Mutex}, thread, time::Duration};

use serde::{Deserialize, Serialize};

use crate::logger::Loggable;

use super::{
    application::Application,
    client_pool::ClientPool,
    command_listener::{CommandListener, ProcessError},
    command_sender::CommandSender,
    commands::{ServerRequest, ServerResponse, ServerStarted, ServerTerminated, ClientTerminated},
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
    /// It also creates a thread that listens for server commands through channels.
    /// 
    /// Once a new connection to a new client is established, that client is assigned a new
    /// isolated socket with its own port. Each client then connects to the server through its own
    /// assigned socket.
    /// 
    /// The port 7878 is only used as a common ground to establish new connections with new clients.
    pub fn start(config: ServerConfig, app: A) -> CommandSender {
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

            // set command listener callback for parsing server commands before starting command listener thread
            command_listener.set_command_processor({
                let server = Arc::clone(&server);
                move |req| {
                    Self::command_parser(server.clone(), req)
                }
            });

            // non blocking
            let delay = Duration::from_millis(1000);
            let handler = command_listener.listen(delay);
            
            // blocking - only exits when the server is terminated
            Self::start_client_listener(server);
            Self::static_log_info("Client listener thread has exited.");

            // await for non-blocking thread
            handler.schedule_shutdown();
            Self::static_log_info("Waiting on command listener thread to shutdown.");
            handler.wait_for_exit();
            Self::static_log_info("Command listener thread has exited.");
        });

        // return channel endpoints to send messages and also receive messages to / from the server
        CommandSender::new(
            send_to_server,
            receive_from_server
        )

    }

    /// Main loop.
    /// Waits on a new client connection.
    fn start_client_listener(server: Arc<Mutex<Self>>) {
        let mut server_is_scheduled_for_termination ;

        let starting_port = {
            let lock = server.lock().unwrap();
            server_is_scheduled_for_termination = lock.terminate_signal;
            lock.config.starting_port
        };
        let socket = utils::create_socket(starting_port);
        // configure it such that .accept() returns immediately
        // without blocking the thread. Allows to sleep for a while if no
        // new connections are available.
        socket.set_nonblocking(true).unwrap();

        Self::static_log_info(&format!("Starting client listener: {}", socket.local_addr().unwrap()));
        
        loop {
            if server_is_scheduled_for_termination {
                Self::static_log_info(&format!("Terminated client listener thread. Server is scheduled for termination."));
                break;
            }

            match socket.accept() {
                Ok(connection) => {
                    Self::handle_new_client(&server, connection);
                }
                Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                    // No new connections available, sleep for a while
                    thread::sleep(Duration::from_millis(100));
                }
                Err(e) => {
                    Self::static_log_error(&format!("Error accepting connection: {}", e));
                }
            }

            // pull the server lock to check if the server is scheduled for termination
            server_is_scheduled_for_termination = {
                let lock = server.lock().unwrap();
                lock.terminate_signal
            };
        }
    }

    // Upon receiving a new connection request, create a new client
    // waiting on a new port and send the new socket's port dedicated
    // to that connection to the client
    fn handle_new_client(server: &Arc<Mutex<Self>>, connection: (TcpStream, SocketAddr)) {
        let label = "[ClientListener]:";
        let (mut stream, addr) = connection;
        Self::static_log_info(&format!("{label} Received client connection"));
        let mut lock = server.lock().unwrap();

        if lock.listening_to_clients {
            Self::static_log_debug(&format!("{label} Received connection from address: {:?}", addr));
            // try adding new client to pool
            let app = Arc::clone(&lock.app);
            let port = match lock.clients.add(addr, app) {
                Ok(connection_port) => {
                    Self::static_log_info(&format!("{label} Opened socket for new client at {connection_port}"));
                    connection_port as i32
                },
                Err(reason) => {
                    Self::static_log_error(&format!("{reason}"));
                    SERVER_REACHED_MAX_CONCURRENT_CLIENTS
                }
            };

            let data = serde_json::to_vec(&NewClientResponse { 
                port,
                server_os: std::env::consts::OS.to_owned(), // send the server OS to client
            }).unwrap();

            stream.write_all(&data).unwrap();

            Self::static_log_debug(&format!("{label} Sent new client response: {:?}", data));
        }
        else {
            Self::static_log_warn(&format!("{label} Received connection from address: {:?}, but server is not listening to clients!", addr));
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
                lock.clients.shutdown();
                Ok(ServerResponse::ServerTerminated(ServerTerminated {}))
            }
            ServerRequest::TerminateClient(client_id) => {
                match lock.clients.terminate_client(client_id) {
                    Ok(_) => Ok(ServerResponse::ClientTerminated(ClientTerminated { client_id })),
                    Err(err_msg) => {
                        Self::static_log_error(&err_msg);
                        Err(ProcessError { message: err_msg })
                    }
                }
            }
        }
    }
}