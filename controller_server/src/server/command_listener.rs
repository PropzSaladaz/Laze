use std::{
    error::Error, sync::{atomic::AtomicBool, mpsc::{Receiver, Sender}, Arc, RwLock}, thread, time::Duration
};
use std::sync::mpsc::RecvTimeoutError;

use crate::logger::Loggable;
use super::commands::{ServerRequest, ServerResponse, ServerStarted, ServerTerminated, ClientTerminated, ClientList, VariantOf};

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

struct CommandProcessor<Req, Resp> {
    callback: RwLock<Option<Box<dyn Fn(Req) -> Result<Resp, ProcessError> + Send + Sync>>>,
}

/// Holds a processor callback function that can process commands of type `Req` and return a response of type `Resp`.
/// The processor can be set using `set_processor` method.
impl<Req, Resp> CommandProcessor<Req, Resp> {
    pub fn new() -> Self {
        CommandProcessor {
            callback: RwLock::new(None),
        }
    }

    fn set_processor<F>(&self, processor: F)
    where
        F: Fn(Req) -> Result<Resp, ProcessError> + Send + Sync + 'static,
    {
        let mut lock = self.callback.write().unwrap();
        *lock = Some(Box::new(processor));
    }

    fn has_processor(&self) -> bool {
        let lock = self.callback.read().unwrap();
        lock.is_some()
    }

    fn wait_for_processor(&self) {
        while !self.has_processor() {
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
    }

    fn process(&self, request: Req) -> Result<Resp, ProcessError> {
        let lock = self.callback.read().unwrap();
        if let Some(ref processor) = *lock {
            return processor(request);
        }
        Err(ProcessError::new("No processor set".to_string()))
    }
}

/// Handle for the command listener thread.
/// This handle can be used to wait for the thread to finish execution.
pub struct CommandListenerHandler {
    thread_handle: thread::JoinHandle<()>,
    termination_signal: Arc<AtomicBool>,
}

impl CommandListenerHandler {
    pub fn wait_for_exit(self) {
        self.thread_handle.join().expect("Failed to join command listener thread");
    }

    // Sets the termination signal to true, which will cause the command listener thread to exit.
    pub fn schedule_shutdown(&self) {
        self.termination_signal.store(true, std::sync::atomic::Ordering::SeqCst);
    }
}



/// A command listener that processes server requests in a separate thread.
/// 
/// The `CommandListener` receives `ServerRequest` messages through a channel receiver
/// and sends `ServerResponse` messages back through a channel sender. It uses a
/// configurable command processor to handle the actual request processing logic.
/// 
/// # Usage
/// 
/// 1. Create a new `CommandListener` with sender and receiver channels
/// 2. Set a command processor using `set_command_processor()`
/// 3. Start listening by calling `listen()` which spawns a new thread
/// 
/// # Example
/// 
/// ```rust
/// let (tx, rx) = mpsc::channel();
/// let (response_tx, response_rx) = mpsc::channel();
/// 
/// let listener = CommandListener::new(response_tx, rx);
/// listener.set_command_processor(|req| {
///     // Process the request and return a response
///     Ok(ServerResponse::ServerStarted(ServerStarted))
/// });
/// 
/// let handler = listener.listen(Duration::from_secs(1));
/// // ... send requests through tx channel
/// handler.schedule_shutdown();
/// handler.wait_for_exit();
/// ```
/// 
/// # Supported Requests
/// 
/// - `InitServer`: Initializes the server and returns `ServerStarted` response
/// - `TerminateServer`: Terminates the server and returns `ServerTerminated` response  
/// - `TerminateClient(client_id)`: Terminates a specific client and returns `ClientTerminated` response
/// 
/// # Error Handling
/// 
/// If request processing fails, an `Error` response is sent back through the channel
/// containing the error message. The listener continues processing subsequent requests.
/// 
/// # Thread Safety
/// 
/// The command processor is wrapped in an `Arc<CommandProcessor>` to allow safe sharing
/// between threads. The listener waits for a processor to be set before beginning
/// request processing.
pub struct CommandListener {
    sender: Sender<ServerResponse>,
    receiver: Receiver<ServerRequest>,

    /// This is an Arc to allow some other thread to set the command processor callback.
    /// when calling the `listen` method, the command listener thread will wait for the processor to be set.
    /// The processor is used to process the requests received from the channel receiver.
    command_processor: Arc<CommandProcessor<ServerRequest, ServerResponse>>,

