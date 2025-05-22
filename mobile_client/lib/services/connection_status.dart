/// Connection status
sealed class ConnectionStatus {
  const ConnectionStatus();
}

/// Represents successful connection status
final class ConnectionEstablished extends ConnectionStatus {
  const ConnectionEstablished();
}

/// Represents that connection was refused 
/// Usually due to time out.
/// This is an expected refusal. Not treated as error
final class ConnectionRefused extends ConnectionStatus {
  const ConnectionRefused();
}

/// Represents that connection was established with server,
/// but server sent error message, and rejected the client
final class ConnectionRejectedByServer extends ConnectionStatus {
  final String reason;
  const ConnectionRejectedByServer(this.reason);
}


/// 2-step connection with server
sealed class TwoStepConnection {
  final ConnectionStatus status;
  const TwoStepConnection(this.status);
}

final class BasePortServerConnection extends TwoStepConnection {
  const BasePortServerConnection(super.status);
}

final class DedicatedPortServerConnection extends TwoStepConnection {
  const DedicatedPortServerConnection(super.status);
}
