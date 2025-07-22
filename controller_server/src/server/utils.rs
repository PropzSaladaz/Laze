use std::net::TcpListener;

use local_ip_address::local_ip;

/// Creates a TcpListener using the local machine's IP address
pub fn create_socket(port: usize) -> TcpListener {
    let local_ip = local_ip().unwrap();
    log::debug!("Created new Sync socket: {local_ip}:{port}");
    TcpListener::bind(format!("{local_ip}:{port}")).unwrap()
}

pub fn get_local_ip() -> String {
    local_ip().unwrap().to_string()
}