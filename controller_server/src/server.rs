use std::{
    collections::HashMap, 
    io::{Read, Write}, 
    net::{SocketAddr}, 
    sync::{Arc, Mutex}, 
    thread
};

// Sync
use std::sync::mpsc::{channel, Sender, Receiver};
use std::net::TcpListener;
use std::net::TcpStream;

use local_ip_address::local_ip;
use serde::{Deserialize, Serialize};

const DEFAULT_CLIENT_PORT: usize = 7878;

/// Creates a TcpListener using the local machine's IP address
fn create_socket(port: usize) -> TcpListener {
    let local_ip = local_ip().unwrap();
    log::debug!("Created new Sync socket: {local_ip}:{port}");
    TcpListener::bind(format!("{local_ip}:{port}")).unwrap()
}

//  ---------------------------------------
//              Application
//  ---------------------------------------

pub enum ConnectionStatus {
    Disconnected,
    Connected,
}

/// Represents a remote server application that is capable of handling
/// inputs in byte arrays.
/// This handling is server-specific (coud be from changing server software to just update 
/// the mouse position, or input keyboard keys)
pub trait Application: Sync + Send {
    /// Invoked whenever the server receives a new input from a client.
    /// This is the only entry-point for the remote Application - It should parse
    /// the input, and have some effect on the server.
    /// 
    /// # Arguments
    /// 
    /// * `input` - The input received from the client encoded into a byte array
    /// 
    /// # Returns
    /// 
    /// The current connection status. There should always be an input from the client that closes
    /// the connection. The return value is used to check for that command, and close the
    /// connection if such command is issued, or keep the connection alive otherwise.
    /// 
    fn dispatch_to_device(&mut self, input: &[u8]) -> ConnectionStatus;
}

//  ---------------------------------------
//                  SERVER
//  ---------------------------------------


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

pub struct Server<A: Application> {
    clients: ClientPool,
    config: ServerConfig,
    /// The application that will handle all client's requests.
    app: Arc<Mutex<A>>,
}

const SERVER_REACHED_MAX_CONCURRENT_CLIENTS: i32 = -1;

/// Data sent to a brand new client specifying both:
/// 1) The new port to which the client should connect.
/// 2) The server's OS type
#[derive(Debug, Serialize, Deserialize)]
pub struct NewClientResponse {
    port: i32,
    server_os: String,
}

pub enum ServerRequest {
    InitServer,
    TerminateServer,
    TerminateClient(usize),
}
pub enum ServerResponse {
    ServerStarted(String),
    ServerTerminated,
    ClientTerminated(usize),
}

#[derive(Debug)]
pub struct ServerCommunicator {
    sender_channel: Sender::<ServerRequest>,
    receiver_channel: Receiver::<ServerResponse>,
}

impl ServerCommunicator {
    /// Sends a request to the server.
    pub fn send_request(&self, request: ServerRequest) {
        self.sender_channel.send(request).unwrap();
    }

    /// Receives a response from the server.
    pub fn receive_response(&mut self) -> Result<ServerResponse, std::sync::mpsc::RecvError> {
        self.receiver_channel.recv()
    }
}


