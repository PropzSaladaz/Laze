use crate::security::SessionId;
use enigo::Button;
use std::collections::{HashMap, HashSet};

/// A physical button stays pressed until the last session holding it releases it.
#[derive(Default)]
pub(crate) struct HeldMouseButtons {
    owners: HashMap<Button, HashSet<Option<SessionId>>>,
}

impl HeldMouseButtons {
    /// True only when the button needs a physical press.
    pub fn press(&mut self, session: Option<SessionId>, button: Button) -> bool {
        let owners = self.owners.entry(button).or_default();
        let first = owners.is_empty();
        owners.insert(session);
        first
    }

    /// Ignore duplicate and unrelated mouse-up records.
    pub fn release(&mut self, session: Option<SessionId>, button: Button) -> bool {
        let Some(owners) = self.owners.get_mut(&button) else {
            return false;
        };
        if !owners.remove(&session) || !owners.is_empty() {
            return false;
        }
        self.owners.remove(&button);
        true
    }

    pub fn is_held(&self, button: Button) -> bool {
        self.owners.contains_key(&button)
    }

    pub fn release_session(&mut self, session: Option<SessionId>) -> Vec<Button> {
        let mut released = Vec::new();
        self.owners.retain(|button, owners| {
            if owners.remove(&session) && owners.is_empty() {
                released.push(*button);
                false
            } else {
                true
            }
        });
        released
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disconnect_releases_only_buttons_without_another_owner() {
        let mut held = HeldMouseButtons::default();
        let first = Some([1; 16]);
        let second = Some([2; 16]);
        assert!(held.press(first, Button::Left));
        assert!(!held.press(second, Button::Left));
        assert!(held.press(first, Button::Right));
        assert_eq!(held.release_session(first), vec![Button::Right]);
        assert!(held.is_held(Button::Left));
        assert_eq!(held.release_session(second), vec![Button::Left]);
        assert!(!held.is_held(Button::Left));
    }

    #[test]
    fn duplicate_down_and_cleanup_are_idempotent() {
        let mut held = HeldMouseButtons::default();
        let session = Some([1; 16]);
        assert!(held.press(session, Button::Left));
        assert!(!held.press(session, Button::Left));
        assert_eq!(held.release_session(session), vec![Button::Left]);
        assert!(held.release_session(session).is_empty());
        assert!(!held.release(session, Button::Left));
    }

    #[test]
    fn mouse_up_cannot_release_another_session_or_a_reconnected_session() {
        let mut held = HeldMouseButtons::default();
        let old = Some([1; 16]);
        let new = Some([2; 16]);
        assert!(held.press(old, Button::Left));
        assert!(!held.release(new, Button::Left));
        assert_eq!(held.release_session(old), vec![Button::Left]);
        assert!(held.press(new, Button::Left));
        assert!(!held.release(old, Button::Left));
        assert!(held.release_session(old).is_empty());
        assert!(held.release(new, Button::Left));
    }
}
