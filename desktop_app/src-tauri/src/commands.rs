use std::sync::{Arc, Mutex};

use server::{CommandSender, ClientInfo};

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

#[tauri::command]
pub fn remove_client(state: tauri::State<'_, SharedCommunicator>, client_id: usize) -> String {
    state.lock().unwrap().send_request(server::ServerRequest::TerminateClient(client_id)).unwrap();

    match state.lock().unwrap().receive_response() {
        Ok(server::ServerResponse::ClientTerminated(_)) => {
            return format!("Client {} removed successfully.", client_id);
        },
        Ok(server::ServerResponse::Error(err)) => {
            return format!("Error removing client {}: {}", client_id, err);
        },
        _ => {
            return format!("Unexpected response during client removal.");
        }
    }
}

#[tauri::command]
pub fn get_clients(state: tauri::State<'_, SharedCommunicator>) -> Vec<ClientInfo> {
    state.lock().unwrap().send_request(server::ServerRequest::GetClients).unwrap();

    match state.lock().unwrap().receive_response() {
        Ok(server::ServerResponse::ClientList(client_list)) => {
            return client_list.clients;
        },
        _ => {
            return Vec::new();
        }
    }
}