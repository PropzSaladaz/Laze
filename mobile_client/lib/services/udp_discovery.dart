import 'dart:async';
import 'dart:io';
import 'dart:convert';

class DiscoveryResult {
  final String ip, serverId;
  final int port;
  DiscoveryResult(
      {required this.ip, required this.port, required this.serverId});
}

class UdpDiscovery {
  static const discoveryPort = 7877;
  static Future<List<DiscoveryResult>> discoverServers() async {
    RawDatagramSocket? socket;
    final results = <String, DiscoveryResult>{};
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      final done = Completer<void>();
      final timer = Timer(const Duration(milliseconds: 1500), () {
        if (!done.isCompleted) done.complete();
      });
      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        Datagram? datagram;
        while ((datagram = socket!.receive()) != null) {
          try {
            final parts = utf8.decode(datagram!.data).split(':');
            if (parts.length != 5 ||
                parts[0] != 'MOBILE_CONTROLLER' ||
                parts[4] != '2') {
              continue;
            }
            final port = int.tryParse(parts[2]);
            if (port == null ||
                port < 1 ||
                port > 65535 ||
                !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(parts[3])) {
              continue;
            }
            // Discovery is only an address hint; trust is checked in the subsequent mutual handshake.
            final result = DiscoveryResult(
                ip: datagram.address.address, port: port, serverId: parts[3]);
            results['${result.serverId}:${result.ip}:${result.port}'] = result;
          } catch (_) {}
        }
      }, onError: (_) {
        if (!done.isCompleted) done.complete();
      });
      socket.send(utf8.encode('DISCOVER_MOBILE_CONTROLLER'),
          InternetAddress('255.255.255.255'), discoveryPort);
      await done.future;
      timer.cancel();
      await subscription.cancel();
    } catch (_) {
    } finally {
      socket?.close();
    }
    return results.values.toList();
  }
}
