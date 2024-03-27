use std::{
    collections::HashMap, 
    io::{Read, Write}, 
    net::{SocketAddr, TcpListener, TcpStream}, 
    sync::{mpsc, Arc, Mutex}, 
    thread
};

use local_ip_address::local_ip;

use super::messages::NewClientResponse;

const DEFAULT_PORT: u16 = 7878;

/// Creates a TcpListener using the local machine's IP address
fn create_socket(port: u16) -> TcpListener {
    println!("Created new socket: {port}");
    let local_ip = local_ip().unwrap();
    TcpListener::bind(format!("{local_ip}:{port}")).unwrap()
}

pub enum ConnectionStatus {
    Disconnected,
    Connected,
}
pub trait Application: Sync + Send {
    fn handle(&mut self, input: &[u8]) -> ConnectionStatus;
}

//  ---------------------------------------
//                  SERVER
//  ---------------------------------------


/// Represents the server configuration.
///
/// All new connections will start form the specified port
/// increasing by 1 for each new connection until reaching
/// the max_clients.
pub struct ServerConfig {
    starting_port: u16,
    max_clients: usize,
}

impl ServerConfig {
    pub fn new(starting_port: u16, max_clients: usize) -> Self {
        Self {
            starting_port, max_clients
        }
    }
}

#[derive(Debug)]
pub enum ServerError {}

pub struct Server<T: Application> {
    clients: ClientPool<T>,
    config: ServerConfig,
}



impl<T: Application + 'static> Server<T> {
    /// Initialize server's internal structures.
    ///
    /// app: Is the application that will be called to handle incomming requests.
    pub fn build(config: ServerConfig, app: T) -> Result<Self, ServerError> {
        let (sender, receiver) = mpsc::channel();
        let clients = ClientPool {
            clients: HashMap::new(),
            sender,
            app: Arc::new(Mutex::new(app)),
            receiver: Arc::new(receiver),
        };

        Ok(Server {
            clients, config
        })
    }

    /// Run the server.
    ///
    /// This call is blocking, and allows the server to wait for
    /// new client connection requests at port 7878.
    pub fn start(&mut self) {
        let socket = create_socket(self.config.starting_port);
        loop {
            // Upon receiving a new connection request, create a new client
            // waiting on a new port and send the new socket's port dedicated
            // to that connection to the client
            match socket.accept() {
                Ok((mut stream, addr)) => {
                    let port = self.clients.add(addr);
                    let data = serde_json::to_vec(&NewClientResponse { port }).unwrap();
                    stream.write_all(data.as_slice())
                        .expect("Could not write into socket's client");
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
struct ClientPool<T: Application> {
    clients: HashMap<SocketAddr, Client>,
    app: Arc<Mutex<T>>,
    sender: mpsc::Sender<Terminate>,
    receiver: Arc<mpsc::Receiver<Terminate>>
}

impl<T: Application + 'static> ClientPool<T> where T: Application {
    /// Add a new client connection to the pool.
    ///
    /// For each new client, the id increases by 1, as well as the port.
    pub fn add(&mut self, addr: SocketAddr) -> u16 {
        let new_client = Client::new(
            addr,
            self.clients.len() + 1,
            self.app.clone()
        );
        // insert new client only if it doesn't exist yet
        let port = new_client.port;
        self.clients.entry(addr).or_insert(new_client);
        port
    }
}

/// Represents a Client handler.
/// 
/// Parses requests into the specified device
struct Client {
    address: SocketAddr,
    id: usize,
    port: u16,
    thread: thread::JoinHandle<()>
}

impl Client {
    /// Creates a new client, which consists of a thread waiting for incomming packets.
    ///
    /// Upon receiving an incoming message, send it to the application to be parsed.
    // All information sent/received is in bytes.
    fn new(address: SocketAddr, id: usize, app: Arc<Mutex<impl Application + 'static>>) -> Client {
        let port = DEFAULT_PORT + id as u16;
        let socket = create_socket(port);

        // Create thread
        let thread = thread::spawn(move || {

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
            if let ConnectionStatus::Disconnected = app.lock().unwrap().handle(bytes) {
                println!("Client disconnected");
                break;
            }
        }
    }
}

struct Terminate;