use crate::actions;
use std::collections::HashMap;

type KeyCombo = Vec<enigo::Key>;

pub struct KeyBindings {
    // binds an action into the respective OS key code
    key_bindings: HashMap<actions::Key, KeyCombo>,
    button_bindings: HashMap<actions::Button, enigo::Button>,
}

impl KeyBindings {
    pub fn new() -> Self {
        KeyBindings {
            key_bindings: KeyBindings::get_key_mapping(),
            button_bindings: KeyBindings::get_button_mapping(),
        }
    }

    pub fn translate_to_os_key(&self, key: &actions::Key) -> Option<KeyCombo> {
        self.key_bindings.get(key).cloned()
    }

    pub fn translate_to_os_button(&self, button: &actions::Button) -> Option<enigo::Button> {
        self.button_bindings.get(button).cloned()
    }
}

/// Create maps that bind interfaced key codes used by this application into the
/// underlying OS keys
impl KeyBindings {
    fn get_key_mapping() -> HashMap<actions::Key, KeyCombo> {
        return HashMap::from([
            // keyboard
            (actions::Key::Backspace, vec![enigo::Key::Backspace]),
            (actions::Key::VolumeMute, vec![enigo::Key::VolumeMute]),
            (actions::Key::VolumeDown, vec![enigo::Key::VolumeDown]),
            (actions::Key::VolumeUp, vec![enigo::Key::VolumeUp]),
            (actions::Key::Pause, vec![enigo::Key::MediaStop]),
            (actions::Key::Play, vec![enigo::Key::MediaPlayPause]),
            (actions::Key::Enter, vec![enigo::Key::Return]),
            (actions::Key::Fullscreen, vec![enigo::Key::F11]),
            (
                actions::Key::CloseTab,
                vec![enigo::Key::Control, enigo::Key::Unicode('w')],
            ),
            // Fixed: NextTab = Ctrl+Tab, PreviousTab = Ctrl+Shift+Tab
            (
                actions::Key::NextTab,
                vec![enigo::Key::Control, enigo::Key::Tab],
            ),
            (
                actions::Key::PreviousTab,
                vec![enigo::Key::Control, enigo::Key::Shift, enigo::Key::Tab],
            ),
            // BrightnessDown not supported by enigo - maps to no-op (empty vec handled specially)
        ]);
    }

    fn get_button_mapping() -> HashMap<actions::Button, enigo::Button> {
        return HashMap::from([
            // keyboard
            (actions::Button::Left, enigo::Button::Left),
        ]);
    }
}
