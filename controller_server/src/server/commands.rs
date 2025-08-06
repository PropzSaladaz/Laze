use serde::{Deserialize, Serialize};

// ------------------ Requests ------------------- //

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerRequest {
    InitServer,
    TerminateServer,
    TerminateClient(usize),
    GetClients,
}

// ------------------ Responses ------------------ //

#[derive(Debug, Serialize, Deserialize)]
pub enum ServerResponse {
    ServerStarted(ServerStarted),
    ServerTerminated(ServerTerminated),
    ClientTerminated(ClientTerminated),
    ClientList(ClientList),
    Error(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerStarted {}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServerTerminated;

#[derive(Debug, Serialize, Deserialize)]
pub struct ClientTerminated {
    pub client_id: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ClientList {
    pub clients: Vec<ClientInfo>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ClientInfo {
    pub id: usize,
    pub address: String,
    pub port: usize,
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
    ServerTerminated,
    ClientTerminated,
    ClientList,
});