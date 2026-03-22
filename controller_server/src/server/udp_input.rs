//! UDP Input Service
#![allow(dead_code)]
//!
//! Listens for UDP motion input packets (mouse move, scroll) from mobile clients
//! and dispatches them through the existing Application path.
//!
//! Each packet starts with a 4-byte big-endian sequence number so stale or
//! out-of-order packets can be dropped without affecting the cursor.

use std::{
    collections::HashMap,
    net::{IpAddr, Ipv4Addr, SocketAddr, UdpSocket},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    thread,
    time::Duration,
};

use crate::logger::Loggable;

use super::application::Application;

/// UDP port for receiving motion input (mouse move, scroll)
pub const UDP_INPUT_PORT: u16 = 7876;

/// Maximum UDP packet size: seq(4) + action_type(1) + max_payload(11)
const MAX_PACKET_SIZE: usize = 16;

/// Handle to control the UDP input listener
pub struct UdpInputHandle {
    shutdown_signal: Arc<AtomicBool>,
    thread_handle: Option<thread::JoinHandle<()>>,
}

impl UdpInputHandle {
    /// Signal the listener to stop
    pub fn shutdown(&self) {
        self.shutdown_signal.store(true, Ordering::SeqCst);
    }

    /// Wait for the listener thread to finish
    pub fn wait_for_exit(mut self) {
        if let Some(handle) = self.thread_handle.take() {
            // Send a packet to ourselves to unblock recv_from
            if let Ok(socket) = UdpSocket::bind("0.0.0.0:0") {
                let _ = socket.send_to(b"SHUTDOWN", format!("127.0.0.1:{}", UDP_INPUT_PORT));
            }
            let _ = handle.join();
        }
    }
}

/// Start the UDP input listener.
///
/// Accepts motion input packets with the format:
///   `[seq: u32 big-endian, action_type: u8, ...payload]`
///
/// Only action types 2 (Scroll) and 3 (MouseMove) are accepted.
/// Stale or out-of-order packets are dropped via per-source sequence tracking.
pub fn start_udp_input_listener<A: Application + 'static>(
    app: Arc<Mutex<A>>,
) -> Result<UdpInputHandle, std::io::Error> {
    let socket = UdpSocket::bind(SocketAddr::new(
        IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)),
        UDP_INPUT_PORT,
    ))?;
    socket.set_read_timeout(Some(Duration::from_secs(1)))?;

    let shutdown_signal = Arc::new(AtomicBool::new(false));
    let shutdown_clone = Arc::clone(&shutdown_signal);

    let thread_handle = thread::spawn(move || {
        UdpInputListener::run(socket, app, shutdown_clone);
    });

    UdpInputListener::static_log_info(&format!(
        "UDP input listener started on port {}",
        UDP_INPUT_PORT
    ));

    Ok(UdpInputHandle {
        shutdown_signal,
        thread_handle: Some(thread_handle),
    })
}

struct UdpInputListener;

impl UdpInputListener {
    fn run<A: Application + 'static>(
        socket: UdpSocket,
        app: Arc<Mutex<A>>,
        shutdown_signal: Arc<AtomicBool>,
    ) {
        let mut buf = [0u8; MAX_PACKET_SIZE];
        // Per-source sequence tracking: drops stale/out-of-order packets
        let mut last_seq: HashMap<SocketAddr, u32> = HashMap::new();

        loop {
            if shutdown_signal.load(Ordering::SeqCst) {
                Self::static_log_info("UDP input listener shutting down");
                break;
            }

            match socket.recv_from(&mut buf) {
                Ok((len, src_addr)) => {
                    // Must have at least seq(4) + action_type(1)
                    if len < 5 {
                        continue;
                    }

                    let seq = u32::from_be_bytes(buf[0..4].try_into().unwrap());
                    let action_bytes = &buf[4..len];

                    // Only accept MouseMove (3) and Scroll (2) — reject everything else
                    if action_bytes[0] != 2 && action_bytes[0] != 3 {
                        Self::static_log_debug(&format!(
                            "Rejected UDP packet with action type {} from {}",
                            action_bytes[0], src_addr
                        ));
                        continue;
                    }

                    // Sequence check — drop stale/duplicate packets
                    // u32::MAX as initial value ensures the very first packet always passes
                    let stored = last_seq.entry(src_addr).or_insert(u32::MAX);
                    if !Self::seq_is_newer(seq, *stored) {
                        Self::static_log_debug(&format!(
                            "Dropped stale UDP packet (seq={}, last={}) from {}",
                            seq, stored, src_addr
                        ));
                        continue;
                    }
                    *stored = seq;

                    // Dispatch through the existing Application path — no changes needed there
                    app.lock().unwrap().dispatch_to_device(action_bytes);
                }
                Err(ref e)
                    if e.kind() == std::io::ErrorKind::WouldBlock
                        || e.kind() == std::io::ErrorKind::TimedOut =>
                {
                    // Timeout — loop back and check the shutdown signal
                    continue;
                }
                Err(e) => {
                    Self::static_log_error(&format!("UDP input socket error: {}", e));
                }
            }
        }
    }

    /// Returns true if `incoming` is strictly newer than `last`.
    /// Uses a half-window wraparound check so u32 rollover is handled correctly
    /// (standard technique from RTP / game networking).
    fn seq_is_newer(incoming: u32, last: u32) -> bool {
        let diff = incoming.wrapping_sub(last);
        diff > 0 && diff < u32::MAX / 2
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_seq_is_newer_normal() {
        assert!(UdpInputListener::seq_is_newer(1, 0));
        assert!(UdpInputListener::seq_is_newer(100, 99));
        assert!(!UdpInputListener::seq_is_newer(0, 1));
        assert!(!UdpInputListener::seq_is_newer(99, 100));
    }

    #[test]
    fn test_seq_is_newer_equal_is_not_newer() {
        assert!(!UdpInputListener::seq_is_newer(5, 5));
    }

    #[test]
    fn test_seq_is_newer_wraparound() {
        // u32::MAX → 0 should be considered newer
        assert!(UdpInputListener::seq_is_newer(0, u32::MAX));
        // u32::MAX → u32::MAX - 1 should be considered newer
        assert!(UdpInputListener::seq_is_newer(u32::MAX, u32::MAX - 1));
    }

    #[test]
    fn test_seq_is_newer_first_packet() {
        // Initial stored value is u32::MAX, so any seq passes
        assert!(UdpInputListener::seq_is_newer(0, u32::MAX));
        assert!(UdpInputListener::seq_is_newer(1000, u32::MAX));
    }
}
