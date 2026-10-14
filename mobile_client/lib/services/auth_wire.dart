import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart' as kdf;

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthWire {
  static const version = 2;
  static const overhead = 56;
  static const maxInput = 1024;
  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List.generate(length, (_) => random.nextInt(256)));
  }

  static String encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
  static Uint8List decode(String text, int length) {
    try {
      final bytes = base64Url.decode(base64Url.normalize(text));
      if (bytes.length == length && encode(bytes) == text) return bytes;
    } catch (_) {}
    throw const AuthException('Invalid authentication data');
  }

  static Uint8List transcript(String label, List<List<int>> fields) {
    final output = BytesBuilder(copy: false);
    for (final field in [utf8.encode(label), ...fields]) {
      final size = ByteData(4)..setUint32(0, field.length, Endian.big);
      output.add(size.buffer.asUint8List());
      output.add(field);
    }
    return output.takeBytes();
  }

  static Uint8List tag(List<int> key, List<int> message) => Uint8List.fromList(
      crypto.Hmac(crypto.sha256, key).convert(message).bytes);
  static bool equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  static Uint8List helloBytes(Map<String, dynamic> hello) =>
      transcript('laze-v2/client-hello', [
        utf8.encode(hello['server_id'] as String),
        utf8.encode(hello['device_id'] as String),
        utf8.encode(hello['device_name'] as String),
        utf8.encode(hello['invite_id'] as String),
        decode(hello['client_nonce'] as String, 32),
      ]);
  static Uint8List challengeBytes(
      Map<String, dynamic> hello, Map<String, dynamic> challenge) {
    final port = challenge['udp_port'];
    if (challenge['version'] != version ||
        port is! int ||
        port < 0 ||
        port > 65535 ||
        !['windows', 'linux', 'macos'].contains(challenge['server_os'])) {
      throw const AuthException('Incompatible desktop authentication protocol');
    }
    final portBytes = ByteData(2)..setUint16(0, port, Endian.big);
    return transcript('laze-v2/server-challenge', [
      helloBytes(hello),
      decode(challenge['server_nonce'] as String, 32),
      decode(challenge['session_id'] as String, 16),
      utf8.encode(challenge['server_os'] as String),
      portBytes.buffer.asUint8List()
    ]);
  }
}

class SessionCrypto {
  final Uint8List id;
  final List<int> clientTcpKey, clientUdpKey, serverTcpKey;
  int _tcpSequence = 0, _udpSequence = 0, _serverSequence = 0;
  SessionCrypto(
      this.id, this.clientTcpKey, this.clientUdpKey, this.serverTcpKey);
  static Future<SessionCrypto> establish(List<int> key,
      Map<String, dynamic> hello, Map<String, dynamic> challenge) async {
    final bytes = AuthWire.challengeBytes(hello, challenge);
    if (!AuthWire.equal(AuthWire.tag(key, bytes),
        AuthWire.decode(challenge['proof'] as String, 32))) {
      throw const AuthException('The computer could not prove its identity');
    }
    final id = AuthWire.decode(challenge['session_id'] as String, 16);
    final salt = [
      ...AuthWire.decode(hello['client_nonce'] as String, 32),
      ...AuthWire.decode(challenge['server_nonce'] as String, 32)
    ];
    final algorithm = kdf.Hkdf(hmac: kdf.Hmac.sha256(), outputLength: 32);
    Future<List<int>> derive(String label) async {
      final secret = await algorithm.deriveKey(
          secretKey: kdf.SecretKey(key),
          nonce: salt,
          info: AuthWire.transcript('laze-v2/session-key', [
            utf8.encode(hello['server_id'] as String),
            utf8.encode(hello['device_id'] as String),
            id,
            utf8.encode(label)
          ]));
      return secret.extractBytes();
    }

    final keys = await Future.wait(
        ['client-tcp', 'client-udp', 'server-tcp'].map(derive));
    return SessionCrypto(id, keys[0], keys[1], keys[2]);
  }

