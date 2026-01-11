use serde::{Deserialize, Serialize};

// ------------------ Requests ------------------- //

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerRequest {
    InitServer,
    StopServer,
    TerminateServer,
    TerminateClient(usize),
}

// ------------------ Responses ------------------ //

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerResponse {
    ServerStarted(ServerStarted),
    ServerStopped(ServerStopped),
    ServerTerminated(ServerTerminated),
    ClientTerminated(ClientTerminated),
    Error(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStarted {}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStopped {}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerTerminated;

#[derive(Debug, Serialize, Deserialize)]
pub struct ClientTerminated {
    pub client_id: usize,
}

// ------------------ VariantOf Trait ------------------ //

pub trait VariantOf<T> {
    fn assert_variant_of(other: T) -> Self
    where
        Self: Sized;
}

/// A macro to implement the `VariantOf` trait for each variant of an enum.
/// Allows to call `assert_variant_of` on the enum type to force it into its variant type.
/// Avoid using `match` statements to extract the inner value of the enum variant when we know
/// the expected type. Panics if asserted variant is not the received.
macro_rules! impl_variant_of {
    ($enum_type:ident => { $($variant:ident),* $(,)? }) => {
        $(
            impl VariantOf<$enum_type> for $variant {
                fn assert_variant_of(other: $enum_type) -> Self {
                    if let $enum_type::$variant(inner) = other {
                        inner
                    } else {
                        panic!("Expected variant {} but found {:?}", stringify!($variant), other);
                    }
                }
            }
        )*
    };
}

impl_variant_of!(ServerResponse => {
    ServerStarted,
    ServerStopped,
    ServerTerminated,
    ClientTerminated,
});

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_server_request_serialization() {
        let request = ServerRequest::InitServer;
        let serialized = serde_json::to_string(&request).unwrap();
        let deserialized: ServerRequest = serde_json::from_str(&serialized).unwrap();

        match deserialized {
            ServerRequest::InitServer => assert!(true),
            _ => panic!("Expected InitServer"),
        }
    }

    #[test]
    fn test_terminate_client_request() {
        let request = ServerRequest::TerminateClient(42);
        let serialized = serde_json::to_string(&request).unwrap();
        let deserialized: ServerRequest = serde_json::from_str(&serialized).unwrap();

        match deserialized {
            ServerRequest::TerminateClient(id) => assert_eq!(id, 42),
            _ => panic!("Expected TerminateClient"),
        }
    }

    #[test]
    fn test_server_response_server_started() {
        let response = ServerResponse::ServerStarted(ServerStarted {});
        let serialized = serde_json::to_string(&response).unwrap();
        let deserialized: ServerResponse = serde_json::from_str(&serialized).unwrap();

        match deserialized {
            ServerResponse::ServerStarted(_) => assert!(true),
            _ => panic!("Expected ServerStarted"),
        }
    }

    #[test]
    fn test_server_response_client_terminated() {
        let response = ServerResponse::ClientTerminated(ClientTerminated { client_id: 123 });
        let serialized = serde_json::to_string(&response).unwrap();
        let deserialized: ServerResponse = serde_json::from_str(&serialized).unwrap();

        match deserialized {
            ServerResponse::ClientTerminated(terminated) => assert_eq!(terminated.client_id, 123),
            _ => panic!("Expected ClientTerminated"),
        }
    }

    #[test]
    fn test_server_response_error() {
        let error_msg = "Test error message";
        let response = ServerResponse::Error(error_msg.to_string());
        let serialized = serde_json::to_string(&response).unwrap();
        let deserialized: ServerResponse = serde_json::from_str(&serialized).unwrap();

        match deserialized {
            ServerResponse::Error(msg) => assert_eq!(msg, error_msg),
            _ => panic!("Expected Error"),
        }
    }

    #[test]
    fn test_variant_of_server_started() {
        let response = ServerResponse::ServerStarted(ServerStarted {});
        let _extracted = ServerStarted::assert_variant_of(response);
    }

    #[test]
    #[should_panic(expected = "Expected variant ServerStarted")]
    fn test_variant_of_wrong_variant() {
        let response = ServerResponse::ServerTerminated(ServerTerminated);
        let _extracted = ServerStarted::assert_variant_of(response);
    }
}
