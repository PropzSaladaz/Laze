import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:laze/data/repositories/server/pairing_repository.dart';
import 'package:laze/services/auth_wire.dart';
import 'package:laze/data/services/input.dart';

class MemoryStorage implements PairingStorage {
  String? data;
  bool fail = false;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('test storage failure');
    data = value;
  }
}

PairedComputer computer(String id) => PairedComputer(
    serverId: id,
    deviceId: 'phone',
    name: 'Desktop',
    secret: Uint8List.fromList(List.generate(32, (i) => i)),
    hosts: ['127.0.0.1'],
    port: 7878);
void main() {
  test('secure storage reload and serialized concurrent updates', () async {
    final storage = MemoryStorage();
    final repo = PairingRepository(storage: storage);
    await repo.init();
    await Future.wait(
        [repo.save(computer('first')), repo.save(computer('second'))]);
    expect(repo.computers.map((v) => v.serverId), ['second', 'first']);
    final restarted = PairingRepository(storage: storage);
    await restarted.init();
    expect(restarted.computers.length, 2);
    expect(restarted.computers.first.secret, computer('second').secret);
    await restarted.forget('first');
    expect(restarted.computers.single.serverId, 'second');
  });
  test('storage failures keep previous credentials and do not report success',
      () async {
    final storage = MemoryStorage();
    final repo = PairingRepository(storage: storage);
    await repo.save(computer('first'));
    storage.fail = true;
    await expectLater(repo.forget('first'), throwsA(isA<AuthException>()));
    await expectLater(
        repo.save(computer('second')), throwsA(isA<AuthException>()));
    expect(repo.computers.single.serverId, 'first');
    storage.fail = false;
    await repo.forget('first');
    expect(repo.computers, isEmpty);
  });
  test('corrupt stored data never grants trust', () async {
    final storage = MemoryStorage()..data = '[{"secret":"bad"}]';
    await expectLater(PairingRepository(storage: storage).init(),
        throwsA(isA<AuthException>()));
  });
  test(
      'pairing code validates version, secret, addresses and clears invite on persistence',
      () {
    final data = {
      'version': 2,
      'server_id': 'desktop',
      'invite_id': 'invite',
      'secret': AuthWire.encode(Uint8List(32)),
      'hosts': ['127.0.0.1'],
      'port': 7878,
      'name': 'Desktop',
      'expires_at': 0
    };
    String qr(Map value) =>
        'laze://pair/${AuthWire.encode(utf8.encode(jsonEncode(value)))}';
    final pending = PairedComputer.fromQr(qr(data));
    expect(pending.inviteId, 'invite');
    expect(pending.connectedAt('127.0.0.2').inviteId, isEmpty);
    expect(pending.connectedAt('127.0.0.2').hosts, ['127.0.0.2', '127.0.0.1']);
    for (final bad in [
      {...data, 'version': 1},
      {...data, 'secret': 'bad'},
      {
        ...data,
        'hosts': ['example.com']
      },
      {...data, 'invite_id': ''},
      {...data, 'port': 0}
    ]) {
      expect(
          () => PairedComputer.fromQr(qr(bad)), throwsA(isA<AuthException>()));
    }
  });
  test(
      'terminal command length measures UTF-8 bytes with an enforced 255-byte bound',
      () {
    final result = Input.runCommand({'unknown': 'echo café'});
    expect(result[1], utf8.encode('echo café').length);
    expect(utf8.decode(result.sublist(2)), 'echo café');
    expect(Input.runCommand({'unknown': 'a' * 255})[1], 255);
    expect(
        () => Input.runCommand({'unknown': 'é' * 128}), throwsFormatException);
  });
}
