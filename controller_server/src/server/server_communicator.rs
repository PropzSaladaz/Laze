use std::sync::mpsc::{Receiver, Sender};

use serde::{Deserialize, Serialize};

pub trait VariantOf<T> {
    fn assert_variant_of(other: T) -> Self
    where 
        Self: Sized;
}

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