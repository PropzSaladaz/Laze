pub mod commands;

use std::sync::{Arc, Mutex};

use server::{start_discovery_listener, DiscoveryHandle, MobileController, Server, ServerConfig};
use tauri::{Manager, RunEvent};

use commands::SharedCommunicator;

/// Shared handle to the discovery listener
pub type SharedDiscovery = Arc<Mutex<Option<DiscoveryHandle>>>;

const TCP_PORT: u16 = 7878;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let app = tauri::Builder::default()
        .setup(|app| {
            // load environment variables from .env file
            // includes log level
            dotenv::dotenv().ok();

            let controller: MobileController = MobileController::new(1, 1, 1, 1500).unwrap();

            let config = ServerConfig::new(TCP_PORT as usize, 10);

            let handle = Server::start(config, controller);
            let shared_comm: SharedCommunicator = Arc::new(Mutex::new(handle));
            app.manage(shared_comm);

            // Start UDP discovery listener
            match start_discovery_listener(TCP_PORT) {
                Ok(discovery_handle) => {
                    let shared_discovery: SharedDiscovery =
                        Arc::new(Mutex::new(Some(discovery_handle)));
                    app.manage(shared_discovery);
                    println!("UDP discovery listener started on port 7877");
                }
                Err(e) => {
                    eprintln!("Failed to start discovery listener: {}", e);
                    // Non-fatal - app can still work without discovery
                    let shared_discovery: SharedDiscovery = Arc::new(Mutex::new(None));
                    app.manage(shared_discovery);
                }
            }

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

            // Shutdown discovery listener
            if let Some(state) = app_handle.try_state::<SharedDiscovery>() {
                if let Some(handle) = state.lock().unwrap().take() {
                    println!("Shutting down discovery listener...");
                    handle.shutdown();
                }
            }
        }
    });
}
