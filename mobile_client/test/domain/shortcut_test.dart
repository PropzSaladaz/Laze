import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';

void main() {
  group('Shortcut', () {
    test('creates shortcut with generated ID', () {
      final shortcut = Shortcut(
        icon: Icons.play_arrow,
        name: 'Test Shortcut',
        commands: {'linux': 'echo test'},
      );
      
      expect(shortcut.id, isNotEmpty);
      expect(shortcut.name, equals('Test Shortcut'));
      expect(shortcut.icon, equals(Icons.play_arrow));
      expect(shortcut.commands, equals({'linux': 'echo test'}));
    });

    test('creates shortcut with specific ID', () {
      const testId = 'test-id-123';
      
      final shortcut = Shortcut.withId(
        id: testId,
        icon: Icons.stop,
        name: 'Named Shortcut',
        commands: {'windows': 'cmd /c echo test'},
      );
      
      expect(shortcut.id, equals(testId));
      expect(shortcut.name, equals('Named Shortcut'));
      expect(shortcut.icon, equals(Icons.stop));
      expect(shortcut.commands, containsPair('windows', 'cmd /c echo test'));
    });

    test('different shortcuts have different IDs', () {
      final shortcut1 = Shortcut(
        icon: Icons.play_arrow,
        name: 'Shortcut 1',
        commands: {},
      );
      
      final shortcut2 = Shortcut(
        icon: Icons.stop,
        name: 'Shortcut 2',
        commands: {},
      );
      
      expect(shortcut1.id, isNot(equals(shortcut2.id)));
    });

    test('shortcut can store multiple OS commands', () {
      final shortcut = Shortcut(
        icon: Icons.computer,
        name: 'Multi-OS Shortcut',
        commands: {
          'linux': 'xdg-open',
          'windows': 'start',
          'macos': 'open',
        },
      );
      
      expect(shortcut.commands.length, equals(3));
      expect(shortcut.commands['linux'], equals('xdg-open'));
      expect(shortcut.commands['windows'], equals('start'));
      expect(shortcut.commands['macos'], equals('open'));
    });

    test('shortcut with empty commands map', () {
      final shortcut = Shortcut(
        icon: Icons.help,
        name: 'Empty Commands',
        commands: {},
      );
      
      expect(shortcut.commands, isEmpty);
    });
  });
}
