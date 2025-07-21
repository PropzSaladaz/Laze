use std::{io::{Read, Write}, net::{SocketAddr, TcpStream}};

use serde::{de::DeserializeOwned, Serialize};

use crate::server::server_communicator::VariantOf;

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

/// Used to send commands to the server from the server controller.
/// This communicator establishes a TCP connection to the server running on localhost
/// and provides methods to send requests and receive responses.
/// 
/// Requests and responses are sent via the TCP stream in JSON format.
/// 
/// The sender is designed to work with the ServerController
/// that needs to communicate with the server thread to send internal commands.
/// 
/// For each request sent, the sender expects a response from the server.
/// 
/// # Examples
/// 
/// ```rust
/// let mut sender = InternalServerCommSender::new(8080);
/// let response = sender.send_and_receive(&my_request)?;
/// ```
pub struct InternalServerCommSender {
    socket: TcpStream,
}


impl InternalServerCommSender {
    /// Creates a new internal server communicator.
    pub fn new(port: usize) -> Self {
        let socket = TcpStream::connect(format!("127.0.0.1:{port}")).unwrap();
        InternalServerCommSender { socket }
    }


    /// Sends a request to the internal server and receives a response of a specific type.
    ///
    /// This method serializes the given request to JSON, sends it over the TCP connection,
    /// reads the response, deserializes it to the expected response enum type, and then
    /// extracts the specific response variant requested.
    ///
    /// # Type Parameters
    ///
    /// * `Request` - The type of the request to send. Must implement `Serialize`.
    /// * `ResponseEnum` - The enum type that represents all possible response types from the server.
    ///   Must implement `DeserializeOwned`.
    /// * `RespVariant` - The specific response variant expected from the `ResponseEnum`.
    ///   Must implement `VariantOf<ResponseEnum>`.
    ///
    /// # Arguments
    ///
    /// * `request` - A reference to the request object to be sent to the server.
    ///
    /// # Returns
    ///
    /// * `Ok(RespVariant)` - The specific response variant if the communication succeeds.
    /// * `Err(std::io::Error)` - An I/O error if the network communication fails or if
    ///   deserialization fails.
    ///
    /// # Panics
    ///
    /// This method will panic if:
    /// * The request cannot be serialized to JSON
    /// * The response variant assertion fails (indicating an unexpected response type)
    ///
    /// # Examples
    ///
    /// ```rust
    /// let mut sender = InternalServerCommSender::new(8080);
    /// let request = MyRequest { data: "example" };
    /// let response: MySpecificResponse = sender.send_and_receive(&request)?;
    /// ```
    pub fn send_and_receive<Request, ResponseEnum, RespVariant>(&mut self, request: &Request) -> Result<RespVariant, std::io::Error>
    where
        Request: Serialize,                  // Encodes the request type
        ResponseEnum: DeserializeOwned,      // Encodes the response enum, which includes all possible response types
        RespVariant: VariantOf<ResponseEnum> // Encodes the specific expected response type from all of the possible responses
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