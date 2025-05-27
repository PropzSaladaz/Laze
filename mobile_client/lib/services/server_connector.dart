// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mobile_client/data/dto/new_client_response.dart';
import 'package:mobile_client/services/connection_status.dart';

typedef CallbackSetStatus = void Function(String connectionStatus);
typedef CallbackGetStatus = String Function();
typedef CallbackOnError = void Function(String errorMessage);

class ServerConnector {
  // specifies server's operative system
  // used when sending commands - client only sends the command
  // for the specific server OS
  static late String _serverOS;

  static const String NOT_CONNECTED = "NOT CONNECTED";
  static const String CONNECTED = "CONNECTED";
  static const String SEARCHING = "SEARCHING...";

  static const serverPort = 7878;
  // specifies the amount of tries in a row done
  static const connectionBatchedTries = 40;
  static const connectionWaitTIme = 1000; // 1s

  static late Socket server;
  static Map<String, Future<TwoStepConnection>> connections = {};

  // Used to inform application of current connection status
  static late CallbackSetStatus setConnectionStatus;
  // connection status may change while we search for the server.
  // this can happen if the user cancels the search manually.
  static late CallbackGetStatus getConnectionStatus;

  static late CallbackOnError onError;

  static final Logger _log = Logger("ServerConnector");

  static String getServerOS() {
    return _serverOS;
  }

  // Sets the callback function to be used by the application that uses the server connector to update
  // its state upon server connector changes
  static void init(
    CallbackSetStatus setConnectionStatus,
    CallbackGetStatus getConnectionStatus,
    CallbackOnError onError,
  ) {
    ServerConnector.setConnectionStatus = setConnectionStatus;
    ServerConnector.getConnectionStatus = getConnectionStatus;
    ServerConnector.onError = onError;
  }

  static void disconnect() {
    setConnectionStatus(NOT_CONNECTED);
    server.close();
    server.destroy();
  }

  static void sendInput(Uint8List bytes) {
    server.add(bytes);
  }

  static Future<bool> _isWifiEnabled() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Searches for a server listening for requests in local network
  /// 
  static Future<bool> findServer() async {
    connections.clear();

    bool isWifiEnabled = await _isWifiEnabled();
    if (!isWifiEnabled) {
      String message = "You must be connected to a Wi-Fi network to search for servers.";
      _log.warning(message);
      onError(message);
      setConnectionStatus(NOT_CONNECTED);
      return false;
    }

    setConnectionStatus(SEARCHING);

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
        
        _log.config(testIp);

        connections[testIp.address] = _connectToHost(testIp.address);

        // waits for responses from X requests at a time
        if (i % connectionBatchedTries == 0) {
          ConnectionStatus status = await _waitForBatchedConnections();
          switch (status) {
            case ConnectionEstablished():
              // halt search
              setConnectionStatus(CONNECTED);
              return true;
            case ConnectionRejectedByServer(reason: var r):
              _log.warning("Connection rejected by server. Reason: $r");
              // halt search
              setConnectionStatus(NOT_CONNECTED);
              return false;
            default:
              // any other type -> continue searching
              break;
          } 
        }
      }
    }

    setConnectionStatus(NOT_CONNECTED);
    return false;
  }

  /// Waits for all requests currently in the map of sent requests
  /// Returns true if one of the requests was accepted at the server,
  /// and also
  static Future<ConnectionStatus> _waitForBatchedConnections() async {

    connection_search:
    for (var conn in connections.keys) {

      // will be in a loop trying to reach step 2 of communication.
      while(true) {
        var future = connections[conn];
        if (future != null) {
          // await connection from main server port
          TwoStepConnection connStep = await future;
          switch (connStep) {

            // connection from base server port
            case BasePortServerConnection(status: var status):
              switch (status) {

                case ConnectionEstablished():
                  _log.info("Successfully connected to server base port: "
                  "$conn\n Now waiting for dedicated port...");
                  // Connection to server was made
                  // now wait for connection to the new dedicated port
                  
                  // sleep is to give time for connection type to be updated by the async thread
                  // from `_connectToHost`
                  sleep(const Duration(microseconds: 2000));
                  break;

                case ConnectionRejectedByServer():
                  String error = "Server rejected communication - max clients reached";
                  _log.severe(error);
                  onError(error);
                  // halt batch search
                  return status;
                
                default:
                  // Even if there was some timeout, we accept as a non-error
                  // and continue searching
                  _log.info("Other");
                  continue connection_search; 
              }
            
            // connection from the dedicated port
            case DedicatedPortServerConnection(status: var status):
              switch (status) {

                case ConnectionEstablished():
                  _log.info("Successfully connected to server dedicated port ");
                  return status;

                default:
                  String error = "Unexpected connection status from dedicated port";
                  _log.severe(error);
                  onError(error);
                  return status;
              }
          }
        }
      }
    }
    // there was no connection established and no connections rejected
    return const ConnectionRefused();
  }


  static Future<BasePortServerConnection> _connectToHost(String ipAddress) async {
    try {
      // try connecting to base port
      var socket = await Socket.connect(ipAddress, serverPort,
          timeout: const Duration(milliseconds: connectionWaitTIme));

      /// This is non-blocking - we will set this async function to
      /// whenever a message is received by the socket. Then we jump to the
      /// return ConnectionEstablished to indicate we established connection 
      /// with server base port
      socket.listen((jsonBytes) async {
        // upon receiving the new dedicated port
        var json = jsonDecode(utf8.decode(jsonBytes));
        NewClientResponse resp = NewClientResponse.fromJson(json);
        
        // check for error from server
        if (resp.port == -1) {
          connections[ipAddress] = Future.value(
            const BasePortServerConnection(
              ConnectionRejectedByServer("Server reached max clients!")
            )
          );
          return;
        }

        // try connecting to dedicated port
        var newSocket = await Socket.connect(ipAddress, resp.port);
        server = newSocket;
        // Update the future
        connections[ipAddress] = Future.value(
            const DedicatedPortServerConnection(
              ConnectionEstablished()
            )
          );
        _serverOS = resp.server_os;
        // !IMPORTANT! this is set to force all data to be sent in a different tcp packet
        server.setOption(SocketOption.tcpNoDelay, true);
      }, onDone: () => socket.destroy());

      return const BasePortServerConnection(ConnectionEstablished());

    } catch (e) {
      // Due to socket timeout
      _log.warning("$ipAddress -> !!NOT CONNECTED: $e");
      return const BasePortServerConnection(ConnectionRefused());
    }
  }

  static int _ipToInt(String address) {
    var parts = address.split('.').map(int.parse).toList();
    return (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + (parts[3]);
  }

  static InternetAddress _intToIp(int ip) {
    return InternetAddress([
      ip >> 24,
      (ip >> 16) & 0xFF,
      (ip >> 8) & 0xFF,
      ip & 0xFF,
    ].join("."));
  }
}
