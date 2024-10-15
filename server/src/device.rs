use std::{error::Error, io::BufReader, str::from_utf8};

use copypasta::ClipboardContext;
use enigo::{Axis, Coordinate, Direction, Enigo, Keyboard, Mouse, Settings};
use serde_json::Deserializer;

use crate::{actions::{Action, Key}, keybinds::KeyBindings, server::ConnectionStatus};

pub trait InputHandler: Send + Sync {
    /// Converts the received byte data into jsons, and then to the Action type struct, and
    /// invokes the 'handle_input' method with the parsed Action struct
    fn handle(&mut self, bytes: &[u8]) -> ConnectionStatus {
        // Sometimes input from socket comes with several inputs at the same time.
        // we need to parse each seperately
        // TODO - add a terminator byte to separate commands
        // while let Some(action) = deserializer.next() {
            // match Action::decode(bytes) {
            //     Ok(action) => match self.handle_input(action) {
            //         ConnectionStatus::Disconnected => return ConnectionStatus::Disconnected,
            //         _ => (),
            //     },
            //     Err(e) => eprintln!("Failed to decode action: {}", e)
            // }
        // }
        let action = Action::decode(bytes);
        match self.handle_input(action) {
            ConnectionStatus::Disconnected => return ConnectionStatus::Disconnected,
            _ => (),
        };
        ConnectionStatus::Connected
    } 
    fn handle_input(&mut self, input: Action) -> ConnectionStatus;
}


pub struct Device {
    enigo: Enigo,
    clipboard: ClipboardContext,
    key_bindings: KeyBindings,

    move_x_sense: u8,
    move_y_sense: u8,
    wheel_sense: u8,
    move_delay: u32,
 }

 // now device can be shared across threads
unsafe impl Send for Device {}
unsafe impl Sync for Device {}

 impl Device {
    pub fn new(
        move_x_sense: u8, 
        move_y_sense: u8, 
        wheel_sense: u8,
        move_delay: u32
    ) -> Result<Self, Box<dyn Error>> {
        Ok(Device {
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
}

impl InputHandler for Device {
    fn handle_input(&mut self, action: Action) -> ConnectionStatus {

        match action {
            // State machine -> set holding state.
            // If set to hold, all next invocations will end up in "NO_CHANGE"
            // until it is eventually RELEASEd
            Action::SensitivityUp       => self.add_sensitivity(1),
            Action::SensitivityDown     => self.add_sensitivity(-1),

            Action::KeyPress(key) => {
                if let Some(key_code) = self.key_bindings.translate_to_os_key(&key) {
                    self.press_key(key_code);
                }
                else {
                    println!("Key: {:?} is not mapped for current OS", key);
                }
            },

            Action::MouseButton(button) => {
                if let Some(button) = self.key_bindings.translate_to_os_button(&button) {
                    self.mouse_button(button);
                }
                else {
                    println!("Key: {:?} is not mapped for current OS", button);
                }
            }

            Action::Text(text) => self.type_string(&text.to_string()),

            Action::Scroll(delta) => self.scroll(delta),

            Action::MouseMove(coordinates ) => self.mouse_move_relative(coordinates.x, coordinates.y),

            Action::Disconnect => return ConnectionStatus::Disconnected,
        };

        ConnectionStatus::Connected
    }
}
