use std::sync::{Arc, Mutex};

use server::{ServerHandler, ServerEvent};
use tauri::Emitter;
use tokio::sync::broadcast;

type SharedCommunicator = Arc<Mutex<ServerHandler>>;

#[tauri::command]
pub fn start_server(app_handle: tauri::AppHandle, state: tauri::State<'_, SharedCommunicator>) -> String {
    let mut state = state.lock().unwrap();
    state.start_server().unwrap();

    match state.receive_response() {
        Ok(server::ServerResponse::ServerStarted(_)) => {
            spawn_event_listener(state.subscribe_events(), app_handle);
            return format!("Server initialized successfully.");
        },
        _ => {
            return format!("Unexpected response during server initialization.");
        }
    }
}

#[tauri::command]
pub fn stop_server(state: tauri::State<'_, SharedCommunicator>) -> String {
    state.lock().unwrap().terminate_server().unwrap();

    match state.lock().unwrap().receive_response() {
        Ok(server::ServerResponse::ServerTerminated(_)) => {
            return format!("Server terminated successfully.");
        },
        _ => {
            return format!("Unexpected response during server termination.");
        }
    }
}


fn spawn_event_listener(
    mut event_receiver: broadcast::Receiver<ServerEvent>,
    app_handle: tauri::AppHandle,
) {
    // listen for server events
    tauri::async_runtime::spawn(async move {
        while let Ok(event) = event_receiver.recv().await {

            // Handle server events here, e.g., log them or update UI
            println!("Received server event: {:?}", event);
            match event {
                ServerEvent::ClientAdded(client_info) => {
                    app_handle.emit("client-added", client_info).unwrap();
                }
                ServerEvent::ClientRemoved(client_info) => {
                    app_handle.emit("client-removed", client_info).unwrap();
                }
            }
        }
    });
}