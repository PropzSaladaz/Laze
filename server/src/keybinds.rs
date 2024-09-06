use std::collections::HashMap;

use crate::actions::Key;


pub struct KeyBindings {
    // binds an action into the respective OS key code
    bindings: HashMap<Key, u32>,
}

impl KeyBindings {

    pub fn new() -> Self {
        KeyBindings {
            bindings: KeyBindings::get_key_mapping()
        }
    }

    pub fn translate_to_os_key(&self, key: Key) -> Option<u32> {
        self.bindings.get(&key).cloned()
    }

    fn get_key_mapping() -> HashMap<Key, u32> {
        
        #[cfg(target_os = "windows")]
        {
            todo!();
        }

        #[cfg(target_os = "macos")]
        {
            todo!();
        }

        #[cfg(target_os = "linux")]
        {
            return HashMap::from([
                // keyboard
                (Key::Num1, 2),
                (Key::Num2, 3),
                (Key::Num3, 4),
                (Key::Num4, 5),
                (Key::Num5, 6),
                (Key::Num6, 7),
                (Key::Num7, 8),
                (Key::Num8, 9),
                (Key::Num9, 10),
                (Key::Num0, 11),
                (Key::Minus, 12),
                (Key::Equal, 13),
                (Key::BackSpace, 14),
                (Key::Tab, 15),
                (Key::Q, 16),
                (Key::W, 17),
                (Key::E, 18),
                (Key::R, 19),
                (Key::T, 20),
                (Key::Y, 21),
                (Key::U, 22),
                (Key::I, 23),
                (Key::O, 24),
                (Key::P, 25),
                (Key::LeftBrace, 26),
                (Key::RightBrace, 27),
                (Key::Enter, 28),
                (Key::LeftCtrl, 29),
                (Key::A, 30),
                (Key::S, 31),
                (Key::D, 32),
                (Key::F, 33),
                (Key::G, 34),
                (Key::H, 35),
                (Key::J, 36),
                (Key::K, 37),
                (Key::L, 38),
                (Key::SemiColon, 39),
                (Key::Apostrofe, 40),
                (Key::Grave, 41),
                (Key::LeftShift, 42),
                (Key::BackSlash, 43),
                (Key::Z, 44),
                (Key::X, 45),
                (Key::C, 46),
                (Key::V, 47),
                (Key::B, 48),
                (Key::N, 49),
                (Key::M, 50),
                (Key::Comma, 51),
                (Key::Dot, 52),
                (Key::Slash, 53),
                (Key::RightShift, 54),
                (Key::KPAsteristk, 55),
                (Key::LeftAlt, 56),
                (Key::Space, 57),
                (Key::CapsLock, 58),
                (Key::LeftClick, 0x110),
            ]);
        }
    }
}




