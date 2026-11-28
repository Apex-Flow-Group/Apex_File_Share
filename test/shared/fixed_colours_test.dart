import 'package:apex_file_share/shared/apex_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Owner decision (2026-11-28): the colours the screens wrote by hand became
/// roles with the values they had, in dark and in light; only the purple
/// went to the accent. The Material names below are those old values.
void main() {
  const dark = ApexColors.dark;
  const light = ApexColors.light;

  // A MaterialColor is never == a plain Color, so the values are compared.
  void same(Color actual, Color? old) {
    expect(actual.toARGB32(), old!.toARGB32());
  }

  test('status and neutral roles keep the Material values the screens had', () {
    for (final c in [dark, light]) {
      same(c.success, Colors.green);
      same(c.warning, Colors.orange);
      same(c.info, Colors.blue);
      same(c.critical, Colors.red);
      same(c.inactive, Colors.grey);
      same(c.caption, Colors.grey[600]);
      same(c.captionStrong, Colors.grey[700]);
      same(c.onTint, Colors.white);
      same(c.paper, Colors.white);
      same(c.shadow, Colors.black);
    }
  });

  test('a surface or ink that differed by brightness keeps both values', () {
    same(dark.sheetSurface, Colors.grey[900]);
    same(light.sheetSurface, Colors.white);
    same(dark.veil, Colors.white);
    same(light.veil, Colors.black);
    same(dark.inkSoft, Colors.white54);
    same(light.inkSoft, Colors.black45);
    same(dark.inkMid, Colors.white60);
    same(light.inkMid, Colors.black54);
    same(dark.inkBody, Colors.white70);
    same(light.inkBody, Colors.black87);
    same(dark.inkIcon, Colors.white70);
    same(light.inkIcon, Colors.black54);
    same(dark.inkFaint, Colors.white38);
    same(light.inkFaint, Colors.black38);
    same(dark.inkEdge, Colors.white30);
    same(light.inkEdge, Colors.black26);
    same(dark.heading, Colors.white);
    same(light.heading, Colors.black);
  });

  test('a system that gives its own colours still gets the fixed roles by its brightness', () {
    final system = ApexColors.fromSystem(const {
      'theme_bg_color': Color(0xFF202326),
      'theme_base_color': Color(0xFF141618),
      'theme_fg_color': Color(0xFFFCFCFC),
      'theme_selected_bg_color': Color(0xFF3DAEE9),
    })!;
    expect(system.cardSurface, dark.cardSurface);
    expect(system.bubble, dark.bubble);
    expect(system.accent, const Color(0xFF3DAEE9));
    expect(dark.withAccent(const Color(0xFF3DAEE9)).cardSurface, dark.cardSurface);
  });
}