  static Uint8List record(
      List<int> id, int sequence, List<int> payload, List<int> key) {
    final counter = ByteData(8)..setUint64(0, sequence, Endian.big);
    final body = Uint8List.fromList(
        [...id, ...counter.buffer.asUint8List(), ...payload]);
    return Uint8List.fromList([...body, ...AuthWire.tag(key, body)]);
  }

  Uint8List clientRecord(Uint8List payload, {bool motion = false}) {
    if (payload.isEmpty || payload.length > AuthWire.maxInput) {
      throw const AuthException('Invalid input size');
    }
    final sequence = motion ? _udpSequence++ : _tcpSequence++;
    if (sequence >= 0x7fffffffffffffff) {
      throw const AuthException('Reconnect to renew the session');
    }
    return record(id, sequence, payload, motion ? clientUdpKey : clientTcpKey);
  }

  Uint8List serverRecord(Uint8List bytes) {
    if (bytes.length <= AuthWire.overhead ||
        bytes.length > AuthWire.overhead + AuthWire.maxInput ||
        !AuthWire.equal(id, bytes.sublist(0, 16))) {
      throw const AuthException('Invalid server message');
    }
    final body = bytes.sublist(0, bytes.length - 32);
    if (!AuthWire.equal(
        AuthWire.tag(serverTcpKey, body), bytes.sublist(bytes.length - 32))) {
      throw const AuthException('Invalid server authentication');
    }
    final sequence =
        ByteData.sublistView(bytes, 16, 24).getUint64(0, Endian.big);
    if (sequence != _serverSequence || sequence >= 0x7fffffffffffffff) {
      throw const AuthException('Repeated server message');
    }
    _serverSequence++;
    return Uint8List.fromList(bytes.sublist(24, bytes.length - 32));
  }
}

/// One reader for both the handshake and subsequent event records; TCP chunks are never message boundaries.
class FramedSocket {
  final Socket socket;
  late final StreamIterator<Uint8List> _iterator = StreamIterator(socket);
  Uint8List _chunk = Uint8List(0);
  int _offset = 0;
  bool _closed = false;
  FramedSocket(this.socket);
  Future<Uint8List> _read(int count, Stopwatch clock, Duration timeout) async {
    final result = Uint8List(count);
    var copied = 0;
    while (copied < count) {
      if (_closed) throw const SocketException('Connection closed');
      if (_offset == _chunk.length) {
        final remaining = timeout - clock.elapsed;
        if (remaining <= Duration.zero ||
            !await _iterator.moveNext().timeout(remaining)) {
          throw const SocketException('Connection closed or timed out');
        }
        _chunk = _iterator.current;
        _offset = 0;
        if (_chunk.length > 65536) {
          throw const AuthException('Invalid server frame');
        }
        if (_chunk.isEmpty) continue;
      }
      final length = min(count - copied, _chunk.length - _offset);
      result.setRange(copied, copied + length, _chunk, _offset);
      _offset += length;
      copied += length;
    }
    return result;
  }

  Future<Uint8List> readFrame(
      {int max = 2048, Duration timeout = const Duration(seconds: 5)}) async {
    final clock = Stopwatch()..start();
    final header = await _read(4, clock, timeout);
    final length = ByteData.sublistView(header).getUint32(0, Endian.big);
    if (length == 0 || length > max) {
      throw const AuthException('Invalid server frame length');
    }
    return _read(length, clock, timeout);
  }

  void writeFrame(List<int> payload) {
    if (_closed) throw const SocketException('Connection closed');
    final header = ByteData(4)..setUint32(0, payload.length, Endian.big);
    socket
        .add(Uint8List.fromList([...header.buffer.asUint8List(), ...payload]));
  }

  void close() {
    if (_closed) return;
    _closed = true;
    socket.destroy();
    unawaited(_iterator.cancel());
  }
}
