use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct NewClientResponse {
    pub port: u16,
}

#[derive(Serialize, Deserialize)]
pub struct NewClientRequest {
}

#[derive(Serialize, Deserialize)]
pub struct DeviceInputRequest {
}
