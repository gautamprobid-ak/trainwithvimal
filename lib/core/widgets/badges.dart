import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum BadgeTone {
  ok(AppColors.okBg, AppColors.okText),
  warn(AppColors.warnBg, AppColors.warnText),
  bad(AppColors.badBg, AppColors.badText),
  info(AppColors.infoBg, AppColors.infoText),
  neutral(AppColors.sub, AppColors.text2);

  const BadgeTone(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

/// Badge (radius 6, h 22). Status badges show a dot; labels don't.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.tone = BadgeTone.neutral, this.dot = false, this.icon});

  /// Status badge with a dot (Active, Pending, At risk, Paused ...).
  const AppBadge.status(this.label, {super.key, required this.tone, this.icon}) : dot = true;

  final String label;
  final BadgeTone tone;
  final bool dot;
  final IconData? icon;

  /// Maps the status words used across the design to a tone.
  static BadgeTone toneFor(String status) => switch (status.toLowerCase()) {
        'active' || 'done' || 'on' || 'approved' || 'reviewed' || 'met' || 'live' || 'sent' || 'paid' => BadgeTone.ok,
        'pending' || 'due' || 'due today' || 'waiting' || 'draft' || 'new' => BadgeTone.warn,
        'at risk' || 'overdue' || 'missed' || 'failed' || 'rejected' || 'expired' => BadgeTone.bad,
        'updated' || 'scheduled' || 'info' => BadgeTone.info,
        _ => BadgeTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(AppRadius.badge)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[Icon(icon, size: 13, color: tone.fg), const SizedBox(width: 4)],
          Text(label, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: tone.fg)),
        ],
      ),
    );
  }
}

/// Grey chip (ca-chip) — tags like "Strength", "6 exercises".
class AppChip extends StatelessWidget {
  const AppChip(this.label, {super.key, this.icon, this.color = AppColors.sub, this.textColor = AppColors.text2});
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: textColor), const SizedBox(width: 4)],
          Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

/// Selectable pill (filter chips, quick picks). Selected = dark fill.
class ChoicePill extends StatelessWidget {
  const ChoicePill(this.label, {super.key, required this.selected, this.onTap, this.count, this.icon, this.accent = false});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  final IconData? icon;

  /// Use accent blue instead of dark for the selected state.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final selBg = accent ? AppColors.accentSoft : AppColors.text;
    final selFg = accent ? AppColors.accentText : Colors.white;
    return Material(
      color: selected ? selBg : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? (accent ? AppColors.accent : AppColors.text) : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: selected ? selFg : AppColors.text2), const SizedBox(width: 5)],
              Text(
                label,
                style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: selected ? selFg : AppColors.text2),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text('$count',
                    style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700, color: selected ? selFg.withValues(alpha: .75) : AppColors.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small red count badge (nav badge / unread counts).
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.bad,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text('$count', style: AppText.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
    );
  }
}
