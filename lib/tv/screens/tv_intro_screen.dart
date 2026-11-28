import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/settings_service.dart';
import '../../shared/apex_colors.dart';
import 'tv_tour_screen.dart';

class TVIntroScreen extends StatefulWidget {
  final SettingsService settings;
  const TVIntroScreen({required this.settings, super.key});

  @override
  State<TVIntroScreen> createState() => _TVIntroScreenState();
}

class _TVIntroScreenState extends State<TVIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonFade;
  late Animation<double> _shimmer;

  final FocusNode _btnFocus = FocusNode(debugLabel: 'intro-start');

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _titleSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.35, curve: Curves.easeIn)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 0.55, curve: Curves.easeIn)),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.6, 0.85, curve: Curves.easeIn)),
    );
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // فور ظهور الزر نضع الفوكس عليه
    _ctrl.addListener(() {
      if (_ctrl.value >= 0.85 && !_btnFocus.hasFocus) {
        _btnFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _btnFocus.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TVTourScreen(settings: widget.settings),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ApexColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(children: [
          // خلفية
          _TVBackground(progress: _ctrl.value),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Transform.translate(
                  offset:
                      Offset(isAr ? _titleSlide.value : -_titleSlide.value, 0),
                  child: Opacity(
                    opacity: _titleFade.value,
                    child: _ShimmerText(
                      text: l10n.appTitle,
                      fontSize: 72,
                      shimmer: _shimmer.value,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // الوصف
                Opacity(
                  opacity: _subtitleFade.value,
                  child: _ShimmerText(
                    text: l10n.fastAndSecure,
                    fontSize: 24,
                    shimmer: _shimmer.value,
                  ),
                ),
                const SizedBox(height: 64),
                // الزر
                Opacity(
                  opacity: _buttonFade.value,
                  child: Focus(
                    focusNode: _btnFocus,
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.enter)) {
                        _next();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(builder: (ctx) {
                      final hasFocus = Focus.of(ctx).hasFocus;
                      return GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 280,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(29),
                            color: hasFocus
                                ? c.brandSoft
                                : Colors.transparent,
                            border: Border.all(
                              color: hasFocus
                                  ? c.brandSoft
                                  : c.brandDeep,
                              width: hasFocus ? 0 : 2,
                            ),
                            boxShadow: hasFocus
                                ? [
                                    BoxShadow(
                                      color: c.brandSoft
                                          .withValues(alpha: 0.5),
                                      blurRadius: 24,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              l10n.startTour,
                              style: TextStyle(
                                color: c.onTint,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────

class _TVBackground extends StatelessWidget {
  final double progress;
  const _TVBackground({required this.progress});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BGPainter(progress, ApexColors.of(context)),
        child: const SizedBox.expand(),
      );
}

class _BGPainter extends CustomPainter {
  final double p;
  final ApexColors c;
  _BGPainter(this.p, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.introNight,
            c.introNightLift,
            c.introNight
          ],
          stops: [
            (sin(p * pi * 2) * 0.1).clamp(0.0, 1.0),
            0.5,
            1.0,
          ],
        ).createShader(rect),
    );
    for (var i = 0; i < 15; i++) {
      final x = (i * 80.0 + p * 120) % size.width;
      final y = (i * 50.0 + sin(p * pi + i) * 60) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        35,
        Paint()
          ..color = c.brand.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }
  }

  @override
  bool shouldRepaint(_BGPainter o) => o.p != p;
}

// ─── Shimmer Text ─────────────────────────────────────────────────────────────

class _ShimmerText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double shimmer;
  const _ShimmerText(
      {required this.text, required this.fontSize, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final c = ApexColors.of(context);
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          c.brand,
          c.brandSoft,
          c.brandPale,
          c.brandSoft,
          c.brand,
        ],
        stops: [
          max(0.0, shimmer - 0.3),
          max(0.0, shimmer - 0.1),
          shimmer.clamp(0.0, 1.0),
          min(1.0, shimmer + 0.1),
          min(1.0, shimmer + 0.3),
        ],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: c.onTint,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
