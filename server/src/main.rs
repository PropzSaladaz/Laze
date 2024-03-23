use device::{Device, InputHandler};
use server::{ServerConfig, Server};

use crate::messages::Input;

mod keybinds;
mod ffi;
mod device;
mod server;
mod messages;

const PORT: u16 = 7878;

struct DeviceApp<T: InputHandler> {
    handler: T,
}

impl<T: InputHandler> server::Application for DeviceApp<T> {
    fn handle(&mut self, input: &[u8]) {
        self.handler.handle(input);
    }
}

fn main() {
    let config = ServerConfig::new(PORT, 2);
    let app = DeviceApp {
        handler: Device::new(
            "/dev/uinput",
            "virtual-mouse", 
            1, 1, 1,  1500)
    };
    let mut server = Server::build(config, app).unwrap();
    server.start();
}




