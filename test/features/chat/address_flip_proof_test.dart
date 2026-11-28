@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:apex_file_share/core/discovery_merge.dart';
import 'package:apex_file_share/core/protocol/apex_protocol.dart';
import 'package:apex_file_share/features/send/data/send_http.dart';
import 'package:apex_file_share/models/device.dart';
import 'package:apex_file_share/utils/apex_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../identity/tls_peer.dart';
import 'chat_door.dart';

/// Proof of the owner's scenario: after a while the first message fails and
/// a retry delivers it. Hypothesis: a device on two networks is kept under the
/// last address discovery heard; a message from its other address is refused,
/// and the sender reports a bare failure. Each step on the real code.
void main() {
  test('discovery keeps one address per device: the last one heard', () {
    final known = <String, Device>{};
    Device heardAt(String ip) =>
        Device(id: 'jawal', name: 'Jawal', type: 'desktop', ip: ip, port: 54493, fingerprint: 'fp');
    mergeFound(known, heardAt('192.168.0.128'));
    mergeFound(known, heardAt('192.168.8.103'));

    expect(known.keys, ['jawal']);
    expect(known['jawal']!.ip, '192.168.8.103', reason: 'the Ethernet address is gone');
  });

  group('a message from the address discovery did not hear last', () {
    late TlsPeer me;
    late TlsPeer jawal;
    late ChatDoor door;
    setUpAll(() async {
      me = await TlsPeer.create();
      jawal = await TlsPeer.create();
    });
    setUp(() async => door = await ChatDoor.start(me, [jawal]));
    tearDown(() => door.stop());

    test('is refused as a wrong identity, and goes through once the address matches', () async {
      door.hear(jawal, 'jawal', address: '127.0.0.2');
      final first = await door.post(jawal, me, 'jawal', 'hello', address: '127.0.0.1');
      expect(first.status, HttpStatus.forbidden);
      expect(first.json['error'], ApexProtocol.wrongIdentity);

      door.hear(jawal, 'jawal', address: '127.0.0.1');
      final retry = await door.post(jawal, me, 'jawal', 'hello', address: '127.0.0.1');
      expect(retry.status, HttpStatus.ok);
      expect(retry.json['delivered'], isTrue);
    });
  });

  test('the sender reports that refusal as a failure, and now logs its reason', () async {
    await loadPeers();
    final server = await bindReceiver();
    addTearDown(() => server.close(force: true));
    server.listen((req) async {
      await req.drain<void>();
      req.response
        ..statusCode = HttpStatus.forbidden
        ..write(jsonEncode({'error': ApexProtocol.wrongIdentity}));
      await req.response.close();
    });
    final logged = <LogEntry>[];
    final sub = ApexLogger.instance.stream.listen(logged.add);
    addTearDown(sub.cancel);

    final r = await SendHttp(getContext: senderContext, getLocalName: () => 'Jawal', getLocalId: () => 'jawal')
        .sendChat('hello', Device(id: 'fedora', name: 'fedora', type: 'desktop', ip: '127.0.0.1', port: server.port, fingerprint: testReceiver.fingerprint), null);

    // The log stream delivers on a later microtask.
    await Future<void>.delayed(Duration.zero);
    expect(r.outcome, ChatOutcome.failed);
    expect(logged.map((e) => e.message), [contains('403 {"error":"${ApexProtocol.wrongIdentity}"}')],
        reason: 'the refusal and its reason reach the log (apex.log in a release build)');
  });
}
