import 'package:material_ui/material_ui.dart';

/// The app's colour roles, one place for every bar, panel and card (owner
/// decision): the warm greys measured from the owner's references, dark from
/// them and light by the same steps, not approved on a device yet. What is
/// selected is a surface a step lighter, not a colour; [accent] is for the TV
/// focus ring and the unread count only.
@immutable
class ApexColors extends ThemeExtension<ApexColors> {
  const ApexColors({
    required this.window,
    required this.panel,
    required this.panelBorder,
    required this.hover,
    required this.selected,
    required this.floating,
    required this.floatingSelected,
    required this.text,
    required this.muted,
    required this.capsule,
    required this.capsuleBorder,
    required this.circle,
    required this.onCircle,
    required this.filled,
    required this.onFilled,
    required this.hint,
    required this.accent,
    required this.danger,
    required this.online,
  });

  /// Behind everything.
  final Color window;

  /// A card, the sidebar, the TV bar: a step off the window.
  final Color panel;
  final Color panelBorder;

  /// A row under the mouse or the remote's focus.
  final Color hover;

  /// The selected row: two steps off the panel.
  final Color selected;

  /// A bar over content that passes under it, a step above the cards, or it
  /// melts into the card beneath (capsule-ui §2).
  final Color floating;
  final Color floatingSelected;

  /// Text and icons, near white in dark (capsule-ui §2).
  final Color text;

  /// What is not selected, and second lines.
  final Color muted;

  /// The framed capsule (capsule-ui §1b).
  final Color capsule;
  final Color capsuleBorder;

  /// A plain circle: one small step lighter than what it sits on.
  final Color circle;
  final Color onCircle;

  /// The one filled circle, the first action: the background's opposite.
  final Color filled;
  final Color onFilled;
  final Color hint;

  final Color accent;

  /// Block, delete: in the text, not the capsule (capsule-ui §0).
  final Color danger;

  /// The dot before a device that can be reached.
  final Color online;

  static const dark = ApexColors(
    window: Color(0xFF151515),
    panel: Color(0xFF1C1C1C),
    panelBorder: Color(0xFF2E2E2E),
    hover: Color(0xFF262626),
    selected: Color(0xFF2E2E2E),
    floating: Color(0xFF262626),
    floatingSelected: Color(0xFF363634),
    text: Color(0xFFF4F4F2),
    muted: Color(0xFFC8C8C4),
    capsule: Color(0xFF20201E),
    capsuleBorder: Color(0xFF3C3C3A),
    circle: Color(0xFF313131),
    onCircle: Color(0xFFF4F4F2),
    filled: Color(0xFFF9F9F7),
    onFilled: Color(0xFF1F1F1D),
    hint: Color(0xFF9A9792),
    // The app's purple a tone lighter on dark, as Material 3 tones it: the
    // light tone gave a focus ring under 3:1 on the window.
    accent: Color(0xFFD0BCFF),
    danger: Color(0xFFF2B8B5),
    online: Color(0xFF4CAF50),
  );

  static const light = ApexColors(
    window: Color(0xFFFFFFFF),
    panel: Color(0xFFF7F7F5),
    panelBorder: Color(0xFFE2E2DF),
    hover: Color(0xFFEDEDEA),
    selected: Color(0xFFE4E4E1),
    floating: Color(0xFFFFFFFF),
    floatingSelected: Color(0xFFE4E4E1),
    text: Color(0xFF1F1F1D),
    muted: Color(0xFF4A4A47),
    capsule: Color(0xFFF1F1EF),
    capsuleBorder: Color(0xFFCFCFCB),
    circle: Color(0xFFE2E2DF),
    onCircle: Color(0xFF1F1F1D),
    filled: Color(0xFF1F1F1D),
    onFilled: Color(0xFFF9F9F7),
    hint: Color(0xFF66645F),
    accent: Color(0xFF6750A4),
    danger: Color(0xFFB3261E),
    online: Color(0xFF2E7D32),
  );

