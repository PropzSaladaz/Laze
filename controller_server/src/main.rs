use std::time::Duration;
use std::thread::sleep;

use mobile_controller::MobileController;
use server::core::{Server, ServerConfig};

mod logger;
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
        server_comm.send_request(server::commands::ServerRequest::InitServer);
        match server_comm.receive_response() {
            Ok(server::commands::ServerResponse::ServerStarted(_)) => {
                println!("Server initialized successfully.");
            },
            _ => {
                println!("Unexpected response during initialization.");
            }
        }
        sleep(Duration::from_secs(6));

        server_comm.send_request(server::commands::ServerRequest::TerminateClient(2));
        match server_comm.receive_response() {
            Ok(server::commands::ServerResponse::ClientTerminated(t)) => {
                println!("Client terminated successfully.{}", t.client_id);
            },
            _ => {
                println!("Unexpected response during client termination.");
            }
        }

        sleep(Duration::from_secs(6));

        server_comm.send_request(server::commands::ServerRequest::TerminateServer);
        match server_comm.receive_response() {
            Ok(server::commands::ServerResponse::ServerTerminated(_)) => {
                println!("Server terminated successfully.");
            },
            _ => {
                println!("Unexpected response during server termination.");
            }
        }
        sleep(Duration::from_secs(6));
    
    }
}


