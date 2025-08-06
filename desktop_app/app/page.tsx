"use client";

import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";

interface ClientInfo {
  id: number;
  address: string;
  port: number;
}

function App() {

  const [started, setStarted] = useState(false);
  const [clients, setClients] = useState<ClientInfo[]>([]);

  // start server
  async function startServer() {
    await invoke<string>("start_server", {});
    setStarted(true);
    fetchClients();
  }

  // stop server
  async function stopServer() {
    await invoke<string>("stop_server", {});
    setStarted(false);
    setClients([]);
  }

  // fetch current clients
  async function fetchClients() {
    const clientList = await invoke<ClientInfo[]>("get_clients", {});
    setClients(clientList);
  }

  // remove specific client
  async function removeClient(clientId: number) {
    await invoke("remove_client", { clientId });
    fetchClients(); // Refresh the client list after removal
  }

  // Periodically refresh the client list when server is running
  useEffect(() => {
    if (started) {
      const interval = setInterval(() => {
        fetchClients();
      }, 2000); // Refresh every 2 seconds

      return () => clearInterval(interval);
    }
  }, [started]);

  return (
    <main className="container">
      <h1>Welcome to Mobile Controller</h1>
      {started ? (
        <>
          <h1>Server is running</h1>
          <button onClick={stopServer}>Stop Server</button>
          
          <div style={{ marginTop: '20px' }}>
            <h2>Connected Clients ({clients.length})</h2>
            {clients.length === 0 ? (
              <p>No clients connected</p>
            ) : (
              <div>
                {clients.map((client) => (
                  <div
                    key={client.id}
                    style={{
                      border: '1px solid #ccc',
                      padding: '10px',
                      margin: '10px 0',
                      borderRadius: '5px',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center'
                    }}
                  >
                    <div>
                      <strong>Client ID:</strong> {client.id}<br />
                      <strong>Address:</strong> {client.address}<br />
                      <strong>Port:</strong> {client.port}
                    </div>
                    <button
                      onClick={() => removeClient(client.id)}
                      style={{
                        backgroundColor: '#ff4444',
                        color: 'white',
                        border: 'none',
                        padding: '5px 10px',
                        borderRadius: '3px',
                        cursor: 'pointer'
                      }}
                    >
                      Remove
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </>
      ) : (
        <>
          <h1>Server is stopped</h1>
          <button onClick={startServer}>Start Server</button>
        </>
      )}
    </main>
  );
}

export default App;
