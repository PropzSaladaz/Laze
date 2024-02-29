use core::ffi::{c_char, c_int, c_uint};
use std::ffi::CString;

#[repr(C)]
pub struct FFIDevice {
    dev_file: *const c_char,
    dev_name: *const c_char,
    fd: c_int,
    move_x_sense: c_uint,
    move_y_sense: c_uint,
    move_delay: c_uint,
}

extern "C" {
    fn set_device(dev: &FFIDevice) -> i32;

    fn device_move(dev: &FFIDevice, move_x: i32, move_y: i32);

    fn destroy_device(dev: &FFIDevice);
}

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
            move_x_sense,
            move_y_sense,
            move_delay,
            fd: -1,
        };
        unsafe { 
            let i = set_device(&dev);
            if i < 0 {
                panic!("Device could not be created!"); 
            }
        }
        dev
    }

    pub fn pos_move(&self, move_x: i32, move_y: i32) {
        unsafe {  device_move(&self, move_x, move_y) }
    }

}

impl Drop for FFIDevice {
    fn drop(&mut self) {
        unsafe { destroy_device(self) }
    }
}