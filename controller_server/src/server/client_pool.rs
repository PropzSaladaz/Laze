use std::{
    collections::HashMap,
    io::Read,
    net::{SocketAddr, TcpStream},
    sync::{
        atomic::AtomicBool,
        mpsc::{channel, Receiver, Sender},
        Arc, Mutex,
    },
    thread,
    time::Duration,
};

use crate::{logger::Loggable, server::core::ClientInfo};

use tokio::sync::broadcast;

use super::{
    application::{Application, ConnectionStatus},
    core::ServerEvent,
    utils,
};

const CLIENT_POOL_RESERVED_ID: usize = 0;
const DEFAULT_CLIENT_PORT: usize = 7878;

const CLIENT_READ_TIMEOUT: Duration = Duration::from_secs(1);

const ATOMIC_BOOL_ORDERING: std::sync::atomic::Ordering = std::sync::atomic::Ordering::SeqCst;

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
    clients: Arc<Mutex<HashMap<usize, Arc<Client>>>>,

    /// Channel used by client threads to inform the pool to release
    /// the resources of a client.
    /// This is used when the client itself chooses to terminate. Either by
    /// an error or by the client's client application.
    client_termination_sender: Sender<Terminate>,

    /// A broadcast channel to publish server events.
    /// This is used by any server's client (any app controlling the server)
    /// to listen for events that happen on the server.
    /// CientPool uses it to notify client addition and removal.
    event_publisher: broadcast::Sender<ServerEvent>,
}

impl ClientPool {
    pub fn new(max_clients: usize, event_publisher: broadcast::Sender<ServerEvent>) -> ClientPool {
        let (sender, receiver) = channel();
        let pool = ClientPool {
            // IDs must start at 1, to differ from base port used to receive new client requests
            client_id_counter: 1,
            max_concurrent_clients_allowed: max_clients,
            clients: Arc::new(Mutex::new(HashMap::new())),
            client_termination_sender: sender,
            event_publisher,
        };

        pool.start_termination_listener(receiver);

        pool
    }

    /// Starts a thread that listens for termination requests from clients.
    /// When a termination request is received, it removes the client from the pool.
    /// This is used to release resources from an already shut-down client thread.
    /// This thread will run until client pool is shutdown. In that case, it will receive
    /// 'CLIENT_POOL_RESERVED_ID' as the client_id.
    fn start_termination_listener(&self, receiver: Receiver<Terminate>) {
        let clients = Arc::clone(&self.clients);
        let event_publisher = self.event_publisher.clone();

        thread::spawn(move || {
            while let Ok(terminate) = receiver.recv() {
                let mut clients = clients.lock().unwrap();

                if terminate.client_id == CLIENT_POOL_RESERVED_ID {
                    ClientPool::static_log_info(
                        "Received termination signal. Terminating termination listener thread.",
                    );
                    return;
                } else {
                    ClientPool::static_log_info(&format!(
                        "Received termination request for client {}",
                        terminate.client_id
                    ));

                    if let Some(client) = clients.remove(&terminate.client_id) {
                        let client_info = ClientInfo {
                            id: client.id,
                            addr: client.address.to_string(),
                        };

                        // publish event about client removal
                        let _ = event_publisher
                            .send(ServerEvent::ClientRemoved(client_info.clone()))
                            .map_err(|e| {
                                ClientPool::static_log_warn(&format!(
                                    "Failed to send client removal event for client {}: {}",
                                    client_info.id, e
                                ));
                            });

                        client.exit_requested.store(true, ATOMIC_BOOL_ORDERING);
                        ClientPool::static_log_info(&format!(
                            "Client {} terminated successfully.",
                            terminate.client_id
                        ));
                    } else {
                        ClientPool::static_log_warn(&format!(
                            "Client {} not found in pool.",
                            terminate.client_id
                        ));
                    }
                }
            }
        });
    }

