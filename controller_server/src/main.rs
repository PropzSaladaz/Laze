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
    let mut handle = Server::start(config, app);

    // emulates main thread communication with server
    handle.start_server().unwrap();
    match handle.receive_response() {
        Ok(server::commands::ServerResponse::ServerStarted(_)) => {
            println!("Server initialized successfully.");
        },
        Ok(server::commands::ServerResponse::Error(err)) => {
            println!("Error initializing server: {}", err);
        },
        _ => {
            println!("Unexpected response during initialization.");
        }
    }
    sleep(Duration::from_secs(6));

    handle.terminate_client(2).unwrap();
    match handle.receive_response() {
        Ok(server::commands::ServerResponse::ClientTerminated(t)) => {
            println!("Client {} terminated successfully.", t.client_id);
        },
        Ok(server::commands::ServerResponse::Error(err)) => {
            println!("Error terminating client: {}", err);
        },
        _ => {
            println!("Unexpected response during client termination.");
        }
    }

    sleep(Duration::from_secs(6));

    handle.terminate_server().unwrap();
    match handle.receive_response() {
        Ok(server::commands::ServerResponse::ServerTerminated(_)) => {
            println!("Server terminated successfully.");
        },
        Ok(server::commands::ServerResponse::Error(err)) => {
            println!("Error terminating server: {}", err);
        },
        _ => {
            println!("Unexpected response during server termination.");
        }
    }
    sleep(Duration::from_secs(2));    
}


