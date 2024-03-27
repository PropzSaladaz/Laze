use std::str::from_utf8;

use regex::Regex;

use crate::{ffi::*, messages::Input, server::ConnectionStatus};

const DISCONNECT: u8 = 1;

pub struct Device {
   device: FFIDevice,
}

pub trait InputHandler: Send + Sync {
    fn handle(&mut self, bytes: &[u8]) -> ConnectionStatus {
        let pattern = r#"\{[^}]+\}"#;
        let re = Regex::new(pattern).unwrap();
        let json = from_utf8(bytes).unwrap();
        
        // Sometimes input from socket comes with several inputs at the same time.
        // we need to parse each seperately
        for mat in re.find_iter(json) {
            match self.handle_input(&serde_json::from_str(mat.as_str()).unwrap()) {
                ConnectionStatus::Disconnected => return ConnectionStatus::Disconnected,
                _ => (),
            }
        }
        println!("Input: {}", json);
        ConnectionStatus::Connected
    } 
    fn handle_input(&mut self, input: &Input) -> ConnectionStatus;
}

impl InputHandler for Device {
    fn handle_input(&mut self, input: &Input) -> ConnectionStatus {

        // State machine -> set holding state.
        // If set to hold, all next invocations will end up in "NO_CHANGE"
        // until it is eventually RELEASEd
        match input.key_press_status {
            HOLD => self.device.set_hold(),
            RELEASE => self.device.set_release(),
            NO_CHANGE => (),
            _ => ()
        }

        // handle sensitivity change
        if input.sensitivity_delta != 0 {
            self.device.add_sensitivity(input.sensitivity_delta);
        }

        // scroll
        if input.wheel_delta != 0 {
            self.device.scroll(input.wheel_delta);
        }

        // Handle mouse movement
        self.device.pos_move(input.move_x, input.move_y);

        // handle key pressed
        if input.button != NO_BUTTON_PRESSED { // Only press key if key is being pressed
            self.device.press_key(input.button as u32);
        }

        match input.con_status {
            DISCONNECT => ConnectionStatus::Disconnected,
            _          => ConnectionStatus::Connected
        }
    }
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
            )
        }
    }
}