// Declaration of the controller_server library
pub mod logger;
mod server;
mod mobile_controller;
mod actions;
mod keybinds;


// Re-exported types
pub use server::{
    application::Application,
    core::{ServerConfig, Server},
    command_sender::{CommandSender},
    commands::{ServerRequest, ServerResponse, ClientInfo}
};

pub use mobile_controller::MobileController;