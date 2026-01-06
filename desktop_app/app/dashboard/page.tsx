"use client";

import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import { listen } from "@tauri-apps/api/event";
import Link from "next/link";
import styles from "./dashboard.module.css";

interface Timer {
    hours: number;
    minutes: number;
    seconds: number;
}

interface ClientInfo {
    id: number;
    addr: string;
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
        const clientAdded = listen<ClientInfo>("client-added", (event) => {
            const newClient: Client = {
                ...event.payload,
                name: "David", // Default name, could be sent from mobile
                timeConnected: { hours: 0, minutes: 0, seconds: 0 }
            };
            setClients((prev) => [...prev, newClient]);
        });

        const clientRemoved = listen<ClientInfo>("client-removed", (event) => {
            setClients((prev) => prev.filter(c => c.id !== event.payload.id));
        });

        return () => {
            clientAdded.then(unsub => unsub());
            clientRemoved.then(unsub => unsub());
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
                <Link href="/">
                    <button onClick={stopServer} className={styles.stopButton}>
                        Stop Server
                    </button>
                </Link>
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
