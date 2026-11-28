@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('the app itself never changes the firewall', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final p = f.path.replaceAll(r'\', '/');
      if (p.endsWith('.dart') &&
          RegExp(r'''['"](netsh|firewall-cmd|ufw)(\.exe)?['"]''').hasMatch(f.readAsStringSync())) {
        hits.add(p);
      }
    }
    expect(hits, isEmpty,
        reason: 'A rule added at launch is repeated every run and no uninstall '
            'knows about it. Firewall changes belong to the installer, with '
            'their removal in the uninstaller.');
  });

  test('every firewalld service the Fedora package adds, its removal takes away', () {
    final spec = _read('packaging/fedora/apexsender.spec');
    final added = RegExp(r'--add-service=(\S+)').allMatches(spec).map((m) => m.group(1)).toSet();
    final removed = RegExp(r'--remove-service=(\S+)').allMatches(spec).map((m) => m.group(1)).toSet();
    expect(added, isNotEmpty);
    expect(added.difference(removed), isEmpty);
  });
}
