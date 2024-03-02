use server::{ServerConfig, Server};

mod ffi;
mod device;
mod server;
mod messages;

const PORT: u16 = 7878;

struct DeviceApp {
}

// TODO
impl server::Application for DeviceApp {
    fn handle(&self, input: &[u8]) {
        println!("handled!!");
    }
}

fn main() {
    let config = ServerConfig::new(PORT, 2);
    let app = DeviceApp {};
    let mut server = Server::build(config, app).unwrap();
    server.start();
}