impl<A: Application + 'static> Server<A> {

    /// Runs the server.
    ///
    /// This call is blocking, and allows the server to wait for
    /// new client connection requests at port 7878.
    /// 
    /// Once a new connection to a new client is established, that client is assigned a new
    /// isolated socket with its own port. Each client then connects to the server through its own
    /// assigned socket.
    /// 
    /// The port 7878 is only used as a common ground to establish new connections with new clients.
    pub fn start(config: ServerConfig, app: A) -> ServerCommunicator {
        // Initialize logger with default settings
        env_logger::init(); 
        let (clients, receiver) = ClientPool::new(config.max_clients);

        // start async await client termination commands thread
        clients.start_termination_listener(receiver);

        let (send_to_server, receive_from_client) = channel::<ServerRequest>();
        let (send_to_client, receive_from_server) = channel::<ServerResponse>();
        let starting_port = config.starting_port;

        let mut server = Server {
            clients, 
            config,
            app: Arc::new(Mutex::new(app))
        };

        

        thread::spawn(move || {
            let socket = create_socket(starting_port);
            // non blocking
            server.start_commands_listener(send_to_client, receive_from_client);
            // blocking
            server.start_client_listener(socket);
        });

        // return channel endpoints to send messages and also receive messages to / from the server
        ServerCommunicator {
            sender_channel: send_to_server,
            receiver_channel: receive_from_server,
        }
    }

    /// Creates a new thread that listens for server commands.
    fn start_commands_listener(&self, sender: Sender<ServerResponse>, receiver: Receiver<ServerRequest>) {
        let port: usize = self.config.starting_port;

        thread::spawn( move || {
            loop {
                match receiver.recv() {
                    Ok(ServerRequest::InitServer) => {
                        log::info!("Server initialized successfully.");
                        let local_ip = local_ip().unwrap();
                        let response = ServerResponse::ServerStarted(format!("{local_ip}:{}", port));
                        sender.send(response).unwrap();
                    }
                    Ok(ServerRequest::TerminateServer) => {
                        log::info!("Server terminated successfully.");
                        sender.send(ServerResponse::ServerTerminated).unwrap();
                    }
                    Ok(ServerRequest::TerminateClient(client_id)) => {
                        log::info!("Terminating client with id: {client_id}");
                        sender.send(ServerResponse::ClientTerminated(client_id)).unwrap();
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
                stream.set_nodelay(true).unwrap();

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
            Err(e) => log::error!("Could not accept connection! {}", e)
        }
    }
}


//  ---------------------------------------
//            CLIENT CONNECTIONS
//  ---------------------------------------

const CLIENT_POOL_RESERVED_ID: usize = 0;

/// Represents a termination command for a client thread running on
/// the server upon the mobile client disconnects from the server's
/// side client.
#[derive(Debug)]
struct Terminate {
    client_id: usize,
}
/// Represents a pool of all client connections.
struct ClientPool {
    client_id_counter: usize,

    max_concurrent_clients_allowed: usize,

    /// Store clients by id
    /// Must be inside a mutex - there could be conflicts between
    /// creating and removing clients since they run in different
    /// threads
    clients: Arc<Mutex<HashMap<usize, Client>>>,
    
    /// Passed to each client in the client pool
    /// Used to send the `Terminate` command
    sender: Sender<Terminate>,
}

impl ClientPool {

    pub fn new(max_clients: usize) -> (ClientPool, Receiver<Terminate>) {
        let (sender, receiver) = channel();
        let pool = ClientPool {
            // IDs must start at 1, to differ from base port used to receive new client requests
            client_id_counter: 1,
            max_concurrent_clients_allowed: max_clients,
            clients: Arc::new(Mutex::new(HashMap::new())),
            sender,
        };

        (pool, receiver)
    }

    /// Add a new client connection to the pool.
    ///
    /// For each new client, the id increases by 1, as well as the port.
    /// Client ids start at 0, and go up to max usize
    pub fn add<A: Application + 'static>(&mut self, addr: SocketAddr, app: Arc<Mutex<A>>) -> Result<usize, String> {
        let mut clients = self.clients.lock().unwrap();

        if clients.len() == self.max_concurrent_clients_allowed {
            return Err("Maximum number of concurrent clients reached!".to_string());
        }

        let new_client = Client::launch_new_client(
            addr,
            self.client_id_counter,
            app,
            self.sender.clone()
        );

        // insert new client only if it doesn't exist yet
        let port = new_client.port;
        clients.entry(self.client_id_counter).or_insert(new_client);


        self.client_id_counter+=1;

        Ok(port)
    }

    /// Starts a thread that listens for client thread's termination requests.
    /// These 'clients' are actually the threads running in the server. The requests
    /// are used to remove the respective client from the pool.
    pub fn start_termination_listener(&self, receiver: Receiver<Terminate>) {
        let clients = Arc::clone(&self.clients);

        thread::spawn(move || {
            while let Ok(Terminate { client_id }) = receiver.recv() {

                // terminate listener
                if client_id == CLIENT_POOL_RESERVED_ID {
                    return;
                }

                let mut clients = clients.lock().unwrap();
                match clients.remove(&client_id) {
                    Some(client) => log::info!("Removed client with id {:?}: {:?}", client_id, client.address),
                    None => log::error!("Tried to remove client {:?} but he wasn't in the pool!", client_id)
                }
            }
        });
    }

    pub fn shutdown(&self) {
        self.sender
            .send(Terminate {
                client_id: CLIENT_POOL_RESERVED_ID,
            })
            .unwrap();
    }
}


#[derive(Copy, Clone)]
struct Client {
    address: SocketAddr,
    id: usize,
    port: usize,
}

impl Client {
    /// Creates a new client, which consists of a thread waiting for incomming packets.
    ///
    /// Upon receiving an incoming message, send it to the application to be parsed.
    /// All information sent/received is in bytes.
    /// Calling this function creates a new thread that listens to requests.
    fn launch_new_client<A: Application + 'static>(
        address: SocketAddr, 
        id: usize, 
        app: Arc<Mutex<A>>,
        remove_client: Sender<Terminate>
    ) -> Client {
        let port = DEFAULT_CLIENT_PORT + id;
        let socket = create_socket(port);

        let client = Client{ address, id, port };
        
        // Create thread
        thread::spawn(move || {
            log::info!("Client created {:?} @ {:?}:{:?}", id, address, port);
            match socket.accept() {
                Ok((stream, _)) => {
                    Client::handle_requests(&client, stream, app);
                }
                Err(e) => {
                    log::error!("Could not parse stream in Client {id}: {}", e);
                }
            }

            // remove the client upon error or connection termination
            remove_client.send(Terminate{ client_id: id }).unwrap();
        });
        client.clone()
    }

    /// Handle incomming client inputs.
    ///
    /// Sends the received bytes up to the application to handle the input
    fn handle_requests(client: &Client, mut stream: TcpStream, app: Arc<Mutex<impl Application + 'static>>) {
        // make the reads blocking - wait indefinetely for client input
        // stream.set_read_timeout(None).expect("Could not set read timeout."); 
        loop {
            let mut bytes = [0 ; 1024];

            match stream.read(&mut bytes) {
                // Normal processing
                Ok(bytes_size) => {
                    if bytes.is_empty() { continue };

                    let bytes = &bytes[..bytes_size];

                    if let ConnectionStatus::Disconnected = app.lock().unwrap().dispatch_to_device(bytes) {
                        log::info!("Client disconnected");
                        break;
                    }
                }
                // Error on connection (possibly abrupt disconnection by client)
                Err(e) => {
                    log::info!("Client {:?} listening at {:?} disconnected: {:?}", client.id, client.address, e);
                }
            }
        }
    }
}