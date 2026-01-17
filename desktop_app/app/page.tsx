"use client";

import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import styles from "./home.module.css";

interface InitResult {
  success: boolean;
  message: string;
}

type ConnectionState = "loading" | "connecting" | "ready" | "failed" | "starting";

const MAX_RETRY_DURATION_MS = 60000;
const RETRY_INTERVAL_MS = 5000;
const SESSION_KEY_INIT = "server_initialized";
const SESSION_KEY_NAVIGATING = "navigating_to_dashboard";

export default function Home() {
  const [connectionState, setConnectionState] = useState<ConnectionState>("loading");
  const [errorMessage, setErrorMessage] = useState<string>("");
  const [retryCount, setRetryCount] = useState(0);
  const [timeRemaining, setTimeRemaining] = useState(MAX_RETRY_DURATION_MS / 1000);

  // Start the server listening and navigate to dashboard
  async function startServer() {
    console.log("[Home] startServer called");
    setConnectionState("starting");

    try {
      const result = await invoke<string>("start_server", {});
      console.log("[Home] start_server result:", result);

      if (result.includes("successfully")) {
        console.log("[Home] Setting navigation flag and redirecting");
        // Set navigation flag BEFORE navigation - survives Fast Refresh
        sessionStorage.setItem(SESSION_KEY_NAVIGATING, "true");
        window.location.href = "/dashboard";
      } else {
        console.error("[Home] start_server failed:", result);
        setErrorMessage(result);
        setConnectionState("failed");
      }
    } catch (error) {
      console.error("[Home] start_server exception:", error);
      setErrorMessage(error instanceof Error ? error.message : String(error));
      setConnectionState("failed");
    }
  }

  async function handleManualRetry() {
    setConnectionState("connecting");
    setErrorMessage("");
    await doInitWithRetry();
  }

  async function doInitWithRetry() {
    const startTime = Date.now();
    let attempt = 0;

    const tryInit = async (): Promise<boolean> => {
      try {
        const initResult = await invoke<InitResult>("init_server", {});
        console.log("[Home] init_server result:", initResult);
        return initResult.success;
      } catch (error) {
        console.error("[Home] init_server error:", error);
        setErrorMessage(error instanceof Error ? error.message : String(error));
        return false;
      }
    };

    while (Date.now() - startTime < MAX_RETRY_DURATION_MS) {
      attempt++;
      setRetryCount(attempt);
      setTimeRemaining(Math.ceil((MAX_RETRY_DURATION_MS - (Date.now() - startTime)) / 1000));

      const success = await tryInit();
      if (success) {
        sessionStorage.setItem(SESSION_KEY_INIT, "true");
        setConnectionState("ready");
        return;
      }

      await new Promise(resolve => setTimeout(resolve, RETRY_INTERVAL_MS));
    }

    setConnectionState("failed");
  }

  // Main initialization effect
  useEffect(() => {
    let cancelled = false;

    async function initialize() {
      // Check if we were navigating to dashboard (Fast Refresh recovery)
      const wasNavigating = sessionStorage.getItem(SESSION_KEY_NAVIGATING) === "true";
      if (wasNavigating) {
        console.log("[Home] Detected navigation flag, redirecting to dashboard");
        // Don't clear the flag yet - let dashboard clear it
        window.location.href = "/dashboard";
        return;
      }

      // Check if already initialized
      const wasInitialized = sessionStorage.getItem(SESSION_KEY_INIT) === "true";

      if (wasInitialized) {
        try {
          const isInit = await invoke<boolean>("is_server_initialized", {});
          console.log("[Home] sessionStorage says init, backend says:", isInit);
          if (isInit && !cancelled) {
            setConnectionState("ready");
            return;
          }
        } catch (e) {
          console.error("[Home] is_server_initialized check failed:", e);
        }
        sessionStorage.removeItem(SESSION_KEY_INIT);
      }

      // Check backend directly
      try {
        const isInit = await invoke<boolean>("is_server_initialized", {});
        console.log("[Home] is_server_initialized:", isInit);

        if (isInit && !cancelled) {
          sessionStorage.setItem(SESSION_KEY_INIT, "true");
          setConnectionState("ready");
          return;
        }
      } catch (e) {
        console.error("[Home] is_server_initialized error:", e);
      }

      // Not initialized, start retry loop
      if (!cancelled) {
        setConnectionState("connecting");
        await doInitWithRetry();
      }
    }

    initialize();

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (connectionState === "loading") {
    return (
      <main className={styles.container}>
        <h1 className={styles.title}>Initializing...</h1>
      </main>
    );
  }

  if (connectionState === "starting") {
    return (
      <main className={styles.container}>
        <div className={styles.spinner}></div>
        <h1 className={styles.title}>Starting server...</h1>
      </main>
    );
  }

  if (connectionState === "connecting") {
    return (
      <main className={styles.container}>
        <div className={styles.spinner}></div>
        <h1 className={styles.title}>Connecting to network...</h1>
        <p className={styles.subtitle}>
          Attempt #{retryCount} • {timeRemaining}s remaining
        </p>
        <p className={styles.hint}>
          Waiting for WiFi connection...
        </p>
      </main>
    );
  }

  if (connectionState === "failed") {
    return (
      <main className={styles.container}>
        <h1 className={styles.title}>Connection failed</h1>
        <p className={styles.subtitle}>
          Could not connect to the network after multiple attempts.
        </p>
        {errorMessage && (
          <p className={styles.errorMessage}>{errorMessage}</p>
        )}
        <button onClick={handleManualRetry} className={styles.startButton}>
          Retry Connection
        </button>
      </main>
    );
  }

  return (
    <main className={styles.container}>
      <h1 className={styles.title}>
        Server is ready.
      </h1>
      <p className={styles.subtitle}>
        Press "Start Server" to begin accepting connections.
      </p>
      <button onClick={startServer} className={styles.startButton}>
        Start Server
      </button>
    </main>
  );
}
