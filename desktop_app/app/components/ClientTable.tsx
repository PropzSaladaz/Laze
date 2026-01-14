"use client";

import { useEffect, useState } from "react";
import "../App.css";
import Link from "next/link";
import { listen } from "@tauri-apps/api/event";

type Props = {
    onRemove: (clientId: number) => Promise<void>;
}

interface Timer {
    hours: number,
    minutes: number,
    seconds: number,
}

interface ClientInfo {
    id: number,
    addr: string,
    device_name?: string,
}

interface Client extends ClientInfo {
    timeConnected: Timer,
}

function renderTime(timer: Timer): string {
    const { hours, minutes, seconds } = timer;
    return `${hours}h ${minutes}m ${seconds}s`;
}

function incrementTimer(timer: Timer) {
    let { hours, minutes, seconds } = timer;

    seconds += 1;
    if (seconds >= 60) {
        seconds = 0;
        minutes += 1;
    }
    if (minutes >= 60) {
        minutes = 0;
        hours += 1;
    }

    return { hours, minutes, seconds };
}

function ClientTable({ onRemove }: Props) {

    const [clientsConnected, setClientsConnected] = useState<Client[]>([]);

    useEffect(() => {
        let isSubscribed = true;
        const unsubscribers: (() => void)[] = [];

        // Start timer for each client
        const interval = setInterval(() => {
            setClientsConnected((prevClients) =>
                prevClients.map(client => ({
                    ...client,
                    timeConnected: incrementTimer(client.timeConnected)
                }))
            );
        }, 1000); // each 1 second

        const setupListeners = async () => {
            if (!isSubscribed) return;

            // Subscribe to add clients event
            const clientAddedUnsub = await listen<ClientInfo>("client-added", (event) => {
                const newClient: Client = {
                    ...event.payload,
                    timeConnected: {
                        hours: 0,
                        minutes: 0,
                        seconds: 0
                    }
                };
                setClientsConnected((prev) => {
                    // Check if client with same ID already exists (prevent duplicates)
                    if (prev.some(c => c.id === event.payload.id)) {
                        return prev.map(c => c.id === event.payload.id ? newClient : c);
                    }
                    return [...prev, newClient];
                });
            });
            if (isSubscribed) unsubscribers.push(clientAddedUnsub);

            // Subscribe to update clients event
            const clientRemovedUnsub = await listen<ClientInfo>("client-removed", (event) => {
                setClientsConnected((prev) => prev.filter(client => client.id !== event.payload.id));
            });
            if (isSubscribed) unsubscribers.push(clientRemovedUnsub);

            // Subscribe to client info updates (e.g., device name received after connection)
            const clientUpdatedUnsub = await listen<ClientInfo>("client-updated", (event) => {
                setClientsConnected((prev) => prev.map(client =>
                    client.id === event.payload.id
                        ? { ...client, device_name: event.payload.device_name }
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
        }
    }, []);

    return (
        <table>

            <thead>
                <tr>
                    <th>Client ID</th>
                    <th>Device Name</th>
                    <th>Address</th>
                    <th>Time Connected</th>
                    <th>Actions</th>
                </tr>
            </thead>

            <tbody>
                {clientsConnected.map(client => (
                    <tr key={client.id}>
                        <td>{client.id}</td>
                        <td>{client.device_name || 'Unknown Device'}</td>
                        <td>{client.addr}</td>
                        <td>{renderTime(client.timeConnected)}</td>
                        <td>
                            <Link href="/">
                                <button onClick={() => onRemove(client.id)}>Remove</button>
                            </Link>
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    );
}

export default ClientTable;
