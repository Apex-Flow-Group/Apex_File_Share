import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/device.dart';
import '../../../models/transfer_progress.dart';
import '../../../services/transfer_progress_service.dart';
import '../../../shared/apex_colors.dart';
import '../../../shared/apex_header.dart';
import '../../../shared/apex_snackbar.dart';
import '../tv_focusable_widgets.dart';

class TVReceiveTab extends StatefulWidget {
  final Device? localDevice;
  final bool isRunning;
  final bool startFailed;
  final VoidCallback onRetry;
  final VoidCallback? onBackToSidebar;
  final FocusNode? contentFocusNode;
  const TVReceiveTab({
    required this.localDevice,
    required this.isRunning,
    required this.startFailed,
    required this.onRetry,
    this.onBackToSidebar,
    this.contentFocusNode,
    super.key,
  });

  @override
  State<TVReceiveTab> createState() => _TVReceiveTabState();
}

class _TVReceiveTabState extends State<TVReceiveTab>
    with SingleTickerProviderStateMixin {
  bool _isReceiving = false;
  bool _cancelledByUser = false;
  late AnimationController _pulseAnim;
  late final FocusNode _copyFocus;
  final FocusNode _cancelFocus = FocusNode(debugLabel: 'cancel-receive');

  @override
  void initState() {
    super.initState();
    _copyFocus = widget.contentFocusNode ?? FocusNode(debugLabel: 'copy-ip');
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    TransferProgressService().progressStream.listen((p) {
      if (!mounted) {
        return;
      }
      if (_cancelledByUser) {
        if (p == null) {
          _cancelledByUser = false;
        }
        return;
      }
      final svc = TransferProgressService();
      setState(() => _isReceiving =
          !svc.isSending && p?.status == TransferStatus.transferring);
    });
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    if (widget.contentFocusNode == null) {
      _copyFocus.dispose();
    }
    _cancelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: widget.localDevice == null || !widget.isRunning
                ? _buildNotReady()
                : _buildReady(),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return ApexHeader(
      icon: Icons.smartphone_rounded,
      title: l10n.receive,
    );
  }

  // ─── Not Ready ─────────────────────────────────────────────────────────────

  Widget _buildNotReady() {
    final c = ApexColors.of(context);
    final l10n = AppLocalizations.of(context);
    if (!widget.startFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.starting,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: c.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 64, color: c.warning),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.startFailed,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // The content focus node: the remote reaches it from the sidebar.
            TVFocusableButton(
              focusNode: _copyFocus,
              onTap: widget.onRetry,
              color: c.warning,
              label: l10n.retry,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ready ─────────────────────────────────────────────────────────────────

  Widget _buildReady() {
    final l10n = AppLocalizations.of(context);
    final device = widget.localDevice!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(l10n),
          const SizedBox(height: 14),
          _buildDeviceCard(device, l10n),
          const SizedBox(height: 14),
          _buildTipsCard(l10n),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n) {
    final c = ApexColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isReceiving
                ? [
                    c.accent
                        .withValues(alpha: 0.15 + _pulseAnim.value * 0.05),
                    c.accent.withValues(alpha: 0.05),
                  ]
                : [
                    c.success.withValues(alpha: isDark ? 0.15 : 0.08),
                    c.success.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isReceiving
                ? c.accent.withValues(alpha: 0.3)
                : c.success.withValues(alpha: 0.2),
          ),
        ),
        child: _isReceiving
            ? _buildReceivingContent()
            : _buildReadyContent(l10n),
      ),
    );
  }

  Widget _buildReadyContent(AppLocalizations l10n) {
    final c = ApexColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.check_circle_rounded,
              size: 36, color: c.success),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.readyToReceive,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: c.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceivingContent() {
    final c = ApexColors.of(context);
    return StreamBuilder<TransferProgress?>(
      stream: TransferProgressService().progressStream,
      builder: (context, snapshot) {
        final p = snapshot.data;
        final svc = TransferProgressService();
        if (svc.isSending) {
          return _buildReadyContent(AppLocalizations.of(context));
        }
        final senderName = svc.senderDeviceName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).receiving,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: c.accent,
                      ),
                    ),
                    if (senderName != null && senderName.isNotEmpty)
                      Text(
                        AppLocalizations.of(context).fromSender(senderName),
                        style: TextStyle(
                          fontSize: 12,
                          color: c.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (p != null)
                Text(p.speedFormatted,
                    style: TextStyle(fontSize: 12, color: c.accent)),
              const SizedBox(width: 8),
              // Cancel button — focusable for remote
              TVFocusableButton(
                focusNode: _cancelFocus,
                onTap: () {
                  _cancelledByUser = true;
                  TransferProgressService().cancelReceive();
                  setState(() => _isReceiving = false);
                },
                color: c.critical,
                label: AppLocalizations.of(context).cancel,
              ),
            ]),
            if (p != null) ...[
              const SizedBox(height: 14),
              Text(p.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.percentage / 100,
                  minHeight: 8,
                  backgroundColor: c.accent.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(c.accent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: c.accent,
                          fontWeight: FontWeight.w600)),
                  Text(p.remainingTimeFormatted(AppLocalizations.of(context)),
                      style: TextStyle(fontSize: 12, color: c.inactive)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDeviceCard(Device device, AppLocalizations l10n) {
    final c = ApexColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.phone_android_rounded,
                size: 16, color: c.inactive),
            const SizedBox(width: 6),
            Text(l10n.thisDevice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: c.inactive,
                )),
          ]),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.badge_rounded,
            iconColor: c.tintBlue,
            label: l10n.deviceName,
            value: device.name,
          ),
          if (device.hostname != null && device.hostname!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _infoTileWithCopy(
              icon: Icons.tv_rounded,
              iconColor: c.tintOrange,
              label: l10n.hostnameTv,
              value: device.hostname!,
            ),
          ],
          if (device.ip.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _infoTileWithCopy(
              icon: Icons.wifi_rounded,
              iconColor: c.tintGreen,
              label: l10n.ipAddress,
              value: device.ip,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTileWithCopy({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        // Copy button — focusable for TV remote
        TVFocusableIconButton(
          focusNode: _copyFocus,
          icon: Icons.copy_rounded,
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ApexSnackBar.info(context, AppLocalizations.of(context).textCopied);
          },
        ),
      ],
    );
  }

  Widget _buildTipsCard(AppLocalizations l10n) {
    final c = ApexColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = c.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tips_and_updates_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(l10n.howToReceive,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                )),
          ]),
          const SizedBox(height: 10),
          _tipRow('1', l10n.instruction1),
          _tipRow('2', l10n.instruction3),
          _tipRow('3', l10n.instruction4),
        ],
      ),
    );
  }

  Widget _tipRow(String num, String text) {
    final c = ApexColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(num,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: c.accent,
                  )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── TV Focusable Button ──────────────────────────────────────────────────────
