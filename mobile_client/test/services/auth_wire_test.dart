import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:laze/services/auth_wire.dart';

void main() {
  final vectors = jsonDecode(
          File('../tools/protocol/auth-v2-vectors.json').readAsStringSync())
      as Map<String, dynamic>;
  final hello = Map<String, dynamic>.from(vectors['hello'] as Map);
  final challenge = Map<String, dynamic>.from(vectors['challenge'] as Map);
  final key = AuthWire.decode(vectors['secret'] as String, 32);
  test('Rust/Dart protocol matches independent HMAC and HKDF vectors',
      () async {
    expect(AuthWire.encode(AuthWire.helloBytes(hello)), vectors['hello_bytes']);
    expect(AuthWire.encode(AuthWire.challengeBytes(hello, challenge)),
        vectors['challenge_bytes']);
    expect(AuthWire.encode(AuthWire.tag(key, AuthWire.helloBytes(hello))),
        hello['proof']);
    final session = await SessionCrypto.establish(key, hello, challenge);
    final keys = vectors['keys'] as Map;
    expect(AuthWire.encode(session.clientTcpKey), keys['client-tcp']);
    expect(AuthWire.encode(session.clientUdpKey), keys['client-udp']);
    expect(AuthWire.encode(session.serverTcpKey), keys['server-tcp']);
    expect(AuthWire.encode(session.clientRecord(Uint8List.fromList([4, 0]))),
        vectors['tcp_record']);
    expect(
        AuthWire.encode(session.clientRecord(Uint8List.fromList([3, 1, 255]),
            motion: true)),
        vectors['udp_record']);
    final ready = base64Url
        .decode(base64Url.normalize(vectors['ready_record'] as String));
    expect(session.serverRecord(ready), [253]);
    expect(() => session.serverRecord(ready), throwsA(isA<AuthException>()));
    expect(
        AuthWire.encode(AuthWire.tag(
            key,
            AuthWire.transcript('laze-v2/client-finish',
                [AuthWire.challengeBytes(hello, challenge)]))),
        (vectors['finish'] as Map)['proof']);
  });
  test('server identity, tampering, reflection and ordering fail closed',
      () async {
    final bad = {...challenge, 'proof': AuthWire.encode(Uint8List(32))};
    await expectLater(SessionCrypto.establish(key, hello, bad),
        throwsA(isA<AuthException>()));
    await expectLater(
        SessionCrypto.establish(key, hello, {...challenge, 'udp_port': 7875}),
        throwsA(isA<AuthException>()));
    final session = await SessionCrypto.establish(key, hello, challenge);
    final ready = base64Url
        .decode(base64Url.normalize(vectors['ready_record'] as String));
    final tampered = Uint8List.fromList(ready)..[24] ^= 1;
    expect(() => session.serverRecord(tampered), throwsA(isA<AuthException>()));
    expect(
        () => session.serverRecord(
            SessionCrypto.record(session.id, 1, [253], session.serverTcpKey)),
        throwsA(isA<AuthException>()));
    expect(
        () => session.serverRecord(
            SessionCrypto.record(session.id, 0, [253], session.clientTcpKey)),
        throwsA(isA<AuthException>()));
    expect(
        () => session.serverRecord(SessionCrypto.record(
            Uint8List(16), 0, [253], session.serverTcpKey)),
        throwsA(isA<AuthException>()));
    expect(session.serverRecord(ready),
        [253]); // rejection didn't advance the receive counter
    expect(() => session.clientRecord(Uint8List(1025)),
        throwsA(isA<AuthException>()));
  });
  test('framed socket handles split headers, combined frames, EOF and limits',
      () async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = listener.first;
    final client = await Socket.connect(listener.address, listener.port);
    final server = await accepted;
    final wire = FramedSocket(client);
    final read = wire.readFrame();
    server.add([0]);
    await server.flush();
    server.add([0, 0, 3, 1]);
    await server.flush();
    server.add([2, 3, 0, 0, 0, 2, 4, 5]);
    await server.flush();
    expect(await read, [1, 2, 3]);
    expect(await wire.readFrame(), [4, 5]);
    server.destroy();
    await expectLater(wire.readFrame(), throwsA(isA<SocketException>()));
    wire.close();
    await listener.close();

    final second = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final secondAccept = second.first;
    final secondClient = await Socket.connect(second.address, second.port);
    final secondServer = await secondAccept;
    final bounded = FramedSocket(secondClient);
    secondServer.add([0, 0, 16, 0]);
    await secondServer.flush();
    await expectLater(bounded.readFrame(), throwsA(isA<AuthException>()));
    bounded.close();
    secondServer.destroy();
    await second.close();
  });
  test('partial-frame deadline is bounded and close cancels the reader',
      () async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = listener.first;
    final client = await Socket.connect(listener.address, listener.port);
    final server = await accepted;
    final wire = FramedSocket(client);
    server.add([0, 0, 0, 2, 1]);
    await server.flush();
    await expectLater(
        wire.readFrame(timeout: const Duration(milliseconds: 100)),
        throwsA(anyOf(isA<TimeoutException>(), isA<SocketException>())));
    wire.close();
    server.destroy();
    await listener.close();
  });
}
