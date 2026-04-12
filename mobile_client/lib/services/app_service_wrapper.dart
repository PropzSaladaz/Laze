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

  // Tracks whether the user had an active connection — used to auto-reconnect
  // when the app resumes after the screen was locked.
  bool _wasConnected = false;

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
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _volumeService.setDisconnected();
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

  void _onServerEvent(ServerEvent event) {
    // Server intentionally ended the session — do not auto-reconnect.
    _wasConnected = false;
    _volumeService.setDisconnected();
    connectionStatus = AppConnectionStatus.notConnected;
    errorMessage = event.description;
    notifyListeners();
  }

  void dismissError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> connect() async {
    _setConnectionState(AppConnectionStatus.searching);
    final success = await ServerConnector.findServer();
    if (success) {
      _wasConnected = true;
      _volumeService.setConnected();
      _setConnectionState(AppConnectionStatus.connected);
    } else {
      _setConnectionState(AppConnectionStatus.notConnected);
    }
    return success;
  }

  void cancelSearch() {
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  void disconnect() {
    // User explicitly disconnected — do not auto-reconnect.
    _wasConnected = false;
    _volumeService.setDisconnected();
    ServerConnector.sendInput(Input.disconnect());
    ServerConnector.disconnect();
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  void turnOffPc() {
    // User explicitly shut down — do not auto-reconnect.
    _wasConnected = false;
    _volumeService.setDisconnected();
    ServerConnector.sendInput(Input.shutdown());
    ServerConnector.disconnect();
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _volumeService.dispose();
    super.dispose();
  }
}
