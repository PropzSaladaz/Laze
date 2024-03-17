use serde::{Deserialize, Serialize};

use crate::{ffi::FFIDevice, messages::Input};

pub struct Device {
   device: FFIDevice,
}

pub trait InputHandler: Send + Sync {
    fn handle(&self, bytes: &[u8]) {
        // TODO - Sometimes we read 2 or 3 inputs all joined together as a string
        // from the socket stream, thus throwing an error.
        // We are ignoring those, working only if we receive 1 at a time.
        if let Ok(input) = serde_json::from_slice(bytes) {
            self.handle_input(&input);
        }
        
    } 
    fn handle_input(&self, input: &Input);
}

impl InputHandler for Device {
    fn handle_input(&self, input: &Input) {
        println!("Received: {:?}", input);
        self.device.pos_move(input.move_x, input.move_y);
        self.device.press_key(input.button);
    }
}

impl Device {
    pub fn new(
        dev_file: &'static str, 
        dev_name: &'static str, 
        move_x_sense: u32, 
        move_y_sense: u32, 
        move_delay: u32
    ) -> Self {
        Device {
            device: FFIDevice::new(
                dev_file, 
                dev_name, 
                move_x_sense, 
                move_y_sense, 
                move_delay
            )
        }
    }
}