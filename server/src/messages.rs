use serde::{Deserialize, Serialize};

/// Represents the response to a new connection request from a client.
#[derive(Serialize, Deserialize)]
pub struct NewClientResponse {
    /// Port to be used by the new connection
    pub port: u16,
}

/// Represents a request for a new connection from some client.
#[derive(Serialize, Deserialize)]
pub struct NewClientRequest {
}

#[derive(Serialize, Deserialize)]
pub struct DeviceInputRequest {
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Input {
    pub move_x: i32,
    pub move_y: i32,
    pub button: u32,
}
