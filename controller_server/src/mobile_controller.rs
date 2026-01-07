use std::error::Error;
use std::process::Command;
use copypasta::ClipboardContext;
use enigo::{Axis, Coordinate, Direction, Enigo, Keyboard, Mouse, Settings};

use crate::{
    actions::{Action, TerminalCommand}, keybinds::KeyBindings, logger::Loggable, server::application::{Application, ConnectionStatus}
};

pub struct MobileController {
    enigo: Enigo,
    clipboard: ClipboardContext,
    key_bindings: KeyBindings,

    move_x_sense: u8,
    move_y_sense: u8,
    wheel_sense: u8,
    move_delay: u32,
 }

 // now device can be shared across threads
unsafe impl Send for MobileController {}
unsafe impl Sync for MobileController {}

impl MobileController {
    pub fn new(
        move_x_sense: u8, 
        move_y_sense: u8, 
        wheel_sense: u8,
        move_delay: u32
    ) -> Result<Self, Box<dyn Error>> {
        Ok(MobileController {
            enigo: Enigo::new(&Settings::default())?,
            clipboard: ClipboardContext::new().unwrap(),
            key_bindings: KeyBindings::new(),

            move_x_sense,
            move_y_sense,
            wheel_sense,
            move_delay,
        })
    }

    pub fn mouse_move_relative(&mut self, move_x: i8, move_y: i8) {
        self.enigo.move_mouse(
            self.move_x_sense as i32 * move_x as i32, 
            self.move_y_sense as i32 * move_y as i32, 
            Coordinate::Rel
        ).unwrap();
    }

    pub fn scroll(&mut self, wheel_delta: i8) {
        self.enigo.scroll(wheel_delta as i32, Axis::Vertical).unwrap();
    }

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
        self.enigo.button(button, Direction::Click).unwrap();
    }

    fn type_string(&mut self, text: &str) {
        self.enigo.text(text).unwrap();
    }

    pub fn add_sensitivity(&mut self, sensitivity_delta: i8) {
        let curr_sense = self.move_x_sense as i8; // cast for the sum as the result may be < 0
        let mut new_sense = curr_sense + sensitivity_delta;
        
        if new_sense < 1 { new_sense = 1; } // must always be at least at 1

        let new_sense = new_sense as u8;

        self.move_x_sense = new_sense;
        self.move_y_sense = new_sense;
    }

    fn handle_input(&mut self, action: Action) -> ConnectionStatus {

        match action {
            Action::SensitivityUp       => self.add_sensitivity(1),
            Action::SensitivityDown     => self.add_sensitivity(-1),

            Action::KeyPress(key) => {
                if let Some(key_combo) = self.key_bindings.translate_to_os_key(&key) {
                    self.press_key_combo(&key_combo);
                }
                else {
                    self.log_warn(&format!("Key: {:?} is not mapped for current OS", key));
                }
            },

            Action::MouseButton(button) => {
                if let Some(button) = self.key_bindings.translate_to_os_button(&button) {
                    self.mouse_button(button);
                }
                else {
                    self.log_warn(&format!("Key: {:?} is not mapped for current OS", button));
                }
            }

            Action::Text(text) => self.type_string(&text.to_string()),

            Action::Scroll(delta) => self.scroll(delta),

            Action::MouseMove(coordinates ) => self.mouse_move_relative(coordinates.x, coordinates.y),

            Action::Disconnect => return ConnectionStatus::Disconnected,

            Action::Shutdown => shutdown_computer(),

            Action::TerminalCommand(TerminalCommand { command}) => run_command(&command),
        };

        ConnectionStatus::Connected
    }
}

impl Application for MobileController {
    fn dispatch_to_device(&mut self, mut input: &[u8]) -> ConnectionStatus {
        // while there are bytes to be consumed -> consume.
        // each TCP may send buffered inputs within the same packet, thus we need to
        // check if there aren't any other commands within the bytes of the current packet
        while input.len() > 0 {
            let action = Action::decode(&mut input);
            self.log_debug(&format!("Action received: {:?}", action));
            match self.handle_input(action) {
                ConnectionStatus::Disconnected => return ConnectionStatus::Disconnected,
                _ => (),
            };
        };
        ConnectionStatus::Connected
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
        .expect("Failed to execute command on Windows");
}


mod tests {
    
    #![allow(unused_imports)]
    use crate::server::application::Application;
    use super::MobileController;
    use super::run_command;

    #[test]
    #[ignore] // Requires X11 DISPLAY environment
    fn parse_several_commands_at_once() {
        //                  | key backspace  | scroll | mouse move            | 
        let commands: &[u8] = &[0u8, 0u8, 2u8, 2u8, 3u8, 2u8, (-8i8) as u8];
        let mut app = MobileController::new(8, 8, 8, 10).unwrap();
        app.dispatch_to_device(commands);
    }

    #[test]
    fn open_firefox_command() {
        // This test just checks that the function doesn't panic when called
        // In a headless environment, it will fail to open firefox but that's ok
        run_command("echo test");
    }
}