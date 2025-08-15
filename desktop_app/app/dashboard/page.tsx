"use client";

import { invoke } from "@tauri-apps/api/core";
import "./App.css";
import Link from "next/link";
import { ClientTable } from "@/components/ClientTable";

function Dashboard() {

  // start server & get IP address
  async function stopServer() {
    await invoke<string>("stop_server", {});
  }

  async function removeClient(clientId: number) {
    await invoke("remove_client", { clientId });
  }

  return (
    <main className="bg-bg">   
        <nav>
            <Link href="/">
                <button onClick={stopServer}>Stop Server</button> 
            </Link>
        </nav>
        <ClientTable onRemove={removeClient} />
    </main>
  );
}

export default Dashboard;
