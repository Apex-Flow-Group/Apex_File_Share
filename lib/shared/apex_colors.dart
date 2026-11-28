import 'package:material_ui/material_ui.dart';

/// The app's colour roles, one place for every bar, panel and card (owner
/// decision): the warm greys measured from the owner's references, dark from
/// them and light by the same steps, not approved on a device yet. What is
/// selected is a surface a step lighter, not a colour; [accent] is the
/// system's accent: the TV focus ring, the unread count and a share's, a
/// desktop's and a video's own colour.
///
/// No screen writes a colour by hand (test/guards/no_hand_colours_test.dart):
/// the roles after [online] are fixed, the same in every system's colours.
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
    required this.success,
    required this.warning,
    required this.info,
    required this.critical,
    required this.tintBlue,
    required this.tintGreen,
    required this.tintOrange,
    required this.tintRed,
    required this.tintPink,
    required this.tintCyan,
    required this.tintTeal,
    required this.tintGrey,
    required this.inactive,
    required this.caption,
    required this.captionStrong,
    required this.onTint,
    required this.paper,
    required this.shadow,
    required this.veil,
    required this.cardSurface,
    required this.groupSurface,
    required this.dialogSurface,
    required this.sheetSurface,
    required this.screenBackdrop,
    required this.browserBackdrop,
    required this.bubble,
    required this.splashBackground,
    required this.splashText,
    required this.titleInk,
    required this.heading,
    required this.inkSoft,
    required this.inkMid,
    required this.inkBody,
    required this.inkIcon,
    required this.inkFaint,
    required this.inkEdge,
    required this.brand,
    required this.brandSoft,
    required this.brandPale,
    required this.brandDeep,
    required this.introNight,
    required this.introNightLift,
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

  /// What is drawn on [accent]: black on a light one, white on a dark one,
  /// as the theme's onPrimary. The accent is the user's choice, so its
  /// lightness is not known in advance.
  Color get onAccent => accent.computeLuminance() < 0.4
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);

  /// Block, delete: in the text, not the capsule (capsule-ui §0).
  final Color danger;

  /// The dot before a device that can be reached.
  final Color online;

  // Status, the same in dark and light.
  /// A good result: saved, up to date, received.
  final Color success;
  /// Caution: a note that needs a look.
  final Color warning;
  /// A notice or a link.
  final Color info;
  /// A failure or a delete, as a fill or an icon.
  final Color critical;

  // A tile with a hue of its own (a file's type, a device's type, a settings or tour tile): the same in dark and light.
  final Color tintBlue;
  final Color tintGreen;
  final Color tintOrange;
  final Color tintRed;
  final Color tintPink;
  final Color tintCyan;
  final Color tintTeal;
  final Color tintGrey;

  // Greys and what sits on a coloured fill, the same in dark and light.
  /// Hints, empty-state icons and what is switched off.
  final Color inactive;
  /// A line under a title.
  final Color caption;
  /// A caption a step darker: the source link.
  final Color captionStrong;
  /// Text and icons on a coloured fill.
  final Color onTint;
  /// What a QR code is printed on: white in both, or it does not scan.
  final Color paper;
  /// Black for shadows and scrims, with its own alpha.
  final Color shadow;
  /// A wash over a surface, with its own alpha: white in dark, black in light.
  final Color veil;

  // Surfaces of the screens that had them by hand: dark and light differ.
  /// A card in a tab and in settings.
  final Color cardSurface;
  /// A group of rows in settings and the tour.
  final Color groupSurface;
  /// A TV dialog and the transfer card.
  final Color dialogSurface;
  /// A bottom sheet.
  final Color sheetSurface;
  /// Behind the TV's pickers and its details panel.
  final Color screenBackdrop;
  /// Behind the shared folder's browser.
  final Color browserBackdrop;
  /// A chat bubble.
  final Color bubble;
  /// Behind the splash.
  final Color splashBackground;
  /// The splash's name.
  final Color splashText;
  /// A transfer's or clipboard item's name.
  final Color titleInk;
  /// A panel's title.
  final Color heading;

  // Text and icons on those surfaces, from the faintest to the strongest.
  /// Close icons and second lines.
  final Color inkSoft;
  /// A row's icon.
  final Color inkMid;
  /// A row's text.
  final Color inkBody;
  /// A back icon.
  final Color inkIcon;
  /// The faintest line and icon.
  final Color inkFaint;
  /// An unticked box's edge.
  final Color inkEdge;

  // The splash and the intro's own look, the same in dark and light.
  final Color brand;
  final Color brandSoft;
  final Color brandPale;
  final Color brandDeep;
  final Color introNight;
  final Color introNightLift;

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
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    info: Color(0xFF2196F3),
    critical: Color(0xFFF44336),
    tintBlue: Color(0xFF007AFF),
    tintGreen: Color(0xFF34C759),
    tintOrange: Color(0xFFFF9500),
    tintRed: Color(0xFFFF3B30),
    tintPink: Color(0xFFFF2D55),
    tintCyan: Color(0xFF32ADE6),
    tintTeal: Color(0xFF30B0C7),
    tintGrey: Color(0xFF8E8E93),
    inactive: Color(0xFF9E9E9E),
    caption: Color(0xFF757575),
    captionStrong: Color(0xFF616161),
    onTint: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    shadow: Color(0xFF000000),
    veil: Color(0xFFFFFFFF),
    cardSurface: Color(0xFF1E1E1E),
    groupSurface: Color(0xFF1C1C1E),
    dialogSurface: Color(0xFF2C2C2E),
    sheetSurface: Color(0xFF212121),
    screenBackdrop: Color(0xFF1C1C1E),
    browserBackdrop: Color(0xFF1C1C1E),
    bubble: Color(0xFF2C2C2E),
    splashBackground: Color(0xFF0D0D0F),
    splashText: Color(0xFFFFFFFF),
    titleInk: Color(0xFFFFFFFF),
    heading: Color(0xFFFFFFFF),
    inkSoft: Color(0x8AFFFFFF),
    inkMid: Color(0x99FFFFFF),
    inkBody: Color(0xB3FFFFFF),
    inkIcon: Color(0xB3FFFFFF),
    inkFaint: Color(0x62FFFFFF),
    inkEdge: Color(0x4DFFFFFF),
    brand: Color(0xFF6750A4),
    brandSoft: Color(0xFF9575CD),
    brandPale: Color(0xFFE1BEE7),
    brandDeep: Color(0xFF7E57C2),
    introNight: Color(0xFF1A237E),
    introNightLift: Color(0xFF283593),
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
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    info: Color(0xFF2196F3),
    critical: Color(0xFFF44336),
    tintBlue: Color(0xFF007AFF),
    tintGreen: Color(0xFF34C759),
    tintOrange: Color(0xFFFF9500),
    tintRed: Color(0xFFFF3B30),
    tintPink: Color(0xFFFF2D55),
    tintCyan: Color(0xFF32ADE6),
    tintTeal: Color(0xFF30B0C7),
    tintGrey: Color(0xFF8E8E93),
    inactive: Color(0xFF9E9E9E),
    caption: Color(0xFF757575),
    captionStrong: Color(0xFF616161),
    onTint: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    shadow: Color(0xFF000000),
    veil: Color(0xFF000000),
    cardSurface: Color(0xFFFFFFFF),
    groupSurface: Color(0xFFFFFFFF),
    dialogSurface: Color(0xFFFFFFFF),
    sheetSurface: Color(0xFFFFFFFF),
    screenBackdrop: Color(0xFFF5F5F7),
    browserBackdrop: Color(0xFFF2F2F7),
    bubble: Color(0xFFF0F0F2),
    splashBackground: Color(0xFFF5F3FF),
    splashText: Color(0xFF1C1B1F),
    titleInk: Color(0xFF1C1C1E),
    heading: Color(0xFF000000),
    inkSoft: Color(0x73000000),
    inkMid: Color(0x8A000000),
    inkBody: Color(0xDD000000),
    inkIcon: Color(0x8A000000),
    inkFaint: Color(0x61000000),
    inkEdge: Color(0x42000000),
    brand: Color(0xFF6750A4),
    brandSoft: Color(0xFF9575CD),
    brandPale: Color(0xFFE1BEE7),
    brandDeep: Color(0xFF7E57C2),
    introNight: Color(0xFF1A237E),
    introNightLift: Color(0xFF283593),
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
    final base = view.computeLuminance() < 0.5 ? dark : light;
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
      success: base.success,
      warning: base.warning,
      info: base.info,
      critical: base.critical,
      tintBlue: base.tintBlue,
      tintGreen: base.tintGreen,
      tintOrange: base.tintOrange,
      tintRed: base.tintRed,
      tintPink: base.tintPink,
      tintCyan: base.tintCyan,
      tintTeal: base.tintTeal,
      tintGrey: base.tintGrey,
      inactive: base.inactive,
      caption: base.caption,
      captionStrong: base.captionStrong,
      onTint: base.onTint,
      paper: base.paper,
      shadow: base.shadow,
      veil: base.veil,
      cardSurface: base.cardSurface,
      groupSurface: base.groupSurface,
      dialogSurface: base.dialogSurface,
      sheetSurface: base.sheetSurface,
      screenBackdrop: base.screenBackdrop,
      browserBackdrop: base.browserBackdrop,
      bubble: base.bubble,
      splashBackground: base.splashBackground,
      splashText: base.splashText,
      titleInk: base.titleInk,
      heading: base.heading,
      inkSoft: base.inkSoft,
      inkMid: base.inkMid,
      inkBody: base.inkBody,
      inkIcon: base.inkIcon,
      inkFaint: base.inkFaint,
      inkEdge: base.inkEdge,
      brand: base.brand,
      brandSoft: base.brandSoft,
      brandPale: base.brandPale,
      brandDeep: base.brandDeep,
      introNight: base.introNight,
      introNightLift: base.introNightLift,
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
      success: success,
      warning: warning,
      info: info,
      critical: critical,
      tintBlue: tintBlue,
      tintGreen: tintGreen,
      tintOrange: tintOrange,
      tintRed: tintRed,
      tintPink: tintPink,
      tintCyan: tintCyan,
      tintTeal: tintTeal,
      tintGrey: tintGrey,
      inactive: inactive,
      caption: caption,
      captionStrong: captionStrong,
      onTint: onTint,
      paper: paper,
      shadow: shadow,
      veil: veil,
      cardSurface: cardSurface,
      groupSurface: groupSurface,
      dialogSurface: dialogSurface,
      sheetSurface: sheetSurface,
      screenBackdrop: screenBackdrop,
      browserBackdrop: browserBackdrop,
      bubble: bubble,
      splashBackground: splashBackground,
      splashText: splashText,
      titleInk: titleInk,
      heading: heading,
      inkSoft: inkSoft,
      inkMid: inkMid,
      inkBody: inkBody,
      inkIcon: inkIcon,
      inkFaint: inkFaint,
      inkEdge: inkEdge,
      brand: brand,
      brandSoft: brandSoft,
      brandPale: brandPale,
      brandDeep: brandDeep,
      introNight: introNight,
      introNightLift: introNightLift,
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
      success: l(success, other.success),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      critical: l(critical, other.critical),
      tintBlue: l(tintBlue, other.tintBlue),
      tintGreen: l(tintGreen, other.tintGreen),
      tintOrange: l(tintOrange, other.tintOrange),
      tintRed: l(tintRed, other.tintRed),
      tintPink: l(tintPink, other.tintPink),
      tintCyan: l(tintCyan, other.tintCyan),
      tintTeal: l(tintTeal, other.tintTeal),
      tintGrey: l(tintGrey, other.tintGrey),
      inactive: l(inactive, other.inactive),
      caption: l(caption, other.caption),
      captionStrong: l(captionStrong, other.captionStrong),
      onTint: l(onTint, other.onTint),
      paper: l(paper, other.paper),
      shadow: l(shadow, other.shadow),
      veil: l(veil, other.veil),
      cardSurface: l(cardSurface, other.cardSurface),
      groupSurface: l(groupSurface, other.groupSurface),
      dialogSurface: l(dialogSurface, other.dialogSurface),
      sheetSurface: l(sheetSurface, other.sheetSurface),
      screenBackdrop: l(screenBackdrop, other.screenBackdrop),
      browserBackdrop: l(browserBackdrop, other.browserBackdrop),
      bubble: l(bubble, other.bubble),
      splashBackground: l(splashBackground, other.splashBackground),
      splashText: l(splashText, other.splashText),
      titleInk: l(titleInk, other.titleInk),
      heading: l(heading, other.heading),
      inkSoft: l(inkSoft, other.inkSoft),
      inkMid: l(inkMid, other.inkMid),
      inkBody: l(inkBody, other.inkBody),
      inkIcon: l(inkIcon, other.inkIcon),
      inkFaint: l(inkFaint, other.inkFaint),
      inkEdge: l(inkEdge, other.inkEdge),
      brand: l(brand, other.brand),
      brandSoft: l(brandSoft, other.brandSoft),
      brandPale: l(brandPale, other.brandPale),
      brandDeep: l(brandDeep, other.brandDeep),
      introNight: l(introNight, other.introNight),
      introNightLift: l(introNightLift, other.introNightLift),
    );
  }
}
