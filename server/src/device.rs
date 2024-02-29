use serde::{Deserialize, Serialize};

use crate::ffi::FFIDevice;

#[derive(Serialize, Deserialize, Debug)]
pub struct Input {
    move_x: i32,
    move_y: i32,
}

pub struct Device {
   device: FFIDevice,
}

trait InputHandler {
    fn handle(&self, input: &Input);
}

impl InputHandler for Device {
    fn handle(&self, input: &Input) {
        self.device.pos_move(input.move_x, input.move_y);
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