use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
#[serde(tag = "action", content = "data")]
pub enum Action {
    KeyPress(Key),
    Keyboard(KeyboardAction),
    // key holding status
    SetHold,
    SetRelease,
    // mouse sensitivity
    SensitivityUp,
    SensitivityDown,
    // scroll delta
    Scroll(i32),
    // x & y mouse movement deltas
    MouseMove((i32, i32)),
    Disconnect,
    // Other actions can be added here
}

#[derive(Serialize, Deserialize, Eq, PartialEq, Hash)]
pub enum Key {

    // Essencial keyboard keys
    Num1,
    Num2,
    Num3,
    Num4,
    Num5,
    Num6,
    Num7,
    Num8,
    Num9,
    Num0,
    Minus,
    Equal,
    BackSpace,
    Tab,
    Q,W,E,R,T,Y,U,I,O,P,
    LeftBrace,
    RightBrace,
    Enter,
    LeftCtrl,
    A,S,D,F,G,H,J,K,L,
    SemiColon,
    Apostrofe,
    Grave,
    LeftShift,
    BackSlash,
    Z,X,C,V,B,N,M,
    Comma,
    Dot,
    Slash,
    RightShift,
    KPAsteristk,
    LeftAlt,
    Space,
    CapsLock,


    Mute,
    VolumeDown,
    VolumeUp,
    Pause,
    ScrollUp,
    ScrollDown,
    LeftClick,

}


#[derive(Serialize, Deserialize)]
pub enum KeyboardAction {
    SimpleCharacter(Key),    // character key or is backspace key
    ComplexCharacter(String) // accent character, or some other complex punctuation characters
}


#[cfg(test)]
mod tests {
    use crate::actions::{Action, Key};


    #[test]
    fn serde_action() {
        // set hold
        let json = r#"{"action": "SetHold", "data": null }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::SetHold);

        // set release
        let json = r#"{"action": "SetRelease", "data": null }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::SetRelease);

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
        let json = r#"{"action": "KeyPress", "data": "Equal" }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::KeyPress(Key::Equal));

        // scroll
        let json = r#"{"action": "Scroll", "data": 1 }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::Scroll(1));

        // mouse move
        let json = r#"{"action": "MouseMove", "data": [1,-2] }"#;
        let action: Action = serde_json::from_str(json).unwrap();
        matches!(action, Action::MouseMove((1, -2)));


    }
}