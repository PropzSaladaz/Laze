// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mobile_client/client/dto/new_client_response.dart';

import 'dto/input.dart';

typedef CallbackSetStatus = void Function(String connectionStatus);
typedef CallbackGetStatus = String Function();

class ServerConnector {
  static const String NOT_CONNECTED = "NOT CONNECTED";
  static const String CONNECTED = "CONNECTED";
  static const String SEARCHING = "SEARCHING...";

  static const serverPort = 7878;
  // specified the amount of tries in a row done
  static const connectionBatchedTries = 40;
  static const connectionWaitTIme = 1000; // 1s

  late Socket server;
  Map<String, Future<bool>> connections = {};

  // Used to inform application of current connection status
  CallbackSetStatus setConnectionStatus;
  // connection status may change while we search for the server.
  // this can happen if the user cancels the search manually.
  CallbackGetStatus getConnectionStatus;

  ServerConnector({
    required this.setConnectionStatus,
    required this.getConnectionStatus,
    });

  void disconnect() {
    setConnectionStatus(NOT_CONNECTED);
    server.close();
    server.destroy();
  }

  void sendInput(Uint8List bytes) {
    server.add(bytes);
  }

  Future<bool> findServer() async {
    setConnectionStatus(ServerConnector.SEARCHING);

    int n_LANs = 255;
    for (int lan = 0; lan < n_LANs; lan++) {
      int baseIp = _ipToInt("192.168.$lan.0");
      var subnetMask = 24;
      var totalLocalIpSuffixes = pow(2, 32 - subnetMask).toInt();

      for (int i = 0; i < totalLocalIpSuffixes; i++) {
        // if status has been changed - return right away & cancel further searching
        if (getConnectionStatus() != SEARCHING) {
          setConnectionStatus(NOT_CONNECTED);
          return false;
        }

        var testIp = _intToIp(baseIp | i);
        print(testIp);
        connections[testIp.address] = _connectToHost(testIp.address);

        // waits for responses from X requests at a time
        if (i % connectionBatchedTries == 0 && 
            await _waitForBatchedConnections()) {
          return true;
        }
      }
    }

    setConnectionStatus(NOT_CONNECTED);
    return false;
  }

  /// Waits for all requests currently in the map of sent requests
  /// Returns true if one of the requests was accepted at the server, 
  /// and also
  Future<bool> _waitForBatchedConnections() async {
    for (var conn in connections.keys) {
      var future = connections[conn];
      if (future != null && await future) {
        print("Connection Successful with $conn");
        // Connection to server was made
        // now wait for connection to the new dedicated port
        sleep(const Duration(microseconds: 2000));
        // the new connection replaced the old one
        var newConn = connections[conn];
        if (newConn != null && await newConn) {
          print("Connected to the server!");
          setConnectionStatus(CONNECTED);
          connections.clear();
          return true;
        }
      }
    }
    connections.clear();
    return false;
  }

  Future<bool> _connectToHost(String ipAddress) async {
    try {
      var socket = await Socket.connect(ipAddress, serverPort,
          timeout: const Duration(milliseconds: connectionWaitTIme));
      print("CONNECTED");
      socket.listen((jsonBytes) async {
        // upon receiving the new dedicated port
        var json = jsonDecode(utf8.decode(jsonBytes));
        NewClientResponse resp = NewClientResponse.fromJson(json);
        // try connecting to it
        var newSocket = await Socket.connect(ipAddress, resp.port);
        server = newSocket;
        // !IMPORTANT! this is set to force all data to be sent in a different tcp packet
        server.setOption(SocketOption.tcpNoDelay, true);
      }, onDone: () => socket.destroy());

      return true;
    } catch (e) {
      print("$ipAddress -> !!NOT CONNECTED: $e");
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
