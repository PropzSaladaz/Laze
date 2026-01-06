pub mod commands;

use std::sync::{Arc, Mutex};

use server::{MobileController, Server, ServerConfig};
use tauri::{Manager, RunEvent};

use commands::SharedCommunicator;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let app = tauri::Builder::default()
        .setup(|app| {
            // load environment variables from .env file
            // includes log level
            dotenv::dotenv().ok();

            let controller: MobileController = MobileController::new(1, 1, 1, 1500).unwrap();

            let config = ServerConfig::new(7878, 10);

            let handle = Server::start(config, controller);
            let shared_comm: SharedCommunicator = Arc::new(Mutex::new(handle));
            app.manage(shared_comm);
            Ok(())
        })
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            commands::start_server,
            commands::stop_server,
            commands::remove_client,
        ])
        .build(tauri::generate_context!())
        .expect("error while building tauri application");

    app.run(|app_handle, event| {
        if let RunEvent::ExitRequested { .. } = event {
            // Terminate the server when app is closing
            if let Some(state) = app_handle.try_state::<SharedCommunicator>() {
                println!("App exiting, terminating server...");
                commands::terminate_server(&state);
            }
        }
    });
}