  /// The app's roles made from the system's colours, by their GTK names
  /// (owner decision: the desktop app follows the system, whatever it is).
  /// Every role is one of the system's colours or a mix of two of them, laid
  /// out as the system's own apps are: the content on the view colour, the
  /// sidebar and cards on the window colour. Null without the colours every
  /// role needs.
  static ApexColors? fromSystem(Map<String, Color> s) {
    final view = s['theme_base_color'];
    final window = s['theme_bg_color'];
    final fg = s['theme_fg_color'];
    final selection = s['theme_selected_bg_color'];
    if (view == null || window == null || fg == null || selection == null) {
      return null;
    }
    final text = s['theme_text_color'] ?? fg;
    final border = s['borders'] ?? Color.lerp(window, fg, 0.2)!;
    Color mix(Color a, Color b, double t) => Color.lerp(a.withAlpha(255), b.withAlpha(255), t)!;
    final floating = mix(window, fg, 0.05);
    return ApexColors(
      window: view.withAlpha(255),
      panel: window.withAlpha(255),
      panelBorder: border.withAlpha(255),
      hover: mix(window, fg, 0.06),
      selected: mix(window, selection, 0.3),
      floating: floating,
      floatingSelected: mix(floating, selection, 0.3),
      text: text.withAlpha(255),
      muted: mix(text, view, 0.28),
      capsule: view.withAlpha(255),
      capsuleBorder: border.withAlpha(255),
      circle: mix(window, fg, 0.1),
      onCircle: fg.withAlpha(255),
      filled: text.withAlpha(255),
      onFilled: view.withAlpha(255),
      hint: mix(text, view, 0.42),
      accent: selection.withAlpha(255),
      danger: (s['error_color'] ?? (view.computeLuminance() < 0.5 ? dark : light).danger).withAlpha(255),
      online: (s['success_color'] ?? (view.computeLuminance() < 0.5 ? dark : light).online).withAlpha(255),
    );
  }

  /// These colours with the system's [accent] for what is selected and for
  /// the accent role: a system that gives only its accent (Windows) keeps
  /// the rest of the app's own.
  ApexColors withAccent(Color accent) {
    final a = accent.withAlpha(255);
    return ApexColors(
      window: window,
      panel: panel,
      panelBorder: panelBorder,
      hover: hover,
      selected: Color.lerp(panel, a, 0.3)!,
      floating: floating,
      floatingSelected: Color.lerp(floating, a, 0.3)!,
      text: text,
      muted: muted,
      capsule: capsule,
      capsuleBorder: capsuleBorder,
      circle: circle,
      onCircle: onCircle,
      filled: filled,
      onFilled: onFilled,
      hint: hint,
      accent: a,
      danger: danger,
      online: online,
    );
  }

  /// Dark or light, read from what is behind everything.
  Brightness get brightness =>
      window.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light;

  /// Falls back by brightness, so a widget pumped without the app's theme
  /// still has its colours.
  static ApexColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ApexColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  ApexColors copyWith() => this;

  @override
  ApexColors lerp(ApexColors? other, double t) {
    if (other == null) {
      return this;
    }
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ApexColors(
      window: l(window, other.window),
      panel: l(panel, other.panel),
      panelBorder: l(panelBorder, other.panelBorder),
      hover: l(hover, other.hover),
      selected: l(selected, other.selected),
      floating: l(floating, other.floating),
      floatingSelected: l(floatingSelected, other.floatingSelected),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      capsule: l(capsule, other.capsule),
      capsuleBorder: l(capsuleBorder, other.capsuleBorder),
      circle: l(circle, other.circle),
      onCircle: l(onCircle, other.onCircle),
      filled: l(filled, other.filled),
      onFilled: l(onFilled, other.onFilled),
      hint: l(hint, other.hint),
      accent: l(accent, other.accent),
      danger: l(danger, other.danger),
      online: l(online, other.online),
    );
  }
}
