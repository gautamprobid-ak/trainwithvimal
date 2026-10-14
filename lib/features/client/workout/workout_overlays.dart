import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

import 'workout_session.dart';
import 'workout_sheets.dart';

String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

const _tab = [FontFeature.tabularFigures()];

/// Dark rest bar at the bottom while a rest runs and the dialog is closed (cl-rest).
class RestBar extends ConsumerWidget {
  const RestBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    final c = ref.read(workoutSessionProvider.notifier);
    final max = s.restMax > s.restLeft ? s.restMax : s.restLeft;
    Widget btn(Widget child, VoidCallback f) => Material(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: f,
            child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 10), alignment: Alignment.center, child: child),
          ),
        );
    final bt = AppText.bodyBold.copyWith(fontSize: 13, color: Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => c.openRest(true),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(s.restPaused ? 'REST · PAUSED' : 'REST', style: AppText.overline.copyWith(fontSize: 11, color: const Color(0xFFA3A3A3))),
              Text(_mmss(s.restLeft), style: AppText.cardTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, fontFeatures: _tab)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: ProgressBar(s.restLeft / max, color: const Color(0xFF7CC4FF), track: Colors.white.withValues(alpha: .15))),
          const SizedBox(width: 8),
          btn(Icon(s.restPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16, color: Colors.white), c.toggleRestPause),
          const SizedBox(width: 6),
          btn(Text('+15s', style: bt), c.restMore),
          const SizedBox(width: 6),
          btn(Text('Skip', style: bt), c.skipRest),
        ],
      ),
    );
  }
}

/// White workout-time bar at the bottom (cl-wbar); opens the timer sheet.
class WorkoutTimerBar extends ConsumerWidget {
  const WorkoutTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
      elevation: 6,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => WorkoutSheets.timer(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: s.paused ? const Color(0xFFFFF4DB) : AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: Icon(s.paused ? Icons.pause_rounded : Icons.timer_outlined, size: 17, color: s.paused ? const Color(0xFFA15C00) : AppColors.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.paused ? 'TIMER PAUSED' : 'WORKOUT TIME', style: AppText.overline.copyWith(fontSize: 11)),
                Text(fmtWorkoutTime(s.elapsed), style: AppText.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: _tab)),
              ]),
            ),
            Text('${s.setsDone} of ${s.setsTotal} sets', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_less_rounded, size: 18, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}

/// Rest timer dialog with a ring (cr).
class RestDialog extends ConsumerWidget {
  const RestDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    final c = ref.read(workoutSessionProvider.notifier);
    final ex = WorkoutSession.exercises;
    final max = s.restMax > s.restLeft ? s.restMax : s.restLeft;
    final sub = '${ex[s.restAt.$1].name}${s.restAt.$2 >= 0 ? ' · after set ${s.restAt.$2 + 1}' : ''}';
    return ColoredBox(
      color: const Color(0x61111111),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.modal)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                AppIconButton(Icons.arrow_back_rounded, small: true, tooltip: 'Back to the workout', onPressed: () => c.openRest(false)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Rest timer', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    Text(sub, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Text('REST', style: AppText.overline.copyWith(fontSize: 11.5, letterSpacing: 1)),
              const SizedBox(height: 4),
              RingProgress(
                value: s.restLeft / max,
                size: 200,
                stroke: 12,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_mmss(s.restLeft), style: AppText.bigNumber.copyWith(fontSize: 48, height: 1, fontFeatures: _tab)),
                  const SizedBox(height: 4),
                  Text(s.restPaused ? 'Paused' : 'of ${_mmss(max)}', style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppButton.outline('−15s', small: true, onPressed: c.restLess),
                const SizedBox(width: 8),
                AppButton.dark(s.restPaused ? 'Resume' : 'Pause', small: true, onPressed: c.toggleRestPause),
                const SizedBox(width: 8),
                AppButton.outline('+15s', small: true, onPressed: c.restMore),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: 160, child: AppButton('Skip rest', expand: true, onPressed: c.skipRest)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.skip_next_rounded, size: 15, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Text('Next up', style: AppText.caption.copyWith(fontSize: 12.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(nextUp(s),
                        textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
