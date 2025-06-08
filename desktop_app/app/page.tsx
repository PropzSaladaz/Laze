"use client";


import { useState } from "react";
import reactLogo from "./assets/react.svg";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";

function App() {

  const [serverIp, setServerIp] = useState("");

  // start server & get IP address
  async function startServer() {
    let ip = await invoke<string>("start_server", {});
    setServerIp(ip);
  }

  return (
    <main className="container">
      <h1>Welcome to Mobile Controller</h1>
      {serverIp ?
        <h1>Server running at {serverIp}</h1>
        :
        <button onClick={startServer}>Start Server</button>
      }
    </main>
  );
}

export default App;
