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


    fn static_label() -> &'static str;

    fn static_composed_label() -> String {
        format!("[{}]: ", Self::static_label())
    }

    fn static_log_info(message: &str) {
        log::info!("{} {}", Self::static_label(), message);
    }

    fn static_log_debug(message: &str) {
        log::debug!("{} {}", Self::static_label(), message);
    }

    fn static_log_error(message: &str) {
        log::error!("{} {}", Self::static_label(), message);
    }

    fn static_log_warn(message: &str) {
        log::warn!("{} {}", Self::static_label(), message);
    }

    fn static_log_trace(message: &str) {
        log::trace!("{} {}", Self::static_label(), message);
    }
}

impl<T> Loggable for T {
    fn label(&self) -> &str {
        let full = std::any::type_name::<T>();
        // return only the last part - struct name
        full.split("::").last().unwrap_or(full) 
    }

    fn static_label() -> &'static str {
        let full = std::any::type_name::<T>();
        // return only the last part - struct name
        full.split("::").last().unwrap_or(full) 
    }
}