// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mobile_client/data/dto/new_client_response.dart';
import 'package:mobile_client/data/dto/client_info_request.dart';
import 'package:mobile_client/data/dto/server_event.dart';
import 'package:mobile_client/data/repositories/server/server_cache_repository.dart';
import 'package:mobile_client/data/repositories/device/device_settings_repository.dart';
import 'package:mobile_client/services/connection_status.dart';
import 'package:mobile_client/services/udp_discovery.dart';

typedef CallbackSetStatus = void Function(String connectionStatus);
typedef CallbackGetStatus = String Function();
typedef CallbackOnError = void Function(String errorMessage);
typedef CallbackOnServerEvent = void Function(ServerEvent event);

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

  // Subscription for server event listener
  static StreamSubscription<Uint8List>? _serverEventSubscription;

  // Server cache for fast reconnection
  static final ServerCacheRepository _serverCache = ServerCacheRepository();
  static bool _cacheInitialized = false;

  // Device settings for sending device name
  static DeviceSettingsRepository? _deviceSettings;

  // Used to inform application of current connection status
  static late CallbackSetStatus setConnectionStatus;
  // connection status may change while we search for the server.
  // this can happen if the user cancels the search manually.
  static late CallbackGetStatus getConnectionStatus;

  static late CallbackOnError onError;
  
  static late CallbackOnServerEvent onServerEvent;

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
    CallbackOnServerEvent onServerEvent,
    {DeviceSettingsRepository? deviceSettings}
  ) {
    ServerConnector.setConnectionStatus = setConnectionStatus;
    ServerConnector.getConnectionStatus = getConnectionStatus;
    ServerConnector.onError = onError;
    ServerConnector.onServerEvent = onServerEvent;
    _deviceSettings = deviceSettings;
  }

  static void disconnect() {
    setConnectionStatus(NOT_CONNECTED);
    // Cancel the event listener subscription
    _serverEventSubscription?.cancel();
    _serverEventSubscription = null;
    server.close();
    server.destroy();
  }

  static void sendInput(Uint8List bytes) {
    server.add(bytes);
  }

  /// Send device information to the server
  static Future<void> _sendDeviceInfo() async {
    if (_deviceSettings != null) {
      try {
        final deviceName = await _deviceSettings!.getDeviceName();
        final clientInfo = ClientInfoRequest(deviceName: deviceName);
        final json = jsonEncode(clientInfo.toJson());
        final bytes = utf8.encode(json);
        server.add(bytes);
        _log.info("Sent device info to server: $deviceName");
      } catch (e) {
        _log.warning("Failed to send device info: $e");
      }
    }
  }

  static Future<bool> _isWifiEnabled() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Initialize server cache
  static Future<void> _initCache() async {
    if (!_cacheInitialized) {
      await _serverCache.init();
      _cacheInitialized = true;
    }
  }

  /// Searches for a server listening for requests in local network
  /// Uses fast discovery: cached IP -> UDP broadcast -> IP sweep
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

    // Initialize cache
    await _initCache();

    // Step 1: Try cached IPs first (instant if valid)
    _log.info("Step 1: Trying cached server IPs...");
    if (await _tryConnectToCachedServers()) {
      return true;
    }

    // Check if user cancelled
    if (getConnectionStatus() != SEARCHING) {
      setConnectionStatus(NOT_CONNECTED);
      return false;
    }

    // Step 2: Try UDP broadcast discovery (~100ms)
    _log.info("Step 2: Trying UDP broadcast discovery...");
    if (await _tryUdpDiscovery()) {
      return true;
    }

    // Check if user cancelled
    if (getConnectionStatus() != SEARCHING) {
      setConnectionStatus(NOT_CONNECTED);
      return false;
    }

    // Step 3: Fallback to IP sweep (slow, but guaranteed to work)
    _log.info("Step 3: Falling back to IP sweep...");
    return await _ipSweepDiscovery();
  }

  /// Try to connect to cached server IPs
  static Future<bool> _tryConnectToCachedServers() async {
    final cachedServers = _serverCache.getCachedServers();
    if (cachedServers.isEmpty) {
      _log.info("No cached servers found");
      return false;
    }

    _log.info("Found ${cachedServers.length} cached server(s)");

    for (final cached in cachedServers) {
      _log.info("Trying cached server: ${cached.ip}:${cached.port}");
      
      final result = await _tryDirectConnection(cached.ip, cached.port);
      if (result) {
        _log.info("Connected to cached server: ${cached.ip}");
        setConnectionStatus(CONNECTED);
        return true;
      }
    }

    _log.info("No cached servers responded");
    return false;
  }

  /// Try UDP broadcast discovery
  static Future<bool> _tryUdpDiscovery() async {
    final result = await UdpDiscovery.discoverServer();
    
    if (result == null) {
      _log.info("UDP discovery: no server found");
      return false;
    }

    _log.info("UDP discovery found server at ${result.ip}:${result.port}");
    
    final connected = await _tryDirectConnection(result.ip, result.port);
    if (connected) {
      setConnectionStatus(CONNECTED);
      return true;
    }

    return false;
  }

  /// Try to connect directly to a known IP/port
  static Future<bool> _tryDirectConnection(String ip, int port) async {
    try {
      // Connect to base port first
      final socket = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 500));
      socket.setOption(SocketOption.tcpNoDelay, true);

      _log.info("Connected to $ip:$port, waiting for dedicated port...");

      // Wait for server response with dedicated port
      final response = await socket.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) {
          _log.warning("Timeout waiting for dedicated port from $ip");
          sink.close();
        },
      ).first;

      final json = jsonDecode(utf8.decode(response));
      final newClientResp = NewClientResponse.fromJson(json);

      if (newClientResp.port == -1) {
        _log.warning("Server rejected connection: max clients");
        socket.destroy();
        return false;
      }

      _log.info("Received dedicated port: ${newClientResp.port}");

      // Connect to dedicated port
      final dedicatedSocket = await Socket.connect(ip, newClientResp.port,
          timeout: const Duration(seconds: 2));
      dedicatedSocket.setOption(SocketOption.tcpNoDelay, true);

      server = dedicatedSocket;
      _serverOS = newClientResp.server_os;

      // Send device info as first message
      await _sendDeviceInfo();

      // Start listening for server events
      _startServerEventListener();

      // Cache this successful connection
      await _serverCache.cacheServer(ip, port);

      socket.destroy();
      _log.info("Successfully connected to $ip:${newClientResp.port}");
      return true;
    } catch (e) {
      _log.warning("Direct connection to $ip:$port failed: $e");
      return false;
    }
  }

  /// Fallback: IP sweep discovery (slow)
  static Future<bool> _ipSweepDiscovery() async {
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
                  await Future.delayed(const Duration(seconds: 2));
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
                  // Cache this connection for future
                  await _serverCache.cacheServer(conn, serverPort);
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
      socket.setOption(SocketOption.tcpNoDelay, true);

      _log.info("Awaiting for $ipAddress:$serverPort");

      /// This is non-blocking - we will set this async function to
      /// whenever a message is received by the socket. Then we jump to the
      /// return ConnectionEstablished to indicate we established connection 
      /// with server base port
      int activeHandlers = 0;
      socket.listen((jsonBytes) async {
        // register async reader -> used to avoid destroying the socket while there is still
        // a handler reading the data
        activeHandlers++;
        _log.info("Client received what was supposed to be a JSON response with dedicated port");
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

        _log.info("Received new dedicated port: ${resp.port} from server");
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
        
        // Send device info as first message
        await _sendDeviceInfo();
        
        // Start listening for server events
        _startServerEventListener();
        
        activeHandlers--;
      
      }, onDone: () async {
        while (activeHandlers > 0) {
          _log.info("Still active listeners $ipAddress");
          await Future.delayed(const Duration(milliseconds: 100));
        } 
        socket.destroy();
        _log.info("Socket destroyed for $ipAddress");
      });

      return const BasePortServerConnection(ConnectionEstablished());

    } catch (e) {
      // Due to socket timeout
      _log.warning("$ipAddress -> !!NOT CONNECTED: $e");
      return const BasePortServerConnection(ConnectionRefused());
    }
  }

  Future<void> _handleNewClientResponse() async {

  }

  /// Starts listening for server events on the established connection
  /// This listens for single-byte event codes sent by the server
  static void _startServerEventListener() {
    // Cancel any existing subscription to avoid multiple listeners
    _serverEventSubscription?.cancel();
    
    _serverEventSubscription = server.listen(
      (Uint8List data) {
        // Check if this is a server event (single byte with high value)
        if (data.length == 1) {
          final eventByte = data[0];
          final event = ServerEvent.fromByte(eventByte);
          
          if (event != null) {
            _log.info("Received server event: ${event.name}");
            onServerEvent(event);
          }
        }
        // Regular data packets would be handled here if needed
        // Currently the client only sends data to server, not receives
      },
      onError: (error) {
        _log.severe("Error in server event listener: $error");
        onError("Connection error: $error");
      },
      onDone: () {
        _log.info("Server connection closed");
        // Connection was closed by server
        setConnectionStatus(NOT_CONNECTED);
      },
      cancelOnError: false,
    );
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
