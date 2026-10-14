use std::fs;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use server::security::{AuthManager, PairingInvite, TrustedDevice};
use server::{MobileController, Server, ServerConfig, ServerEvent, ServerHandler};
use tauri::{Emitter, Manager};
use tokio::sync::broadcast;

use crate::TCP_PORT;

pub type SharedCommunicator = Arc<Mutex<Option<ServerHandler>>>;

/// Result type for server initialization
#[derive(Debug, Clone, serde::Serialize)]
pub struct InitResult {
    pub success: bool,
    pub message: String,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct DesktopNameSettings {
    name: String,
}

fn valid_desktop_name(name: &str) -> bool {
    !name.is_empty()
        && name.chars().count() <= 64
        && name.len() <= 128
        && !name.chars().any(char::is_control)
}

fn default_desktop_name() -> String {
    ["COMPUTERNAME", "HOSTNAME"]
        .into_iter()
        .filter_map(|key| std::env::var(key).ok())
        .map(|name| name.trim().to_owned())
        .find(|name| valid_desktop_name(name))
        .unwrap_or_else(|| "Laze desktop".into())
}

fn desktop_name_path(app_handle: &tauri::AppHandle) -> Result<PathBuf, String> {
    app_handle
        .path()
        .app_data_dir()
        .map(|path| path.join("desktop-name.json"))
        .map_err(|_| "Unable to locate desktop settings".into())
}

fn load_desktop_name(app_handle: &tauri::AppHandle) -> Result<String, String> {
    let path = desktop_name_path(app_handle)?;
    let data = match fs::read_to_string(path) {
        Ok(data) => data,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            return Ok(default_desktop_name());
        }
        Err(_) => return Err("Unable to read the computer name".into()),
    };
    let settings: DesktopNameSettings =
        serde_json::from_str(&data).map_err(|_| "Saved computer name is invalid")?;
    if !valid_desktop_name(&settings.name) {
        return Err("Saved computer name is invalid".into());
    }
    Ok(settings.name)
}

#[tauri::command]
pub fn get_desktop_name(app_handle: tauri::AppHandle) -> Result<String, String> {
    load_desktop_name(&app_handle)
}

#[tauri::command]
pub fn set_desktop_name(name: String, app_handle: tauri::AppHandle) -> Result<String, String> {
    let name = name.trim().to_owned();
    if !valid_desktop_name(&name) {
        return Err("Use 1–64 characters (up to 128 bytes), without control characters".into());
    }
    let path = desktop_name_path(&app_handle)?;
    fs::create_dir_all(path.parent().ok_or("Unable to locate desktop settings")?)
        .map_err(|_| "Unable to save the computer name")?;
    let data = serde_json::to_vec(&DesktopNameSettings { name: name.clone() })
        .map_err(|_| "Unable to save the computer name")?;
    fs::write(path, data).map_err(|_| "Unable to save the computer name")?;
    Ok(name)
}

/// Check if server is already initialized (quick check, no side effects)
#[tauri::command]
pub fn is_server_initialized(state: tauri::State<'_, SharedCommunicator>) -> bool {
    let guard = state.lock().unwrap();
    guard.is_some()
}

/// Initialize the server - can be called multiple times for retry
#[tauri::command]
pub fn init_server(
    app_handle: tauri::AppHandle,
    state: tauri::State<'_, SharedCommunicator>,
) -> InitResult {
    let mut guard = state.lock().unwrap();

    // Already initialized - but verify network is still available
    if let Some(handler) = guard.as_mut() {
        // Check if network is available
        if let Err(e) = local_ip_address::local_ip() {
            // Network went away after initialization. Terminate the old server instance.
            if let Err(term_err) = handler.terminate_server() {
                eprintln!(
                    "Failed to terminate server after network loss: {:?}",
                    term_err
                );
            }
            // Wait for termination to complete
            match handler.receive_response() {
                Ok(server::ServerResponse::ServerTerminated(_)) => {
                    println!("Server terminated due to network loss.");
                }
                Err(recv_err) => {
                    eprintln!("Failed to receive termination confirmation: {:?}", recv_err);
                }
                _ => {}
            }

            *guard = None; // Clear the old handler
            return InitResult {
                success: false,
                message: format!("Network unavailable: {}", e),
            };
        }
        return InitResult {
            success: true,
            message: "Server already initialized.".to_string(),
        };
    }

    // First check if network is available before doing anything else
    if let Err(e) = local_ip_address::local_ip() {
        return InitResult {
            success: false,
            message: format!(
                "Network unavailable: {}. Please check your WiFi connection.",
                e
            ),
        };
    }

    // Try to create the controller (requires display access on Linux)
    let controller = match MobileController::new() {
        Ok(c) => c,
        Err(e) => {
            return InitResult {
                success: false,
                message: format!("Failed to create controller: {}", e),
            };
        }
    };

    let config = ServerConfig::new(TCP_PORT as usize, 10);

    // Now safe to start since we verified network is available
    let auth_path = match app_handle.path().app_data_dir() {
        Ok(path) => path.join("paired-phones.json"),
        Err(_) => {
            return InitResult {
                success: false,
                message: "Unable to locate secure phone credentials".into(),
            }
        }
    };
    let auth = match AuthManager::load(auth_path) {
        Ok(auth) => Arc::new(auth),
        Err(message) => {
            return InitResult {
                success: false,
                message,
            }
        }
    };
    let handler = match Server::start(config, controller, auth) {
        Ok(handler) => handler,
        Err(_) => {
            return InitResult {
                success: false,
                message: "Unable to open the Laze network listener".into(),
            }
        }
    };
    *guard = Some(handler);

    InitResult {
        success: true,
        message: "Server initialized successfully.".to_string(),
    }
}

