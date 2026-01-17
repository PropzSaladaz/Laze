pub mod commands;

use std::sync::{Arc, Mutex};

use tauri::{
    menu::{Menu, MenuItem},
    tray::{TrayIconBuilder, TrayIconEvent},
    Manager, RunEvent, WindowEvent,
};
use tauri_plugin_autostart::MacosLauncher;

use commands::SharedCommunicator;

pub const TCP_PORT: u16 = 7878;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let app = tauri::Builder::default()
        .setup(|app| {
            // load environment variables from .env file
            // includes log level
            dotenv::dotenv().ok();

            // Initialize shared communicator as None - will be populated when server starts
            let shared_comm: SharedCommunicator = Arc::new(Mutex::new(None));
            app.manage(shared_comm);

            // System Tray Setup
            let quit_i = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            let show_i = MenuItem::with_id(app, "show", "Show", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show_i, &quit_i])?;

            let _tray = TrayIconBuilder::with_id("tray")
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_menu_event(|app, event| match event.id.as_ref() {
                    "quit" => {
                        app.exit(0);
                    }
                    "show" => {
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                    _ => {}
                })
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click { .. } = event {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                })
                .build(app)?;

            Ok(())
        })
        // set safe, platform-specific defaults if we need to open external things such
        // as filesystem, or browser.
        .plugin(tauri_plugin_opener::init())
        // autostart plugin (for all OSes) & specific setup for MacOS
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            Some(vec![]),
        ))
        .invoke_handler(tauri::generate_handler![
            commands::init_server,
            commands::start_server,
            commands::stop_server,
            commands::remove_client,
        ])
        .build(tauri::generate_context!())
        .expect("error while building tauri application");

    app.run(|app_handle, event| match event {
        RunEvent::ExitRequested { .. } => {
            // Terminate the server when app is closing (really exiting)
            if let Some(state) = app_handle.try_state::<SharedCommunicator>() {
                println!("App exiting, terminating server...");
                commands::terminate_server(&state);
            }
        }

        // On window close - prevent the app from exiting. Minimize instead.
        RunEvent::WindowEvent {
            label,
            event: WindowEvent::CloseRequested { api, .. },
            ..
        } => {
            if label == "main" {
                if let Some(window) = app_handle.get_webview_window(&label) {
                    let _ = window.hide();
                    api.prevent_close();
                }
            }
        }
        _ => {}
    });
}
