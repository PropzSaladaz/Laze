use std::{
    net::{Ipv4Addr, TcpListener, TcpStream}, thread
};

mod ffi;
mod device;

use local_ip_address as ip;

const PORT: usize = 7878;


fn main() {

    let dev = device::Device::new("/dev/uinput", "mouse", 1, 1, 15000);
    let local_ip = ip::local_ip().unwrap();
    let listener = TcpListener::bind(format!("{local_ip}:{PORT}")).unwrap();
    match listener.accept() {
        Ok((_socket, addr)) => {
            let mut a = 50;
            while a > 0 {
                a-=1;
                dev.pos_move(5, 5);
            }
            println!("Received connection from {addr}");
        }
        Err(e) => println!("Error: {e}"),
    }
}

