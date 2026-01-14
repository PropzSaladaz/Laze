import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_client/data/repositories/device/device_settings_repository.dart';

void main() {
  group('DeviceSettingsRepository', () {
    late DeviceSettingsRepository repository;
    late Directory tempDir;

    setUp(() async {
      // Use a temporary directory for testing (avoids path_provider dependency)
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      repository = DeviceSettingsRepository();
      await repository.init();
    });

    tearDown(() async {
      // Clean up after each test
      await repository.clear();
      await Hive.close();
      // Delete temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should store and retrieve device name', () async {
      const testName = 'Test Device';
      
      await repository.setDeviceName(testName);
      final retrievedName = await repository.getDeviceName();
      
      expect(retrievedName, equals(testName));
    });

    test('should generate default device name if not set', () async {
      final deviceName = await repository.getDeviceName();
      
      // In test environment, device_info_plus returns empty strings
      // so we expect the fallback "Mobile Device"
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
