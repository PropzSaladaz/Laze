use std::{
    collections::HashMap, 
    io::{BufReader, Write}, 
    net::{SocketAddr, TcpListener, TcpStream}, 
    sync::{mpsc, Arc, Mutex}, 
    thread
};

use local_ip_address::local_ip;

use super::messages::{NewClientResponse};

const DEFAULT_PORT: u16 = 7878;

fn create_socket(port: u16) -> TcpListener {
    println!("Created new socket: {port}");
    let local_ip = local_ip().unwrap();
    TcpListener::bind(format!("{local_ip}:{port}")).unwrap()
}

pub trait Application: Sync + Send {
    fn handle(&self, input: &[u8]);
}

// SERVER ---------------------------------------

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
pub enum ServerError {
    ServerCreationError,
}

pub struct Server<T: Application> {
    clients: ClientPool<T>,
    config: ServerConfig,
}



impl<T: Application + 'static> Server<T> {
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

    pub fn start(&mut self) {
        let socket = create_socket(DEFAULT_PORT);
        loop {
            match socket.accept() {
                Ok((mut stream, addr)) => {
                    println!("new socket: {:#?}", &stream);
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

struct ClientPool<T: Application> {
    clients: HashMap<SocketAddr, Client>,
    app: Arc<Mutex<T>>,
    sender: mpsc::Sender<Terminate>,
    receiver: Arc<mpsc::Receiver<Terminate>>
}

impl<T: Application + 'static> ClientPool<T> where T: Application {
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
    fn new(address: SocketAddr, id: usize, app: Arc<Mutex<impl Application + 'static>>) -> Client {
        let port = DEFAULT_PORT + id as u16;
        let socket = create_socket(port);
        // Create thread
        let thread = thread::spawn(move || {
            println!("socket {:#?}", socket);
            for stream in socket.incoming() {
                match stream {
                    Ok(stream) => {
                        println!("stream-client: {:#?}", stream);
                        // convert received request into bytes & pass to application
                        let buf_reader = BufReader::new(&stream);
                        let bytes = buf_reader.buffer();
                        app.lock().unwrap().handle(bytes);
                    }
                    Err(e) => {
                        eprintln!("Could not parse stream in Client {id}: {}", e);
                        break;
                    }
                }
                println!("after match");
            }
            println!("after for");
        });
        Client { address, id, port, thread }
    }
}

struct Terminate;