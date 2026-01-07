// Declaration of the controller_server library
mod actions;
mod keybinds;
pub mod logger;
mod mobile_controller;
mod server;

// Re-exported types
pub use server::{
    application::Application,
    commands::{ServerRequest, ServerResponse},
    core::{ClientInfo, Server, ServerConfig, ServerEvent, ServerHandler},
    discovery::{start_discovery_listener, DiscoveryHandle, DISCOVERY_PORT},
};

pub use mobile_controller::MobileController;
