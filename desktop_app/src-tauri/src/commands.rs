use std::sync::{Arc, Mutex};

use server::CommandSender;

type SharedCommunicator = Arc<Mutex<CommandSender>>;

#[tauri::command]
pub fn start_server(state: tauri::State<'_, SharedCommunicator>) -> String {
    state.lock().unwrap().send_request(server::ServerRequest::InitServer).unwrap();
    
    match state.lock().unwrap().receive_response() {
        Ok(server::ServerResponse::ServerStarted(_)) => {
            return format!("Server initialized successfully.");
        },
        _ => {
            return format!("Unexpected response during server initialization.");
        }
    }
}

#[tauri::command]
pub fn stop_server(state: tauri::State<'_, SharedCommunicator>) -> String {
    state.lock().unwrap().send_request(server::ServerRequest::TerminateServer).unwrap();

    match state.lock().unwrap().receive_response() {
        Ok(server::ServerResponse::ServerTerminated(_)) => {
            return format!("Server terminated successfully.");
        },
        _ => {
            return format!("Unexpected response during server termination.");
        }
    }
}