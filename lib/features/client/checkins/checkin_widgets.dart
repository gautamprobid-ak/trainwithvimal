import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';

enum PastState { ok, missed, waiting }

/// Row in "Past check-ins" (ck-row).
class PastRow extends StatelessWidget {
  const PastRow({super.key, required this.title, required this.subtitle, required this.state, required this.pill, required this.tone, this.reply, required this.onTap});
  final String title;
  final String subtitle;
  final PastState state;
  final String pill;
  final PillTone tone;
  final String? reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (state) {
      PastState.ok => (AppColors.okBg, AppColors.okText, Icons.check_rounded),
      PastState.missed => (AppColors.badBg, AppColors.badText, Icons.close_rounded),
      PastState.waiting => (AppColors.infoBg, AppColors.infoText, Icons.schedule_rounded),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 14, color: fg)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(subtitle, style: AppText.caption),
                  if (reply != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'Aman: ', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.okText)),
                          TextSpan(text: reply, style: AppText.caption.copyWith(color: AppColors.text2)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pill(pill, tone: tone),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// A question card of the daily check-in (ck-q).
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.title, required this.label, required this.child, this.need = false});
  final String title;
  final String label;
  final Widget child;
  final bool need;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.bodyBold.copyWith(fontSize: 14.5))),
              Text(label,
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: need ? AppColors.warnText : (label == 'Optional' ? AppColors.muted : AppColors.accentText))),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// 1–5 scale (ck-scale) or a row of plain options.
class ScaleButtons extends StatelessWidget {
  const ScaleButtons({super.key, required this.labels, required this.selected, required this.onPick, this.numbered = true, this.large = false});
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onPick;
  final bool numbered;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Material(
              color: i == selected ? (numbered ? AppColors.accent : AppColors.text) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: i == selected ? (numbered ? AppColors.accent : AppColors.text) : AppColors.line),
              ),
              child: InkWell(
                onTap: () => onPick(i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: numbered ? (large ? 12 : 8) : 10, horizontal: 2),
                  child: Column(
                    children: [
                      Text(numbered ? '${i + 1}' : labels[i],
                          style: AppText.bodyBold.copyWith(
                              fontSize: numbered ? (large ? 20 : 15) : 12.5, fontWeight: FontWeight.w800, color: i == selected ? Colors.white : AppColors.text)),
                      if (numbered)
                        Text(labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: i == selected ? Colors.white70 : AppColors.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Note text field with tap-to-add suggestions.
class NoteField extends StatelessWidget {
  const NoteField({super.key, required this.controller, required this.hint, required this.chips, required this.onChanged, this.chipsLabel, this.maxLines = 2});
  final TextEditingController controller;
  final String hint;
  final List<String> chips;
  final VoidCallback onChanged;
  final String? chipsLabel;
  final int maxLines;

  void _add(String t) {
    final cur = controller.text;
    controller.text = cur.isNotEmpty && !cur.contains(t) ? '$cur. $t' : (cur.isEmpty ? t : cur);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: maxLines,
          onChanged: (_) => onChanged(),
          style: AppText.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TryRow(label: chipsLabel, chips: [for (final c in chips) TryChip(c, onTap: () => _add(c))]),
      ],
    );
  }
}

/// "Sent" card with a summary (ck-done).
class SentCard extends StatelessWidget {
  const SentCard({super.key, required this.title, required this.subtitle, required this.rows, required this.actions});
  final String title;
  final String subtitle;
  final List<(String, String)> rows;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: AppColors.okBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.okText, size: 28),
          ),
          const SizedBox(height: 10),
          Text(title, style: AppText.sectionTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: AppText.secondary),
          const SizedBox(height: 12),
          KvList(rows),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: actions[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Progress photo slot (ck-slot).
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({super.key, required this.name, required this.has, required this.onTap});
  final String name;
  final bool has;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: has ? AppColors.okBg : AppColors.sub,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(has ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: has ? AppColors.okText : AppColors.muted),
              const SizedBox(height: 6),
              Text(name, style: AppText.bodyBold.copyWith(fontSize: 13)),
              Text(has ? 'Added · tap to remove' : 'Tap to add', textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 10.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coach reply bubble (ck-reply).
class CoachReply extends StatelessWidget {
  const CoachReply({super.key, required this.text, required this.when});
  final String text;
  final String when;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Avatar('AV', size: 32, color: AvatarColor.c2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Aman Verma ', style: AppText.bodyBold.copyWith(fontSize: 13)),
                  TextSpan(text: when, style: AppText.caption),
                ])),
                const SizedBox(height: 2),
                Text(text, style: AppText.body.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QaList extends StatelessWidget {
  const _QaList(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (q, a) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q, style: AppText.caption),
                Text(a, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Past weekly check-in sheet body.
class WeeklyDetail extends StatelessWidget {
  const WeeklyDetail({super.key, required this.item, required this.angle, required this.onAngle, required this.showPhotos});
  final WeeklyCheckin item;
  final int angle;
  final ValueChanged<int> onAngle;
  final bool showPhotos;

  static const _angles = ['Front', 'Side', 'Back'];

  @override
  Widget build(BuildContext context) {
    final r = item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.kpis.isNotEmpty) ...[StatCells(r.kpis), const SizedBox(height: 12)],
        if (r.reply != null) ...[CoachReply(text: r.reply!, when: r.replyWhen ?? ''), const SizedBox(height: 12)],
        if (r.waiting || r.reviewed) ...[
          InfoBanner(
            icon: r.reviewed ? Icons.task_alt_rounded : Icons.schedule_rounded,
            text: r.reviewed ? 'Aman reviewed this check-in and did not add a note.' : 'Waiting for Aman’s reply. He usually replies within a day.',
          ),
          const SizedBox(height: 12),
        ],
        if (r.missed) ...[
          const InfoBanner(
            icon: Icons.event_busy_rounded,
            bg: AppColors.sub,
            fg: AppColors.text2,
            text: 'This check-in was not sent. A missed week cannot be filled in later, but the next one opens every Sunday at 6:00 pm.',
          ),
          const SizedBox(height: 12),
        ],
        if (r.answers.isNotEmpty) _QaList(r.answers),
        if (showPhotos) ...[
          const Overline('Photos', padding: EdgeInsets.only(top: 12, bottom: 8)),
          Container(
            height: 180,
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.accessibility_new_rounded, size: 64, color: AppColors.line2),
                const SizedBox(height: 6),
                Text('${_angles[angle]} · ${r.photoDate}', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SegmentedTabs<int>(items: const [(0, 'Front'), (1, 'Side'), (2, 'Back')], value: angle, onChanged: onAngle),
        ],
      ],
    );
  }
}

/// Past daily check-in sheet body.
class DailyDetail extends StatelessWidget {
  const DailyDetail({super.key, required this.item});
  final DailyCheckin item;

  @override
  Widget build(BuildContext context) {
    final a = item.answers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a != null) ...[
          StatCells([(a[0], 'Sleep'), (a[1], 'Energy'), (a[2], 'Mood'), (a[5], 'Steps')]),
          const SizedBox(height: 12),
        ],
        if (item.reply != null) ...[CoachReply(text: item.reply!, when: item.replyWhen ?? ''), const SizedBox(height: 12)],
        if (item.missed)
          const InfoBanner(
            icon: Icons.event_busy_rounded,
            bg: AppColors.sub,
            fg: AppColors.text2,
            text: 'Not sent. A reminder went at 9:00 pm. Daily check-ins cannot be sent for past days.',
          ),
        if (a != null) _QaList([('Hunger', a[3]), ('Soreness', a[4]), ('Water', a[6]), ('Morning weight', a[7]), ('Note', a[8])]),
      ],
    );
  }
}
