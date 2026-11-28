import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every colour of the app comes from ApexColors (owner decision): a colour
/// written by hand in a screen is the purple that looked foreign beside the
/// app's greys. The roles live in apex_colors.dart and apex_theme.dart only.
void main() {
  const allowed = {
    'lib/shared/apex_colors.dart',
    'lib/shared/apex_theme.dart',
  };
  final hand = RegExp(
    r'Color\(\s*0x|(?<![\w.])Colors\.(?!transparent\b)\w+|Color\.from(ARGB|RGBO)',
  );

  test('no screen writes a colour by hand', () {
    final found = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (path.startsWith('lib/l10n/generated/') || allowed.contains(path)) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        if (hand.hasMatch(code)) {
          found.add('$path:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(found, isEmpty,
        reason: '${found.length} colours written by hand; use ApexColors.of(context):\n${found.join('\n')}');
  });
}
