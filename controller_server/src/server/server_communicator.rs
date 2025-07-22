use std::sync::mpsc::{Receiver, Sender};

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerRequest {
    InitServer,
    TerminateServer,
    TerminateClient(usize),
}

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerResponse {
    ServerStarted(ServerStarted),
    ServerTerminated(ServerTerminated),
    ClientTerminated(ClientTerminated),
    Error(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStarted {
    pub addr: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerTerminated;

#[derive(Debug, Serialize, Deserialize)]
pub struct ClientTerminated {
    pub client_id: usize,
}


pub trait VariantOf<T> {
    fn assert_variant_of(other: T) -> Self
    where 
        Self: Sized;
}

/// A macro to implement the `VariantOf` trait for each variant of an enum.
/// Allows to call `assert_variant_of` on the enum type to force it into its variant type.
/// Avoid using `match` statements to extract the inner value of the enum variant when we know
/// the expected type. Panics if asserted variant is not the received.
macro_rules! impl_variant_of {
    ($enum_type:ident => { $($variant:ident),* $(,)? }) => {
        $(
            impl VariantOf<$enum_type> for $variant {
                fn assert_variant_of(other: $enum_type) -> Self {
                    if let $enum_type::$variant(inner) = other {
                        inner
                    } else {
                        panic!("Expected variant {} but found {:?}", stringify!($variant), other);
                    }
                }
            }
        )*
    };
}

impl_variant_of!(ServerResponse => {
    ServerStarted,
    ServerTerminated,
    ClientTerminated,
});




/// A communication interface for interacting with a server through message passing channels.
/// 
/// `ServerCommunicator` provides a simple abstraction over message-passing channels to send
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
/// let mut communicator = ServerCommunicator::new(req_sender, resp_receiver);
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
pub struct ServerCommunicator {
    sender_channel: Sender::<ServerRequest>,
    receiver_channel: Receiver::<ServerResponse>,
}

impl ServerCommunicator {
    pub fn new(sender: Sender<ServerRequest>, receiver: Receiver<ServerResponse>) -> Self {
        ServerCommunicator {
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