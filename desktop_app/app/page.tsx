"use client";

import { useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";
import { Server } from "node:tls";
import Link from "next/link";

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
      <h1>Server is currently offline <br/> Press "Start Server" to begin accepting connections.</h1>
      
      <Link href="/dashboard">
        <button onClick={startServer}>Start Server</button> 
      </Link>
      
      
    </main>
  );
}

export default App;
