import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import 'trainer_widgets.dart';

/// Blue hero at the top of the trainer dashboard (th-hero).
class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key, required this.subline, required this.unread, required this.onBell, required this.onNew, required this.onMe});
  final String subline;
  final bool unread;
  final VoidCallback onBell;
  final VoidCallback onNew;
  final VoidCallback onMe;

  static const contentHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: contentHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: Text(TrainerMock.dashboardDate,
                        style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: .95))),
                  ),
                  _HeroButton(icon: Icons.notifications_none_rounded, tip: 'Notifications', dot: unread, onTap: onBell),
                  const SizedBox(width: 8),
                  _HeroButton(icon: Icons.add_rounded, tip: 'New session', onTap: onNew),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'My profile',
                    child: InkWell(
                      onTap: onMe,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Text('AV', style: AppText.bodyBold.copyWith(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good evening, Aman', style: AppText.heroTitle.copyWith(fontSize: 24, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(subline, style: AppText.caption.copyWith(fontSize: 12.5, color: Colors.white.withValues(alpha: .9), height: 1.45)),
                      ],
                    ),
                  ),
                  const _Illustration(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.icon, required this.tip, required this.onTap, this.dot = false});
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 19, color: Colors.white),
                if (dot)
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.bad,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3A9DEA), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stand-in for the hero illustration (hh-ill).
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 92, height: 92, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle)),
          const Icon(Icons.sports_gymnastics_rounded, size: 58, color: Colors.white),
          Positioned(right: 6, top: 10, child: Icon(Icons.fitness_center_rounded, size: 22, color: Colors.white.withValues(alpha: .85))),
        ],
      ),
    );
  }
}

/// One row in the "Today" card (td-ses).
class TodaySessionRow extends StatelessWidget {
  const TodaySessionRow({
    super.key,
    required this.s,
    required this.state,
    required this.isNext,
    required this.onDone,
    required this.onMenu,
  });

  final TodaySession s;
  final SessionState? state;
  final bool isNext;
  final VoidCallback onDone;
  final VoidCallback onMenu;

  String get _inText {
    final d = s.startMinute - TrainerMock.dashboardNow;
    if (d >= 60) return 'In ${d ~/ 60} h${d % 60 != 0 ? ' ${d % 60} min' : ''}';
    return 'In $d min';
  }

  @override
  Widget build(BuildContext context) {
    final past = state != null;
    return Container(
      color: isNext ? AppColors.hover : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.time,
                    style: AppText.bodyBold.copyWith(
                        fontWeight: FontWeight.w800, color: isNext ? AppColors.accentText : (past ? AppColors.muted : AppColors.text))),
                Text('${s.minutes} min', style: AppText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          Avatar(s.initials, size: 30, color: s.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.client, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(color: past ? AppColors.muted : AppColors.text)),
                Row(
                  children: [
                    Icon(s.videoCall ? Icons.videocam_outlined : Icons.place_outlined, size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s.what, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (state == SessionState.done) const AppBadge('Done', tone: BadgeTone.ok),
          if (state == SessionState.missed) const AppBadge('Missed', tone: BadgeTone.bad),
          if (state == null && isNext) ...[AppBadge(_inText, tone: BadgeTone.info), const SizedBox(width: 6)],
          if (state == null && !isNext) AppButton.outline('Done', icon: Icons.check_rounded, small: true, onPressed: onDone),
          IconButton(
            onPressed: onMenu,
            tooltip: 'More actions',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.more_vert_rounded, size: 19, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// One row in "Clients who need you" (td-at).
class AttentionRow extends StatelessWidget {
  const AttentionRow({super.key, required this.a, required this.reminded, required this.onRemind, required this.onOpen});
  final AttentionItem a;
  final bool reminded;
  final VoidCallback onRemind;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Widget action = switch (a.action) {
      AttentionAction.remind when reminded => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Text('Reminded', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      AttentionAction.remind => AppButton.outline('Remind', icon: Icons.notifications_active_outlined, small: true, onPressed: onRemind),
      AttentionAction.plan => AppButton.outline('Plan next', icon: Icons.event_note_rounded, small: true, onPressed: onOpen),
      AttentionAction.open => AppButton.outline('Open', icon: Icons.open_in_new_rounded, small: true, onPressed: onOpen),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
      child: Row(
        children: [
          Avatar(a.initials, size: 30, color: a.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(onTap: onOpen, child: Text(a.name, style: AppText.bodyBold.copyWith(color: AppColors.accentText))),
                    AppBadge(a.kind.label, tone: a.kind.tone),
                  ],
                ),
                const SizedBox(height: 2),
                Text(a.why, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

/// One row in "Check-ins to review" (td-ci).
class CheckinRow extends StatelessWidget {
  const CheckinRow({super.key, required this.c, required this.onTap});
  final TrainerCheckin c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = c.hours >= 48 ? BadgeTone.bad : (c.hours >= 24 ? BadgeTone.warn : BadgeTone.neutral);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
        child: Row(
          children: [
            Avatar(c.initials, size: 30, color: c.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: c.client, style: AppText.bodyBold),
                      TextSpan(text: ' · ${c.kindLabel}', style: AppText.body.copyWith(color: AppColors.muted)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(c.line, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 6),
            AppBadge(c.age, tone: tone),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// "All check-ins reviewed" (td-empty).
class AllReviewed extends StatelessWidget {
  const AllReviewed({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 22, color: AppColors.okText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All check-ins reviewed', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text('New ones show up here as clients send them.', style: AppText.caption.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "This week" card.
class ThisWeekCard extends StatelessWidget {
  const ThisWeekCard({super.key, required this.onProfile});
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return TrainerSectionCard(
      title: 'This week',
      subtitle: 'Mon 5 – Thu 8 Oct',
      action: 'My profile',
      onAction: onProfile,
      child: KvGrid.text(TrainerMock.thisWeek),
    );
  }
}
