/// Represents the response from the application to the server.
/// If the application parses the input and decides to close the server, then
/// the server is closed.
/// Else, the application should always return `ConnectionStatus::Connected`
pub enum ConnectionStatus {
    Disconnected,
    Connected,
}

/// Represents a remote server application that is capable of handling
/// inputs in byte arrays.
/// This handling is server-specific (coud be from changing server software to just update
/// the mouse position, or input keyboard keys)
pub trait Application: Sync + Send {
    /// Invoked whenever the server receives a new input from a client.
    /// This is the only entry-point for the remote Application - It should parse
    /// the input, and have some effect on the server.
    ///
    /// # Arguments
    ///
    /// * `input` - The input received from the client encoded into a byte array
    ///
    /// # Returns
    ///
    /// The current connection status. There should always be an input from the client that closes
    /// the connection. The return value is used to check for that command, and close the
    /// connection if such command is issued, or keep the connection alive otherwise.
    ///
    fn dispatch_to_device(&mut self, input: &[u8]) -> ConnectionStatus;
}
