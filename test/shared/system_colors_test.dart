import 'package:apex_file_share/platform/system_colors.dart';
import 'package:apex_file_share/shared/apex_colors.dart';
import 'package:apex_file_share/shared/apex_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Owner decision (2026-11-28): on the desktop the app follows the system's
/// colours, whatever they are, and copies none of them into the code. The
/// colours below only stand in for some system: a dark one (as KDE's Breeze
/// sends them through GTK) and a light one.

const _darkSystem = {
  'theme_bg_color': Color(0xFF202326),
  'theme_base_color': Color(0xFF141618),
  'theme_fg_color': Color(0xFFFCFCFC),
  'theme_text_color': Color(0xFFFCFCFC),
  'theme_selected_bg_color': Color(0xFF3DAEE9),
  'theme_selected_fg_color': Color(0xFFFCFCFC),
  'borders': Color(0xFF4C4E51),
  'success_color': Color(0xFF27AE60),
  'error_color': Color(0xFFDA4453),
};

const _lightSystem = {
  'theme_bg_color': Color(0xFFF6F5F4),
  'theme_base_color': Color(0xFFFFFFFF),
  'theme_fg_color': Color(0xFF2E3436),
  'theme_selected_bg_color': Color(0xFF3584E4),
};

void main() {
  group('the roles are the system colours', () {
    final c = ApexColors.fromSystem(_darkSystem)!;

    test('laid out as the system lays out its own apps', () {
      expect(c.window, const Color(0xFF141618), reason: 'content on the view colour');
      expect(c.panel, const Color(0xFF202326), reason: 'sidebar and cards on the window colour');
      expect(c.text, const Color(0xFFFCFCFC));
      expect(c.panelBorder, const Color(0xFF4C4E51));
      expect(c.accent, const Color(0xFF3DAEE9));
      expect(c.danger, const Color(0xFFDA4453));
      expect(c.online, const Color(0xFF27AE60));
    });

    test('the in-between roles are mixes of the system colours, nothing of our own', () {
      Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
      expect(c.hover, mix(const Color(0xFF202326), const Color(0xFFFCFCFC), 0.06));
      expect(c.selected, mix(const Color(0xFF202326), const Color(0xFF3DAEE9), 0.3));
      expect(c.muted, mix(const Color(0xFFFCFCFC), const Color(0xFF141618), 0.28));
    });

    test('dark or light is read from the colours themselves', () {
      expect(c.brightness, Brightness.dark);
      expect(ApexColors.fromSystem(_lightSystem)!.brightness, Brightness.light);
    });

    test('a system that sends another theme gets that theme', () {
      final other = ApexColors.fromSystem(_lightSystem)!;
      expect(other.window, const Color(0xFFFFFFFF));
      expect(other.panel, const Color(0xFFF6F5F4));
      expect(other.text, const Color(0xFF2E3436), reason: 'text falls back to the foreground');
      expect(other.accent, const Color(0xFF3584E4));
    });

    test('without the colours every role needs, the app keeps its own', () {
      expect(ApexColors.fromSystem(const {}), isNull);
      expect(ApexColors.fromSystem({..._darkSystem}..remove('theme_selected_bg_color')), isNull);
    });
  });

  group('the theme', () {
    final system = ApexColors.fromSystem(_darkSystem)!;

    test('uses the system colours when they are as dark or light as asked', () {
      final t = apexTheme(Brightness.dark, system: system);
      expect(t.extension<ApexColors>()!.window, const Color(0xFF141618));
      expect(t.scaffoldBackgroundColor, const Color(0xFF141618));
      expect(t.colorScheme.primary, const Color(0xFF3DAEE9),
          reason: "Material's own widgets take the system's selection colour");
      expect(t.colorScheme.outline, const Color(0xFF4C4E51));
    });

    test('keeps light for a user who picked light in the app on a dark desktop', () {
      final t = apexTheme(Brightness.light, system: system);
      expect(t.extension<ApexColors>()!.window, ApexColors.light.window);
    });

    test('without system colours it is the app\'s own, as before', () {
      expect(apexTheme(Brightness.dark).extension<ApexColors>()!.window, ApexColors.dark.window);
    });
  });

  test('the channel map is read as name to colour, anything else dropped', () {
    final read = SystemColors.readColors({
      'theme_bg_color': 0xFF202326,
      'bad': 'x',
      3: 0xFF000000,
    });
    expect(read, {'theme_bg_color': const Color(0xFF202326)});
    expect(SystemColors.readColors(null), isEmpty);
  });
}
