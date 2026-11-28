import 'dart:io';

import 'package:apex_file_share/utils/apex_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File log;
  setUp(() {
    root = Directory.systemTemp.createTempSync('apex_logger_file_');
    log = File('${root.path}/apex.log');
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('a release build keeps errors and warnings on disk, not the rest', () {
    ApexLogger.instance.useFile(log);
    ApexLogger.instance.log('SEND', 'Chat failed: timed out', LogLevel.error);
    ApexLogger.instance.log('UDP', 'Send failed: no route', LogLevel.warning);
    ApexLogger.instance.log('NEARBY', 'Sent: clip.mp4', LogLevel.success);

    final lines = log.readAsLinesSync();
    expect(lines, hasLength(2));
    expect(lines[0], endsWith('error [SEND] Chat failed: timed out'));
    expect(lines[1], endsWith('warning [UDP] Send failed: no route'));
  });

  test('the file stops growing: past its limit it moves to .1 and starts again', () {
    ApexLogger.instance.useFile(log, maxBytes: 200);
    for (var i = 0; i < 10; i++) {
      ApexLogger.instance.log('SEND', 'Upload failed: number $i', LogLevel.error);
    }

    final old = File('${log.path}.1');
    expect(old.existsSync(), isTrue);
    expect(log.lengthSync(), lessThan(400));
    expect(old.lengthSync(), lessThan(400));
    expect(log.readAsStringSync(), contains('number 9'));
  });
}
