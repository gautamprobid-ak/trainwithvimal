import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../workout/workout_session.dart';
import 'training_widgets.dart';

/// Design: ClientTrain.dc.html — week strip, today's workout, coach note,
/// exercise blocks (open the guide), past workouts, live workout bar.
class ClientTrainScreen extends ConsumerWidget {
  const ClientTrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(workoutSessionProvider.select((s) => s.isLive));
    return Stack(
      children: [
        PageScroll(
          padding: EdgeInsets.fromLTRB(16, 6, 16, live ? 96 : 28),
          children: [
            PageHeader(
              title: 'Train',
              subtitle: '${ClientTrainingMock.programName} · week 6 of 12',
              actions: [AppButton.outline('History', icon: Icons.history_rounded, small: true, onPressed: () => showPastWorkouts(context))],
            ),
            const _TrainWeek(),
            const _TodayCard(),
            const CoachNoteCard(title: 'Note from Aman', subtitle: 'For this workout', text: ClientTrainingMock.workoutNote, compact: true),
            for (final b in ClientTrainingMock.todayBlocks) _BlockList(block: b),
          ],
        ),
        if (live) const Positioned(left: 12, right: 12, bottom: 12, child: LiveWorkoutBar()),
      ],
    );
  }
}

/// Opens the logger: starts today's workout, or reopens it after finishing.
void openWorkout(BuildContext context, WidgetRef ref) {
  final c = ref.read(workoutSessionProvider.notifier);
  final s = ref.read(workoutSessionProvider);
  if (s.isFinished) c.reopen();
  context.push(Routes.cWorkout);
}

class _TrainWeek extends ConsumerWidget {
  const _TrainWeek();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fin = ref.watch(workoutSessionProvider.select((s) => s.isFinished));
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _TrainDay(
                wd: wd[i],
                name: ClientTrainingMock.weekShort[i],
                today: i == ClientTrainingMock.todayIndex,
                rest: ClientTrainingMock.week[i] == null,
                done: (i < ClientTrainingMock.todayIndex && ClientTrainingMock.week[i] != null) || (i == ClientTrainingMock.todayIndex && fin),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainDay extends StatelessWidget {
  const _TrainDay({required this.wd, required this.name, required this.today, required this.rest, required this.done});
  final String wd;
  final String name;
  final bool today;
  final bool rest;
  final bool done;

  @override
  Widget build(BuildContext context) {
    const todayText = Color(0xFF1E3A8A);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: today ? AppColors.accentSoft : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: today ? const Color(0xFFBFD3FB) : Colors.transparent),
      ),
      child: Column(
        children: [
          Text(wd, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: today ? todayText : AppColors.muted)),
          const SizedBox(height: 2),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                fontSize: 10.5,
                fontWeight: rest ? FontWeight.w600 : FontWeight.w700,
                color: today ? todayText : (rest ? AppColors.muted : AppColors.text),
              )),
          const SizedBox(height: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF22C55E) : (today ? Colors.white : (rest ? null : AppColors.sub)),
              border: done
                  ? null
                  : today
                      ? Border.all(color: AppColors.accent, width: 2)
                      : rest
                          ? Border.all(color: const Color(0xFFCFCFC9), width: 1.5)
                          : null,
            ),
            child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    final n = WorkoutSession.exercises.length;
    final done = s.exercisesDone;
    final btn = s.isFinished ? 'Log more sets' : (s.isLive ? 'Continue workout' : 'Start workout');
    Widget meta(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 14, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(t, style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2)),
        ]);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkoutHero(
            label: 'Today · Fri, 9 Oct',
            icon: Icons.directions_run_rounded,
            title: ClientTrainingMock.todayTitle,
            gradient: AppColors.blueHero,
            trailing: s.isFinished ? const Pill('Completed today', tone: 'green') : null,
            bottom: Wrap(spacing: 14, runSpacing: 6, children: [
              meta(Icons.schedule_rounded, 'About 45 min'),
              meta(Icons.format_list_bulleted_rounded, '$n exercises · 10 sets'),
              meta(Icons.fitness_center_rounded, 'Treadmill, kettlebell, mat'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Spaced(
              gap: 10,
              children: [
                DoneProgress(value: done / n, label: '$done of $n exercises done', color: AppColors.accent),
                SizedBox(
                  height: 40,
                  child: AppButton(btn, icon: Icons.play_arrow_rounded, expand: true, onPressed: () => openWorkout(context, ref)),
                ),
                const SessionStrip(compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockList extends ConsumerWidget {
  const _BlockList({required this.block});
  final WorkoutBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    final all = WorkoutSession.exercises;
    final idx = [for (var i = 0; i < all.length; i++) if (all[i].block == block.name) i];
    final sub = '${idx.length}${idx.length > 1 ? ' exercises · ' : ' exercise · '}${block.sub}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(block.name, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800))),
              Text(sub, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var k = 0; k < idx.length; k++) ...[
                if (k > 0) const Divider(height: 1),
                _ExerciseRow(e: all[idx[k]], done: s.isFinished || s.exerciseDone(idx[k]), onTap: () => showExerciseGuide(context, idx[k])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.e, required this.done, required this.onTap});
  final LogExercise e;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (e.kind) {
      LogKind.cardio => (Icons.directions_walk_rounded, Tint.blue),
      LogKind.weight => (Icons.fitness_center_rounded, Tint.green),
      LogKind.time => (Icons.timer_outlined, Tint.amber),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            TintIcon(icon, tint: tint, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(e.target, style: AppText.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            if (done) ...[const OkLabel('Done'), const SizedBox(width: 6)],
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Sticky "Workout in progress" bar (cl-wbar) shown while the workout runs.
class LiveWorkoutBar extends ConsumerWidget {
  const LiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(Routes.cWorkout),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s.paused ? const Color(0xFFFFF4DB) : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s.paused ? Icons.pause_rounded : Icons.timer_outlined, size: 19, color: s.paused ? const Color(0xFFA15C00) : AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.paused ? 'TIMER PAUSED' : 'WORKOUT IN PROGRESS', style: AppText.overline.copyWith(fontSize: 11)),
                    Text(fmtWorkoutTime(s.elapsed),
                        style: AppText.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
              Text('${s.setsDone} of ${s.setsTotal} sets', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
