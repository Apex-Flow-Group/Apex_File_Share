import 'package:material_ui/material_ui.dart';

import 'apex_colors.dart';

/// The head of every screen and sheet, one look everywhere. It fills the top
/// of what holds it: behind a phone's status bar, or under a sheet's handle
/// ([ApexSheetTop]); both reach it as its top padding, so the screen above
/// it must not take that padding away (no SafeArea top over it).
///
/// A faint gradient from a step off the window into the window (owner
/// decision): lighter in dark, darker in light, never a screen's colour. Its
/// icon is the text's colour on a neutral step.
class ApexHeader extends StatelessWidget {
  const ApexHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.detail,
    this.leading,
    this.trailing = const [],
    this.inset = 20,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// A fainter line under [subtitle], such as an address.
  final String? detail;

  /// Before the icon, such as back.
  final Widget? leading;
  final List<Widget> trailing;

  /// From the side edges, to start in line with the content below it.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ApexColors.of(context);
    final small = theme.textTheme.bodySmall;
    return Container(
      padding: EdgeInsets.fromLTRB(
          inset, MediaQuery.paddingOf(context).top + 16, inset, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [c.panel, c.window],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.circle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: c.onCircle, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: c.text)),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small?.copyWith(color: c.muted)),
                if (detail != null)
                  Text(detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small?.copyWith(color: c.hint, fontSize: 11)),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// A sheet's top: its handle, drawn on [header] when there is one.
class ApexSheetTop extends StatelessWidget {
  const ApexSheetTop({this.header, super.key});

  final Widget? header;

  static const _handleTop = 12.0;

  @override
  Widget build(BuildContext context) {
    final handle = Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
    if (header == null) {
      return Padding(
        padding: const EdgeInsets.only(top: _handleTop, bottom: 8),
        child: handle,
      );
    }
    final media = MediaQuery.of(context);
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        fit: StackFit.passthrough,
        children: [
          // The handle's room is the header's top padding, as the status bar
          // is on a screen.
          MediaQuery(
            data: media.copyWith(
                padding: media.padding.copyWith(top: _handleTop)),
            child: header!,
          ),
          // Positioned: passthrough would stretch it across the sheet.
          Positioned(top: _handleTop, child: handle),
        ],
      ),
    );
  }
}
