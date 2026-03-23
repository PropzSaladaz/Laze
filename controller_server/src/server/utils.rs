use std::net::TcpListener;

/// Creates a TcpListener bound on all IPv4 interfaces.
///
/// Binding to a single detected local IP is fragile on machines with multiple
/// adapters (Wi-Fi, Ethernet, VPN, Hyper-V). Discovery already tells clients
/// which concrete IP to use, so the listener should accept connections on any
/// local interface.
pub fn create_socket(port: usize) -> std::io::Result<TcpListener> {
    let bind_addr = format!("0.0.0.0:{port}");
    log::debug!("Created new Sync socket: {bind_addr}");
    TcpListener::bind(bind_addr)
}
