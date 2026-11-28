import 'package:material_ui/material_ui.dart';

import 'apex_colors.dart';

/// The app's theme, light and dark, built on [ApexColors].
///
/// [system] is the system's own colours ([ApexColors.fromSystem]); they are
/// used when they are as dark or light as asked, so a user who picked light
/// in the app on a dark desktop still gets light. Without them, [accent] is
/// the accent the user picked in the system (Windows gives only that one):
/// what is selected and Material's own widgets take it, the rest stays the
/// app's own.
ThemeData apexTheme(Brightness brightness, {ApexColors? system, Color? accent}) {
  final isLight = brightness == Brightness.light;
  final fromSystem = system != null && system.brightness == brightness;
  final own = isLight ? ApexColors.light : ApexColors.dark;
  final c = fromSystem ? system : (accent != null ? own.withAccent(accent) : own);
  // Material's own accent and lines: the system's selection and borders when
  // the colours are the system's, and its accent when only that is.
  final followsAccent = fromSystem || accent != null;
  final primary = followsAccent ? c.accent : const Color(0xFF6750A4);
  // Black or white on it, whichever the accent is lighter or darker for, as
  // the system itself does.
  final onPrimary = !followsAccent || primary.computeLuminance() < 0.4
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
  final line = fromSystem
      ? c.panelBorder
      : (isLight ? const Color(0xFFCAC4D0) : const Color(0xFF938F99));
  return ThemeData(
    useMaterial3: true,
    extensions: [c],
    scaffoldBackgroundColor: c.window,
    // The surfaces are the roles' steps, so Material's own widgets (dialogs,
    // menus, sheets) sit on the same greys as the bars and cards.
    colorScheme: (isLight ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: const Color(0xFF00897B),
      onSecondary: const Color(0xFFFFFFFF),
      error: c.danger,
      surface: c.window,
      onSurface: c.text,
      surfaceContainer: c.panel,
      surfaceContainerHigh: c.hover,
      surfaceContainerHighest: c.circle,
      onSurfaceVariant: c.muted,
      outline: line,
    ),
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: line,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: line,
      thickness: 1,
    ),
  );
}
