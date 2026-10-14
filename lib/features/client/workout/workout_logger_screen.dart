import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';

import '../train/training_widgets.dart';
import 'workout_done_view.dart';
import 'workout_overlays.dart';
import 'workout_panel.dart';
import 'workout_session.dart';
import 'workout_sheets.dart';

/// Design: ClientWorkout.dc.html — live workout logger: timer, exercise pager,
/// set table (tick, edit, warm-up, delete, add), hold timer, rest timer,
/// guide, past workouts, finish / restart / remove flows and the done summary.
class WorkoutLoggerScreen extends ConsumerStatefulWidget {
  const WorkoutLoggerScreen({super.key});

  @override
  ConsumerState<WorkoutLoggerScreen> createState() => _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends ConsumerState<WorkoutLoggerScreen> {
  bool _idleOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(workoutSessionProvider.notifier).ensureStarted();
    });
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.cTrain);

  void _onChange(WorkoutSession? prev, WorkoutSession next) {
    final ev = next.event;
    if (ev != null && ev.id != prev?.event?.id) {
      showToast(context, ev.title, subtitle: ev.subtitle, kind: ev.title == 'Rest is over' ? ToastKind.info : ToastKind.ok);
    }
    final idle = next.isLive && !next.paused && next.elapsed - next.lastActivity >= 1800;
    if (idle && !_idleOpen && !WorkoutSheets.busy) {
      _idleOpen = true;
      WorkoutSheets.idle(context, ref).whenComplete(() => _idleOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workoutSessionProvider, _onChange);
    final s = ref.watch(workoutSessionProvider);
    if (s.isFinished) return WorkoutDoneView(onHome: () => context.go(Routes.cHome));
    if (s.isNotStarted) return const SizedBox.shrink();
    final resting = s.restLeft > 0;
    return Stack(
      children: [
        PageScroll(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
          children: [
            _LoggerTop(onBack: _back),
            const _ExercisePager(),
            WorkoutPanel(key: ValueKey('panel-${s.cur}')),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: resting ? (s.restOpen ? const SizedBox.shrink() : const RestBar()) : const WorkoutTimerBar(),
        ),
        if (resting && s.restOpen) const Positioned.fill(child: RestDialog()),
      ],
    );
  }
}

class _LoggerTop extends ConsumerWidget {
  const _LoggerTop({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    return Row(
      children: [
        AppIconButton(Icons.arrow_back_rounded, small: true, tooltip: 'Back to overview', onPressed: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ClientTrainingMock.todayTitle, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Row(
                children: [
                  _TimerChip(paused: s.paused, time: fmtWorkoutTime(s.elapsed), onTap: () => WorkoutSheets.timer(context, ref)),
                  if (s.restLeft > 0) ...[
                    const SizedBox(width: 5),
                    _RestChip(left: s.restLeft, onTap: () => ref.read(workoutSessionProvider.notifier).openRest(true)),
                  ],
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text('· ${s.setsDone} of ${s.setsTotal} sets',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<int>(
          tooltip: 'Workout options',
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          onSelected: (v) => switch (v) {
            0 => showPastWorkouts(context, thisOnly: true),
            1 => WorkoutSheets.restart(context, ref),
            _ => WorkoutSheets.discard(context, ref),
          },
          itemBuilder: (_) => [
            _menuItem(0, Icons.history_rounded, 'Past workouts'),
            _menuItem(1, Icons.restart_alt_rounded, 'Restart workout'),
            _menuItem(2, Icons.delete_outline_rounded, 'Remove logged work', danger: true),
          ],
          child: const IgnorePointer(child: AppIconButton(Icons.more_horiz_rounded, small: true)),
        ),
        const SizedBox(width: 8),
        AppButton('Finish', small: true, onPressed: () => WorkoutSheets.finish(context, ref)),
      ],
    );
  }
}

PopupMenuItem<int> _menuItem(int v, IconData icon, String label, {bool danger = false}) {
  final c = danger ? AppColors.bad : AppColors.text2;
  return PopupMenuItem<int>(
    value: v,
    height: 40,
    child: Row(children: [
      Icon(icon, size: 18, color: c),
      const SizedBox(width: 10),
      Text(label, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: danger ? AppColors.bad : AppColors.text)),
    ]),
  );
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.paused, required this.time, required this.onTap});
  final bool paused;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = paused ? const Color(0xFFFFF4DB) : AppColors.sub;
    final fg = paused ? const Color(0xFFA15C00) : AppColors.text;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(paused ? Icons.pause_rounded : Icons.timer_outlined, size: 13, color: fg),
            const SizedBox(width: 4),
            Text(time, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      ),
    );
  }
}

class _RestChip extends StatelessWidget {
  const _RestChip({required this.left, required this.onTap});
  final int left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.hourglass_bottom_rounded, size: 12, color: AppColors.accent),
            const SizedBox(width: 3),
            Text('Rest ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                style: AppText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentText, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      ),
    );
  }
}

class _ExercisePager extends ConsumerWidget {
  const _ExercisePager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    final ex = WorkoutSession.exercises;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ex.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final on = i == s.cur;
          final done = s.exerciseDone(i);
          return Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: on ? AppColors.text : AppColors.line, width: on ? 2 : 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => ref.read(workoutSessionProvider.notifier).goTo(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                child: Row(children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF22C55E) : (on ? AppColors.accent : AppColors.sub),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text('${i + 1}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.text2)),
                  ),
                  const SizedBox(width: 7),
                  Text(ex[i].name,
                      style: AppText.secondary.copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w600, color: on ? AppColors.text : AppColors.text2)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