#[tauri::command]
pub fn start_server(
    app_handle: tauri::AppHandle,
    state: tauri::State<'_, SharedCommunicator>,
) -> String {
    let mut guard = state.lock().unwrap();

    let handler = match guard.as_mut() {
        Some(h) => h,
        None => return "Server not initialized. Call init_server first.".to_string(),
    };

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
    let mut guard = state.lock().unwrap();

    let handler = match guard.as_mut() {
        Some(h) => h,
        None => return "Server not initialized.".to_string(),
    };

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
    let mut guard = state.lock().unwrap();

    let handler = match guard.as_mut() {
        Some(h) => h,
        None => return, // Server was never initialized, nothing to terminate
    };

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
    let mut guard = state.lock().unwrap();

    let handler = match guard.as_mut() {
        Some(h) => h,
        None => return "Server not initialized.".to_string(),
    };

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

#[tauri::command]
pub fn create_pairing_invite(
    app_handle: tauri::AppHandle,
    state: tauri::State<'_, SharedCommunicator>,
) -> Result<PairingInvite, String> {
    let name = load_desktop_name(&app_handle)?;
    let guard = state.lock().map_err(|_| "Server state unavailable")?;
    let handler = guard.as_ref().ok_or("Start the server before pairing")?;
    let hosts: Vec<_> = local_ip_address::list_afinet_netifas()
        .map_err(|_| "Network unavailable")?
        .into_iter()
        .filter_map(|(_, ip)| match ip {
            std::net::IpAddr::V4(ip) if !ip.is_loopback() && !ip.is_unspecified() => {
                Some(ip.to_string())
            }
            _ => None,
        })
        .take(8)
        .collect();
    if hosts.is_empty() {
        return Err("Connect the computer to your local network".into());
    }
    handler.create_pairing_invite(hosts, TCP_PORT, name)
}

#[tauri::command]
pub fn cancel_pairing_invite(
    invite_id: String,
    state: tauri::State<'_, SharedCommunicator>,
) -> Result<(), String> {
    let guard = state.lock().map_err(|_| "Server state unavailable")?;
    if let Some(handler) = guard.as_ref() {
        handler.cancel_pairing_invite(&invite_id);
    }
    Ok(())
}

#[tauri::command]
pub fn list_paired_devices(
    state: tauri::State<'_, SharedCommunicator>,
) -> Result<Vec<TrustedDevice>, String> {
    let guard = state.lock().map_err(|_| "Server state unavailable")?;
    Ok(guard
        .as_ref()
        .ok_or("Server not initialized")?
        .trusted_devices())
}

#[tauri::command]
pub fn list_connected_clients(
    state: tauri::State<'_, SharedCommunicator>,
) -> Result<Vec<server::ClientInfo>, String> {
    let guard = state.lock().map_err(|_| "Server state unavailable")?;
    Ok(guard
        .as_ref()
        .ok_or("Server not initialized")?
        .connected_clients())
}

#[tauri::command]
pub fn revoke_phone(
    device_id: String,
    state: tauri::State<'_, SharedCommunicator>,
) -> Result<(), String> {
    let guard = state.lock().map_err(|_| "Server state unavailable")?;
    guard
        .as_ref()
        .ok_or("Server not initialized")?
        .revoke_phone(&device_id)
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
