use device::{Device, InputHandler};
use server::{ConnectionStatus, Server, ServerConfig};

mod device;
mod server;
mod actions;
mod keybinds;

const PORT: usize = 7878;


fn main() {
    let config = ServerConfig::new(PORT, 2);
    let app = server::MobileControllerApp::new(
        Device::new(
            1, 
            1,
            1,
            1500).unwrap()
        );
    let mut server = Server::build(config, app).unwrap();
    server.start();
}


