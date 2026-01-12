import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_client/data/repositories/device/device_settings_repository.dart';

void main() {
  group('DeviceSettingsRepository', () {
    late DeviceSettingsRepository repository;

    setUp(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      repository = DeviceSettingsRepository();
      await repository.init();
    });

    tearDown(() async {
      // Clean up after each test
      await repository.clear();
      await Hive.close();
    });

    test('should store and retrieve device name', () async {
      const testName = 'Test Device';
      
      await repository.setDeviceName(testName);
      final retrievedName = await repository.getDeviceName();
      
      expect(retrievedName, equals(testName));
    });

    test('should generate default device name if not set', () async {
      final deviceName = await repository.getDeviceName();
      
      expect(deviceName, isNotEmpty);
      expect(deviceName.length, greaterThan(0));
    });

    test('should update device name', () async {
      const firstName = 'First Name';
      const secondName = 'Second Name';
      
      await repository.setDeviceName(firstName);
      await repository.setDeviceName(secondName);
      final retrievedName = await repository.getDeviceName();
      
      expect(retrievedName, equals(secondName));
    });

    test('should clear device settings', () async {
      const testName = 'Test Device';
      
      await repository.setDeviceName(testName);
      await repository.clear();
      
      // After clearing, it should generate a new default name
      final deviceName = await repository.getDeviceName();
      expect(deviceName, isNotEmpty);
    });
  });
}
