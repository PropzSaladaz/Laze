//! UDP Discovery Service
//!
//! Listens for UDP broadcast discovery requests from mobile clients
//! and responds with the server's IP address.
#![allow(dead_code)]

use std::{
    net::{IpAddr, Ipv4Addr, SocketAddr, UdpSocket},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    thread,
    time::Duration,
};

use crate::logger::Loggable;

/// Discovery port for UDP broadcast
pub const DISCOVERY_PORT: u16 = 7877;

/// Discovery request message from mobile clients
const DISCOVERY_REQUEST: &[u8] = b"DISCOVER_MOBILE_CONTROLLER";

/// Response prefix - will be followed by IP:PORT
const DISCOVERY_RESPONSE_PREFIX: &str = "MOBILE_CONTROLLER";

/// Handle to control the discovery listener
pub struct DiscoveryHandle {
    shutdown_signal: Arc<AtomicBool>,
    thread_handle: Option<thread::JoinHandle<()>>,
}

impl DiscoveryHandle {
    /// Signal the discovery listener to stop
    pub fn shutdown(&self) {
        self.shutdown_signal.store(true, Ordering::SeqCst);
    }

    /// Wait for the discovery thread to finish
    pub fn wait_for_exit(mut self) {
        if let Some(handle) = self.thread_handle.take() {
            // Send a packet to ourselves to unblock the recv
            if let Ok(socket) = UdpSocket::bind("0.0.0.0:0") {
                let _ = socket.send_to(b"SHUTDOWN", format!("127.0.0.1:{}", DISCOVERY_PORT));
            }
            let _ = handle.join();
        }
    }
}

/// Start the UDP discovery listener
///
/// Listens for broadcast messages from mobile clients and responds with
/// the server's IP address so they can connect.
pub fn start_discovery_listener(tcp_port: u16) -> Result<DiscoveryHandle, std::io::Error> {
    let socket = UdpSocket::bind(SocketAddr::new(
        IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)),
        DISCOVERY_PORT,
    ))?;

    socket.set_broadcast(true)?;
    socket.set_read_timeout(Some(Duration::from_secs(1)))?;

    let shutdown_signal = Arc::new(AtomicBool::new(false));
    let shutdown_clone = Arc::clone(&shutdown_signal);

    let thread_handle = thread::spawn(move || {
        DiscoveryListener::run(socket, tcp_port, shutdown_clone);
    });

    DiscoveryListener::static_log_info(&format!(
        "Discovery listener started on UDP port {}",
        DISCOVERY_PORT
    ));

    Ok(DiscoveryHandle {
        shutdown_signal,
        thread_handle: Some(thread_handle),
    })
}

struct DiscoveryListener;

impl DiscoveryListener {
    fn run(socket: UdpSocket, tcp_port: u16, shutdown_signal: Arc<AtomicBool>) {
        let mut buf = [0u8; 1024];

        loop {
            if shutdown_signal.load(Ordering::SeqCst) {
                Self::static_log_info("Discovery listener shutting down");
                break;
            }

            match socket.recv_from(&mut buf) {
                Ok((len, src_addr)) => {
                    let message = &buf[..len];

                    // Check if this is a valid discovery request
                    if message == DISCOVERY_REQUEST {
                        Self::static_log_info(&format!(
                            "Received discovery request from {}",
                            src_addr
                        ));

                        // Get our local IP that can reach the client
                        if let Some(local_ip) = Self::get_local_ip_for(&src_addr) {
                            let response =
                                format!("{}:{}:{}", DISCOVERY_RESPONSE_PREFIX, local_ip, tcp_port);

                            if let Err(e) = socket.send_to(response.as_bytes(), src_addr) {
                                Self::static_log_error(&format!(
                                    "Failed to send discovery response: {}",
                                    e
                                ));
                            } else {
                                Self::static_log_info(&format!(
                                    "Sent discovery response to {}: {}",
                                    src_addr, response
                                ));
                            }
                        }
                    }
                }
                Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                    // Timeout, just continue
                    continue;
                }
                Err(e) => {
                    Self::static_log_error(&format!("Discovery socket error: {}", e));
                }
            }
        }
    }

    /// Get the local IP address that can reach a given remote address
    fn get_local_ip_for(remote: &SocketAddr) -> Option<String> {
        // Connect to the remote address to determine which local interface to use
        let probe_socket = UdpSocket::bind("0.0.0.0:0").ok()?;
        probe_socket.connect(remote).ok()?;
        let local_addr = probe_socket.local_addr().ok()?;
        Some(local_addr.ip().to_string())
    }
}
