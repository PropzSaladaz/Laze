import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:laze/data/dto/server_event.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/data/repositories/server/pairing_repository.dart';
import 'package:laze/services/app_connection_status.dart';
import 'package:laze/services/auth_wire.dart';
import 'package:laze/services/udp_discovery.dart';

typedef CallbackSetStatus = void Function(AppConnectionStatus status);
typedef CallbackGetStatus = AppConnectionStatus Function();
typedef CallbackOnError = void Function(String message);
typedef CallbackOnServerEvent = void Function(ServerEvent event);
typedef CallbackOnConnectionLost = void Function();

class _Connection {
  final FramedSocket tcp;
  final SessionCrypto crypto;
  final PairedComputer computer;
  final String host, os;
  final int udpPort, generation;
  RawDatagramSocket? udp;
  _Connection(this.tcp, this.crypto, this.computer, this.host, this.os,
      this.udpPort, this.generation);
  void close() {
    udp?.close();
    tcp.close();
  }
}

class ServerConnector {
  static const serverPort = 7878;
  static final pairings = PairingRepository();
  static _Connection? _active;
  static final Set<FramedSocket> _pending = {};
  static int _generation = 0;
  static DeviceSettingsRepository? _deviceSettings;
  static late CallbackSetStatus setConnectionStatus;
  static late CallbackGetStatus getConnectionStatus;
  static late CallbackOnError onError;
  static late CallbackOnServerEvent onServerEvent;
  static late CallbackOnConnectionLost onConnectionLost;
  static String getServerOS() => _active?.os ?? 'unknown';
  static String? get activeServerId => _active?.computer.serverId;
  static void init(
      CallbackSetStatus setStatus,
      CallbackGetStatus getStatus,
      CallbackOnError error,
      CallbackOnServerEvent event,
      CallbackOnConnectionLost lost,
      {DeviceSettingsRepository? deviceSettings}) {
    setConnectionStatus = setStatus;
    getConnectionStatus = getStatus;
    onError = error;
    onServerEvent = event;
    onConnectionLost = lost;
    _deviceSettings = deviceSettings;
  }

  static bool _current(int generation) => generation == _generation;
  static void _closeResources() {
    _active?.close();
    _active = null;
    for (final socket in _pending.toList()) {
      socket.close();
    }
    _pending.clear();
  }

  static int _begin() {
    _generation++;
    _closeResources();
    setConnectionStatus(AppConnectionStatus.searching);
    return _generation;
  }

  static void cancelPendingConnection({bool notify = true}) {
    _generation++;
    _closeResources();
    if (notify) setConnectionStatus(AppConnectionStatus.notConnected);
  }

  static void disconnect() {
    _generation++;
    _closeResources();
    setConnectionStatus(AppConnectionStatus.notConnected);
  }

  static void sendInput(Uint8List payload) {
    final connection = _active;
    if (connection == null) return;
    try {
      connection.tcp.writeFrame(connection.crypto.clientRecord(payload));
    } catch (_) {
      _lost(connection);
    }
  }

  static void sendMotionInput(Uint8List payload) {
    final connection = _active;
    if (connection == null) return;
    if (connection.udp == null || connection.udpPort == 0) {
      sendInput(payload);
      return;
    }
    try {
      final packet = connection.crypto.clientRecord(payload, motion: true);
      connection.udp!
          .send(packet, InternetAddress(connection.host), connection.udpPort);
    } catch (_) {
      _lost(connection);
    }
  }

  static Future<void> sendAndDisconnect(Uint8List payload) async {
    final connection = _active;
    if (connection == null) {
      disconnect();
      return;
    }
    // Detach immediately so no UI/volume input can enter the closing session.
    _active = null;
    _generation++;
    connection.udp?.close();
    setConnectionStatus(AppConnectionStatus.notConnected);
    try {
      connection.tcp.writeFrame(connection.crypto.clientRecord(payload));
      await connection.tcp.socket.flush().timeout(const Duration(seconds: 2));
      await connection.tcp.socket.close().timeout(const Duration(seconds: 2));
    } catch (_) {
    } finally {
      connection.close();
    }
  }

  static void _lost(_Connection connection) {
    if (!identical(_active, connection) || !_current(connection.generation)) {
      return;
    }
    disconnect();
    onConnectionLost();
  }

