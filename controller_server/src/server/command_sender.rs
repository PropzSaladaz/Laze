use std::sync::mpsc::{Receiver, Sender};
use super::commands::{ServerRequest, ServerResponse, VariantOf};

/// A communication interface for interacting with a server through message passing channels.
/// 
/// `CommandSender` provides a simple abstraction over message-passing channels to send
/// requests to a server and receive responses back. It uses Rust's standard library MPSC
/// (Multi-Producer, Single-Consumer) channels for thread-safe communication.
/// 
/// # Examples
/// 
/// ```rust
/// use std::sync::mpsc;
/// 
/// let (req_sender, req_receiver) = mpsc::channel();
/// let (resp_sender, resp_receiver) = mpsc::channel();
/// 
/// let mut communicator = CommandSender::new(req_sender, resp_receiver);
/// 
/// // Send a request to initialize the server
/// communicator.send_request(ServerRequest::InitServer);
/// 
/// // Receive the response
/// match communicator.receive_response() {
///     Ok(ServerResponse::ServerStarted(info)) => {
///         println!("Server started at: {}", info.addr);
///     }
///     Ok(response) => println!("Received: {:?}", response),
///     Err(e) => eprintln!("Failed to receive response: {}", e),
/// }
/// ```
/// 
/// # Thread Safety
/// 
/// This struct is designed to be used in multi-threaded environments where one thread
/// sends requests and waits for responses, while another thread (typically the server)
/// processes requests and sends back responses through the corresponding channels.
#[derive(Debug)]
pub struct CommandSender {
    sender_channel: Sender::<super::commands::ServerRequest>,
    receiver_channel: Receiver::<ServerResponse>,
}

impl CommandSender {
    pub fn new(sender: Sender<ServerRequest>, receiver: Receiver<ServerResponse>) -> Self {
        CommandSender {
            sender_channel: sender,
            receiver_channel: receiver,
        }
    }

    /// Sends a request to the server.
    pub fn send_request(&self, request: ServerRequest) {
        self.sender_channel.send(request).unwrap();
    }

    /// Receives a response from the server.
    pub fn receive_response(&mut self) -> Result<ServerResponse, std::sync::mpsc::RecvError> {
        self.receiver_channel.recv()
    }
}