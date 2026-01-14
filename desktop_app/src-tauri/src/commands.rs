use std::sync::{Arc, Mutex};

use server::{ServerEvent, ServerHandler};
use tauri::Emitter;
use tokio::sync::broadcast;

pub type SharedCommunicator = Arc<Mutex<ServerHandler>>;

#[tauri::command]
pub fn start_server(
    app_handle: tauri::AppHandle,
    state: tauri::State<'_, SharedCommunicator>,
) -> String {
    let mut handler = state.lock().unwrap();

    if let Err(e) = handler.start_server() {
        return format!("Failed to start server: {:?}", e);
    }

    match handler.receive_response() {
        Ok(server::ServerResponse::ServerStarted(_)) => {
            spawn_event_listener(handler.subscribe_events(), app_handle);
            "Server initialized successfully.".to_string()
        }
        Ok(resp) => {
            format!("Unexpected response: {:?}", resp)
        }
        Err(e) => {
            format!("Failed to receive response: {:?}", e)
        }
    }
}

#[tauri::command]
pub fn stop_server(state: tauri::State<'_, SharedCommunicator>) -> String {
    let mut handler = state.lock().unwrap();

    if let Err(e) = handler.stop_server() {
        return format!("Failed to stop server: {:?}", e);
    }

    match handler.receive_response() {
        Ok(server::ServerResponse::ServerStopped(_)) => "Server stopped successfully.".to_string(),
        Ok(resp) => {
            format!("Unexpected response: {:?}", resp)
        }
        Err(e) => {
            format!("Failed to receive response: {:?}", e)
        }
    }
}

/// Called on app exit to fully terminate the server
pub fn terminate_server(state: &SharedCommunicator) {
    let mut handler = state.lock().unwrap();

    if let Err(e) = handler.terminate_server() {
        eprintln!("Failed to terminate server: {:?}", e);
        return;
    }

    match handler.receive_response() {
        Ok(server::ServerResponse::ServerTerminated(_)) => {
            println!("Server terminated successfully.");
        }
        Ok(resp) => {
            eprintln!("Unexpected response during termination: {:?}", resp);
        }
        Err(e) => {
            eprintln!("Failed to receive termination response: {:?}", e);
        }
    }
}

#[tauri::command]
pub fn remove_client(state: tauri::State<'_, SharedCommunicator>, client_id: usize) -> String {
    let mut handler = state.lock().unwrap();

    if let Err(e) = handler.terminate_client(client_id) {
        return format!("Failed to remove client: {:?}", e);
    }

    match handler.receive_response() {
        Ok(server::ServerResponse::ClientTerminated(_)) => {
            format!("Client {} removed successfully.", client_id)
        }
        Ok(resp) => {
            format!("Unexpected response: {:?}", resp)
        }
        Err(e) => {
            format!("Failed to receive response: {:?}", e)
        }
    }
}

fn spawn_event_listener(
    mut event_receiver: broadcast::Receiver<ServerEvent>,
    app_handle: tauri::AppHandle,
) {
    // Listen for server events in background task
    tauri::async_runtime::spawn(async move {
        loop {
            match event_receiver.recv().await {
                Ok(event) => {
                    println!("Received server event: {:?}", event);
                    let result = match event {
                        ServerEvent::ClientAdded(client_info) => {
                            app_handle.emit("client-added", client_info)
                        }
                        ServerEvent::ClientRemoved(client_info) => {
                            app_handle.emit("client-removed", client_info)
                        }
                        ServerEvent::ClientUpdated(client_info) => {
                            app_handle.emit("client-updated", client_info)
                        }
                    };

                    if let Err(e) = result {
                        eprintln!("Failed to emit event: {:?}", e);
                    }
                }
                Err(broadcast::error::RecvError::Closed) => {
                    // Channel closed, server terminated - exit gracefully
                    println!("Event channel closed, stopping event listener");
                    break;
                }
                Err(broadcast::error::RecvError::Lagged(n)) => {
                    eprintln!("Event listener lagged, missed {} events", n);
                }
            }
        }
    });
}
