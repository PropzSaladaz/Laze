import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';

/// UDP Discovery Service for finding the server on local network
class UdpDiscovery {
  static const int discoveryPort = 7877;
  static const String discoveryRequest = 'DISCOVER_MOBILE_CONTROLLER';
  static const String responsePrefix = 'MOBILE_CONTROLLER';
  static const Duration timeout = Duration(milliseconds: 1500);

  static final Logger _log = Logger('UdpDiscovery');

  /// Discover server using UDP broadcast
  /// Returns server IP and port if found, null otherwise
  static Future<DiscoveryResult?> discoverServer() async {
    RawDatagramSocket? socket;
    
    try {
      // Create UDP socket
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Let OS assign a port
      );
      socket.broadcastEnabled = true;

      _log.info('Starting UDP discovery broadcast...');

      // Send discovery broadcast
      final data = Uint8List.fromList(discoveryRequest.codeUnits);
      socket.send(
        data,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      // Wait for response with timeout
      final completer = Completer<DiscoveryResult?>();
      Timer? timeoutTimer;

      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _log.info('Discovery timeout - no server found');
          completer.complete(null);
        }
      });

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            _log.info('Received response: $response from ${datagram.address.address}');

            // Parse response: "MOBILE_CONTROLLER:IP:PORT"
            final result = _parseResponse(response);
            if (result != null && !completer.isCompleted) {
              timeoutTimer?.cancel();
              completer.complete(result);
            }
          }
        }
      });

      return await completer.future;
    } catch (e) {
      _log.severe('UDP discovery error: $e');
      return null;
    } finally {
      socket?.close();
    }
  }

  /// Parse server response
  static DiscoveryResult? _parseResponse(String response) {
    if (!response.startsWith(responsePrefix)) {
      return null;
    }

    final parts = response.split(':');
    if (parts.length != 3) {
      _log.warning('Invalid response format: $response');
      return null;
    }

    final ip = parts[1];
    final port = int.tryParse(parts[2]);

    if (port == null) {
      _log.warning('Invalid port in response: $response');
      return null;
    }

    return DiscoveryResult(ip: ip, port: port);
  }
}

/// Result of UDP discovery
class DiscoveryResult {
  final String ip;
  final int port;

  DiscoveryResult({required this.ip, required this.port});

  @override
  String toString() => 'DiscoveryResult($ip:$port)';
}
