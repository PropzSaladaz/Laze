use enigo::{Axis, Coordinate, Direction, Enigo, Keyboard, Mouse, Settings};
use std::error::Error;
use std::process::Command;

use crate::{
    actions::{Action, TerminalCommand},
    keybinds::KeyBindings,
    logger::Loggable,
    mouse_buttons::HeldMouseButtons,
    security::SessionId,
    server::application::{Application, ConnectionStatus},
};

pub struct MobileController {
    enigo: Enigo,
    key_bindings: KeyBindings,
    held_buttons: HeldMouseButtons,
}

// now device can be shared across threads
unsafe impl Send for MobileController {}
unsafe impl Sync for MobileController {}

impl MobileController {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        Ok(MobileController {
            enigo: Enigo::new(&Settings::default())?,
            key_bindings: KeyBindings::new(),
            held_buttons: HeldMouseButtons::default(),
        })
    }

    pub fn mouse_move_relative(&mut self, move_x: i8, move_y: i8) {
        self.enigo
            .move_mouse(move_x as i32, move_y as i32, Coordinate::Rel)
            .unwrap();
    }

    pub fn scroll(&mut self, wheel_delta: i8) {
        self.enigo
            .scroll(wheel_delta as i32, Axis::Vertical)
            .unwrap();
    }

    #[allow(dead_code)]
    pub fn press_key(&mut self, key: enigo::Key) {
        self.enigo.key(key, Direction::Click).unwrap();
    }

    pub fn press_key_combo(&mut self, keys: &[enigo::Key]) {
        for key in keys {
            self.enigo.key(*key, Direction::Press).unwrap();
        }
        for key in keys.iter().rev() {
            self.enigo.key(*key, Direction::Release).unwrap();
        }
    }

    fn mouse_button(&mut self, button: enigo::Button) {
        // A click from another phone must not release an ongoing drag.
        if !self.held_buttons.is_held(button) {
            self.enigo.button(button, Direction::Click).unwrap();
        }
    }

    fn mouse_button_down(&mut self, session: Option<SessionId>, button: enigo::Button) -> bool {
        if self.held_buttons.press(session, button) {
            if let Err(error) = self.enigo.button(button, Direction::Press) {
                self.log_warn(&format!("Unable to press mouse button: {error}"));
                return false;
            }
        }
        true
    }

    fn mouse_button_up(&mut self, session: Option<SessionId>, button: enigo::Button) -> bool {
        if self.held_buttons.release(session, button) {
            if let Err(error) = self.enigo.button(button, Direction::Release) {
                // Keep ownership so disconnect cleanup can attempt the release again.
                self.held_buttons.press(session, button);
                self.log_warn(&format!("Unable to release mouse button: {error}"));
                return false;
            }
        }
        true
    }

    fn type_string(&mut self, text: &str) {
        self.enigo.text(text).unwrap();
    }

    fn handle_input(&mut self, session: Option<SessionId>, action: Action) -> ConnectionStatus {
        match action {
            Action::KeyPress(key) => {
                if let Some(key_combo) = self.key_bindings.translate_to_os_key(&key) {
                    self.press_key_combo(&key_combo);
                } else {
                    self.log_warn(&format!("Key: {:?} is not mapped for current OS", key));
                }
            }

            Action::MouseClick(button) => {
                if let Some(button) = self.key_bindings.translate_to_os_button(&button) {
                    self.mouse_button(button);
                } else {
                    self.log_warn(&format!("Key: {:?} is not mapped for current OS", button));
                }
            }

            Action::MouseDown(button) => {
                if let Some(button) = self.key_bindings.translate_to_os_button(&button) {
                    if !self.mouse_button_down(session, button) {
                        return ConnectionStatus::Disconnected;
                    }
                }
            }

            Action::MouseUp(button) => {
                if let Some(button) = self.key_bindings.translate_to_os_button(&button) {
                    if !self.mouse_button_up(session, button) {
                        return ConnectionStatus::Disconnected;
                    }
                }
            }

            Action::Text(text) => self.type_string(&text.to_string()),

            Action::Scroll(delta) => self.scroll(delta),

            Action::MouseMove(coordinates) => {
                self.mouse_move_relative(coordinates.x, coordinates.y)
            }

            Action::Disconnect => return ConnectionStatus::Disconnected,

            Action::Shutdown => shutdown_computer(),

            Action::TerminalCommand(TerminalCommand { command }) => run_command(&command),
        };

        ConnectionStatus::Connected
    }
    fn dispatch_input(&mut self, session: Option<SessionId>, input: &[u8]) -> ConnectionStatus {
        let actions = match Action::decode_batch(input) {
            Ok(actions) => actions,
            Err(_) => return ConnectionStatus::Disconnected,
        };
        for action in actions {
            self.log_debug(&format!("Action received: {:?}", action));
            match self.handle_input(session, action) {
                ConnectionStatus::Disconnected => return ConnectionStatus::Disconnected,
                _ => (),
            };
        }
        ConnectionStatus::Connected
    }
}

impl Application for MobileController {
    fn dispatch_to_device(&mut self, input: &[u8]) -> ConnectionStatus {
        self.dispatch_input(None, input)
    }

    fn dispatch_session_input(&mut self, session: &SessionId, input: &[u8]) -> ConnectionStatus {
        self.dispatch_input(Some(*session), input)
    }

    fn release_session_input(&mut self, session: &SessionId) {
        for button in self.held_buttons.release_session(Some(*session)) {
            if let Err(error) = self.enigo.button(button, Direction::Release) {
                self.log_warn(&format!(
                    "Unable to release mouse button after disconnect: {error}"
                ));
            }
        }
    }
}

// Machine Shutdown OS dependent
#[cfg(target_os = "windows")]
fn shutdown_computer() {
    Command::new("shutdown")
        .args(&["/s", "/f", "/t", "0"])
        .spawn()
        .expect("Failed to execute shutdown command");
}

#[cfg(target_os = "linux")]
fn shutdown_computer() {
    Command::new("shutdown")
        .arg("now")
        .spawn()
        .expect("Failed to execute shutdown command");
}

#[cfg(target_os = "macos")]
fn shutdown_computer() {
    Command::new("shutdown")
        .args(&["-h", "now"])
        .spawn()
        .expect("Failed to execute shutdown command");
}

// OS-dependent terminal command issuer
#[cfg(target_os = "windows")]
fn run_command(command: &str) {
    Command::new("cmd")
        .args(&["/C", command])
        .spawn()
        .expect("Failed to execute command on Windows");
}

#[cfg(not(target_os = "windows"))]
fn run_command(command: &str) {
    Command::new("sh")
        .arg("-c")
        .arg(command)
        .spawn()
        .expect("Failed to execute command");
}

mod tests {

    #![allow(unused_imports)]
    use super::run_command;
    use super::MobileController;
    use crate::server::application::Application;

    #[test]
    #[ignore] // Requires X11 DISPLAY environment
    fn parse_several_commands_at_once() {
        //                  | key backspace  | scroll | mouse move            |
        let commands: &[u8] = &[0u8, 0u8, 2u8, 2u8, 3u8, 2u8, (-8i8) as u8];
        let mut app = MobileController::new().unwrap();
        app.dispatch_to_device(commands);
    }

    #[test]
    fn open_firefox_command() {
        // This test just checks that the function doesn't panic when called
        // In a headless environment, it will fail to open firefox but that's ok
        run_command("echo test");
    }
}
