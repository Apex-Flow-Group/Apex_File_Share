import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../shared/apex_colors.dart';
import '../utils/apex_logger.dart';

/// The system's own colours, read while the app runs and read again when the
/// user changes them (owner decision: the app follows the system, whatever
/// it is, and copies no colour of it into the code).
///
/// Linux sends its theme's colours by their standard GTK names (KDE fills
/// them from its colour scheme). Windows gives apps only its accent colour,
/// as "accent_color". A system that sends none keeps the app's own colours.
class SystemColors extends ChangeNotifier {
  SystemColors._();
  static final instance = SystemColors._();

  static const _channel = MethodChannel('com.apex.core/system_colors');

  ApexColors? _palette;
  Color? _accent;

  /// The app's colours made from the system's, or null when it sent none.
  ApexColors? get palette => _palette;

  /// The accent colour the user picked in the system (Windows sends only
  /// this one), or null when it sent none.
  Color? get accent => _accent;

  Future<void> load() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') {
        _take(call.arguments);
      }
    });
    try {
      _take(await _channel.invokeMethod<Object?>('get'));
    } on MissingPluginException { // swallow-ok: this system sends no colours, which is the expected outcome there
      // This system sends no colours.
    } on PlatformException catch (e) {
      // Nor does a runner that failed to read them.
      ApexLogger.instance.log('THEME', 'The runner could not read the system colours: $e', LogLevel.warning);
    }
  }

  void _take(Object? raw) {
    final colors = readColors(raw);
    _palette = ApexColors.fromSystem(colors);
    _accent = colors['accent_color']?.withAlpha(255);
    notifyListeners();
  }

  /// The channel's map of name to 0xAARRGGBB, without anything else in it.
  @visibleForTesting
  static Map<String, Color> readColors(Object? raw) => {
        if (raw is Map)
          for (final e in raw.entries)
            if (e.key is String && e.value is int) e.key as String: Color(e.value as int),
      };
}
