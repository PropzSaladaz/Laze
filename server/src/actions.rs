use core::str;

use serde::{Serialize, Deserialize};
use num_enum::TryFromPrimitive;


/// This macro generates 2 separate enums:
/// 
/// `ActionType` - Used to convert u8 into an ActionType
/// `Action` - will hold the actual data
/// 
/// This is needed when parsing the actions from bytes into in-memory structures.
/// The process goes from bytes (u8) -> ActionType -> Action
macro_rules! define_actions {
    (
        $(
            $variant:ident $(($data:ty))? = $id:expr
        ),* $(,)?
    ) => {

        #[repr(u8)]
        #[derive(Debug, Clone, Copy, TryFromPrimitive)]
        pub enum ActionType {
            $(
                $variant = $id,
            )*
        }

        impl ActionType {
            pub fn from_u8(action_type: u8) -> Option<Self> {
                match action_type {
                    $(
                        $id => Some(Self::$variant),
                    )*
                    _ => None,
                }
            }
        }

        #[derive(Serialize, Deserialize, Debug)]
        pub enum Action {
            $(
                $variant $(($data))?,
            )*
        }
    };
}

define_actions!(
    KeyPress(Key) = 0,
    Text(char) = 1,
    Scroll(i8) = 2,
    MouseMove(DeltaCoordinates) = 3,
    MouseButton(Button) = 4,
    SensitivityDown = 5,
    SensitivityUp = 6,
    Disconnect = 7,
    Shutdown = 8,
    TerminalCommand(TerminalCommand) = 9,
);

/// Action struct is defined by the define_macros! macro
/// Here we only define its decoding implementation
impl Action {
    pub fn decode(encoded: &mut &[u8]) -> Self {
        let action_type = ActionType::from_u8(encoded[0]);
        *encoded = &encoded[1..];
        match action_type {
            Some(ActionType::KeyPress) => Self::KeyPress(DeserializableAction::from_bytes(encoded)),
            Some(ActionType::Text)     => {
                let char = encoded[0] as char;
                *encoded = &encoded[1..];
                Self::Text(char)
            },
            Some(ActionType::Scroll)   => {
                let scroll_val = encoded[0] as i8;
                *encoded = &encoded[1..];
                Self::Scroll(scroll_val)
            },
            Some(ActionType::MouseMove)       => Self::MouseMove(DeserializableAction::from_bytes(encoded)),
            Some(ActionType::MouseButton)     => Self::MouseButton(DeserializableAction::from_bytes(encoded)),
            Some(ActionType::SensitivityDown) => Self::SensitivityDown,
            Some(ActionType::SensitivityUp)   => Self::SensitivityUp,
            Some(ActionType::Disconnect)      => Self::Disconnect,
            Some(ActionType::Shutdown)        => Self::Shutdown,
            Some(ActionType::TerminalCommand) => Self::TerminalCommand(DeserializableAction::from_bytes(encoded)),
            None => unreachable!("Action type not recognized!"),
        }

    }
}

/// Any data associated to any action must implement this trait.
/// Defines a single method to build the structure holding the data from bytes
trait DeserializableAction {
    fn from_bytes(bytes: &mut &[u8]) -> Self;
}

/// Stores any input from user that may represent
/// a command to run in a terminal shell at the server
#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub struct TerminalCommand {
    pub command: String,
}

impl DeserializableAction for TerminalCommand {
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


/// Represents keys from keyboard
#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub enum Key {
    Backspace = 0,
    VolumeMute = 1,
    VolumeDown = 2,
    VolumeUp = 3,
    Pause = 4,
    Play = 5,
    Enter = 6,
    Fullscreen = 7,
    CloseTab = 8,
    NextTab = 9,
    PreviousTab = 10,
}

impl DeserializableAction for Key {
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
            5 => Key::Play,
            6 => Key::Enter,
            7 => Key::Fullscreen,
            8 => Key::CloseTab,
            9 => Key::NextTab,
            10 => Key::PreviousTab,
            _ => unreachable!("Key type not supported!")
        }
    }
}

/// Represent the mouse movement delta -> how much the mouse moved in each 
/// axis comparing to last frame
#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub struct DeltaCoordinates {
    pub x: i8,
    pub y: i8,
}

impl DeserializableAction for DeltaCoordinates {
    fn from_bytes(bytes: &mut &[u8]) -> Self {
        let coords = DeltaCoordinates { 
            x: bytes[0] as i8, 
            y: bytes[1] as i8 
        };
        // after consuming the bytes, move forward
        *bytes = &bytes[2..];

        coords
    }
}


#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
#[repr(u8)]
pub enum Button {
    Left = 0,
}


impl DeserializableAction for Button {
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



#[cfg(test)]
mod tests {

    use crate::actions::{Action, Button, DeltaCoordinates, Key, TerminalCommand};

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

        matches!(Action::decode(&mut mouse_move),    Action::MouseMove(DeltaCoordinates { x: 2, y: -8 }));
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
        let utf8_bytes: &[u8] = "firefox".as_bytes();
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