    /// Add a new client connection to the pool.
    ///
    /// For each new client, the id increases by 1, as well as the port.
    /// Client ids start at 1, and go up to max usize
    pub fn add<A: Application + 'static>(
        &mut self,
        addr: SocketAddr,
        app: Arc<Mutex<A>>,
    ) -> Result<usize, String> {
        let mut clients = self.clients.lock().unwrap();

        if clients.len() == self.max_concurrent_clients_allowed {
            return Err("Maximum number of concurrent clients reached!".to_string());
        }

        // launch new client
        let new_client = Client::launch_new_client(
            addr,
            self.client_id_counter,
            app,
            self.client_termination_sender.clone(),
        );

        // publish event about new client
        self.event_publisher
            .send(ServerEvent::ClientAdded(ClientInfo {
                id: new_client.id,
                addr: new_client.address.to_string(),
            }))
            .map_err(|e| {
                ClientPool::static_log_warn(&format!(
                    "Failed to send client addition event: {}",
                    e
                ));
                "Failed to send client addition event".to_string()
            })?;

        // insert new client only if it doesn't exist yet
        let port = new_client.port;
        clients.entry(self.client_id_counter).or_insert(new_client);

        self.client_id_counter += 1;

        Ok(port)
    }

    /// Schedules client for termination.
    pub fn terminate_client(&self, client_id: usize) -> Result<(), String> {
        let clients = self.clients.lock().unwrap();
        if clients.contains_key(&client_id) {
            let client = clients.get(&client_id).unwrap();
            client.exit_requested.store(true, ATOMIC_BOOL_ORDERING);
            ClientPool::static_log_info(&format!(
                "Client {} scheduled for termination.",
                client_id
            ));
            Ok(())
        } else {
            Err(format!("Client {} not found in pool.", client_id))
        }
    }

    /// Disconnects all clients but keeps the pool running.
    /// This allows the server to be stopped and restarted.
    pub fn clear(&self) {
        self.log_info("Clearing client pool (disconnecting all clients)...");
        let mut clients = self.clients.lock().unwrap();

        clients.iter().for_each(|(_, client)| {
            client.exit_requested.store(true, ATOMIC_BOOL_ORDERING);
            self.log_info(&format!("Client {} scheduled to terminate.", client.id));
        });
        clients.clear();

        self.log_info("All clients disconnected. Pool still running.");
    }

    /// Schedules all current clients for termination, and releases resources for them.
    /// Schedules termination listener thread to terminate as well.
    pub fn shutdown(&self) {
        self.log_info("Shutting down client pool...");
        let mut clients = self.clients.lock().unwrap();

        clients.iter().for_each(|(_, client)| {
            client.exit_requested.store(true, ATOMIC_BOOL_ORDERING);
            self.log_info(&format!("Client {} scheduled to terminate.", client.id));
        });
        clients.clear();

        self.log_info("All clients scheduled for termination. Scheduling termination listener thread to terminate.");
        self.client_termination_sender
            .send(Terminate {
                client_id: CLIENT_POOL_RESERVED_ID,
            })
            .unwrap();
    }
}

struct Client {
    address: SocketAddr,
    id: usize,
    port: usize,

    /// Client pool sets this to true when it wants to terminate the client.
    /// The client thread checks this variable periodically to see if it should exit.
    /// This is used to gracefully shut down the client thread.
    exit_requested: AtomicBool,
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
        termination_sender: Sender<Terminate>,
    ) -> Arc<Client> {
        let port = DEFAULT_CLIENT_PORT + id;
        let socket = utils::create_socket(port);

        let client = Arc::new(Client {
            address,
            id,
            port,
            exit_requested: AtomicBool::new(false),
        });

        let cloned_client = Arc::clone(&client);

        // Create thread
        thread::spawn(move || {
            log::info!("Client created {:?} @ {:?}:{:?}", id, address, port);

            let exit_reason = match socket.accept() {
                Ok((stream, _)) => client.handle_requests(stream, app),
                Err(e) => {
                    ExitReason::Unexpected(format!("Could not parse stream in Client {id}: {}", e))
                }
            };

            match exit_reason {
                ExitReason::RequestedByServer => {
                    // no need to ask server to release resources
                    Self::static_log_info(&format!(
                        "Client {} requested to terminate by server.",
                        id
                    ));
                }
                ExitReason::RequestedByClient => {
                    // need to ask server to release resources
                    termination_sender
                        .send(Terminate { client_id: id })
                        .unwrap();
                    Self::static_log_info(&format!(
                        "Client {} requested to terminate by itself.",
                        id
                    ));
                }
                ExitReason::Unexpected(reason) => {
                    // need to ask server to release resources
                    termination_sender
                        .send(Terminate { client_id: id })
                        .unwrap();
                    Self::static_log_error(&format!(
                        "Client {} terminated unexpectedly: {}",
                        id, reason
                    ));
                }
            }
        });

        cloned_client
    }

    /// Handle incomming client inputs.
    ///
    /// Sends the received bytes up to the application to handle the input
    fn handle_requests(
        &self,
        mut stream: TcpStream,
        app: Arc<Mutex<impl Application + 'static>>,
    ) -> ExitReason {
        // client timesout if no data available & checks for termination signal
        stream.set_read_timeout(Some(CLIENT_READ_TIMEOUT)).unwrap();

        // make the reads blocking - wait indefinetely for client input
        // stream.set_read_timeout(None).expect("Could not set read timeout.");
        loop {
            let mut bytes = [0; 1024];

            match stream.read(&mut bytes) {
                // Normal processing
                Ok(bytes_size) => {
                    if bytes.is_empty() {
                        continue;
                    };

                    let bytes = &bytes[..bytes_size];

                    if let ConnectionStatus::Disconnected =
                        app.lock().unwrap().dispatch_to_device(bytes)
                    {
                        return ExitReason::RequestedByClient;
                    }
                }
                Err(ref e)
                    if e.kind() == std::io::ErrorKind::WouldBlock
                        || e.kind() == std::io::ErrorKind::TimedOut =>
                {
                    // No data available, timed out

                    // client was requested to terminate by the server
                    if self.exit_requested.load(ATOMIC_BOOL_ORDERING) {
                        return ExitReason::RequestedByServer;
                    }
                }
                // Error on connection (possibly abrupt disconnection by client)
                Err(e) => {
                    return ExitReason::Unexpected(format!(
                        "Client {:?} listening at {:?} disconnected: {:?}",
                        self.id, self.address, e
                    ));
                }
            }
        }
    }
}

enum ExitReason {
    RequestedByServer,
    RequestedByClient,
    Unexpected(String),
}
