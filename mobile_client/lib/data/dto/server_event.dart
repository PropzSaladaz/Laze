// ignore_for_file: constant_identifier_names

/// Events sent from the server to the mobile client
/// These are single-byte event codes that notify the client of server-side events
enum ServerEvent {
  /// Server is terminating this specific client
  clientTerminated(254),
  
  /// Server is shutting down completely
  serverShutdown(255);

  final int code;
  const ServerEvent(this.code);

  /// Parse a server event from a byte code
  static ServerEvent? fromByte(int byte) {
    for (var event in ServerEvent.values) {
      if (event.code == byte) {
        return event;
      }
    }
    return null;
  }

  /// Get a user-friendly description of the event
  String get description {
    switch (this) {
      case ServerEvent.clientTerminated:
        return "You were disconnected by the server";
      case ServerEvent.serverShutdown:
        return "Server has shut down";
    }
  }
}
