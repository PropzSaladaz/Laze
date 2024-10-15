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
    // Other actions can be added here
}

impl Action {
    pub fn decode(encoded: &[u8]) -> Self {
        let action_type = encoded[0];
        let action_val = &encoded[1..];
        match action_type {
            0 => Self::KeyPress(Key::from_bytes(action_val)),
            1 => Self::Text(action_val[0] as char),
            2 => Self::Scroll(action_val[0] as i8),
            3 => Self::MouseMove(Coordinates::from_bytes(action_val)),
            4 => Self::MouseButton(Button::from_bytes(action_val)),
            5 => Self::SensitivityDown,
            6 => Self::SensitivityUp,
            7 => Self::Disconnect,
            _ => unreachable!("Action type not recognized!"),
        }

    }
}


#[derive(Serialize, Deserialize, Eq, PartialEq, Hash)]
pub struct Coordinates {
    pub x: i8,
    pub y: i8,
}

impl Coordinates {
    fn from_bytes(bytes: &[u8]) -> Self {
        Coordinates { 
            x: bytes[0] as i8, 
            y: bytes[1] as i8 
        }
    }
}


#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub enum Key {
    Backspace = 0,
    VolumeMute = 1,
    VolumeDown = 2,
    VolumeUp = 3,
    Pause = 4,
    ScrollDown = 5,
    ScrollUp = 6,
}

impl Key {
    fn from_bytes(bytes: &[u8]) -> Self {
        match bytes[0] {
            0 => Key::Backspace,
            1 => Key::VolumeMute,
            2 => Key::VolumeDown,
            3 => Key::VolumeUp,
            4 => Key::Pause,
            5 => Key::ScrollDown,
            6 => Key::ScrollUp,
            _ => unreachable!("Key type not supported!")
        }
    }
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
#[repr(u8)]
pub enum Button {
    Left = 0,
}

impl Button {
    fn from_bytes(bytes: &[u8]) -> Self {
        match bytes[0] {
            0 => Button::Left,
            _ => unreachable!("Unsupported button type")
        }
    }
}


#[cfg(test)]
mod tests {

    use crate::actions::{self, Action, Button, Coordinates, Key};

    #[test]
    fn decode_key() {
        let key_backspace = [0u8, 0u8];
        let key_vol_mute = [0u8, 1u8];
        let key_vol_down = [0u8, 2u8];
        let key_vol_up = [0u8, 3u8];
        let key_pause = [0u8, 4u8];
        let key_scroll_down = [0u8, 5u8];
        let key_scroll_up = [0u8, 6u8];

        matches!(Action::decode(&key_backspace),    Action::KeyPress(Key::Backspace));
        matches!(Action::decode(&key_vol_mute),     Action::KeyPress(Key::VolumeMute));
        matches!(Action::decode(&key_vol_down),     Action::KeyPress(Key::VolumeDown));
        matches!(Action::decode(&key_vol_up),       Action::KeyPress(Key::VolumeUp));
        matches!(Action::decode(&key_pause),        Action::KeyPress(Key::Pause));
        matches!(Action::decode(&key_scroll_down),  Action::KeyPress(Key::ScrollDown));
        matches!(Action::decode(&key_scroll_up),    Action::KeyPress(Key::ScrollUp));
    }

    #[test]
    fn decode_text() {
        let text_a_lower = [1u8, 'a' as u8];
        let text_v_upper = [1u8, 'V' as u8];

        matches!(Action::decode(&text_a_lower),    Action::Text('a'));
        matches!(Action::decode(&text_v_upper),    Action::Text('V'));

    }


    #[test]
    fn decode_scroll() {
        let scroll1 = [2u8, 2u8];
        let scroll2 = [2u8, (-5i8) as u8];

        matches!(Action::decode(&scroll1),    Action::Scroll(2));
        matches!(Action::decode(&scroll2),    Action::Scroll(-5));

    }

    #[test]
    fn mouse_move() {
        let mouse_move = [3u8, 2u8, (-8i8) as u8];

        matches!(Action::decode(&mouse_move),    Action::MouseMove(Coordinates { x: 2, y: -8 }));
    }

    #[test]
    fn mouse_button() {
        let mouse_btn = [4u8, 0u8];
        matches!(Action::decode(&mouse_btn),    Action::MouseButton(Button::Left));
    }

    #[test]
    fn mouse_sensitivity() {
        let sense_down = [5u8];
        let sense_up = [6u8];

        matches!(Action::decode(&sense_down),    Action::SensitivityDown);
        matches!(Action::decode(&sense_up),    Action::SensitivityUp);
    }

    #[test]
    fn disconnect() {
        let disconnect = [7u8];
        matches!(Action::decode(&disconnect),    Action::Disconnect);
    }
}