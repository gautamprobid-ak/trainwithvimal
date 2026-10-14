import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import 'workout_session.dart';
import 'workout_sheets.dart';

const _restColor = Color(0xFFF5B544);
const _quickNotes = ['Felt easy today', 'Knee was fine on the incline', 'Had to slow down'];

/// "Workout done!" summary: time, sets, volume, where the time went, effort, note, send.
class WorkoutDoneView extends ConsumerWidget {
  const WorkoutDoneView({super.key, required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(workoutSessionProvider);
    final c = ref.read(workoutSessionProvider.notifier);
    return PageScroll(
      children: [
        const _Hero(),
        Row(children: [
          _Stat(fmtWorkoutTime(s.elapsed), 'Total time'),
          const SizedBox(width: 8),
          _Stat('${s.setsDone}/${s.setsTotal}', 'Sets'),
          const SizedBox(width: 8),
          _Stat('${TNum.n(s.totalVolume)} kg', 'Volume'),
        ]),
        _TimeCard(s: s),
        _EffortCard(effort: s.effort, onPick: c.setEffort),
        _NoteCard(note: s.note, onEdit: () => WorkoutSheets.note(context, ref), onPick: c.setNote),
        if (!s.sent)
          AppButton('Save and send to Aman', icon: Icons.send_rounded, expand: true, onPressed: () {
            if (s.effort == 0) {
              showToast(context, 'Pick how hard it was', subtitle: 'Tap a number from 1 to 10', kind: ToastKind.warn);
              return;
            }
            c.send();
            showToast(context, 'Sent to Aman', subtitle: 'Effort ${s.effort} of 10${s.note != null ? ' · with your note' : ''}', kind: ToastKind.ok);
          })
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.okText),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Sent to Aman. He usually replies within a few hours.',
                    style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.okText)),
              ),
            ]),
          ),
        AppButton.outline('Back to home', expand: true, onPressed: onHome),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.accentSoft, spreadRadius: 8)],
          ),
          child: const Icon(Icons.check_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text('Workout done!', style: AppText.sectionTitle.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        Text('${ClientTrainingMock.todayTitle} · Fri, 9 Oct', style: AppText.secondary.copyWith(fontSize: 13.5)),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          FittedBox(child: Text(value, style: AppText.cardTitle.copyWith(fontSize: 19, fontWeight: FontWeight.w800))),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.s});
  final WorkoutSession s;

  @override
  Widget build(BuildContext context) {
    final el = s.elapsed;
    final rest = s.restUsed < el ? s.restUsed : el;
    final active = (el - rest).clamp(0, 1 << 30);
    final total = el < 1 ? 1 : el;
    final ex = WorkoutSession.exercises;
    // time per exercise: from the last tick before its first set to its last ticked set
    final ticks = [for (final xs in s.sets) [for (final x in xs) if (x.done && x.at != null) x.at!]];
    final all = ticks.expand((t) => t).toList();
    int? exT(int i) {
      final t = ticks[i];
      if (t.isEmpty) return null;
      final first = t.reduce((a, b) => a < b ? a : b), last = t.reduce((a, b) => a > b ? a : b);
      final before = all.where((x) => x < first);
      return last - (before.isEmpty ? 0 : before.reduce((a, b) => a > b ? a : b));
    }

    return AppCard(
      child: Spaced(
        gap: 10,
        children: [
          Text('Where the time went', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: Row(children: [
                if (active > 0) Expanded(flex: active, child: const ColoredBox(color: AppColors.accent)),
                if (rest > 0) Expanded(flex: rest, child: const ColoredBox(color: _restColor)),
                if (active + rest < total) Expanded(flex: total - active - rest, child: const ColoredBox(color: AppColors.sub)),
              ]),
            ),
          ),
          Row(children: [
            _Legend(AppColors.accent, 'Active', fmtWorkoutTime(active)),
            const SizedBox(width: 16),
            _Legend(_restColor, 'Rest', fmtWorkoutTime(rest)),
          ]),
          Column(children: [
            for (var i = 0; i < ex.length; i++) _ExTime(name: ex[i].name, sub: _exSub(i), time: exT(i)),
          ]),
          Text('Aman sees the same times with your workout.', style: AppText.secondary.copyWith(fontSize: 12.5)),
        ],
      ),
    );
  }

  String _exSub(int i) {
    final xs = s.sets[i];
    final done = xs.where((y) => y.done).toList();
    final base = '${done.length} of ${xs.length} ${xs.length == 1 ? 'set' : 'sets'}';
    if (WorkoutSession.exercises[i].isCardio && done.any((x) => x.at != null)) {
      return '$base · ${TNum.short(done.fold(0.0, (a, y) => a + y.values[0]))} min on the machine';
    }
    return base;
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label, this.value);
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final st = AppText.secondary.copyWith(fontWeight: FontWeight.w600);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text('$label ', style: st),
      Text(value, style: st.copyWith(color: AppColors.text, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _ExTime extends StatelessWidget {
  const _ExTime({required this.name, required this.sub, required this.time});
  final String name;
  final String sub;
  final int? time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppText.bodyBold),
            Text(sub, style: AppText.secondary.copyWith(fontSize: 12.5)),
          ]),
        ),
        time == null
            ? Text('Skipped', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600))
            : Text(fmtWorkoutTime(time!), style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

class _EffortCard extends StatelessWidget {
  const _EffortCard({required this.effort, required this.onPick});
  final int effort;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final label = effort == 0
        ? 'Tap a number'
        : '$effort of 10 · ${effort <= 3 ? 'easy' : effort <= 6 ? 'moderate' : effort <= 8 ? 'hard' : 'very hard'}';
    final cap = AppText.caption.copyWith(fontWeight: FontWeight.w600);
    return AppCard(
      child: Spaced(
        gap: 10,
        children: [
          Text('How hard was it?', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
          Row(children: [
            for (var i = 1; i <= 10; i++) ...[
              if (i > 1) const SizedBox(width: 4),
              Expanded(
                child: Material(
                  color: effort == i ? AppColors.accent : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9), side: BorderSide(color: effort == i ? AppColors.accent : AppColors.line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onPick(i),
                    child: SizedBox(
                      height: 38,
                      child: Center(
                        child: Text('$i', style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800, color: effort == i ? Colors.white : AppColors.text)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
          Row(children: [
            Text('Easy', style: cap),
            Expanded(child: Text(label, textAlign: TextAlign.center, style: cap.copyWith(color: AppColors.text, fontWeight: FontWeight.w700))),
            Text('Max', style: cap),
          ]),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit, required this.onPick});
  final String? note;
  final VoidCallback onEdit;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Spaced(
        gap: 10,
        children: [
          Text('Note for Aman', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFAFAF8), border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
              child: Text(note ?? 'Add a note for Aman (optional)',
                  style: AppText.body.copyWith(color: note == null ? AppColors.muted : AppColors.text, fontWeight: note == null ? FontWeight.w500 : FontWeight.w600)),
            ),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final q in _quickNotes) ChoicePill(q, selected: note == q, onTap: () => onPick(q)),
          ]),
        ],
      ),
    );
  }
}
