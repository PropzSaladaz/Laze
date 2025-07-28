use std::{
    error::Error, sync::{mpsc::{Receiver, Sender}, Arc, RwLock}, thread, time::Duration
};
use crate::{logger::Loggable, server::{concurrent_queue::ConcurrentQueue, server_communicator::VariantOf, ClientTerminated, ServerStarted, ServerTerminated}, ServerRequest, ServerResponse};


#[derive(Debug)]
pub struct ProcessError {
    pub message: String,
}

impl ProcessError {
    pub fn new(message: String) -> Self {
        ProcessError { message }
    }
}

impl std::fmt::Display for ProcessError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Process error: {}", self.message)
    }
}

impl Error for ProcessError {}

pub struct CommandProcessor<Req, Resp> {
    callback: RwLock<Option<Box<dyn Fn(Req) -> Result<Resp, ProcessError> + Send + Sync>>>,
}

impl<Req, Resp> CommandProcessor<Req, Resp> {
    pub fn new() -> Self {
        CommandProcessor {
            callback: RwLock::new(None),
        }
    }

    pub fn set_processor<F>(&self, processor: F)
    where
        F: Fn(Req) -> Result<Resp, ProcessError> + Send + Sync + 'static,
    {
        let mut lock = self.callback.write().unwrap();
        *lock = Some(Box::new(processor));
    }

    pub fn has_processor(&self) -> bool {
        let lock = self.callback.read().unwrap();
        lock.is_some()
    }

    pub fn wait_for_processor(&self) {
        while !self.has_processor() {
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
    }

    pub fn process(&self, request: Req) -> Result<Resp, ProcessError> {
        let lock = self.callback.read().unwrap();
        if let Some(ref processor) = *lock {
            return processor(request);
        }
        Err(ProcessError::new("No processor set".to_string()))
    }
}


pub struct CommandListener {
    sender: Sender<ServerResponse>,
    receiver: Receiver<ServerRequest>,
    command_processor: Arc<CommandProcessor<ServerRequest, ServerResponse>>,
}

impl CommandListener {
    pub fn new( sender: Sender<ServerResponse>, receiver: Receiver<ServerRequest>) -> Self {
        CommandListener { sender, receiver, command_processor: Arc::new(CommandProcessor::new()) }
    }

    pub fn get_command_processor(&self) -> Arc<CommandProcessor<ServerRequest, ServerResponse>> {
        self.command_processor.clone()
    }

    /// Creates a new thread that listens for ServerController commands.
    /// This thread listens for commands received via the channel receiver,
    /// and sends responses through the channel sender.
    /// The server controller (tauri app) should connect to this port to send commands.
    /// After a command is processed, this thread sends a response back to the server controller.
    /// 
    /// This method is non-blocking.
    pub fn listen(&self, delay: Duration) {

        thread::spawn( move || {
            // wait for the server listener thread at consfig.starting_port to start
            thread::sleep(delay);
            self.log_info("Waiting for command processor to be set...");
            self.command_processor.wait_for_processor();

            self.log_info("Starting command listener thread...");

            loop {
                match self.receiver.recv() {
                    Ok(ServerRequest::InitServer) => {
                        self.log_info("Received InitServer request from ServerController. Sending request to server.");

                        match self.command_processor.process(ServerRequest::InitServer) {
                            Ok(resp) => {
                                let started = ServerStarted::assert_variant_of(resp);
                                // send response back to the client
                                let address = started.addr.clone();
                                let response = ServerResponse::ServerStarted(started);

                                self.log_info(&format!("Received confirmation that server started at: {}", address));
                                self.log_info("Sending response back to ServerController");
                                
                                self.sender.send(response).unwrap();
                            },
                            Err(e) => {
                                let err_msg = format!("Failed to initialize server: {}", e);
                                self.log_error(&err_msg);

                                // send error response back to the client
                                let response = ServerResponse::Error(err_msg);
                                self.sender.send(response).unwrap();
                                continue;
                            }
                        }
                    }
                    Ok(ServerRequest::TerminateServer) => {
                        self.log_info("Received TerminateServer request from ServerController. Sending request to server.");

                        match self.command_processor.process(ServerRequest::TerminateServer) {
                            Ok(resp) => {
                                let terminated = ServerTerminated::assert_variant_of(resp);
                                let response = ServerResponse::ServerTerminated(terminated);
                                self.log_info("Received confirmation that server terminated.");
                                self.sender.send(response).unwrap();
                            },
                            Err(e) => {
                                let err_msg = format!("Failed to terminate server: {}", e);
                                self.log_error(&err_msg);

                                // send error response back to the client
                                let response = ServerResponse::Error(err_msg.to_string());
                                self.sender.send(response).unwrap();
                            }
                        }   
                    }
                    Ok(ServerRequest::TerminateClient(client_id)) => {
                        self.log_info(&format!("Received TerminateClient request for client {} from ServerController.", client_id));

                        match self.command_processor.process(ServerRequest::TerminateClient(client_id)) {
                            Ok(resp) => {
                                let client_terminated = ClientTerminated::assert_variant_of(resp);
                                let response = ServerResponse::ClientTerminated(client_terminated);
                                self.log_info(&format!("Received confirmation that client {} terminated.", client_id));
                                self.sender.send(response).unwrap();
                            },
                            Err(e) => {
                                let err_msg = format!("Failed to terminate client {}: {}", client_id, e);
                                self.log_error(&err_msg);

                                // send error response back to the client
                                let response = ServerResponse::Error(err_msg.to_string());
                                self.sender.send(response).unwrap();
                            }
                        }

                    }
                    Err(e) => log::error!("Error receiving server request: {}", e),
                }
            }
        });
    }
}