use mobile_controller::MobileController;
use server::{Server, ServerConfig};
use tokio::time::{sleep, Duration};

mod mobile_controller;
mod server;
mod actions;
mod keybinds;

const PORT: usize = 7878;

#[tokio::main(flavor = "multi_thread")]
async fn main() {
    let config = ServerConfig::new(PORT, 10);
    let app = MobileController::new(
            1, 
            1,
            1,
            1500).unwrap();

    // server has started here
    let mut server_comm = Server::start(config, app);

    // emulates main thread communication with server
    loop {
        server_comm.send_request(server::ServerRequest::InitServer).await;
        match server_comm.receive_response().await {
            Some(server::ServerResponse::ServerStarted(p)) => {
                println!("Server initialized successfully. {p}");
            },
            _ => {
                println!("Unexpected response during initialization.");
            }
        }
        sleep(Duration::from_secs(6)).await;

        server_comm.send_request(server::ServerRequest::TerminateClient(2)).await;
        match server_comm.receive_response().await {
            Some(server::ServerResponse::ClientTerminated(t)) => {
                println!("Client terminated successfully.{t}");
            },
            _ => {
                println!("Unexpected response during client termination.");
            }
        }

        sleep(Duration::from_secs(6)).await;

        server_comm.send_request(server::ServerRequest::TerminateServer).await;
        match server_comm.receive_response().await {
            Some(server::ServerResponse::ServerTerminated) => {
                println!("Server terminated successfully.");
            },
            _ => {
                println!("Unexpected response during server termination.");
            }
        }
        sleep(Duration::from_secs(6)).await;
    
    }
}


