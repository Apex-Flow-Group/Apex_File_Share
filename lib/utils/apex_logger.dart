import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum LogLevel { info, success, warning, error, debug }

class LogEntry {
  final String tag;
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  LogEntry(this.tag, this.message, this.level) : timestamp = DateTime.now();
}

class ApexLogger {
  static final ApexLogger instance = ApexLogger._();
  ApexLogger._();

  final _controller = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get stream => _controller.stream;

  File? _file;
  int _maxBytes = 256 * 1024;

  /// Errors and warnings are also kept in [file], so a release build, which
  /// prints nothing, still says why a send failed. Past [maxBytes] the file
  /// moves to `<file>.1` and starts again, so it never grows without end.
  void useFile(File file, {int maxBytes = 256 * 1024}) {
    _file = file;
    _maxBytes = maxBytes;
  }

  void log(String tag, String message, [LogLevel level = LogLevel.info]) {
    final entry = LogEntry(tag, message, level);
    _controller.add(entry);

    if (kDebugMode) {
      final emoji = _getEmoji(level);
      debugPrint('$emoji [$tag] $message');
    }
    if (level == LogLevel.error || level == LogLevel.warning) {
      _append(entry);
    }
  }

  void _append(LogEntry e) {
    final file = _file;
    if (file == null) {
      return;
    }
    try {
      if (file.existsSync() && file.lengthSync() > _maxBytes) {
        final old = File('${file.path}.1');
        if (old.existsSync()) {
          old.deleteSync();
        }
        file.renameSync(old.path);
      }
      file.writeAsStringSync(
          '${e.timestamp.toIso8601String()} ${e.level.name} [${e.tag}] ${e.message}\n',
          mode: FileMode.append,
          flush: true);
    } on FileSystemException {
      // A log that cannot be written never stops what was being logged.
    }
  }

  String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.success: return '✅';
      case LogLevel.error: return '❌';
      case LogLevel.warning: return '⚠️';
      case LogLevel.debug: return '🔍';
      default: return 'ℹ️';
    }
  }

  void dispose() => _controller.close();
}
