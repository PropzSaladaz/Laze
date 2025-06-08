use std::time::Duration;
use std::thread::sleep;

use mobile_controller::MobileController;
use server::{Server, ServerConfig};

mod mobile_controller;
mod server;
mod actions;
mod keybinds;

const PORT: usize = 7878;

fn main() {
    let config = ServerConfig::new(PORT, 10);
    let app = MobileController::new(
            1, 
            1,
            1,
            1500).unwrap();

    // server has started here
    let mut server_comm = Server::start(config, app);

    // emulates main thread communication with server
    loop {
        println!("Sending msg to server...");
        server_comm.send_request(server::ServerRequest::InitServer);
        match server_comm.receive_response() {
            Ok(server::ServerResponse::ServerStarted(p)) => {
                println!("Server initialized successfully. {p}");
            },
            _ => {
                println!("Unexpected response during initialization.");
            }
        }
        sleep(Duration::from_secs(6));

        server_comm.send_request(server::ServerRequest::TerminateClient(2));
        match server_comm.receive_response() {
            Ok(server::ServerResponse::ClientTerminated(t)) => {
                println!("Client terminated successfully.{t}");
            },
            _ => {
                println!("Unexpected response during client termination.");
            }
        }

        sleep(Duration::from_secs(6));

        server_comm.send_request(server::ServerRequest::TerminateServer);
        match server_comm.receive_response() {
            Ok(server::ServerResponse::ServerTerminated) => {
                println!("Server terminated successfully.");
            },
            _ => {
                println!("Unexpected response during server termination.");
            }
        }
        sleep(Duration::from_secs(6));
    
    }
}


