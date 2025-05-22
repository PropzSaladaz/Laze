use mobile_controller::MobileController;
use server::{Server, ServerConfig};

mod mobile_controller;
mod server;
mod actions;
mod keybinds;

const PORT: usize = 7878;


fn main() {
    let config = ServerConfig::new(PORT, 0);
    let app = MobileController::new(
            1, 
            1,
            1,
            1500).unwrap();
    let mut server = Server::build(config, app).unwrap();
    server.start();
}


