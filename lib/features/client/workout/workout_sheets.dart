import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';

import '../train/training_widgets.dart';
import 'workout_session.dart';

/// Sheets of the workout logger (timer, finish, remove, restart, still working out, note).
abstract final class WorkoutSheets {
  /// True while one of these sheets is open (the idle sheet waits).
  static bool busy = false;

  static Future<T?> _open<T>(Future<T?> f) {
    busy = true;
    return f.whenComplete(() => busy = false);
  }

  static TextStyle get _p => AppText.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.text2);

  // ------------------------------------------------------------ timer

  static Future<void> timer(BuildContext context, WidgetRef ref) {
    return _open(showLiveSheet<void>(
      context,
      builder: (ctx, _) => Consumer(builder: (ctx, ref, _) {
        final s = ref.watch(workoutSessionProvider);
        final c = ref.read(workoutSessionProvider.notifier);
        final time = fmtWorkoutTime(s.elapsed);
        return SheetContent(
          title: 'Workout timer',
          subtitle: 'Started at 5:22 pm · ${ClientTrainingMock.todayTitle}',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.paused ? 'TIMER PAUSED' : 'WORKOUT TIME', textAlign: TextAlign.center, style: AppText.overline.copyWith(fontSize: 11.5)),
              Text(time,
                  textAlign: TextAlign.center,
                  style: AppText.bigNumber.copyWith(fontSize: 44, fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: AppButton.outline('1 min', icon: Icons.remove_rounded, small: true, onPressed: () => c.addMinutes(-1))),
                const SizedBox(width: 6),
                Expanded(
                  child: AppButton.dark(s.paused ? 'Resume' : 'Pause', icon: s.paused ? Icons.play_arrow_rounded : Icons.pause_rounded, small: true, onPressed: () {
                    c.togglePause();
                    showToast(context, s.paused ? 'Timer running' : 'Timer paused', subtitle: 'Workout time $time');
                  }),
                ),
                const SizedBox(width: 6),
                Expanded(child: AppButton.outline('1 min', icon: Icons.add_rounded, small: true, onPressed: () => c.addMinutes(1))),
              ]),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    restart(context, ref);
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.text2),
                  icon: const Icon(Icons.restart_alt_rounded, size: 15),
                  label: const Text('Restart workout'),
                ),
              ),
              Text('The timer stops when you finish the workout. Leaving this screen does not stop it.',
                  textAlign: TextAlign.center, style: AppText.secondary.copyWith(fontSize: 12.5)),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                discard(context, ref);
              },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('Remove logged work', overflow: TextOverflow.ellipsis),
            ),
            AppButton('Finish workout', icon: Icons.flag_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              finish(context, ref);
            }),
          ],
        );
      }),
    ));
  }

  // ------------------------------------------------------------ finish

  static Future<void> finish(BuildContext context, WidgetRef ref) {
    final s = ref.read(workoutSessionProvider);
    final done = s.setsDone, all = s.setsTotal;
    return _open(showAppSheet<void>(
      context,
      title: 'Finish workout?',
      subtitle: '$done of $all sets done',
      builder: (_) => Text(
        done == all
            ? 'Nice, every set is done. Aman sees your workout as soon as you finish.'
            : '${all - done} sets are not ticked yet. They are saved as skipped, and Aman sees what you did.',
        style: _p,
      ),
      actions: (ctx) => [
        AppButton.outline('Keep going', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Finish', icon: Icons.flag_rounded, onPressed: () {
          Navigator.of(ctx).pop();
          ref.read(workoutSessionProvider.notifier).finish();
          showToast(context, 'Workout saved', subtitle: '$done of $all sets', kind: ToastKind.star);
        }),
      ],
    ));
  }

  // ------------------------------------------------------------ remove logged work

  static Future<void> discard(BuildContext context, WidgetRef ref) {
    var pick = 'all';
    return _open(showLiveSheet<void>(
      context,
      builder: (ctx, setSheet) {
        final s = ref.read(workoutSessionProvider);
        final e = WorkoutSession.exercises[s.cur];
        final opts = [
          ('ex', 'Clear this exercise', '${e.name} · timer keeps going'),
          ('sets', 'Clear all sets', '${s.setsDone} ticked · timer keeps going'),
          ('all', 'Discard the whole workout', 'Nothing is saved · timer stops'),
        ];
        final btn = switch (pick) { 'ex' => 'Clear exercise', 'sets' => 'Clear all sets', _ => 'Discard workout' };
        return SheetContent(
          title: 'Remove what you logged?',
          subtitle: 'Pick how much to remove',
          body: Column(children: [
            for (final o in opts) _RadioOption(title: o.$2, subtitle: o.$3, on: pick == o.$1, onTap: () => setSheet(() => pick = o.$1)),
          ]),
          actions: [
            AppButton.outline('Keep it', onPressed: () => Navigator.of(ctx).pop()),
            AppButton.danger(btn, icon: Icons.delete_outline_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              _doDiscard(context, ref, pick, e.name);
            }),
          ],
        );
      },
    ));
  }

  static void _doDiscard(BuildContext context, WidgetRef ref, String pick, String name) {
    final c = ref.read(workoutSessionProvider.notifier);
    final prev = ref.read(workoutSessionProvider);
    switch (pick) {
      case 'ex':
        c.clearExercise();
        showToast(context, '$name cleared', subtitle: 'Timer keeps going', kind: ToastKind.del, onUndo: () => c.restore(prev));
      case 'sets':
        c.clearAllSets();
        showToast(context, 'All sets cleared', subtitle: 'Timer keeps going', kind: ToastKind.del, onUndo: () => c.restore(prev));
      default:
        // the whole workout goes: back to Train, not started
        final router = GoRouter.of(context);
        showToast(context, 'Workout discarded', subtitle: 'Nothing was saved', kind: ToastKind.del);
        c.discardAll();
        router.go(Routes.cTrain);
    }
  }

  // ------------------------------------------------------------ restart

  static Future<void> restart(BuildContext context, WidgetRef ref) {
    final s = ref.read(workoutSessionProvider);
    final n = s.setsDone;
    final lead = n == 0 ? 'The' : '${n == 1 ? 'Your 1 ticked set goes' : 'All $n ticked sets go'} back to not done and the';
    final msg = '$lead timer starts again from 0:00. You start from the first exercise.';
    return _open(showAppSheet<void>(
      context,
      title: 'Restart workout?',
      subtitle: '${ClientTrainingMock.todayTitle} · ${fmtWorkoutTime(s.elapsed)} so far',
      builder: (_) => Text(msg, style: _p),
      actions: (ctx) => [
        AppButton.outline('Keep going', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Restart', icon: Icons.restart_alt_rounded, onPressed: () {
          Navigator.of(ctx).pop();
          final c = ref.read(workoutSessionProvider.notifier);
          final prev = ref.read(workoutSessionProvider);
          c.restart();
          showToast(context, 'Workout restarted', subtitle: 'Timer is running from 0:00', onUndo: () => c.restore(prev));
        }),
      ],
    ));
  }

  // ------------------------------------------------------------ still working out?

  static Future<void> idle(BuildContext context, WidgetRef ref) async {
    final s = ref.read(workoutSessionProvider);
    final c = ref.read(workoutSessionProvider.notifier);
    final at = s.lastTickAt;
    final mins = (s.elapsed - s.lastActivity) ~/ 60;
    final time = fmtWorkoutTime(s.elapsed);
    var answered = false;
    await showAppSheet<void>(
      context,
      title: 'Still working out?',
      subtitle: 'No set ticked for $mins min · timer at $time',
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          at >= 0
              ? Text.rich(TextSpan(style: _p, children: [
                  const TextSpan(text: 'Your last set was at '),
                  TextSpan(text: fmtWorkoutTime(at), style: _p.copyWith(fontWeight: FontWeight.w800)),
                  const TextSpan(text: '. Finish there so the extra minutes don’t count.'),
                ]))
              : Text('You haven’t ticked a set yet.', style: _p),
          const SizedBox(height: 8),
          Text('If you don’t answer, the workout is saved at your last set after 3 hours.',
              textAlign: TextAlign.center, style: AppText.secondary.copyWith(fontSize: 12.5)),
        ],
      ),
      actions: (ctx) => [
        AppButton.outline('Keep going', onPressed: () => Navigator.of(ctx).pop()),
        at >= 0
            ? AppButton('Finish at ${fmtWorkoutTime(at)}', icon: Icons.flag_rounded, onPressed: () {
                answered = true;
                Navigator.of(ctx).pop();
                c.finishAtLastSet();
                showToast(context, 'Workout saved', subtitle: 'Time set to ${fmtWorkoutTime(at)}, your last set', kind: ToastKind.star);
              })
            : AppButton('Finish workout', icon: Icons.flag_rounded, onPressed: () {
                answered = true;
                Navigator.of(ctx).pop();
                c.keepGoing();
                if (context.mounted) finish(context, ref);
              }),
      ],
    );
    if (!answered) {
      c.keepGoing();
      if (context.mounted) showToast(context, 'Timer keeps running', subtitle: 'Workout time ${fmtWorkoutTime(ref.read(workoutSessionProvider).elapsed)}');
    }
  }

  // ------------------------------------------------------------ note for Aman

  static Future<void> note(BuildContext context, WidgetRef ref) {
    final ctl = TextEditingController(text: ref.read(workoutSessionProvider).note ?? '');
    return showAppSheet<void>(
      context,
      title: 'Note for Aman',
      subtitle: 'Optional · he sees it with your workout',
      builder: (_) => TextField(
        controller: ctl,
        autofocus: true,
        maxLines: 4,
        minLines: 3,
        style: AppText.body,
        decoration: const InputDecoration(hintText: 'How did it go?'),
      ),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Save note', icon: Icons.check_rounded, onPressed: () {
          ref.read(workoutSessionProvider.notifier).setNote(ctl.text);
          Navigator.of(ctx).pop();
        }),
      ],
    ).whenComplete(ctl.dispose);
  }
}

/// Radio option row (dr-opt).
class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.title, required this.subtitle, required this.on, required this.onTap});
  final String title;
  final String subtitle;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: on ? AppColors.accentSoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: on ? AppColors.accent : AppColors.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: on ? 4.5 : 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(subtitle, style: AppText.caption),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
