use core::ffi::{c_char, c_int, c_uint};
use std::ffi::{c_uchar, CString};

use super::keybinds::*;

const KEY_TAP:  u32 = 1;
const KEY_HOLD: u32 = 0;

extern "C" {
    fn set_device(dev: &FFIDevice) -> c_int;

    fn device_move(dev: &FFIDevice, move_x: c_int, move_y: c_int);

    fn press_key(dev: &FFIDevice, key_code: c_uint, key_tap: c_uint);

    fn destroy_device(dev: &FFIDevice);
}

/// Represents the virtual device as a C struct to be sent
/// when calling C Foreign Function Interface (FFI)
#[repr(C)]
pub struct FFIDevice {
    dev_file: *const c_char,
    dev_name: *const c_char,
    fd: c_int,
    // mouse
    move_x_sense: c_uint,
    move_y_sense: c_uint,
    move_delay: c_uint,
    // keyboard
    key_press_status: c_uchar, // set when dragging/maintaining key pressed
}

unsafe impl Send for FFIDevice {}
unsafe impl Sync for FFIDevice {}

impl FFIDevice {
    pub fn new(
        dev_file: &'static str, 
        dev_name: &'static str, 
        move_x_sense: u32, 
        move_y_sense: u32, 
        move_delay: u32
    ) -> Self {
        let dev_file = CString::new(dev_file).unwrap();
        let dev_name = CString::new(dev_name).unwrap();

        let dev = FFIDevice {
            dev_file: dev_file.as_ptr(),
            dev_name: dev_name.as_ptr(),
            fd: -1,
            move_x_sense,
            move_y_sense,
            move_delay,
            key_press_status: 0,
        };
        unsafe { 
            let i = set_device(&dev);
            if i < 0 {
                panic!("Device could not be created!"); 
            }
        }
        dev
    }

    fn default() -> Self {
        FFIDevice::new("/dev/uinput", "default", 5, 5, 15000)
    }

    pub fn pos_move(&self, move_x: i32, move_y: i32) {
        unsafe {  device_move(&self, move_x, move_y) }
    }

    pub fn press_key(&self, key_code: u32) {
        unsafe { press_key(&self, key_code, KEY_TAP) }
    }

}

impl Drop for FFIDevice {
    fn drop(&mut self) {
        unsafe { destroy_device(self) }
    }
}

#[cfg(test)]
mod tests {
    use std::{io, thread};
    use std::time::Duration;
    use crate::keybinds::*;

    use super::FFIDevice;

    /// Auxiliary function to test keyboard input
    fn keyboard_test<F>(target: &str, key_presses: F)
    where
        F: FnOnce(&FFIDevice) + Send + 'static
    {
        let t = thread::spawn(move || {
            let dev = FFIDevice::default();
            thread::sleep(Duration::from_secs(1));
            key_presses(&dev);

            dev.press_key(KEY_ENTER);
        });

        let mut input = String::new();
        io::stdin().read_line(&mut input).unwrap();

        assert_eq!(
            input, 
            format!("{}\n", target) // include enter
        );

        t.join().unwrap();
    }



    #[test]
    fn device_move() {
        let mut dev = FFIDevice::default();
        for _ in 0..50 {
            dev.pos_move(3, 3);
        }

        dev.move_delay = 100000;
        for _ in 0..50 {
            dev.pos_move(-3, -3);
        }
    }

    #[test]
    fn numbers() {
        keyboard_test( 
            "1234567890",
            |dev| {
                // 1..0
                for key in 2..12 {
                    dev.press_key(key);
                }
            }
        );
    }

    #[test]
    fn lowercase_letters() {
        keyboard_test( 
            "qwertyuiopasdfghjklzxcvbnm",
            |dev| {          
                // q...p
                for key in 16..26 {
                    dev.press_key(key);
                }
        
                // a...l
                for key in 30..39 {
                    dev.press_key(key);
                }
        
        
                // z...m
                for key in 44..51 {
                    dev.press_key(key);
                }
            }
        );
    }



    #[test]
    fn uppercase_letters() {
        keyboard_test( 
            "QWERTYUIOPASDFGHJKLZXCVBNM",
            |dev| {   
                dev.press_key(KEY_CAPSLOCK);

                // q...p
                for key in 16..26 {
                    dev.press_key(key);
                }
        
                // a...l
                for key in 30..39 {
                    dev.press_key(key);
                }
        
        
                // z...m
                for key in 44..51 {
                    dev.press_key(key);
                }

                dev.press_key(KEY_CAPSLOCK);
            }
        );
    }


}