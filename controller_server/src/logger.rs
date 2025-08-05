use std::os::linux::raw::stat;

pub trait Loggable {
    fn log_info(&self, message: &str) {
        log::info!("{}", Self::static_build_message(message));
    }

    fn log_debug(&self, message: &str) {
        log::debug!("{}", Self::static_build_message(message));
    }

    fn log_error(&self, message: &str) {
        log::error!("{}", Self::static_build_message(message));
    }

    fn log_warn(&self, message: &str) {
        log::warn!("{}", Self::static_build_message(message));
    }

    fn log_trace(&self, message: &str) {
        log::trace!("{}", Self::static_build_message(message));
    }


    fn static_label() -> String;

    fn static_log_info(message: &str) {
        log::info!("{}", Self::static_build_message(message));
    }

    fn static_log_debug(message: &str) {
        log::debug!("{}", Self::static_build_message(message));
    }

    fn static_log_error(message: &str) {
        log::error!("{}", Self::static_build_message(message));
    }

    fn static_log_warn(message: &str) {
        log::warn!("{}", Self::static_build_message(message));
    }

    fn static_log_trace(message: &str) {
        log::trace!("{}", Self::static_build_message(message));
    }

    fn static_build_message(message: &str) -> String {
        format!("{} {}", Self::static_label(), message)
    }
}

impl<T> Loggable for T {

    fn static_label() -> String {
        let full = std::any::type_name::<T>();
        // return only the last part - struct name
        format!("[{:<18}]: ", full.split("::").last().unwrap_or(full)) 
    }
}