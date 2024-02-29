use std::{
    io::BufReader, net::{SocketAddr, TcpListener}, sync::{mpsc, Arc, Mutex}, thread
};
use local_ip_address::local_ip;
use serde::de::value::Error;

const DEFAULT_PORT: u32 = 7878;




fn create_socket(port: u16) -> TcpListener {
    let local_ip = local_ip().unwrap();
    TcpListener::bind(format!("{local_ip}:{port}")).unwrap()
}


trait Application {
    fn handle(input: &[u8]);
}

// DEVICE APP ---------------------------------------
// TODO
struct DeviceApp {
}
// TODO
impl Application for DeviceApp {
    fn handle(input: &[u8]) {
        println!("handled!!");
    }
}

impl DeviceApp {
    fn new() {

    }
}


// SERVER ---------------------------------------

pub struct ServerConfig {
    starting_port: u16,
    max_clients: usize,
}

pub enum ServerError {
    ServerCreationError,
}

pub struct Server<T: Application> {
    clients: ClientPool<T>,
    config: ServerConfig,
}


impl<T: Application> Server<T> {
    pub fn build(config: &ServerConfig) -> Result<Server<T>, ServerError> {
        let (sender, receiver) = mpsc::channel();
        let clients = ClientPool {
            clients: vec![],
            sender,
            app: Arc::new(Mutex::new(DeviceApp::new())),
            receiver: Arc::new(receiver),
        };

        Ok(Server {
            clients,
            config,
        })
    }

    pub fn start(&self) {
        let socket = create_socket(DEFAULT_PORT);
        loop {
            match socket.accept() {
                Ok((socket, addr)) => {
                    self.clients.add(&addr);
                }
                Err(e) => {
                    eprintln!("Could not accept connection! {}", e);
                }
            }
        }
    }
}

struct ClientPool<T: Application> {
    clients: Vec<Client>,
    app: Arc<Mutex<T>>,
    sender: mpsc::Sender<Terminate>,
    receiver: Arc<mpsc::Sender<Terminate>>
}

impl<T: Application> ClientPool<T> {
    pub fn add(&self, addr: &SocketAddr) {
        self.clients.push(Client::new(
            addr,
            self.clients.len(),
            self.app.clone()
        ));
    }
}

/// Represents a Client handler.
/// 
/// Parses requests into the specified device
struct Client {
    address: SocketAddr,
    id: u8,
    thread: thread::JoinHandle<()>
}

impl Client {
    fn new(address: &SocketAddr, id: usize, app: Arc<Mutex<dyn Application>>) -> Client {
        let socket = create_socket(DEFAULT_PORT + id);
        // Create thread
        let thread = thread::spawn(move || {
            for stream in socket.incoming() {
                match stream {
                    Ok(stream) => {
                        // convert received request into bytes & pass to application
                        let buf_reader = BufReader::new(&mut stream);
                        let bytes = buf_reader.buffer();
                        app.lock().unwrap().handle(bytes);
                    }
                    Err(e) => {
                        eprintln!("Could not parse stream in Client {id}: {}", e);
                        break;
                    }
                }
            }
        });
        Client { address, id, thread }
    }
}

struct Terminate;