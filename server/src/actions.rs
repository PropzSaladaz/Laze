use core::str;

use byteorder::LittleEndian;
use serde::{Serialize, Deserialize};


/// Action codification
/// 
/// Actions are encoded into bit arrays.
/// The fisrt bit identifies the action. The next bits identify the values of the action.


#[derive(Serialize, Deserialize)]
#[serde(tag = "action", content = "data")]
pub enum Action {
    KeyPress(Key),                      // 0
    Text(char),                         // 1
    // key holding status
    // SetHold,
    // SetRelease,
    // scroll delta
    Scroll(i8),                         // 2
    // x & y mouse movement deltas
    MouseMove(Coordinates),             // 3
    MouseButton(Button),                // 4
    // mouse sensitivity
    SensitivityDown,                    // 5
    SensitivityUp,                      // 6
    Disconnect,                         // 7
    Shutdown,                           // 8
    TerminalCommand(TerminalCommand),// 9
    // Other actions can be added here
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub struct TerminalCommand {
    pub command: String,
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub enum Key {
    Backspace = 0,
    VolumeMute = 1,
    VolumeDown = 2,
    VolumeUp = 3,
    Pause = 4,
    Enter = 5,
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash)]
pub struct Coordinates {
    pub x: i8,
    pub y: i8,
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
#[repr(u8)]
pub enum Button {
    Left = 0,
}


impl Action {
    pub fn decode(encoded: &mut &[u8]) -> Self {
        let action_type = encoded[0];
        *encoded = &encoded[1..];
        match action_type {
            0 => Self::KeyPress(Key::from_bytes(encoded)),
            1 => {
                let char = encoded[0] as char;
                *encoded = &encoded[1..];
                Self::Text(char)
            },
            2 => {
                let scroll_val = encoded[0] as i8;
                *encoded = &encoded[1..];
                Self::Scroll(scroll_val)
            },
            3 => Self::MouseMove(Coordinates::from_bytes(encoded)),
            4 => Self::MouseButton(Button::from_bytes(encoded)),
            5 => Self::SensitivityDown,
            6 => Self::SensitivityUp,
            7 => Self::Disconnect,
            8 => Self::Shutdown,
            9 => Self::TerminalCommand(TerminalCommand::from_bytes(encoded)),
            _ => unreachable!("Action type not recognized!"),
        }

    }
}


impl Coordinates {
    fn from_bytes(bytes: &mut &[u8]) -> Self {
        let coords = Coordinates { 
            x: bytes[0] as i8, 
            y: bytes[1] as i8 
        };
        // after consuming the bytes, move forward
        *bytes = &bytes[2..];

        coords
    }
}

impl Key {
    fn from_bytes(bytes: &mut &[u8]) -> Self {
        let btn = bytes[0];
        // after consuming the bytes, move forward
        *bytes = &bytes[1..];
        match btn {
            0 => Key::Backspace,
            1 => Key::VolumeMute,
            2 => Key::VolumeDown,
            3 => Key::VolumeUp,
            4 => Key::Pause,
            5 => Key::Enter,
            _ => unreachable!("Key type not supported!")
        }
    }
}


impl Button {
    fn from_bytes(bytes: &mut &[u8]) -> Self {
        let btn = bytes[0];
        // after consuming the bytes, move forward
        *bytes = &bytes[1..];
        match btn {
            0 => Button::Left,
            _ => unreachable!("Unsupported button type")
        }
    }
}

impl TerminalCommand {
    fn from_bytes(bytes: &mut &[u8]) -> Self {
        let command_size: usize = bytes[0] as usize;
        let command = match str::from_utf8(&bytes[1_usize..command_size+1]) {
            Ok(command) => TerminalCommand { command: command.to_owned() },
            Err(e) => panic!("Invalid UTF-8 sequence: {}", e),
        };
        // after consuming the bytes, move forward
        *bytes = &bytes[(command_size + 1)..];
        command
    }
}


#[cfg(test)]
mod tests {

    use crate::actions::{Action, Button, Coordinates, Key, TerminalCommand};

    #[test]
    fn decode_key() {
        let mut key_backspace: &[u8] = &[0u8, 0u8];
        let mut key_vol_mute: &[u8] = &[0u8, 1u8];
        let mut key_vol_down: &[u8] = &[0u8, 2u8];
        let mut key_vol_up: &[u8] = &[0u8, 3u8];
        let mut key_pause: &[u8] = &[0u8, 4u8];
        let mut key_enter: &[u8] = &[0u8, 5u8];

        matches!(Action::decode(&mut key_backspace),    Action::KeyPress(Key::Backspace));
        matches!(Action::decode(&mut key_vol_mute),     Action::KeyPress(Key::VolumeMute));
        matches!(Action::decode(&mut key_vol_down),     Action::KeyPress(Key::VolumeDown));
        matches!(Action::decode(&mut key_vol_up),       Action::KeyPress(Key::VolumeUp));
        matches!(Action::decode(&mut key_pause),        Action::KeyPress(Key::Pause));
        matches!(Action::decode(&mut key_enter),  Action::KeyPress(Key::Enter));
    }

    #[test]
    fn decode_text() {
        let mut text_a_lower: &[u8] = &[1u8, 'a' as u8];
        let mut text_v_upper: &[u8] = &[1u8, 'V' as u8];

        matches!(Action::decode(&mut text_a_lower),    Action::Text('a'));
        matches!(Action::decode(&mut text_v_upper),    Action::Text('V'));

    }


    #[test]
    fn decode_scroll() {
        let mut scroll1: &[u8] = &[2u8, 2u8];
        let mut scroll2: &[u8] = &[2u8, (-5i8) as u8];

        matches!(Action::decode(&mut scroll1),    Action::Scroll(2));
        matches!(Action::decode(&mut scroll2),    Action::Scroll(-5));

    }

    #[test]
    fn mouse_move() {
        let mut mouse_move: &[u8] = &[3u8, 2u8, (-8i8) as u8];

        matches!(Action::decode(&mut mouse_move),    Action::MouseMove(Coordinates { x: 2, y: -8 }));
    }

    #[test]
    fn mouse_button() {
        let mut mouse_btn: &[u8] = &[4u8, 0u8];
        matches!(Action::decode(&mut mouse_btn),    Action::MouseButton(Button::Left));
    }

    #[test]
    fn mouse_sensitivity() {
        let mut sense_down: &[u8] = &[5u8];
        let mut sense_up: &[u8] = &[6u8];

        matches!(Action::decode(&mut sense_down),    Action::SensitivityDown);
        matches!(Action::decode(&mut sense_up),    Action::SensitivityUp);
    }

    #[test]
    fn disconnect() {
        let mut disconnect: &[u8] = &[7u8];
        matches!(Action::decode(&mut disconnect),    Action::Disconnect);
    }

    #[test]
    fn terminal_command_open_firefox() {
        let mut firefox_command: Vec<u8> = vec![9u8];
        let utf8_bytes = "firefox".as_bytes();
        firefox_command.push(utf8_bytes.len() as u8);
        firefox_command.append(&mut utf8_bytes.to_owned());
        let mut bytes = &mut firefox_command.as_slice();

    // First, match the Action enum to ensure it's a TerminalCommand
    if let Action::TerminalCommand(TerminalCommand { command }) = Action::decode(&mut bytes) {
        // Then check if the command matches "firefox"
        assert_eq!(command, "firefox");
        assert_eq!(bytes.len(), 0);
    } else {
        panic!("Expected TerminalCommand but got something else.");
    }

    }
}