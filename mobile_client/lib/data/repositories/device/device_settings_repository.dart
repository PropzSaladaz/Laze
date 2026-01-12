import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Repository for managing device settings including device name
class DeviceSettingsRepository {
  static const String boxName = 'device_settings';
  static const String deviceNameKey = 'device_name';

  static final Logger _log = Logger('DeviceSettingsRepository');
  
  late Box<String> _box;
  bool _initialized = false;

  /// Initialize the repository
  Future<void> init() async {
    if (_initialized) return;
    
    _box = await Hive.openBox<String>(boxName);
    _initialized = true;
    _log.info('Device settings initialized');
  }

  /// Get the device name, generating one if not set
  Future<String> getDeviceName() async {
    if (!_initialized) {
      await init();
    }
    
    String? deviceName = _box.get(deviceNameKey);
    
    if (deviceName == null || deviceName.isEmpty) {
      // Generate a default device name
      deviceName = await _generateDefaultDeviceName();
      await setDeviceName(deviceName);
    }
    
    return deviceName;
  }

  /// Set the device name
  Future<void> setDeviceName(String name) async {
    if (!_initialized) {
      await init();
    }
    
    await _box.put(deviceNameKey, name);
    _log.info('Device name set to: $name');
  }

  /// Generate a default device name based on device brand and model
  Future<String> _generateDefaultDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (await _isAndroid()) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand ?? 'Unknown';
        final model = androidInfo.model ?? 'Device';
        return '${_capitalize(brand)} $model';
      } else if (await _isIOS()) {
        final iosInfo = await deviceInfo.iosInfo;
        final name = iosInfo.name ?? 'iOS Device';
        return name;
      } else {
        // Fallback for other platforms
        return 'Mobile Device';
      }
    } catch (e) {
      _log.warning('Failed to get device info: $e');
      return 'Mobile Device';
    }
  }

  /// Check if running on Android
  Future<bool> _isAndroid() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      await deviceInfo.androidInfo;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if running on iOS
  Future<bool> _isIOS() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      await deviceInfo.iosInfo;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Capitalize first letter of string
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Clear all device settings
  Future<void> clear() async {
    if (!_initialized) return;
    await _box.clear();
    _log.info('Device settings cleared');
  }
}
