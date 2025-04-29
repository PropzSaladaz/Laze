use std::collections::HashMap;
use crate::actions;


pub struct KeyBindings {
    // binds an action into the respective OS key code
    key_bindings: HashMap<actions::Key, enigo::Key>,
    button_bindings: HashMap<actions::Button, enigo::Button>,
}

impl KeyBindings {

    pub fn new() -> Self {
        KeyBindings {
            key_bindings: KeyBindings::get_key_mapping(),
            button_bindings: KeyBindings::get_button_mapping(),
        }
    }

    pub fn translate_to_os_key(&self, key: &actions::Key) -> Option<enigo::Key> {
        self.key_bindings.get(key).cloned()
    }

    pub fn translate_to_os_button(&self, button: &actions::Button) -> Option<enigo::Button> {
        self.button_bindings.get(button).cloned()
    }
}

/// Create maps that bind interfaced key codes used by this application into the
/// underlying OS keys
impl KeyBindings {
    fn get_key_mapping() -> HashMap<actions::Key, enigo::Key> {
        return HashMap::from([
            // keyboard
            (actions::Key::Backspace, enigo::Key::Backspace),
            (actions::Key::VolumeMute, enigo::Key::VolumeMute),
            (actions::Key::VolumeDown, enigo::Key::VolumeDown),
            (actions::Key::VolumeUp, enigo::Key::VolumeUp),
            (actions::Key::Pause, enigo::Key::Pause),
            (actions::Key::Enter, enigo::Key::Return),
        ]);
    }

    fn get_button_mapping() -> HashMap<actions::Button, enigo::Button> {
        return HashMap::from([
            // keyboard
            (actions::Button::Left, enigo::Button::Left),
        ]);
    }
}