import 'package:flutter/material.dart';
import 'package:laze/data/dto/server_event.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/services/server_connector.dart';
import 'package:laze/services/volume_service.dart';

class AppServiceWrapper extends ChangeNotifier {
  final VolumeService _volumeService = VolumeService();
  final DeviceSettingsRepository _deviceSettings;

  String connectionStatus = ServerConnector.NOT_CONNECTED;
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

  void _setConnectionState(String state) {
    connectionStatus = state;
    notifyListeners();
  }

  String _getConnectionState() {
    return connectionStatus;
  }

  void _onError(String error) {
    errorMessage = error;
    notifyListeners();
  }

  void _onServerEvent(ServerEvent event) {
    _volumeService.setDisconnected();
    connectionStatus = ServerConnector.NOT_CONNECTED;
    errorMessage = event.description;
    notifyListeners();
  }

  void dismissError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> connect() async {
    final success = await ServerConnector.findServer();
    if (success) {
      _volumeService.setConnected();
    }
    return success;
  }

  void cancelSearch() {
    _setConnectionState(ServerConnector.NOT_CONNECTED);
  }

  void disconnect() {
    _volumeService.setDisconnected();
    ServerConnector.sendInput(Input.disconnect());
    ServerConnector.disconnect();
    _setConnectionState(ServerConnector.NOT_CONNECTED);
  }

  void turnOffPc() {
    _volumeService.setDisconnected();
    ServerConnector.sendInput(Input.shutdown());
    ServerConnector.disconnect();
    _setConnectionState(ServerConnector.NOT_CONNECTED);
  }

  @override
  void dispose() {
    _volumeService.dispose();
    super.dispose();
  }
}
