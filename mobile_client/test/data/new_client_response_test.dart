import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_client/data/dto/new_client_response.dart';

void main() {
  group('NewClientResponse', () {
    test('creates instance with port and server_os', () {
      final response = NewClientResponse(
        port: 7879,
        server_os: 'linux',
      );
      
      expect(response.port, equals(7879));
      expect(response.server_os, equals('linux'));
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'port': 8080,
        'server_os': 'windows',
      };
      
      final response = NewClientResponse.fromJson(json);
      
      expect(response.port, equals(8080));
      expect(response.server_os, equals('windows'));
    });

    test('toJson serializes correctly', () {
      final response = NewClientResponse(
        port: 9000,
        server_os: 'macos',
      );
      
      final json = response.toJson();
      
      expect(json['port'], equals(9000));
      expect(json['server_os'], equals('macos'));
    });

    test('round-trip serialization preserves data', () {
      final original = NewClientResponse(
        port: 7878,
        server_os: 'linux',
      );
      
      final json = original.toJson();
      final deserialized = NewClientResponse.fromJson(json);
      
      expect(deserialized.port, equals(original.port));
      expect(deserialized.server_os, equals(original.server_os));
    });

    test('handles different port numbers', () {
      final response1 = NewClientResponse(port: 1024, server_os: 'linux');
      final response2 = NewClientResponse(port: 65535, server_os: 'linux');
      
      expect(response1.port, equals(1024));
      expect(response2.port, equals(65535));
    });

    test('handles different operating systems', () {
      final linuxResponse = NewClientResponse(port: 8000, server_os: 'linux');
      final windowsResponse = NewClientResponse(port: 8000, server_os: 'windows');
      final macosResponse = NewClientResponse(port: 8000, server_os: 'macos');
      
      expect(linuxResponse.server_os, equals('linux'));
      expect(windowsResponse.server_os, equals('windows'));
      expect(macosResponse.server_os, equals('macos'));
    });
  });
}