  static Future<bool> pairWithQr(String code) async {
    final generation = _begin();
    try {
      await pairings.init();
      final computer = PairedComputer.fromQr(code.trim());
      if (!_current(generation)) return false;
      String? failureMessage;
      var reachedDesktop = false;
      void rememberFailure(String message, bool reached) {
        if (!reachedDesktop || reached) failureMessage = message;
        reachedDesktop = reachedDesktop || reached;
      }

      for (final host in computer.hosts) {
        if (!_current(generation)) return false;
        if (await _connect(computer, host, generation,
            onFailure: rememberFailure)) return true;
      }
      if (_current(generation)) {
        onError(failureMessage ??
            'Unable to pair. Keep the desktop server running and generate a fresh QR code.');
      }
    } on AuthException catch (error) {
      if (_current(generation)) onError(error.message);
    } catch (_) {
      if (_current(generation)) {
        onError(
            'Unable to complete secure pairing. Check your network and device secure storage.');
      }
    }
    if (_current(generation)) {
      setConnectionStatus(AppConnectionStatus.notConnected);
    }
    return false;
  }

  static Future<bool> findServer(String serverId) async {
    final generation = _begin();
    try {
      await pairings.init();
      if (!_current(generation)) return false;
      final computers = pairings.computers
          .where((computer) => computer.serverId == serverId)
          .toList();
      if (computers.isEmpty) {
        onError(
            'This computer is no longer paired. Choose another computer or pair it again.');
        setConnectionStatus(AppConnectionStatus.notConnected);
        return false;
      }
      final connectivity = await Connectivity().checkConnectivity();
      if (!_current(generation)) return false;
      if (!connectivity.contains(ConnectivityResult.wifi)) {
        onError('Connect to the same Wi-Fi network as your computer.');
        setConnectionStatus(AppConnectionStatus.notConnected);
        return false;
      }
      for (final computer in computers) {
        for (final host in computer.hosts) {
          if (!_current(generation)) return false;
          if (await _connect(computer, host, generation)) return true;
        }
      }
      final discoveries = await UdpDiscovery.discoverServers();
      for (final result in discoveries) {
        if (!_current(generation)) return false;
        for (final computer in computers.where(
            (v) => v.serverId == result.serverId && v.port == result.port)) {
          if (await _connect(computer, result.ip, generation)) return true;
        }
      }
      // A bounded /24 fallback around the phone's local interfaces replaces the old 65,280-host sweep.
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: false);
      final prefixes = <String>{};
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final octets = address.address.split('.').map(int.parse).toList();
          if (octets[0] == 10 ||
              (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
              (octets[0] == 192 && octets[1] == 168)) {
            prefixes.add(octets.take(3).join('.'));
          }
        }
      }
      for (final prefix in prefixes.take(2)) {
        for (var start = 1; start < 255; start += 32) {
          if (!_current(generation)) return false;
          // Authenticate candidates sequentially after the cheap bounded port probe; only one session is published.
          final hosts = await Future.wait(
              List.generate((255 - start).clamp(0, 32).toInt(), (i) async {
            final host = '$prefix.${start + i}';
            Socket? probe;
            try {
              probe = await Socket.connect(host, serverPort,
                  timeout: const Duration(milliseconds: 250));
              return host;
            } catch (_) {
              return null;
            } finally {
              probe?.destroy();
            }
          }));
          for (final host in hosts.whereType<String>()) {
            for (final computer
                in computers.where((v) => v.port == serverPort)) {
              if (!_current(generation)) return false;
              if (await _connect(computer, host, generation)) return true;
            }
          }
        }
      }
      if (_current(generation)) {
        onError(
            'Selected computer not found. Start Laze on that computer; pair again if its trusted-phone list was reset.');
      }
    } on AuthException catch (error) {
      if (_current(generation)) onError(error.message);
    } catch (_) {
      if (_current(generation)) {
        onError('Unable to connect securely to the computer.');
      }
    }
    if (_current(generation)) {
      setConnectionStatus(AppConnectionStatus.notConnected);
    }
    return false;
  }

  static Future<bool> _connect(
      PairedComputer computer, String host, int generation,
      {void Function(String message, bool reachedDesktop)? onFailure}) async {
    FramedSocket? wire;
    RawDatagramSocket? udp;
    var published = false;
    var phase = 'connect';
    try {
      final socket = await Socket.connect(host, computer.port,
          timeout: const Duration(milliseconds: 700));
      wire = FramedSocket(socket);
      _pending.add(wire);
      if (!_current(generation)) return false;
      phase = 'device';
      socket.setOption(SocketOption.tcpNoDelay, true);
      final deviceName = await _deviceSettings?.getDeviceName() ?? 'My phone';
      if (!_current(generation)) return false;
      final hello = <String, dynamic>{
        'version': 2,
        'server_id': computer.serverId,
        'device_id': computer.deviceId,
        'device_name': deviceName,
        'invite_id': computer.inviteId,
        'client_nonce': AuthWire.encode(AuthWire.randomBytes(32))
      };
      hello['proof'] = AuthWire.encode(
          AuthWire.tag(computer.secret, AuthWire.helloBytes(hello)));
      wire.writeFrame(utf8.encode(jsonEncode(hello)));
      phase = 'challenge';
      final challenge = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(await wire.readFrame())) as Map);
      final crypto =
          await SessionCrypto.establish(computer.secret, hello, challenge);
      if (!_current(generation)) return false;
      final finish = AuthWire.transcript(
          'laze-v2/client-finish', [AuthWire.challengeBytes(hello, challenge)]);
      phase = 'ready';
      wire.writeFrame(utf8.encode(jsonEncode(
          {'proof': AuthWire.encode(AuthWire.tag(computer.secret, finish))})));
      final ready = crypto.serverRecord(
          await wire.readFrame(max: AuthWire.overhead + AuthWire.maxInput));
      if (!_current(generation)) return false;
      if (ready.length != 1 || ready[0] != 253) {
        throw const AuthException(
            'The desktop ended the connection before pairing completed. Generate a fresh QR code.');
      }
      final trusted = computer.connectedAt(host);
      phase = 'storage';
      await pairings.save(trusted);
      if (!_current(generation)) return false;
      final port = challenge['udp_port'] as int;
      if (port != 0) {
        try {
          udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        } catch (_) {}
      }
      if (!_current(generation)) return false;
      final connection = _Connection(wire, crypto, trusted, host,
          challenge['server_os'] as String, port, generation)
        ..udp = udp;
      _pending.remove(wire);
      _active = connection;
      published = true;
      setConnectionStatus(AppConnectionStatus.connected);
      unawaited(_listen(connection));
      return true;
    } catch (error) {
      if (_current(generation) && onFailure != null) {
        final String message;
        if (error is AuthException) {
          message = error.message;
        } else if (phase == 'connect') {
          message =
              'Cannot reach the desktop. Connect both devices to the same network and allow Laze through Windows Firewall.';
        } else if (phase == 'storage') {
          message =
              'The desktop accepted pairing, but the phone could not save its credentials. Check phone secure storage and create a new QR code.';
        } else if (phase == 'device') {
          message =
              'Unable to read this phone\'s device name. Restart the phone app and try pairing again.';
        } else if (error is TimeoutException) {
          message =
              'The desktop did not finish authentication in time. Restart the desktop app and generate a fresh QR code.';
        } else if (phase == 'challenge') {
          message =
              'The desktop closed or returned an invalid pairing handshake. Restart the updated desktop app and generate a fresh QR code.';
        } else {
          message =
              'The desktop did not complete pairing. Generate a new QR code; check desktop credential storage if this repeats.';
        }
        onFailure(message, wire != null);
      }
      return false;
    } finally {
      if (!published) {
        udp?.close();
        wire?.close();
      }
      if (wire != null) _pending.remove(wire);
    }
  }

  static Future<void> _listen(_Connection connection) async {
    try {
      while (
          identical(_active, connection) && _current(connection.generation)) {
        final payload = connection.crypto.serverRecord(await connection.tcp
            .readFrame(
                max: AuthWire.overhead + AuthWire.maxInput,
                timeout: const Duration(days: 1)));
        if (payload.length != 1) {
          throw const AuthException('Invalid server event');
        }
        final event = ServerEvent.fromByte(payload[0]);
        if (event == null) throw const AuthException('Unknown server event');
        if (!identical(_active, connection) ||
            !_current(connection.generation)) {
          return;
        }
        disconnect();
        onServerEvent(event);
        if (event == ServerEvent.pairingRevoked) {
          try {
            await pairings.forget(connection.computer.serverId);
          } catch (_) {}
        }
        return;
      }
    } catch (_) {
      _lost(connection);
    }
  }

  static Future<void> forgetComputer(String serverId) async {
    // Cancel searches before changing trust so an in-flight handshake cannot save it again.
    if (_active == null || _active?.computer.serverId == serverId) disconnect();
    await pairings.forget(serverId);
  }
}
