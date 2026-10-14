//! Authenticated motion input, tied to a live TCP session and its own replay counter.
use super::application::Application;
use crate::security::{AuthManager, Transport, FRAME_OVERHEAD};
use std::{
    io,
    net::UdpSocket,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    thread,
    time::Duration,
};
pub const UDP_INPUT_PORT: u16 = 7876;
pub struct UdpInputHandle {
    shutdown: Arc<AtomicBool>,
    thread: Option<thread::JoinHandle<()>>,
}
impl UdpInputHandle {
    pub fn shutdown(&self) {
        self.shutdown.store(true, Ordering::SeqCst);
    }
}
impl Drop for UdpInputHandle {
    fn drop(&mut self) {
        self.shutdown();
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}
pub fn start_udp_input_listener<A: Application + 'static>(
    app: Arc<Mutex<A>>,
    auth: Arc<AuthManager>,
) -> io::Result<UdpInputHandle> {
    let socket = UdpSocket::bind(("0.0.0.0", UDP_INPUT_PORT))?;
    start_udp_socket(socket, app, auth)
}
fn start_udp_socket<A: Application + 'static>(
    socket: UdpSocket,
    app: Arc<Mutex<A>>,
    auth: Arc<AuthManager>,
) -> io::Result<UdpInputHandle> {
    socket.set_read_timeout(Some(Duration::from_millis(250)))?;
    let shutdown = Arc::new(AtomicBool::new(false));
    let flag = Arc::clone(&shutdown);
    let thread = thread::spawn(move || {
        // Extra byte detects oversized datagrams even when recv_from truncates them.
        let mut buf = [0; FRAME_OVERHEAD + 4];
        while !flag.load(Ordering::SeqCst) {
            match socket.recv_from(&mut buf) {
                Ok((len, _)) => {
                    if len > FRAME_OVERHEAD + 3 {
                        continue;
                    }
                    let _ = auth.with_input(None, Transport::Udp, &buf[..len], |payload| {
                        if let Ok(mut app) = app.lock() {
                            app.dispatch_to_device(payload);
                        }
                    });
                }
                Err(e)
                    if e.kind() == io::ErrorKind::TimedOut
                        || e.kind() == io::ErrorKind::WouldBlock => {}
                Err(_) => thread::sleep(Duration::from_millis(10)),
            }
        }
    });
    Ok(UdpInputHandle {
        shutdown,
        thread: Some(thread),
    })
}
#[cfg(test)]
mod tests;
