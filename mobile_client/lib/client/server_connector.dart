import 'dart:io';
import 'dart:math';

enum ConnStatus { UNDEFINED, NOT_LISTENING, CONNECTED }

class Connection {
  late Future<Null> connection;
  ConnStatus status = ConnStatus.UNDEFINED;
}

class ServerConnector {
  static const serverPort = 7878;
  late Socket server;

  ServerConnector() {
    findServer();
  }

  Future<bool> findServer() async {
    int baseIp = _ipToInt("192.168.1.0");
    var subnetMask = 24;
    var totalLocalIpSuffixes = pow(2, 32 - subnetMask).toInt();

    final List<Connection> connections =
        List.filled(totalLocalIpSuffixes, Connection());

    for (int i = 0; i < totalLocalIpSuffixes; i++) {
      print("init status: ${connections[i].status}");
      var testIp = _intToIp(baseIp | i);
      connections[i].connection =
          Socket.connect(testIp.address, serverPort).then((socket) {
        connections[i].status = ConnStatus.CONNECTED;
        print("Changing status: ${i} to ${connections[i].status}");
        socket.listen(
            (event) => print("Received: ${testIp.address} - ${event}"),
            onDone: () => socket.destroy());
        server = socket;
      }).catchError((error) {
        print("Error in connection with ${i} ${testIp.address} - ${error}");
        connections[i].status = ConnStatus.NOT_LISTENING;
      }); // ignore
    }

    for (int i = 0; i < totalLocalIpSuffixes; i++) {
      await connections[i].connection;
      print(
          "testing ${i} ${connections[i].connection} - ${connections[i].status}");
      if (connections[i].status == ConnStatus.CONNECTED) {
        print("Connected");
        return true; // connected
      }
    }
    return false; // no server listening
  }

  int _ipToInt(String address) {
    var parts = address.split('.').map(int.parse).toList();
    return (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + (parts[3]);
  }

  InternetAddress _intToIp(int ip) {
    return InternetAddress([
      ip >> 24,
      (ip >> 16) & 0xFF,
      (ip >> 8) & 0xFF,
      ip & 0xFF,
    ].join("."));
  }
}
