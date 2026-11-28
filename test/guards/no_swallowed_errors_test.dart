import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No error is swallowed silently (owner decision): a catch block either logs
/// through ApexLogger, rethrows, or hands the error on (uses the caught
/// variable). Where swallowing is the intended outcome, the catch line says so
/// and why: `// swallow-ok: <reason>`.
///
/// Why: a failed chat message once showed only "did not arrive" because the
/// sender turned a 403 into a bare failure; the cause was found only after
/// logging was added.

/// Replaces comments (and, in [noStrings], string contents) by spaces, keeping
/// every offset and newline, so brace matching and keyword search do not read
/// text that is not code.
({String noComments, String noStrings}) _mask(String src) {
  final a = StringBuffer(); // comments blanked
  final b = StringBuffer(); // comments and strings blanked
  String blank(String s) => s.replaceAll(RegExp(r'[^\n]'), ' ');
  var i = 0;
  while (i < src.length) {
    final c = src[i];
    if (src.startsWith('//', i)) {
      var j = src.indexOf('\n', i);
      if (j < 0) {
        j = src.length;
      }
      a.write(blank(src.substring(i, j)));
      b.write(blank(src.substring(i, j)));
      i = j;
    } else if (src.startsWith('/*', i)) {
      var j = src.indexOf('*/', i + 2);
      j = j < 0 ? src.length : j + 2;
      a.write(blank(src.substring(i, j)));
      b.write(blank(src.substring(i, j)));
      i = j;
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && src[i - 1] == 'r';
      final triple = src.startsWith(c * 3, i);
      final quote = triple ? c * 3 : c;
      var j = i + quote.length;
      while (j < src.length && !src.startsWith(quote, j)) {
        if (!raw && src[j] == r'\') {
          j += 2;
        } else if (!raw && src.startsWith(r'${', j)) {
          var depth = 1;
          j += 2;
          while (j < src.length && depth > 0) {
            depth += {'{': 1, '}': -1}[src[j]] ?? 0;
            j++;
          }
        } else {
          j++;
        }
      }
      j = (j + quote.length).clamp(0, src.length);
      a.write(src.substring(i, j));
      b.write(blank(src.substring(i, j)));
      i = j;
    } else {
      a.write(c);
      b.write(c);
      i++;
    }
  }
  return (noComments: a.toString(), noStrings: b.toString());
}

int _line(String src, int offset) => '\n'.allMatches(src.substring(0, offset)).length + 1;

/// End offset (exclusive, past the closing brace) of the block opened at [open].
int _blockEnd(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == '{') {
      depth++;
    } else if (code[i] == '}') {
      depth--;
      if (depth == 0) {
        return i + 1;
      }
    }
  }
  return code.length;
}

/// End offset of an arrow body that began at [from] inside a call: up to the
/// parenthesis that closes the call.
int _arrowEnd(String code, int from) {
  var depth = 0;
  for (var i = from; i < code.length; i++) {
    if (code[i] == '(') {
      depth++;
    } else if (code[i] == ')') {
      if (depth == 0) {
        return i;
      }
      depth--;
    }
  }
  return code.length;
}

final _head = RegExp(
  r'\bcatch\s*\(\s*(\w+)\s*(?:,\s*\w+\s*)?\)\s*\{'
  r'|\}\s*on\s+[\w<>.?]+\s*\{'
  r'|\.catchError\(\s*\(\s*(\w*)\s*(?:,\s*\w+\s*)?\)\s*(?:async\s*)?(\{|=>)',
);
final _handled = RegExp(r'ApexLogger|(?<![\w])_?log\(|debugPrint|\brethrow\b|\bthrow\b');
final _accepted = RegExp(r'//\s*swallow-ok:\s*\S');

/// `file:line` of every catch / on / catchError block of [src] that neither
/// logs, rethrows, nor uses the caught error, and carries no `swallow-ok`.
List<String> findSwallowed(String src, String name) {
  final masked = _mask(src);
  final lines = src.split('\n');
  final found = <String>[];
  for (final m in _head.allMatches(masked.noStrings)) {
    final isArrow = m.group(3) == '=>';
    final isCatchError = m.group(3) != null;
    final varName = isCatchError ? m.group(2) : m.group(1);
    final int start;
    final int end;
    if (isArrow) {
      start = m.end;
      end = _arrowEnd(masked.noStrings, m.end);
    } else {
      start = m.end;
      end = _blockEnd(masked.noStrings, m.end - 1);
    }
    final body = masked.noComments.substring(start, end);
    final used = varName != null && varName != '_' && varName.isNotEmpty && RegExp('\\b$varName\\b').hasMatch(body);
    if (used || _handled.hasMatch(body)) {
      continue;
    }
    final first = _line(src, m.start);
    final last = _line(src, m.end);
    final marked = [for (var l = first; l <= last; l++) lines[l - 1]].any(_accepted.hasMatch);
    if (!marked) {
      found.add('$name:$first: ${lines[first - 1].trim()}');
    }
  }
  return found;
}

void main() {
  test('the scanner tells swallowed errors from handled ones', () {
    const swallowed = '''
void a() { try { x(); } catch (_) {} }
void b() { try { x(); } on SocketException { return; } }
void c() { f().catchError((_) {}); }
void d() { try { x(); } catch (e) { return; } }
void e() { try { x(); } catch (e) { // not logged: log(
  return;
} }
''';
    expect(findSwallowed(swallowed, 'x.dart'), hasLength(5));
    const handled = '''
void a() { try { x(); } catch (e) { ApexLogger.instance.log('t', '\$e'); } }
void b() { try { x(); } catch (_) { rethrow; } }
void c() { try { x(); } catch (e) { return fail(e); } }
void d() { try { x(); } catch (_) {} // swallow-ok: closing twice is harmless
}
void e() { try { x(); } on StateError { // swallow-ok: already closed
  return;
} }
void f() { g().catchError((e) => handle(e)); }
void g() { try { x(); } catch (_) { final s = '{'; log('t', 'x'); } }
''';
    expect(findSwallowed(handled, 'x.dart'), isEmpty);
    expect(findSwallowed('void a() { try { x(); } catch (_) {} // swallow-ok:\n}', 'x.dart'), hasLength(1),
        reason: 'a swallow-ok without a reason does not count');
  });

  test('no catch block swallows an error without a log or a reason', () {
    final found = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (path.startsWith('lib/l10n/generated/')) {
        continue;
      }
      found.addAll(findSwallowed(file.readAsStringSync(), path));
    }
    expect(found, isEmpty,
        reason: '${found.length} swallowed errors; log through ApexLogger, rethrow, or add '
            '"// swallow-ok: <reason>" on the catch line:\n${found.join('\n')}');
  });
}
