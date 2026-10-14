import 'dart:async';
import 'package:flutter/material.dart';
import 'package:laze/data/dto/server_event.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/services/app_connection_status.dart';
import 'package:laze/services/server_connector.dart';
import 'package:laze/services/volume_service.dart';

/// Central service layer between the UI and the underlying connection/input
/// services. Manages connection state, error messages, and volume input,
/// and exposes actions (connect, disconnect, etc.) consumed by the UI via
/// [ChangeNotifier]. Also observes app lifecycle events to auto-reconnect
/// after the screen is unlocked.
class AppServiceWrapper extends ChangeNotifier with WidgetsBindingObserver {
  final VolumeService _volumeService = VolumeService();
  final DeviceSettingsRepository _deviceSettings;

  AppConnectionStatus connectionStatus = AppConnectionStatus.notConnected;
  String? errorMessage;

  bool _isInit = false;
  int _operation = 0;

  // Tracks whether the user had an active connection — used to auto-reconnect
  // when the app resumes after the screen was locked.
  bool _wasConnected = false;
  String? _targetServerId;

  // Latest app lifecycle state. Used to decide whether a dropped connection
  // can be reconnected immediately (foreground) or should wait for resume
  // (screen off / backgrounded).
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  AppServiceWrapper({required DeviceSettingsRepository deviceSettings})
      : _deviceSettings = deviceSettings {
    _init();
  }

  void _init() {
    if (_isInit) return;
    _isInit = true;

    WidgetsBinding.instance.addObserver(this);

    ServerConnector.init(
      _setConnectionState,
      _getConnectionState,
      _onError,
      _onServerEvent,
      _onConnectionLost,
      deviceSettings: _deviceSettings,
    );

    _volumeService.start(ServerConnector.sendInput);
  }

  // Triggered by the OS whenever the app transitions between lifecycle states
  // (foreground, background, paused, etc.). On resume, if the connection was
  // dropped while the screen was locked (status notConnected but _wasConnected
  // is still true), kick off a reconnect — cached IPs make this nearly instant.
  // On pause/inactive we proactively close the volume gate so that any volume
  // events fired before the TCP drop is detected cannot reach a dead socket.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _volumeService.setDisconnected();
        if (_wasConnected &&
            connectionStatus == AppConnectionStatus.connected) {
          ServerConnector.disconnect();
        }
      case AppLifecycleState.resumed:
        if (_wasConnected &&
            connectionStatus == AppConnectionStatus.notConnected) {
          connect();
        }
      default:
        break;
    }
  }

  void _setConnectionState(AppConnectionStatus state) {
    connectionStatus = state;
    // Close the volume gate whenever we're not actively connected so that
    // hardware-volume events cannot reach a closed/non-existent TCP socket.
    if (state != AppConnectionStatus.connected) {
      _volumeService.setDisconnected();
    }
    notifyListeners();
  }

  AppConnectionStatus _getConnectionState() {
    return connectionStatus;
  }

  void _onError(String error) {
    errorMessage = error;
    notifyListeners();
  }

  // Called when an established connection drops unexpectedly (screen lock,
  // transient network loss). This is recoverable and is deliberately NOT shown
  // as an error. If the app is in the foreground, reconnect right away;
  // otherwise (screen off / backgrounded) just mark it disconnected and let
  // the resume handler reconnect when the screen comes back on.
  void _onConnectionLost() {
    _volumeService.setDisconnected();

    // onError and onDone can both fire for a single drop — ignore the second
    // one if a reconnect is already underway.
    if (connectionStatus == AppConnectionStatus.searching) return;

    if (_wasConnected && _lifecycleState == AppLifecycleState.resumed) {
      connect();
    } else {
      connectionStatus = AppConnectionStatus.notConnected;
      notifyListeners();
    }
  }

  void _onServerEvent(ServerEvent event) {
    _operation++;
    // Server intentionally ended the session — do not auto-reconnect.
    _wasConnected = false;
    _volumeService.setDisconnected();
    connectionStatus = AppConnectionStatus.notConnected;
    errorMessage = event.description;
    notifyListeners();
  }

  /// Reads the pending error message and clears it in a single step, without
  /// notifying listeners. Used by the UI to show an error exactly once: because
  /// the message is consumed on the first rebuild that observes it, the many
  /// rapid rebuilds that follow a socket drop (cleanup, status change, error,
  /// auto-reconnect) no longer each re-queue an identical snackbar.
  String? consumeError() {
    final error = errorMessage;
    errorMessage = null;
    return error;
  }

  Future<bool> connect() async {
    final serverId = _targetServerId;
    if (serverId == null) {
      _onError('Choose a paired computer on Home to connect.');
      return false;
    }
    final operation = ++_operation;
    _setConnectionState(AppConnectionStatus.searching);
    final success = await ServerConnector.findServer(serverId);
    if (operation != _operation) return false;
    if (success) {
      _targetServerId = ServerConnector.activeServerId;
      _wasConnected = true;
      _volumeService.setConnected();
      _setConnectionState(AppConnectionStatus.connected);
    } else {
      _setConnectionState(AppConnectionStatus.notConnected);
    }
    return success;
  }

  Future<bool> connectToComputer(String serverId) {
    // A manual selection starts a new connection intent. Only reconnect it
    // automatically after it has connected successfully.
    _wasConnected = false;
    _targetServerId = serverId;
    return connect();
  }

  Future<bool> pairWithQr(String code) async {
    final operation = ++_operation;
    _wasConnected = false;
    errorMessage = null;
    final success = await ServerConnector.pairWithQr(code);
    if (operation != _operation) return false;
    if (success) {
      _targetServerId = ServerConnector.activeServerId;
      _wasConnected = true;
      _volumeService.setConnected();
      _setConnectionState(AppConnectionStatus.connected);
    } else {
      _setConnectionState(AppConnectionStatus.notConnected);
    }
    return success;
  }

  void cancelSearch() {
    _operation++;
    _wasConnected = false;
    ServerConnector.cancelPendingConnection();
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  Future<void> forgetComputer(String serverId) async {
    if (_targetServerId == serverId) _targetServerId = null;
    if (ServerConnector.activeServerId == null ||
        ServerConnector.activeServerId == serverId) {
      _operation++;
      _wasConnected = false;
      _volumeService.setDisconnected();
    }
    await ServerConnector.forgetComputer(serverId);
  }

  void disconnect() {
    _operation++;
    // User explicitly disconnected — do not auto-reconnect.
    _wasConnected = false;
    _volumeService.setDisconnected();
    unawaited(ServerConnector.sendAndDisconnect(Input.disconnect()));
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  void turnOffPc() {
    _operation++;
    // User explicitly shut down — do not auto-reconnect.
    _wasConnected = false;
    _volumeService.setDisconnected();
    unawaited(ServerConnector.sendAndDisconnect(Input.shutdown()));
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _volumeService.dispose();
    super.dispose();
  }
}
