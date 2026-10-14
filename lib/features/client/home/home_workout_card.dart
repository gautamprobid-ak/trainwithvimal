import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/client_train_screen.dart' show openWorkout;
import '../train/training_widgets.dart';
import '../workout/workout_session.dart';
import 'home_sheets.dart';

const _wdShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Workout of the picked day (ch-wk). Today's progress comes from the logger.
class HomeWorkoutCard extends ConsumerWidget {
  const HomeWorkoutCard({super.key, required this.day});
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ClientTrainingMock.week[day];
    final dateLabel = day == ClientTrainingMock.todayIndex ? 'Fri, 9 Oct' : '${_wdShort[day]}, ${ClientTrainingMock.weekStart.day + day} Oct';
    if (p == null) return _RestCard(dateLabel: dateLabel);
    final today = day == ClientTrainingMock.todayIndex;
    final s = ref.watch(workoutSessionProvider);
    final label = today ? 'Today’s workout' : (day < ClientTrainingMock.todayIndex ? 'Workout' : 'Coming workout');
    final n = p.exercises.length;
    final done = today ? s.exercisesDone : 0;
    final firstOpen = today ? [for (var i = 0; i < n; i++) i].where((i) => !s.exerciseDone(i)).firstOrNull : null;
    final started = !s.isNotStarted || done > 0;
    void preview() => showWorkoutPreview(context, p, day);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkoutHero(
            label: label,
            icon: p.isCardio ? Icons.directions_run_rounded : Icons.fitness_center_rounded,
            title: p.title,
            gradient: p.isCardio ? AppColors.blueHero : AppColors.greenHero,
            trailing: Text(dateLabel, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
            bottom: Wrap(spacing: 6, runSpacing: 6, children: [
              HeroTag(p.kind),
              HeroTag('$n exercises'),
              HeroTag(p.isCardio ? '45 min' : '50 min'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (day >= ClientTrainingMock.todayIndex) ...[
                  for (var i = 0; i < n && i < 4; i++)
                    _ExLine(i: i, e: p.exercises[i], on: today && s.exerciseDone(i), next: today && started && i == firstOpen, last: i == 3 || i == n - 1),
                  if (n > 4)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: preview, child: Text('+ ${n - 4} more')),
                    ),
                ],
                if (today) ...[
                  const SizedBox(height: 10),
                  const SessionStrip(),
                  const SizedBox(height: 12),
                  DoneProgress(value: done / n, label: '$done of $n done'),
                  const SizedBox(height: 10),
                  AppButton(
                    s.isFinished ? 'Log more sets' : (started ? 'Continue workout' : 'Start workout'),
                    icon: Icons.play_arrow_rounded,
                    expand: true,
                    onPressed: () => openWorkout(context, ref),
                  ),
                ] else if (day < ClientTrainingMock.todayIndex) ...[
                  const SizedBox(height: 10),
                  _DoneLine(text: p.doneLine),
                ] else ...[
                  const SizedBox(height: 10),
                  AppButton.outline('See all exercises', icon: Icons.format_list_bulleted_rounded, expand: true, onPressed: preview),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExLine extends StatelessWidget {
  const _ExLine({required this.i, required this.e, required this.on, required this.next, required this.last});
  final int i;
  final PlanExercise e;
  final bool on;
  final bool next;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = on ? (AppColors.okBg, AppColors.okText) : (next ? (AppColors.accent, Colors.white) : (AppColors.sub, AppColors.text2));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text('${i + 1}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: fg)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.name, style: AppText.bodyBold.copyWith(color: on ? AppColors.muted : AppColors.text)),
            Text(e.detail, style: AppText.caption),
          ]),
        ),
        if (on) const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF22C55E)),
      ]),
    );
  }
}

class _DoneLine extends StatelessWidget {
  const _DoneLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.okText),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.okText))),
      ]),
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.dateLabel});
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkoutHero(
            label: 'Rest day',
            icon: Icons.self_improvement_rounded,
            title: 'Rest and recover',
            gradient: AppColors.grayHero,
            trailing: Text(dateLabel, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
            bottom: const Wrap(spacing: 6, runSpacing: 6, children: [HeroTag('No workout'), HeroTag('Walk'), HeroTag('Stretch')]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
              child: Text('Rest helps your muscles grow. A short walk and some stretching is enough.',
                  style: AppText.secondary.copyWith(color: AppColors.text2)),
            ),
          ),
        ],
      ),
    );
  }
}
