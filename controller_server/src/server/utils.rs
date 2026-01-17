use std::net::TcpListener;

use local_ip_address::local_ip;

/// Creates a TcpListener using the local machine's IP address
///
/// Returns an error if no network is available or if binding fails.
pub fn create_socket(port: usize) -> std::io::Result<TcpListener> {
    let local_ip = local_ip()
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::NetworkUnreachable, e.to_string()))?;
    log::debug!("Created new Sync socket: {local_ip}:{port}");
    TcpListener::bind(format!("{local_ip}:{port}"))
}
