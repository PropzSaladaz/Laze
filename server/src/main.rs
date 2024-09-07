use device::{Device, InputHandler};
use server::{ConnectionStatus, Server, ServerConfig};

mod device;
mod server;
mod messages;
mod actions;
mod keybinds;

const PORT: u16 = 7878;

struct DeviceApp<T: InputHandler> {
    handler: T,
}

impl<T: InputHandler> server::Application for DeviceApp<T> {
    fn handle(&mut self, input: &[u8]) -> ConnectionStatus {
        match self.handler.handle(input) {
            ConnectionStatus::Disconnected  => ConnectionStatus::Disconnected,
            ConnectionStatus::Connected     => ConnectionStatus::Connected
        }
        
    }
}

fn main() {
    let config = ServerConfig::new(PORT, 2);
    let app = DeviceApp {
        handler: Device::new(
            1, 
            1,
            1,
            1500).unwrap()
    };
    let mut server = Server::build(config, app).unwrap();
    server.start();
}




