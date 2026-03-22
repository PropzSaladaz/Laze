import 'package:flutter/material.dart';
import 'package:laze/data/dto/server_event.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/services/app_connection_status.dart';
import 'package:laze/services/server_connector.dart';
import 'package:laze/services/volume_service.dart';

class AppServiceWrapper extends ChangeNotifier {
  final VolumeService _volumeService = VolumeService();
  final DeviceSettingsRepository _deviceSettings;

  AppConnectionStatus connectionStatus = AppConnectionStatus.notConnected;
  String? errorMessage;

  bool _isInit = false;

  AppServiceWrapper({required DeviceSettingsRepository deviceSettings})
      : _deviceSettings = deviceSettings {
    _init();
  }

  void _init() {
    if (_isInit) return;
    _isInit = true;

    ServerConnector.init(
      _setConnectionState,
      _getConnectionState,
      _onError,
      _onServerEvent,
      deviceSettings: _deviceSettings,
    );

    _volumeService.start(ServerConnector.sendInput);
  }

  void _setConnectionState(AppConnectionStatus state) {
    connectionStatus = state;
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
    _volumeService.setDisconnected();
    ServerConnector.sendInput(Input.disconnect());
    ServerConnector.disconnect();
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  void turnOffPc() {
    _volumeService.setDisconnected();
    ServerConnector.sendInput(Input.shutdown());
    ServerConnector.disconnect();
    _setConnectionState(AppConnectionStatus.notConnected);
  }

  @override
  void dispose() {
    _volumeService.dispose();
    super.dispose();
  }
}
