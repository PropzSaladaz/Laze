pub mod commands;

use std::sync::{Arc, Mutex};

use server::{MobileController, Server, ServerConfig};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            // load environemnt variables from .env file
            // includes log level
            dotenv::dotenv().ok();

            let controller: MobileController = MobileController::new(
                1, 
                1,
                1,
                1500).unwrap();

            let config = ServerConfig::new(7878, 10);

            let server_comm = Server::start(config, controller);
            let shared_comm = Arc::new(Mutex::new(server_comm));
            app.manage(shared_comm);
            Ok(())
        })
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            commands::start_server,
            commands::stop_server,
            commands::remove_client,
            commands::get_clients,
            // Add more commands here
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
