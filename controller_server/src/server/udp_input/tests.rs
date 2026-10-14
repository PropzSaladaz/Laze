use super::*;
use crate::{
    security::{
        make_record,
        tests::{manager, pair},
    },
    server::application::ConnectionStatus,
};
use std::time::Instant;
#[derive(Default)]
struct Recorder(Vec<Vec<u8>>);
impl Application for Recorder {
    fn dispatch_to_device(&mut self, payload: &[u8]) -> ConnectionStatus {
        self.0.push(payload.to_vec());
        ConnectionStatus::Connected
    }
}
#[test]
fn actual_udp_socket_requires_live_authenticated_motion_and_rejects_replay() {
    let auth = manager();
    let (_, _, id, keys) = pair(&auth, "phone");
    let receiver = UdpSocket::bind(("127.0.0.1", 0)).unwrap();
    let destination = receiver.local_addr().unwrap();
    let app = Arc::new(Mutex::new(Recorder::default()));
    let handle = start_udp_socket(receiver, app.clone(), auth.clone()).unwrap();
    let sender = UdpSocket::bind(("127.0.0.1", 0)).unwrap();
    sender.send_to(&[3, 1, 1], destination).unwrap(); // legacy unauthenticated format
    let motion = make_record(&id, 0, &[3, 1, 255], &keys.client_udp);
    let mut tampered = motion.clone();
    tampered[24] ^= 1;
    sender.send_to(&tampered, destination).unwrap();
    sender
        .send_to(&make_record(&id, 0, &[6], &keys.client_udp), destination)
        .unwrap();
    sender.send_to(&motion, destination).unwrap();
    sender.send_to(&motion, destination).unwrap();
    let deadline = Instant::now() + Duration::from_secs(3);
    while app.lock().unwrap().0.is_empty() {
        assert!(Instant::now() < deadline);
        thread::sleep(Duration::from_millis(5));
    }
    auth.revoke("phone").unwrap();
    sender
        .send_to(
            &make_record(&id, 1, &[3, 1, 1], &keys.client_udp),
            destination,
        )
        .unwrap();
    thread::sleep(Duration::from_millis(100));
    drop(handle);
    assert_eq!(app.lock().unwrap().0, vec![vec![3, 1, 255]]);
}
