use std::{sync::mpsc::{Receiver, Sender}, thread};

use crate::{logger::Loggable, ServerRequest, ServerResponse};

pub struct CommandListener {
    sender: Sender<ServerResponse>,
    receiver: Receiver<ServerRequest>,
}

impl Loggable for CommandListener {
    fn label(&self) -> &str {
        "CommandListener"
    }
}

impl CommandListener {
    pub fn new( sender: Sender<ServerResponse>, receiver: Receiver<ServerRequest>) -> Self {
        CommandListener { sender, receiver }
    }

    pub fn listen(&self) {
        // Implementation for listening to commands
        // This could involve setting up a TCP listener or similar mechanism
        log::info!("CommandListener is now listening for commands.");
    }

    /// Creates a new thread that listens for ServerController commands.
    /// This thread listens for commands received via the channel receiver,
    /// and sends responses through the channel sender.
    /// The server controller (tauri app) should connect to this port to send commands.
    /// After a command is processed, this thread sends a response back to the server controller.
    /// 
    /// This method is non-blocking.
    fn listen(&self, delay: Duration) {

        thread::spawn( move || {
            // wait for the server listener thread at consfig.starting_port to start
            thread::sleep(delay);

            self.log_info("Starting command listener thread...");

            loop {
                match self.receiver.recv() {
                    Ok(ServerRequest::InitServer) => {
                        self.log_info("Received InitServer request from ServerController. Sending request to server.");

                        match internal_comm.send_and_receive::<ServerRequest, ServerResponse, ServerStarted>(&ServerRequest::InitServer) { // blocking - sends & awaits for response
                            Ok(addr) => {
                                // send response back to the client
                                let address = addr.addr.clone();
                                let response = ServerResponse::ServerStarted(addr);

                                log::info!("{label} Received confirmation that server started at: {}", address);
                                log::info!("{label} Sending response back to ServerController");
                                
                                sender.send(response).unwrap();
                            },
                            Err(e) => {
                                log::error!("{label} Failed to initialize server: {}", e);
                                
                                // send error response back to the client
                                let response = ServerResponse::Error(e.to_string());
                                sender.send(response).unwrap();
                                continue;
                            }
                        }
                    }
                    Ok(ServerRequest::TerminateServer) => {
                        log::info!("{label} Received TerminateServer request from ServerController. Sending request to server port {port}");
                        
                        sender.send(ServerResponse::ServerTerminated(ServerTerminated{})).unwrap();
                    }
                    Ok(ServerRequest::TerminateClient(client_id)) => {
                        log::info!("{label} Received TerminateClient request for client {client_id} from ServerController. Sending request to server port {port}");

                        sender.send(ServerResponse::ClientTerminated(ClientTerminated{client_id})).unwrap();
                    }
                    Err(e) => log::error!("Error receiving server request: {}", e),
                }
            }
        });
    }
}