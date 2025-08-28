"use client";

import { listen } from "@tauri-apps/api/event";
import { useEffect, useState } from "react";

interface Client {
    id: number;
    addr: String
}

export default function Dashboard() {
    const [clients, setClients] = useState<Client[]>([]);

    useEffect(() => {
        const newClientAdded = listen<Client>("client-added", (event) => {
            setClients((prevClients) => [...prevClients, event.payload]);
        });

        const clientRemoved = listen<Client>("client-removed", (event) => {
            setClients((prevClients) => prevClients.filter(c => c.id != event.payload.id));
        });

        return () => {
            newClientAdded.then(unsub => unsub());
            clientRemoved.then(unsub => unsub());
        };
    }, []);

    return (
        <main className="container">
            <h1>Dashboard</h1>
            <p>This is the dashboard page.</p>

            <div>
                { clients.map(client => (
                    <div key={client.id}>
                        <p>{client.id}</p>
                        <p>{client.addr}</p>
                    </div>
                ))}
            </div>
        </main>
    )
}