use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
#[serde(tag = "action", content = "data")]
pub enum Action {
    KeyPress(Key),
    Text(String),
    // key holding status
    // SetHold,
    // SetRelease,
    // mouse sensitivity
    SensitivityUp,
    SensitivityDown,
    // scroll delta
    Scroll(i32),
    // x & y mouse movement deltas
    MouseMove(Coordinates),
    MouseButton(Button),
    Disconnect,
    // Other actions can be added here
}


#[derive(Serialize, Deserialize, Eq, PartialEq, Hash)]
pub struct Coordinates {
    pub x: i32,
    pub y: i32,
}


#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub enum Key {

    Backspace,

    VolumeMute,
    VolumeDown,
    VolumeUp,
    Pause,
    ScrollUp,
    ScrollDown,
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash, Debug)]
pub enum Button {
    Left,
}


#[cfg(test)]
mod tests {
    use crate::actions::{Action, Coordinates, Key};


    #[test]
    fn serde_action() {
        // // set hold
        // let json = r#"{"action": "SetHold", "data": null }"#;
        // let action: Action = serde_json::from_str(json).unwrap();
        // matches!(action, Action::SetHold);

        // // set release
        // let json = r#"{"action": "SetRelease", "data": null }"#;
        // let action: Action = serde_json::from_str(json).unwrap();
        // matches!(action, Action::SetRelease);

        // sensitivity up
        let json = r#"{"action": "SensitivityUp", "data": null }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::SensitivityUp);

        // sensitivity down
        let json = r#"{"action": "SensitivityDown", "data": null }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::SensitivityDown);

        // disconnected
        let json = r#"{"action": "Disconnect", "data": null }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::Disconnect);

        // disconnected
        let json = r#"{"action": "KeyPress", "data": "Backspace" }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::KeyPress(Key::Backspace));

        // scroll
        let json = r#"{"action": "Scroll", "data": 1 }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::Scroll(1));

        // mouse move
        let json = r#"{"action": "MouseMove", "data": { "x": 1, "y": -2} }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::MouseMove(Coordinates {x: 1, y: -2}));


    }
}