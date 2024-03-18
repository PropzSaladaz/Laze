import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mobile_client/client/dto/new_client_response.dart';

import 'dto/input.dart';

typedef Callback = void Function(String connectionStatus);

class ServerConnector {
  static const String NOT_CONNECTED = "NOT CONNECTED";
  static const String CONNECTED = "CONNECTED";

  static const serverPort = 7878;
  late Socket server;
  Map<String, Future<bool>> connections = {};
  // Used to inform application of current connection status
  Callback setConnectionStatus;

  ServerConnector({required this.setConnectionStatus});

  void disconnect() {
    setConnectionStatus(NOT_CONNECTED);
    server.close();
    server.destroy();
  }

  void sendInput(Input input) {
    var json = jsonEncode(input.toJson());
    server.add(utf8.encode(json));
  }

  Future<bool> findServer() async {
    int baseIp = _ipToInt("192.168.1.0");
    var subnetMask = 24;
    var totalLocalIpSuffixes = pow(2, 32 - subnetMask).toInt();

    for (int i = 0; i < totalLocalIpSuffixes; i++) {
      var testIp = _intToIp(baseIp | i);
      connections[testIp.address] = _connectToHost(testIp.address);
    }

    for (var conn in connections.keys) {
      var future = connections[conn];
      if (future != null && await future) {
        // Connection to server was made
        // now wait for connection to the new dedicated port
        sleep(const Duration(microseconds: 350));
        // the new connection replaced the old one
        var newConn = connections[conn];
        if (newConn != null && await newConn) {
          return true;
        }
      }
    }
    setConnectionStatus(NOT_CONNECTED);
    return false;
  }

  Future<bool> _connectToHost(String ipAddress) async {
    try {
      var socket = await Socket.connect(ipAddress, serverPort,
          timeout: const Duration(milliseconds: 500));

      socket.listen((jsonBytes) async {
        // upon receiving the new dedicated port
        var json = jsonDecode(utf8.decode(jsonBytes));
        NewClientResponse resp = NewClientResponse.fromJson(json);
        // try connecting to it
        var newSocket = await Socket.connect(ipAddress, resp.port);
        server = newSocket;
        setConnectionStatus(CONNECTED);
      }, onDone: () => socket.destroy());
      return true;
    } catch (e) {
      setConnectionStatus(NOT_CONNECTED);
      return false;
    }
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
