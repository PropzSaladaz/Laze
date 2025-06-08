use std::sync::{Arc, Mutex};

use server::ServerCommunicator;

type SharedCommunicator = Arc<Mutex<ServerCommunicator>>;

#[tauri::command]
pub fn start_server(state: tauri::State<'_, SharedCommunicator>) -> String {
    state.lock().unwrap().send_request(server::ServerRequest::InitServer);
    match state.lock().unwrap().receive_response() {
        Ok(server::ServerResponse::ServerStarted(port)) => {
            return format!("Server initialized successfully on port {port}.");
        },
        _ => {
            return format!("Unexpected response during server initialization.");
        }
    }
}