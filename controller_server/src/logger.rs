pub trait Loggable {
    fn label(&self) -> &str;

    fn composed_label(&self) -> String {
        format!("[{}]: ", self.label())
    }

    fn log_info(&self, message: &str) {
        log::info!("{} {}", self.label(), message);
    }

    fn log_debug(&self, message: &str) {
        log::debug!("{} {}", self.label(), message);
    }

    fn log_error(&self, message: &str) {
        log::error!("{} {}", self.label(), message);
    }

    fn log_warn(&self, message: &str) {
        log::warn!("{} {}", self.label(), message);
    }

    fn log_trace(&self, message: &str) {
        log::trace!("{} {}", self.label(), message);
    }
}

impl<T> Loggable for T {
    fn label(&self) -> &str {
        let full = std::any::type_name::<T>();
        // return only the last part - struct name
        full.split("::").last().unwrap_or(full) 
    }
}