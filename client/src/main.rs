use std::{
    io::{self, Write}, net::{IpAddr, Ipv4Addr, SocketAddr, TcpStream},
    time::Duration,
};

use serde::{Deserialize, Serialize};

const PORT: u16 = 7878;

#[derive(Serialize, Deserialize, Debug)]
pub struct Input {
    move_x: i32,
    move_y: i32,
}


fn main() {
    let base_ip: Ipv4Addr = "192.168.1.0".parse().unwrap();
    let subnet_mask: u32 = 24;

    for i in 0..2u32.pow(32 - subnet_mask) {
        let test_ip = Ipv4Addr::from(u32::from(base_ip) | i);
        println!("Sending msg to: {test_ip}:{PORT}");
        match is_open(test_ip) {
            Some(mut stream) => {
                let mut input = String::new();

                // remain open to test
                loop {
                    match io::stdin().read_line(&mut input) {
                        Ok(_) => {
                            let mut msg = match input.trim() {
                                "a" => serde_json::to_vec(&Input { move_x: -1, move_y:  0}).unwrap(),
                                "w" => serde_json::to_vec(&Input { move_x:  0, move_y: -1}).unwrap(),
                                "s" => serde_json::to_vec(&Input { move_x:  0, move_y:  1}).unwrap(),
                                "d" => serde_json::to_vec(&Input { move_x:  1, move_y:  0}).unwrap(),
                                _ => vec![]
                            };
                            stream.write_all(msg.as_slice());
                        }
                        Err(error) => eprintln!("Error: {}", error)
                    }
                    
                }
            }
            None => (),
        };
    }
}

fn is_open(host: Ipv4Addr) -> Option<TcpStream> {
    let socket_addr: SocketAddr = SocketAddr::new(IpAddr::V4(host), PORT);
    match TcpStream::connect_timeout(&socket_addr, Duration::from_millis(10)) {
        Ok(stream) => {
            println!("Connected to: {host}:{PORT}");
            Some(stream)
        },
        Err(_) => {
            println!("No server here: {host}:{PORT}");
            None
        },
    } 
}
