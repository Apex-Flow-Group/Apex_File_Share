import 'dart:convert';
import 'dart:io';

import 'package:apex_file_share/core/protocol/apex_protocol.dart';
import 'package:apex_file_share/features/send/data/send_http.dart';
import 'package:apex_file_share/models/device.dart';
import 'package:apex_file_share/services/transfer_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../identity/tls_peer.dart';

void main() {
  setUpAll(loadPeers);

  test('the bar follows what the receiver took, not what was read from disk', () async {
    const size = 24 * 1024 * 1024;
    // The socket buffers of both ends sit between the two counts.
    const slack = 8 * 1024 * 1024;
    final root = await Directory.systemTemp.createTemp('apex_upload_progress_');
    final server = await bindReceiver();
    addTearDown(() async {
      await server.close(force: true);
      TransferProgressService().clearProgress();
      await root.delete(recursive: true);
    });
    var received = 0;
    server.listen((req) async {
      if (req.uri.path == ApexProtocol.uploadPath) {
        // A slow receiver: the sender must wait for it.
        await for (final chunk in req) {
          received += chunk.length;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      } else {
        await req.drain<void>();
      }
      req.response.write(jsonEncode(req.uri.path == ApexProtocol.offerPath
          ? {'accepted': true, 'tokens': ['a']}
          : {'success': true}));
      await req.response.close();
    });
    final path = '${root.path}/big.bin';
    File(path).writeAsBytesSync(List<int>.filled(size, 7));
    final ahead = <int>[];
    final sub = TransferProgressService().progressStream.listen((p) {
      if (p != null && p.transferredBytes > received + slack) {
        ahead.add(p.transferredBytes - received);
      }
    });
    addTearDown(sub.cancel);

    final outcome = await SendHttp(getContext: senderContext, getLocalName: () => 'Test Phone', getLocalId: () => 'test-id')
        .sendFiles([(path: path, name: 'big.bin', size: size)],
            Device(id: 't', name: 'Receiver', type: 'desktop', ip: '127.0.0.1', port: server.port, fingerprint: testReceiver.fingerprint));

    expect(outcome, SendOutcome.sent);
    expect(received, size);
    expect(ahead, isEmpty,
        reason: 'The bar showed bytes the receiver had not taken yet (bytes ahead: ${ahead.take(3)}).');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