    /// this is used to signal the command listener thread to exit
    /// it is set via the CommandListenerHandler to true when the server is terminated
    /// This variable is shared across threads
    termination_signal: Arc<AtomicBool>,
}

impl CommandListener {
    pub fn new( sender: Sender<ServerResponse>, receiver: Receiver<ServerRequest>) -> Self {
        CommandListener { sender, receiver, command_processor: Arc::new(CommandProcessor::new()), termination_signal: Arc::new(AtomicBool::new(false)) }
    }

    pub fn set_command_processor<F>(&self, processor: F)
    where
        F: Fn(ServerRequest) -> Result<ServerResponse, ProcessError> + Send + Sync + 'static,
    {
        self.command_processor.set_processor(processor);
    }

    /// Creates a new thread that listens for ServerController commands.
    /// This thread listens for commands received via the channel receiver,
    /// and sends responses through the channel sender.
    /// The server controller (tauri app) should connect to this port to send commands.
    /// After a command is processed, this thread sends a response back to the server controller.
    /// 
    /// This method is non-blocking.
    /// The struct is moved into the thread, so it cannot be used after calling this method.
    pub fn listen(self, delay: Duration) -> CommandListenerHandler {
        let termination_signal = Arc::clone(&self.termination_signal);

        // Start dedicated thread for command listener
        let thread_handle = thread::spawn( move || {
            // wait for the server listener thread at consfig.starting_port to start
            thread::sleep(delay);
            self.log_info("Waiting for command processor to be set...");
            self.command_processor.wait_for_processor();

            self.log_info("Command processor is set. Starting command listener thread...");

            loop {
                match self.receiver.recv_timeout(Duration::from_millis(1000)) {
                    Ok(message) => {
                        self.log_debug(&format!("Received message: {:?}", message));
                        self.parse_message(&message);
                    }
                    Err(RecvTimeoutError::Timeout) => {
                        if self.termination_signal.load(std::sync::atomic::Ordering::SeqCst) {
                            self.log_info("Termination signal received. Exiting command listener thread.");
                            break;
                        }
                    }
                    Err(e) => {
                        self.log_error(&format!("Error receiving message: {}", e));
                        break;
                    }
                }
            }

        });

        CommandListenerHandler {
            thread_handle: thread_handle,
            termination_signal: termination_signal,
        }
    }

    fn parse_message(&self, message: &ServerRequest) {
        match message {
            ServerRequest::InitServer => {
                self.log_info("Received InitServer request from ServerController. Processing...");

                match self.command_processor.process(ServerRequest::InitServer) {
                    Ok(resp) => {
                        let started = ServerStarted::assert_variant_of(resp);
                        let response = ServerResponse::ServerStarted(started);

                        self.log_info(&format!("Received confirmation that server started"));
                        self.log_info("Sending response back to ServerController");
                        
                        self.sender.send(response).unwrap();
                    },
                    Err(e) => {
                        let err_msg = format!("Failed to initialize server: {}", e);
                        self.log_error(&err_msg);

                        // send error response back to the client
                        let response = ServerResponse::Error(err_msg);
                        self.sender.send(response).unwrap();
                    }
                }
            }
            ServerRequest::TerminateServer => {
                self.log_info("Received TerminateServer request from ServerController. Processing...");

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
            ServerRequest::TerminateClient(client_id) => {
                self.log_info(&format!("Received TerminateClient request for client {} from ServerController. Processing...", client_id));

                match self.command_processor.process(ServerRequest::TerminateClient(*client_id)) {
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
            ServerRequest::GetClients => {
                self.log_info("Received GetClients request from ServerController. Processing...");

                match self.command_processor.process(ServerRequest::GetClients) {
                    Ok(resp) => {
                        let client_list = ClientList::assert_variant_of(resp);
                        let response = ServerResponse::ClientList(client_list);
                        self.log_info("Received client list successfully.");
                        self.sender.send(response).unwrap();
                    },
                    Err(e) => {
                        let err_msg = format!("Failed to get clients: {}", e);
                        self.log_error(&err_msg);

                        // send error response back to the client
                        let response = ServerResponse::Error(err_msg.to_string());
                        self.sender.send(response).unwrap();
                    }
                }
            }
        }
    }
}