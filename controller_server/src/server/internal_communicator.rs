use std::{io::{Read, Write}, net::{SocketAddr, TcpStream}};

use serde::{de::DeserializeOwned, Serialize};

use crate::server::server_communicator::VariantOf;

use super::server_communicator::{ServerRequest, ServerResponse};

/// Used to handle communication with the server itself.
/// This is used by the server thread that has access to the server's socket
/// to check for server commands.
/// These commands can only be sent by the server controller.
/// Client requests have no effect on this receiver.
pub struct InternalServerCommReceiver {}

impl InternalServerCommReceiver {

    /// Tries to parse a request from the server controller (Tauri desktop app). 
    /// Assumes that the controller is running on the same machine
    /// and that the request is sent through a TcpStream.
    /// 
    /// If the request is not from the server controller, it returns None,
    /// and should be parsed by the server's main loop as a client request (by some other function outside this scope). 
    pub fn try_parse_request<Request: DeserializeOwned>(mut socket: &TcpStream, addr: &SocketAddr) -> Result<Option<Request>, std::io::Error> {
        if addr.ip().is_loopback() {
            let mut buffer = [0; 1024];
            let bytes = socket.read(&mut buffer)?;
            if bytes == 0 {
                return Err(std::io::Error::new(std::io::ErrorKind::Other, String::from("No data received from server, exiting...")));
            }

            let request: Request = serde_json::from_slice(&buffer[..bytes])
                .expect("Failed to parse server request");
            Ok(Some(request))
        } else {
            log::debug!("Received request from external server at {addr}");
            Ok(None)
        }
    }
}

/// Internal server communicator that sends requests to the server's TcpStream.
/// This is used by the server's main thread to 
/// 
/// Allows to initialize, terminate the server, and terminate clients.
pub struct InternalServerCommSender {
    socket: TcpStream,
}

impl InternalServerCommSender {
    /// Creates a new internal server communicator.
    pub fn new(port: usize) -> Self {
        let socket = TcpStream::connect(format!("127.0.0.1:{port}")).unwrap();
        InternalServerCommSender { socket }
    }

    /// Sends a request and awaits for a response, returning the response.
    pub fn send_and_receive<Request, ResponseEnum, RespVariant>(&mut self, request: &Request) -> Result<RespVariant, std::io::Error>
    where
        Request: Serialize, 
        ResponseEnum: DeserializeOwned, 
        RespVariant: VariantOf<ResponseEnum>
    {
        // Serialize the request
        let req = serde_json::to_vec(request).unwrap();
        // Send the request
        self.socket.write_all(&req)?;
        // Read the response
        let mut buf = vec![0; 1024];
        self.socket.read(&mut buf)?;
        // Deserialize the response
        let resp: ResponseEnum = serde_json::from_slice(&buf)?;

        Ok(RespVariant::assert_variant_of(resp))
    }
}