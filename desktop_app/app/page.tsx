"use client";

import { invoke } from "@tauri-apps/api/core";
import Link from "next/link";
import styles from "./home.module.css";

export default function Home() {
  async function startServer() {
    await invoke<string>("start_server", {});
  }

  return (
    <main className={styles.container}>
      <h1 className={styles.title}>
        Server is currently offline.
      </h1>
      <p className={styles.subtitle}>
        Press "Start Server" to begin accepting connections.
      </p>
      <Link href="/dashboard">
        <button onClick={startServer} className={styles.startButton}>
          Start Server
        </button>
      </Link>
    </main>
  );
}
