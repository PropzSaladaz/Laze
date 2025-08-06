"use client";

import { useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";
import { Server } from "node:tls";

function App() {

  const [started, setStarted] = useState(false);

  // start server & get IP address
  async function startServer() {
    await invoke<string>("start_server", {});
    setStarted(true);
  }

  // start server & get IP address
  async function stopServer() {
    await invoke<string>("stop_server", {});
    setStarted(false);
  }

  async function removeClient(clientId: number) {
    await invoke("remove_client", { clientId });
  }

  return (
    <main className="container">
      <h1>Welcome to Mobile Controller</h1>
      {started ? (
        <>
          <h1>Server is running</h1>
          <button onClick={stopServer}>Stop Server</button>
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
