import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:laze/services/auth_wire.dart';

bool validPairingId(String id) => RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id);

class PairedComputer {
  final String serverId, deviceId, name, inviteId;
  final Uint8List secret;
  final List<String> hosts;
  final int port;
  PairedComputer(
      {required this.serverId,
      required this.deviceId,
      required this.name,
      required this.secret,
      required this.hosts,
      required this.port,
      this.inviteId = ''}) {
    if (!validPairingId(serverId) ||
        !validPairingId(deviceId) ||
        secret.length != 32 ||
        name.length > 128 ||
        hosts.isEmpty ||
        hosts.length > 8 ||
        port < 1 ||
        port > 65535 ||
        hosts.any((host) =>
            InternetAddress.tryParse(host)?.type != InternetAddressType.IPv4) ||
        (inviteId.isNotEmpty && !validPairingId(inviteId))) {
      throw const AuthException('Invalid computer pairing data');
    }
  }
  factory PairedComputer.fromQr(String code) {
    try {
      const prefix = 'laze://pair/';
      if (!code.startsWith(prefix) || code.length > 4096) {
        throw const FormatException();
      }
      final json = jsonDecode(utf8.decode(base64Url
              .decode(base64Url.normalize(code.substring(prefix.length)))))
          as Map<String, dynamic>;
      if (json['version'] != 2 ||
          json['expires_at'] is! int ||
          (json['invite_id'] as String).isEmpty) {
        throw const FormatException();
      }
      return PairedComputer(
          serverId: json['server_id'] as String,
          deviceId: AuthWire.encode(AuthWire.randomBytes(16)),
          name: json['name'] as String,
          secret: AuthWire.decode(json['secret'] as String, 32),
          hosts: List<String>.from(json['hosts'] as List),
          port: json['port'] as int,
          inviteId: json['invite_id'] as String);
    } catch (_) {
      throw const AuthException(
          'That is not a valid Laze pairing code. Generate a new code on the desktop.');
    }
  }
  factory PairedComputer.fromJson(Map<String, dynamic> json) => PairedComputer(
      serverId: json['server_id'] as String,
      deviceId: json['device_id'] as String,
      name: json['name'] as String,
      secret: AuthWire.decode(json['secret'] as String, 32),
      hosts: List<String>.from(json['hosts'] as List),
      port: json['port'] as int);
  Map<String, dynamic> toJson() => {
        'server_id': serverId,
        'device_id': deviceId,
        'name': name,
        'secret': AuthWire.encode(secret),
        'hosts': hosts,
        'port': port
      };
  PairedComputer connectedAt(String host) => PairedComputer(
      serverId: serverId,
      deviceId: deviceId,
      name: name,
      secret: secret,
      hosts: [host, ...hosts.where((v) => v != host)].take(8).toList(),
      port: port);
}

abstract class PairingStorage {
  Future<String?> read();
  Future<void> write(String data);
}

class SecurePairingStorage implements PairingStorage {
  final FlutterSecureStorage storage;
  SecurePairingStorage([this.storage = const FlutterSecureStorage()]);
  static const key = 'laze.paired-computers.v2';
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String data) => storage.write(key: key, value: data);
}

class PairingRepository extends ChangeNotifier {
  final PairingStorage storage;
  Future<void>? _initialization;
  Future<void> _writes = Future.value();
  List<PairedComputer> _computers = [];
  PairingRepository({PairingStorage? storage})
      : storage = storage ?? SecurePairingStorage();
  List<PairedComputer> get computers => List.unmodifiable(_computers);
  Future<void> init() => _initialization ??= _load();
  Future<void> _load() async {
    try {
      final text = await storage.read();
      if (text != null) {
        final records = jsonDecode(text) as List;
        if (records.length > 64) throw const FormatException();
        _computers = records
            .map((v) =>
                PairedComputer.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList();
        if (_computers.map((v) => v.serverId).toSet().length !=
            _computers.length) {
          throw const FormatException();
        }
      }
      notifyListeners();
    } catch (_) {
      throw const AuthException(
          'Unable to read securely stored pairings. Check device secure storage.');
    }
  }

  Future<void> _change(List<PairedComputer> Function() update) {
    final job = _writes.then((_) async {
      await init();
      final next = update();
      try {
        await storage.write(jsonEncode(next.map((v) => v.toJson()).toList()));
      } catch (_) {
        throw const AuthException('Unable to save secure pairing credentials');
      }
      _computers = next;
      notifyListeners();
    });
    _writes = job.catchError((_) {});
    return job;
  }

  Future<void> save(PairedComputer computer) => _change(() {
        final next = [
          computer,
          ..._computers.where((v) => v.serverId != computer.serverId)
        ];
        if (next.length > 64) {
          throw const AuthException(
              'Forget an unused computer before pairing another');
        }
        return next;
      });
  Future<void> forget(String serverId) =>
      _change(() => _computers.where((v) => v.serverId != serverId).toList());
}
