use std::{
    io::{self, BufReader, Read, Write}, net::{IpAddr, Ipv4Addr, SocketAddr, TcpStream}, str::from_utf8, time::Duration
};

use serde::{Deserialize, Serialize};

const PORT: u16 = 7878;

#[derive(Serialize, Deserialize, Debug)]
pub struct Input {
    move_x: i32,
    move_y: i32,
}

#[derive(Serialize, Deserialize)]
pub struct NewClientResponse {
    pub port: u16,
}


fn main() {
    let base_ip: Ipv4Addr = "192.168.1.0".parse().unwrap();
    let subnet_mask: u32 = 24;

    for i in 0..2u32.pow(32 - subnet_mask) {
        let test_ip = Ipv4Addr::from(u32::from(base_ip) | i);
        println!("Sending msg to: {test_ip}:{PORT}");
        match is_open(test_ip, PORT) {
            Some(mut stream) => {
                stream.set_read_timeout(Some(Duration::from_millis(200)));
                let mut bytes = [0 ; 1024];
                let bytes_size = stream.read(&mut bytes).unwrap();
                let bytes = &bytes[..bytes_size];

                let client_resp: NewClientResponse = serde_json::from_slice(&bytes)
                    .expect("Could not parse the data from the socket");

                match is_open(test_ip, client_resp.port) {
                    Some(mut stream) => handle_connection(stream),
                    None => ()
                }
            }
            None => (),
        };
    }
}

fn is_open(host: Ipv4Addr, port: u16) -> Option<TcpStream> {
    let socket_addr: SocketAddr = SocketAddr::new(IpAddr::V4(host), port);
    match TcpStream::connect_timeout(&socket_addr, Duration::from_millis(10)) {
        Ok(stream) => {
            println!("Connected to: {host}:{port}");
            Some(stream)
        },
        Err(_) => {
            println!("No server here: {host}:{port}");
            None
        },
    } 
}

fn handle_connection(mut stream: TcpStream) {
    println!("Connection: {:#?}", stream);
    let mut input = String::new();

    // remain open to test
    loop {
        match io::stdin().read_line(&mut input) {
            Ok(_) => {
                let msg = match input.trim() {
                    "a" => serde_json::to_vec(&Input { move_x: -1, move_y:  0}).unwrap(),
                    "w" => serde_json::to_vec(&Input { move_x:  0, move_y: -1}).unwrap(),
                    "s" => serde_json::to_vec(&Input { move_x:  0, move_y:  1}).unwrap(),
                    "d" => serde_json::to_vec(&Input { move_x:  1, move_y:  0}).unwrap(),
                    _ => vec![]
                };
                println!("msg: {:#?}", msg);
                stream.write_all(msg.as_slice()).unwrap();
            }
            Err(error) => eprintln!("Error: {}", error)
        }
    }
}
