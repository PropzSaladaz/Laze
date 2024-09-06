use std::{io::BufReader, str::from_utf8};

use regex::Regex;
use serde_json::Deserializer;

use crate::{actions::{Action, KeyboardAction}, ffi::*, keybinds::KeyBindings, server::ConnectionStatus};

pub trait InputHandler: Send + Sync {
    /// Converts the received byte data into jsons, and then to the Action type struct, and
    /// invokes the 'handle_input' method with the parsed Action struct
    fn handle(&mut self, bytes: &[u8]) -> ConnectionStatus {
        let reader = BufReader::new(bytes);
        let mut deserializer = Deserializer::from_reader(reader).into_iter::<Action>();

        // Sometimes input from socket comes with several inputs at the same time.
        // we need to parse each seperately
        while let Some(action) = deserializer.next() {
            match action {
                Ok(action) => match self.handle_input(action) {
                    ConnectionStatus::Disconnected => return ConnectionStatus::Disconnected,
                    _ => (),
                },
                Err(e) => eprintln!("Failed to parse JSON: {}", e)
            }
        }
        ConnectionStatus::Connected
    } 
    fn handle_input(&mut self, input: Action) -> ConnectionStatus;
}


pub struct Device {
    device: FFIDevice,
    keybinds: KeyBindings,
 }

 impl Device {
    pub fn new(
        dev_file: &'static str, 
        dev_name: &'static str, 
        move_x_sense: u32, 
        move_y_sense: u32, 
        wheel_sense: u32,
        move_delay: u32
    ) -> Self {
        Device {
            device: FFIDevice::new(
                dev_file, 
                dev_name, 
                move_x_sense, 
                move_y_sense, 
                wheel_sense,
                move_delay
            ),
            keybinds: KeyBindings::new(),
        }
    }
}

impl InputHandler for Device {
    fn handle_input(&mut self, action: Action) -> ConnectionStatus {

        match action {
            // State machine -> set holding state.
            // If set to hold, all next invocations will end up in "NO_CHANGE"
            // until it is eventually RELEASEd
            Action::SetHold             => self.device.set_hold(),
            Action::SetRelease          => self.device.set_release(),
            Action::SensitivityUp       => self.device.add_sensitivity(1),
            Action::SensitivityDown     => self.device.add_sensitivity(-1),

            Action::KeyPress(key) => {
                let key_code = self.keybinds.translate_to_os_key(key).expect("Non existent key");
                self.device.press_key(key_code);
            },

            Action::Keyboard(keyboard_action) => match keyboard_action {
                KeyboardAction::SimpleCharacter(key) => {
                    let key_code = self.keybinds.translate_to_os_key(key).expect("Non existent key");
                    self.device.press_key(key_code);
                },
                KeyboardAction::ComplexCharacter(_) => {
                    todo!("Needs handling for complex characters");
                }
            },

            Action::Scroll(delta) => self.device.scroll(delta),

            Action::MouseMove((x, y)) => self.device.pos_move(x, y),

            Action::Disconnect => return ConnectionStatus::Disconnected,
        };

        ConnectionStatus::Connected
    }
}
