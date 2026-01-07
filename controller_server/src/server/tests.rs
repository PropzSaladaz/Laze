#[cfg(test)]
mod tests {
    use crate::server::{
        commands::*,
        core::{ServerConfig, ClientInfo},
    };

    #[test]
    fn test_server_config_creation() {
        // Test that ServerConfig can be created
        let config = ServerConfig::new(8000, 10);
        // We can't access private fields, but we can test that it was created successfully
        let _ = config;
    }

    #[test]
    fn test_server_request_serialization() {
        // Test that server requests can be serialized/deserialized
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
    fn test_client_info_serialization() {
        let client_info = ClientInfo {
            id: 1,
            addr: "127.0.0.1:8080".to_string(),
        };
        
        // Test that ClientInfo can be serialized (it derives Serialize)
        let serialized = serde_json::to_string(&client_info).unwrap();
        assert!(serialized.contains("127.0.0.1:8080"));
        assert!(serialized.contains("\"id\":1"));
    }

    #[test]
    fn test_variant_of_server_started() {
        let response = ServerResponse::ServerStarted(ServerStarted {});
        let _extracted = ServerStarted::assert_variant_of(response);
        // If we reach here, the assertion passed
    }

    #[test]
    #[should_panic(expected = "Expected variant ServerStarted")]
    fn test_variant_of_wrong_variant() {
        let response = ServerResponse::ServerTerminated(ServerTerminated);
        let _extracted = ServerStarted::assert_variant_of(response);
    }
}
