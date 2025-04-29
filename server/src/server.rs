use std::{
    collections::HashMap, 
    io::{Read, Write}, 
    net::{SocketAddr, TcpListener, TcpStream}, 
    sync::{mpsc, Arc, Mutex}, 
    thread
};

use local_ip_address::local_ip;
use serde::{Deserialize, Serialize};

const DEFAULT_CLIENT_PORT: usize = 7878;

/// Creates a TcpListener using the local machine's IP address
fn create_socket(port: usize) -> TcpListener {
    let local_ip = local_ip().unwrap();
    println!("Created new socket: {local_ip}:{port}");
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

/// Data sent to a brand new client specifying both:
/// 1) The new port to which the client should connect.
/// 2) The server's OS type
#[derive(Debug, Serialize, Deserialize)]
pub struct NewClientResponse {
    port: usize,
    server_os: String,
}


impl<A: Application + 'static> Server<A> {
    /// Initialize server's internal structures.
    ///
    /// # Arguments
    /// * `config` - Server configuration.
    /// * `app` - The application that will be called to handle incomming requests.
    pub fn build(config: ServerConfig, app: A) -> Result<Self, ServerError> {
        let (sender, receiver) = mpsc::channel();
        let clients = ClientPool::new(
            sender,
            Arc::new(receiver));

        Ok(Server {
            clients, 
            config,
            app: Arc::new(Mutex::new(app))
        })
    }

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
    pub fn start(&mut self) {
        let socket = create_socket(self.config.starting_port);
        loop {
            // Upon receiving a new connection request, create a new client
            // waiting on a new port and send the new socket's port dedicated
            // to that connection to the client
            match socket.accept() {
                Ok((mut stream, addr)) => {
                    println!("Received client connection");

                    if self.clients.len() < self.config.max_clients {
                        println!("Connection accepted");
                        let port = self.clients.add(addr, Arc::clone(&self.app));
                        let data = serde_json::to_vec(&NewClientResponse { 
                            port,
                            server_os: std::env::consts::OS.to_owned(), // send the server OS to client
                        }).unwrap();
                        stream.write_all(data.as_slice())
                            .expect("Could not write into socket's client");
                    }
                    else {
                        println!("Max clients reached - droping packet");
                    }

                }
                Err(e) => {
                    eprintln!("Could not accept connection! {}", e);
                }
            }
        }
    }
}


//  ---------------------------------------
//            CLIENT CONNECTIONS
//  ---------------------------------------

/// Represents a pool of all client connections.
struct ClientPool {
    client_id_counter: usize,
    clients: HashMap<SocketAddr, Client>,
    sender: mpsc::Sender<Terminate>,
    receiver: Arc<mpsc::Receiver<Terminate>>
}

impl ClientPool {

    pub fn new(
        sender: mpsc::Sender<Terminate>, 
        receiver: Arc<mpsc::Receiver<Terminate>>
    ) -> ClientPool {

        ClientPool {
            // IDs must start at 1, to differ from base port used to receive new client requests
            client_id_counter: 1,
            clients: HashMap::new(),
            sender,
            receiver
        }
    }

    /// Add a new client connection to the pool.
    ///
    /// For each new client, the id increases by 1, as well as the port.
    /// Client ids start at 0, and go up to max usize
    pub fn add<A: Application + 'static>(&mut self, addr: SocketAddr, app: Arc<Mutex<A>>) -> usize {

        let new_client = Client::launch_new_client(
            addr,
            self.client_id_counter,
            app
        );
        // insert new client only if it doesn't exist yet
        let port = new_client.port;
        self.clients.entry(addr).or_insert(new_client);


        self.client_id_counter+=1;

        port
    }

    pub fn len(&self) -> usize {
        self.clients.len()
    }
}

/// Represents a Client handler.
/// 
/// Parses requests into the specified device
struct Client {
    address: SocketAddr,
    id: usize,
    port: usize,
    thread: thread::JoinHandle<()>
}

impl Client {
    /// Creates a new client, which consists of a thread waiting for incomming packets.
    ///
    /// Upon receiving an incoming message, send it to the application to be parsed.
    /// All information sent/received is in bytes.
    /// Calling this function creates a new thread that listens to requests.
    fn launch_new_client<A: Application + 'static>(address: SocketAddr, id: usize, app: Arc<Mutex<A>>) -> Client {
        let port = DEFAULT_CLIENT_PORT + id;
        let socket = create_socket(port);

        // Create thread
        let thread = thread::spawn(move || {
            println!("Client created {:?} @ {:?}:{:?}", id, address, port);
            match socket.accept() {
                Ok((stream, _)) => {
                    Client::handle_request(stream, app);
                }
                Err(e) => {
                    eprintln!("Could not parse stream in Client {id}: {}", e);
                }
            }
        });
        Client { address, id, port, thread }
    }

    /// Handle incomming client inputs.
    ///
    /// Sends the received bytes up to the application to handle the input
    fn handle_request(mut stream: TcpStream, app: Arc<Mutex<impl Application + 'static>>) {
        // make the reads blocking - wait indefinetely for client input
        stream.set_read_timeout(None).expect("Could not set read timeout."); 
        loop {
            let mut bytes = [0 ; 1024];
            let bytes_size = stream.read(&mut bytes).unwrap();
            let bytes = &bytes[..bytes_size];

            if bytes.is_empty() { continue };
            if let ConnectionStatus::Disconnected = app.lock().unwrap().dispatch_to_device(bytes) {
                println!("Client disconnected");
                break;
            }
        }
    }
}

struct Terminate;