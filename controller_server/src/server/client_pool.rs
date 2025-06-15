use std::{collections::HashMap, io::Read, net::{SocketAddr, TcpStream}, sync::{mpsc::{channel, Receiver, Sender}, Arc, Mutex}, thread};

use super::{
    utils,
    application::{Application, ConnectionStatus},
};

const CLIENT_POOL_RESERVED_ID: usize = 0;
const DEFAULT_CLIENT_PORT: usize = 7878;

/// Represents a termination command for a client thread running on
/// the server upon the mobile client disconnects from the server's
/// side client.
#[derive(Debug)]
struct Terminate {
    client_id: usize,
}

/// Represents a pool of all client connections.
pub struct ClientPool {
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

    pub fn new(max_clients: usize) -> ClientPool {
        let (sender, receiver) = channel();
        let pool = ClientPool {
            // IDs must start at 1, to differ from base port used to receive new client requests
            client_id_counter: 1,
            max_concurrent_clients_allowed: max_clients,
            clients: Arc::new(Mutex::new(HashMap::new())),
            sender,
        };

        pool.start_termination_listener(receiver);

        pool
    }

    /// Add a new client connection to the pool.
    ///
    /// For each new client, the id increases by 1, as well as the port.
    /// Client ids start at 1, and go up to max usize
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

    /// Terminates a client by sending a termination command to the client thread.
    pub fn terminate_client(&self, client_id: usize) {
        self.sender
            .send(Terminate { client_id })
            .expect("Failed to send termination command to client");
    }

    pub fn shutdown(&self) {
        log::info!("Shutting down client pool...");
        let mut clients = self.clients.lock().unwrap();
        // terminate all clients
        unreachable!("TODO");

        // terminate termination_listener thread
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
        let socket = utils::create_socket(port);

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