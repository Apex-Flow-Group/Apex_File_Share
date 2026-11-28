import 'package:material_ui/material_ui.dart';

import 'apex_colors.dart';

/// The app's theme, light and dark, built on [ApexColors].
///
/// [system] is the system's own colours ([ApexColors.fromSystem]); they are
/// used when they are as dark or light as asked, so a user who picked light
/// in the app on a dark desktop still gets light.
ThemeData apexTheme(Brightness brightness, {ApexColors? system}) {
  final isLight = brightness == Brightness.light;
  final fromSystem = system != null && system.brightness == brightness;
  final c = fromSystem ? system : (isLight ? ApexColors.light : ApexColors.dark);
  // Material's own accent and lines: the system's selection and borders when
  // the colours are the system's.
  final primary = fromSystem ? c.accent : const Color(0xFF6750A4);
  final onPrimary = fromSystem ? c.onFilled : const Color(0xFFFFFFFF);
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
