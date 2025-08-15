"use client";

import { useEffect, useState } from "react";
import "./App.css";
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

function ClientTable({ onRemove } : Props) {

    const [clientsConnected, setClientsConnected] = useState<Client[]>([]);

    useEffect( () => {

        // Start timer for each client
        const interval = setInterval( () => {
            setClientsConnected((prevClients) => 
                prevClients.map(client => ({
                    ...client,
                    timeConnected: incrementTimer(client.timeConnected)
                }))
            );
        }, 1000); // each 1 second

        // Subscribe to add clients event
        const clientAdded = listen<ClientInfo>("client_added", (event) => {
            const newClient: Client = {
                ...event.payload,
                timeConnected: {
                    hours: 0,
                    minutes: 0,
                    seconds: 0
                }
            };
            setClientsConnected((prev) => [...prev, newClient]);
        });

        // Subscribe to update clients event
        const clientRemoved = listen<ClientInfo>("client_removed", (event) => {
            setClientsConnected((prev) => prev.filter(client => client.id !== event.payload.id));
        });

        return () => {
            clientAdded.then(unlistenFn => unlistenFn());
            clientRemoved.then(unlistenFn => unlistenFn());
            clearInterval(interval);
        }
    });

  return (
    <table>

        <thead>
            <tr>
                <th>Client ID</th>
                <th>Address</th>
                <th>Time Connected</th>
                <th>Actions</th>
            </tr>
        </thead>

        <tbody>
            {clientsConnected.map(client => (
            <tr key={client.id}>
                <td>{client.id}</td>
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
