"use client";

import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import { listen } from "@tauri-apps/api/event";
import Link from "next/link";
import { enable, disable, isEnabled } from "@tauri-apps/plugin-autostart";
import styles from "./dashboard.module.css";

interface Timer {
    hours: number;
    minutes: number;
    seconds: number;
}

interface ClientInfo {
    id: number;
    addr: string;
    device_name?: string;
}

interface Client extends ClientInfo {
    name: string;
    timeConnected: Timer;
}

function formatTime(timer: Timer): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${pad(timer.hours)}h ${pad(timer.minutes)}m ${pad(timer.seconds)}s`;
}

function incrementTimer(timer: Timer): Timer {
    let { hours, minutes, seconds } = timer;
    seconds += 1;
    if (seconds >= 60) { seconds = 0; minutes += 1; }
    if (minutes >= 60) { minutes = 0; hours += 1; }
    return { hours, minutes, seconds };
}

export default function Dashboard() {
    const [clients, setClients] = useState<Client[]>([]);
    const [selectedClient, setSelectedClient] = useState<number | null>(null);
    const [autostart, setAutostart] = useState(false);

    useEffect(() => {
        isEnabled().then(setAutostart).catch(console.error);
    }, []);

    async function toggleAutostart() {
        try {
            if (autostart) {
                await disable();
                setAutostart(false);
            } else {
                await enable();
                setAutostart(true);
            }
        } catch (error) {
            console.error("Failed to toggle autostart:", error);
        }
    }

    async function stopServer() {
        await invoke<string>("stop_server", {});
    }

    async function removeClient() {
        if (selectedClient !== null) {
            await invoke("remove_client", { clientId: selectedClient });
            setSelectedClient(null);
        }
    }

    useEffect(() => {
        let isSubscribed = true;
        const unsubscribers: (() => void)[] = [];

        // Timer for each client
        const interval = setInterval(() => {
            setClients((prev) =>
                prev.map(client => ({
                    ...client,
                    timeConnected: incrementTimer(client.timeConnected)
                }))
            );
        }, 1000);

        // Subscribe to client events
        const setupListeners = async () => {
            if (!isSubscribed) return;

            const clientAddedUnsub = await listen<ClientInfo>("client-added", (event) => {
                const newClient: Client = {
                    ...event.payload,
                    name: event.payload.device_name || "Unknown Device",
                    timeConnected: { hours: 0, minutes: 0, seconds: 0 }
                };
                setClients((prev) => {
                    // Check if client with same ID already exists (prevent duplicates)
                    if (prev.some(c => c.id === event.payload.id)) {
                        return prev.map(c => c.id === event.payload.id ? newClient : c);
                    }
                    return [...prev, newClient];
                });
            });
            if (isSubscribed) unsubscribers.push(clientAddedUnsub);

            const clientRemovedUnsub = await listen<ClientInfo>("client-removed", (event) => {
                setClients((prev) => prev.filter(c => c.id !== event.payload.id));
            });
            if (isSubscribed) unsubscribers.push(clientRemovedUnsub);

            const clientUpdatedUnsub = await listen<ClientInfo>("client-updated", (event) => {
                setClients((prev) => prev.map(client =>
                    client.id === event.payload.id
                        ? { ...client, name: event.payload.device_name || client.name }
                        : client
                ));
            });
            if (isSubscribed) unsubscribers.push(clientUpdatedUnsub);
        };

        setupListeners();

        return () => {
            isSubscribed = false;
            unsubscribers.forEach(unsub => unsub());
            clearInterval(interval);
        };
    }, []);

    return (
        <main className={styles.dashboard}>
            {/* Header */}
            <header className={styles.header}>
                <div className={styles.status}>
                    <span>Status:</span>
                    <span className={styles.statusDot}></span>
                    <span className={styles.statusText}>Running</span>
                </div>
                <div className={styles.headerActions}>
                    <label className={styles.checkboxLabel}>
                        <input
                            type="checkbox"
                            checked={autostart}
                            onChange={toggleAutostart}
                        />
                        Run on Startup
                    </label>
                    <Link href="/">
                        <button onClick={stopServer} className={styles.stopButton}>
                            Stop Server
                        </button>
                    </Link>
                </div>
            </header>

            {/* Client Table */}
            <div className={styles.tableContainer}>
                <table className={styles.table}>
                    <thead>
                        <tr>
                            <th>Client #</th>
                            <th>Name</th>
                            <th>IP address</th>
                            <th>Running Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        {clients.map(client => (
                            <tr
                                key={client.id}
                                className={selectedClient === client.id ? styles.selected : ''}
                                onClick={() => setSelectedClient(client.id)}
                            >
                                <td>{client.id}</td>
                                <td>{client.name}</td>
                                <td>{client.addr}</td>
                                <td>{formatTime(client.timeConnected)}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Remove Button */}
            <button
                onClick={removeClient}
                className={styles.removeButton}
                disabled={selectedClient === null}
            >
                Remove Client
            </button>
        </main>
    );
}
