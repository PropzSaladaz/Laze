"use client";

import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState, useCallback, useRef } from "react";
import styles from "./home.module.css";

interface InitResult {
  success: boolean;
  message: string;
}

type ConnectionState = "idle" | "connecting" | "connected" | "failed";

const MAX_RETRY_DURATION_MS = 60000; // 1 minute
const RETRY_INTERVAL_MS = 5000; // 5 seconds

export default function Home() {
  const [connectionState, setConnectionState] = useState<ConnectionState>("idle");
  const [errorMessage, setErrorMessage] = useState<string>("");
  const [retryCount, setRetryCount] = useState(0);
  const [timeRemaining, setTimeRemaining] = useState(MAX_RETRY_DURATION_MS / 1000);

  const startTimeRef = useRef<number | null>(null);
  const retryTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const countdownRef = useRef<NodeJS.Timeout | null>(null);

  const clearTimers = useCallback(() => {
    if (retryTimeoutRef.current) {
      clearTimeout(retryTimeoutRef.current);
      retryTimeoutRef.current = null;
    }
    if (countdownRef.current) {
      clearInterval(countdownRef.current);
      countdownRef.current = null;
    }
  }, []);

  const attemptConnection = useCallback(async (): Promise<boolean> => {
    try {
      // First init the server
      const initResult = await invoke<InitResult>("init_server", {});

      if (!initResult.success) {
        setErrorMessage(initResult.message);
        return false;
      }

      // Then start the server
      const startResult = await invoke<string>("start_server", {});

      if (startResult.includes("successfully")) {
        return true;
      } else {
        setErrorMessage(startResult);
        return false;
      }
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : String(error));
      return false;
    }
  }, []);

  const startAutoRetry = useCallback(async () => {
    setConnectionState("connecting");
    setErrorMessage("");
    setRetryCount(0);
    setTimeRemaining(MAX_RETRY_DURATION_MS / 1000);
    startTimeRef.current = Date.now();

    // Countdown timer
    countdownRef.current = setInterval(() => {
      if (startTimeRef.current) {
        const elapsed = Date.now() - startTimeRef.current;
        const remaining = Math.max(0, Math.ceil((MAX_RETRY_DURATION_MS - elapsed) / 1000));
        setTimeRemaining(remaining);
      }
    }, 1000);

    const tryConnect = async () => {
      const success = await attemptConnection();

      if (success) {
        clearTimers();
        setConnectionState("connected");

        // Use direct navigation instead of Next.js router to avoid chunk loading issues
        window.location.href = "/dashboard";
        return;
      }

      // Check if we've exceeded the retry duration
      const elapsed = Date.now() - (startTimeRef.current || Date.now());
      if (elapsed >= MAX_RETRY_DURATION_MS) {
        clearTimers();
        setConnectionState("failed");
        return;
      }

      // Schedule next retry
      setRetryCount(prev => prev + 1);
      retryTimeoutRef.current = setTimeout(tryConnect, RETRY_INTERVAL_MS);
    };

    // First attempt immediately
    await tryConnect();
  }, [attemptConnection, clearTimers]);

  const handleManualRetry = useCallback(() => {
    clearTimers();
    startAutoRetry();
  }, [clearTimers, startAutoRetry]);

  // Start connection attempt on mount
  useEffect(() => {
    startAutoRetry();

    return () => {
      clearTimers();
    };
  }, [startAutoRetry, clearTimers]);

  if (connectionState === "connecting") {
    return (
      <main className={styles.container}>
        <div className={styles.spinner}></div>
        <h1 className={styles.title}>Connecting to network...</h1>
        <p className={styles.subtitle}>
          Attempt #{retryCount + 1} • {timeRemaining}s remaining
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

  // This shouldn't normally be visible (redirects on success)
  return (
    <main className={styles.container}>
      <h1 className={styles.title}>
        Initializing...
      </h1>
    </main>
  );
}
