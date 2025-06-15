mod client_pool;
mod internal_communicator;
mod utils;

pub mod application;

pub mod server_communicator;
pub use server_communicator::{
    ServerCommunicator, ServerRequest, ServerResponse, 
    ServerStarted, ServerTerminated, ClientTerminated
};

pub mod server;
pub use server::{Server, ServerConfig};