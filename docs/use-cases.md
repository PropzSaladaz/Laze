**Dashed lines** represent message passing - either IPC or through sockets.  
**Filled lines** represent memory sharing, or simple calls witout any context switching.


# Server Startup

## Overview

This sequence diagram illustrates the **initialization and startup sequence** between the Desktop Application and the Server logic, focusing particularly on the `CommandListener` thread which handles incoming command requests.

<img src="./diagrams/server-start.svg" width="100%" height="700px">



## Components

- **Desktop App**: The main Tauri-based UI application that initializes the backend server.
- **Server**: The backend logic module responsible for handling device interactions.
- **CommandListener**: A dedicated thread that continuously awaits and processes incoming commands.


## Sequence Description

1. **Startup**  
   The `Desktop App` triggers the startup process by initializing the `Server` instance.

2. **Server Initialization**  
   Once the server module starts, it immediately spawns a `CommandListener` thread.

3. **CommandListener Execution**  
   The `CommandListener` begins running in a loop, where it:
   - Waits for commands with a 1-second timeout.
   - After each interval, checks a termination flag to determine if it should exit.
   - Continues looping unless an external signal is received or an internal shutdown condition is met.

4. **Command Dispatch**  
   When a command like `Start Server` is received:
   - The listener invokes the callback set by the `Server`, and executes all needed logic on its behalf. In this case, sets a simple `start` flag to allow the server listening for new clients.
   - The `Server` proceeds to start listening for incoming client connections.
   - Once ready, a `Server Started` response is sent back and logged.

## Timing Notes

- **Polling Interval**: The command listener uses a 1-second timeout when awaiting commands.
- **Responsiveness**: After a command is received (e.g., `Start Server`), it processes immediately and continues looping.
- **Termination**: The thread periodically checks if it should terminate (e.g., using a shared atomic flag or channel).

---


# New Client & Client Requests

## Overview

This diagram represents the lifecycle of a **client connection** to the server, from initial connection and resource allocation, to command processing and final shutdown. It highlights the orchestration between the `Server`, `ClientPool`, and `DedicatedClient` threads, showcasing how each client is independently handled.

<br>
<br>
<img src="./diagrams/client-connection.svg" width="100%" height="700px">


## Components

- **Client**: A mobile or remote entity attempting to connect and communicate with the server.
- **Server**: The main coordination point responsible for managing new client connections.
- **ClientPool**: A component responsible for managing and launching `DedicatedClient` threads.
- **DedicatedClient**: A per-client handler that listens for and processes incoming commands.
- **Mobile Controller**: Virtual device that processes specific commands received from clients, applying changes to the OS (like mouse movement).


## Sequence Description

1. **Connection Establishment**  
   A client initiates a connection with the `Server`.

2. **Client Registration**  
   The `Server` forwards the connection to the `ClientPool`, which:
   - Launches a new `DedicatedClient` thread.
   - Returns a handle back to the `Server`.

3. **Initial Response**  
   The server responds to the client with:
   - The dynamically assigned communication port.
   - Server metadata such as operating system type.

4. **Command Loop**  
   The `DedicatedClient` enters a loop where it:
   - Waits for commands from the client.
   - Checks regularly whether an exit request has been issued by the server.
   - Parses the received bytes using the `Mobile Controller`.

5. **Command Handling**  
   - If the parsed command is valid but **not** a shutdown, it continues listening.
   - If a **shutdown command** is detected, it breaks the loop.

6. **Termination**  
   The `DedicatedClient`:
   - Releases any resources associated with the client session.
   - Exits the thread cleanly.

## Behavior Notes

- **Isolation**: Each client is handled in its own thread to allow concurrent communication.
- **Graceful Exit**: Shutdown is triggered either by receiving a shutdown command or an internal server request.
- **Polling Model**: Commands are processed in a loop, allowing periodic checks for termination signals.

---


# 3. Server Shutdown Procedure

<br>
<img src="./diagrams/server-shutdown.svg" width="100%" height="400px">

## Overview

This diagram outlines the coordinated **shutdown process** of the entire server system, initiated by the `Desktop App`. It highlights how the termination signal propagates through the various system components, leading to graceful resource cleanup and thread termination.


## Components

- **Desktop App**: The UI interface that initiates the shutdown command.
- **CommandListener**: The mediator that receives and processes desktop commands.
- **Server**: The central server process coordinating shutdown and communicating with the `ClientPool`.
- **ClientPool**: Manages all active client threads (`DedicatedClient` instances).
- **DedicatedClient**: Individual thread handling a single client session.


## Sequence Description

1. **Shutdown Triggered**  
   The `Desktop App` sends a **Shutdown** command to the `CommandListener`.

2. **Propagation of Termination Signal**  
   - `CommandListener` sets a termination signal internally.
   - It then notifies the `Server` to begin the shutdown sequence.
   - The `Server` acknowledges the request and propagates the shutdown to the `ClientPool`.

3. **Client Shutdown Handling**  
   - The `ClientPool` sets the termination flag for each active `DedicatedClient`.
   - It begins releasing all resources associated with client sessions.

4. **Dedicated Client Termination**  
   - Each `DedicatedClient` checks if an exit has been requested by the server.
   - Upon detecting the termination flag, they exit their command loop and terminate.

5. **Component Termination**  
   - Once the `Server`, `ClientPool`, and all `DedicatedClient` instances have completed termination:
     - `CommandListener` acknowledges completion.
     - `Desktop App` is notified that the server has been successfully terminated.


## Behavior Guarantees

- **Thread-safe Termination**: All termination signals are handled using synchronization mechanisms to avoid race conditions.
- **Graceful Cleanup**: Resources are explicitly released before components are terminated.
- **Confirmation Feedback**: The shutdown flow ends only after confirmation is received from all relevant components.

