import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/training_widgets.dart';
import 'workout_session.dart';
import 'workout_sheets.dart';

const _green = Color(0xFF22C55E);

/// The current exercise: header, tools, set table and Previous / Next.
class WorkoutPanel extends ConsumerStatefulWidget {
  const WorkoutPanel({super.key});

  @override
  ConsumerState<WorkoutPanel> createState() => _WorkoutPanelState();
}

class _WorkoutPanelState extends ConsumerState<WorkoutPanel> {
  /// Cell being edited: (set, column).
  (int, int)? _act;

  WorkoutSessionController get _c => ref.read(workoutSessionProvider.notifier);

  String _hint(WorkoutSession s, LogExercise e) {
    if (e.isWeight) {
      return 'Volume so far ${TNum.n(s.volumeOf(s.cur))} kg · BW = ${ClientTrainingMock.bodyweightKg} kg (last weigh-in). '
          'Tap BW on a set to log bodyweight; − / + adds load or assistance.';
    }
    if (e.isTime) {
      final held = s.sets[s.cur].where((x) => x.done).fold(0.0, (a, x) => a + x.values[0]);
      return 'Hold so far ${TNum.short(held)} s each side. Tap ▶ to time the hold: it counts down and ticks the set at 0. '
          'Or tap the time to change it and tick it yourself.';
    }
    return 'Log the time and distance from the machine screen. Speed and incline come from Aman’s target.';
  }

  void _tick(int k) {
    setState(() => _act = null);
    final msg = _c.tickSet(k);
    if (msg != null) showToast(context, msg.$1, subtitle: msg.$2, kind: ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(workoutSessionProvider);
    final cur = s.cur;
    final e = WorkoutSession.exercises[cur];
    final sets = s.sets[cur];
    final last = cur == WorkoutSession.exercises.length - 1;
    var wn = 0;
    final rows = <Widget>[];
    for (var k = 0; k < sets.length; k++) {
      final x = sets[k];
      if (!x.warmup) wn++;
      final act = _act != null && _act!.$1 == k ? _act : null;
      rows.add(_SetRow(
        e: e,
        x: x,
        label: x.warmup ? 'W' : '$wn',
        prev: x.warmup ? 'Warm-up' : (wn - 1 < e.prev.length ? e.prev[wn - 1] : '—'),
        activeCol: act?.$2,
        hold: s.hold != null && s.hold!.$1 == cur && s.hold!.$2 == k ? s.hold!.$3 : null,
        onMenu: (v) => _setMenu(v, k, x, e),
        onEdit: (j) => setState(() => _act = act?.$2 == j ? null : (k, j)),
        onBw: () {
          _c.toggleBw(k);
          setState(() => _act = (k, 0));
        },
        onTick: () => _tick(k),
        onGo: () {
          setState(() => _act = null);
          _c.startHold(k);
        },
        onStop: () {
          _c.stopHold();
          showToast(context, 'Hold stopped', subtitle: 'Tick the set if you finished it');
        },
      ));
      if (act != null) {
        final j = act.$2;
        rows.add(_EditStrip(
          label: e.isWeight && j == 0 ? (x.bw ? 'BW ± kg' : 'Weight kg') : e.cols[j],
          value: formatSetValue(e, x, j),
          onMinus: () => _c.stepValue(k, j, -1),
          onPlus: () => _c.stepValue(k, j, 1),
          onDone: () => setState(() => _act = null),
        ));
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHead(e: e, pos: '${cur + 1} of ${WorkoutSession.exercises.length}', newBest: _newBest(s, e)),
          const SizedBox(height: 6),
          Text('Target ${e.target}', style: AppText.secondary.copyWith(color: AppColors.text2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (e.rest > 0) ...[
                AppButton.outline('Rest ${e.rest}s', icon: Icons.timer_outlined, small: true, onPressed: _c.restNow),
                const SizedBox(width: 6),
              ],
              AppButton.outline('How to do it', icon: Icons.play_circle_outline_rounded, small: true, onPressed: () {
                setState(() => _act = null);
                showExerciseGuide(context, cur);
              }),
              const Spacer(),
              Tooltip(
                message: _hint(s, e),
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 6),
                child: const SizedBox(width: 30, height: 30, child: Icon(Icons.info_outline_rounded, size: 18, color: AppColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
            child: Spaced(
              gap: 8,
              children: [
                if (e.isWeight) _LoadSeg(allBw: sets.isNotEmpty && sets.every((x) => x.bw), onKg: () => _c.setAllBw(false), onBw: () => _c.setAllBw(true)),
                _HeadRow(e: e),
                ...rows,
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _act = null);
                      _c.addSet();
                      showToast(context, 'Set added', subtitle: '${e.name} · set ${sets.length + 1}', kind: ToastKind.ok);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: AppColors.text2,
                      side: const BorderSide(color: AppColors.line2),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add set', style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.text2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AppButton.outline('Previous', icon: Icons.chevron_left_rounded, onPressed: cur == 0 ? null : () => _c.goTo(cur - 1)),
              const SizedBox(width: 8),
              Expanded(
                child: last
                    ? AppButton('Finish workout', icon: Icons.flag_rounded, expand: true, onPressed: () => WorkoutSheets.finish(context, ref))
                    : AppButton.dark('Next exercise', icon: Icons.chevron_right_rounded, expand: true, onPressed: () => _c.goTo(cur + 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A ticked working set beats the PR (kg for weights, seconds for holds).
  bool _newBest(WorkoutSession s, LogExercise e) {
    final pr = double.tryParse(e.pr.split(' ').first);
    if (pr == null) return false;
    return s.sets[s.cur].any((x) => x.done && !x.warmup && (e.isWeight ? s.kgOf(x) : x.values[0]) > pr);
  }

  void _setMenu(int v, int k, LoggedSet x, LogExercise e) {
    setState(() => _act = null);
    if (v == 0) {
      _c.toggleWarmup(k);
      showToast(context, x.warmup ? 'Working set' : 'Warm-up set', subtitle: '${e.name} · ${x.warmup ? 'counts towards volume' : 'not counted in volume'}');
    } else {
      final prev = ref.read(workoutSessionProvider);
      _c.deleteSet(k);
      showToast(context, 'Set deleted', subtitle: e.name, kind: ToastKind.del, onUndo: () => _c.restore(prev));
    }
  }
}

class _PanelHead extends StatelessWidget {
  const _PanelHead({required this.e, required this.pos, this.newBest = false});
  final LogExercise e;
  final bool newBest;
  final String pos;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${e.block} · $pos'.toUpperCase(), style: AppText.overline.copyWith(fontSize: 11.5, color: AppColors.accentText)),
              const SizedBox(height: 2),
              Text(e.name, style: AppText.sectionTitle),
            ],
          ),
        ),
        if (newBest)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(7)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.emoji_events_rounded, size: 12, color: AppColors.warnText),
              const SizedBox(width: 4),
              Text('New best', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.warnText)),
            ]),
          )
        else if (e.pr.isNotEmpty)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(7)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.emoji_events_rounded, size: 12, color: AppColors.okText),
              const SizedBox(width: 4),
              Text('PR ${e.pr}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.okText)),
            ]),
          ),
      ],
    );
  }
}

class _LoadSeg extends StatelessWidget {
  const _LoadSeg({required this.allBw, required this.onKg, required this.onBw});
  final bool allBw;
  final VoidCallback onKg;
  final VoidCallback onBw;

  @override
  Widget build(BuildContext context) {
    Widget seg(String t, bool on, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? AppColors.text : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Text(t, style: AppText.secondary.copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w600, color: on ? Colors.white : AppColors.text2)),
          ),
        );
    return Row(
      children: [
        Expanded(child: Text('Load', style: AppText.bodyBold.copyWith(fontSize: 13.5))),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [seg('kg', !allBw, onKg), seg('Bodyweight', allBw, onBw)]),
        ),
      ],
    );
  }
}

/// Column layout shared by the header and set rows.
List<Widget> _cells(LogExercise e, List<Widget> values, {Widget? lead, Widget? prev, Widget? go, Widget? tick}) {
  final out = <Widget>[SizedBox(width: 34, child: lead), const SizedBox(width: 6), SizedBox(width: 48, child: prev)];
  for (var j = 0; j < values.length; j++) {
    out.add(const SizedBox(width: 6));
    out.add(e.isWeight && j == 1 ? SizedBox(width: 72, child: values[j]) : Expanded(child: values[j]));
  }
  if (e.isTime) out.addAll([const SizedBox(width: 6), SizedBox(width: 40, child: go)]);
  out.addAll([const SizedBox(width: 6), SizedBox(width: 40, child: tick)]);
  return out;
}

class _HeadRow extends StatelessWidget {
  const _HeadRow({required this.e});
  final LogExercise e;

  @override
  Widget build(BuildContext context) {
    final st = AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700);
    return Row(
      children: _cells(e, [for (final c in e.cols) Text(c, textAlign: TextAlign.center, style: st)],
          lead: Padding(padding: const EdgeInsets.only(left: 4), child: Text('Set', style: st)),
          prev: Text('Prev', style: st)),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.e,
    required this.x,
    required this.label,
    required this.prev,
    required this.activeCol,
    required this.hold,
    required this.onMenu,
    required this.onEdit,
    required this.onBw,
    required this.onTick,
    required this.onGo,
    required this.onStop,
  });
  final LogExercise e;
  final LoggedSet x;
  final String label;
  final String prev;
  final int? activeCol;
  final int? hold;
  final ValueChanged<int> onMenu;
  final ValueChanged<int> onEdit;
  final VoidCallback onBw;
  final VoidCallback onTick;
  final VoidCallback onGo;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final running = hold != null;
    final (snBg, snFg) = x.done
        ? (const Color(0xFFDCFCE7), const Color(0xFF166534))
        : x.warmup
            ? (const Color(0xFFFFF4DB), const Color(0xFFA15C00))
            : (AppColors.sub, AppColors.text2);
    final lead = PopupMenuButton<int>(
      tooltip: 'Set options',
      position: PopupMenuPosition.under,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onMenu,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 0,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.local_fire_department_outlined, size: 18, color: AppColors.text2)),
            const SizedBox(width: 10),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.warmup ? 'Make it a working set' : 'Mark as warm-up', style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(x.warmup ? 'Counts towards volume again' : 'Does not count towards volume', style: AppText.caption),
              ]),
            ),
          ]),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(children: [
            const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.bad),
            const SizedBox(width: 10),
            Text('Delete set', style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.bad)),
          ]),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: snBg, borderRadius: BorderRadius.circular(9)),
        child: Text(label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w800, color: snFg)),
      ),
    );

    final values = <Widget>[
      for (var j = 0; j < e.cols.length; j++)
        Row(children: [
          if (e.isWeight && j == 0) ...[
            _BwButton(on: x.bw, onTap: onBw),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: _ValueBox(
              text: running ? '0:${hold.toString().padLeft(2, '0')}' : formatSetValue(e, x, j),
              active: activeCol == j,
              placeholder: !(x.touched || x.done || running),
              running: running,
              done: x.done,
              onTap: () => onEdit(j),
            ),
          ),
        ]),
    ];

    final go = e.isTime && !x.done
        ? _RoundButton(on: running, icon: running ? Icons.stop_rounded : Icons.play_arrow_rounded, onTap: running ? onStop : onGo)
        : null;

    final tick = Material(
      color: x.done ? _green : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: x.done ? _green : AppColors.line, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTick,
        child: SizedBox(height: 40, child: Icon(Icons.check_rounded, size: 20, color: x.done ? Colors.white : const Color(0xFFC9C9C3))),
      ),
    );

    final prevText = Text(prev,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(fontSize: 11.5, color: x.warmup ? const Color(0xFFA15C00) : AppColors.muted));
    return Row(children: _cells(e, values, lead: Align(alignment: Alignment.centerLeft, child: lead), prev: prevText, go: go, tick: tick));
  }
}

class _BwButton extends StatelessWidget {
  const _BwButton({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text('BW', style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.text2)),
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.text, required this.active, required this.placeholder, required this.running, required this.done, required this.onTap});
  final String text;
  final bool active;
  final bool placeholder;
  final bool running;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = running ? AppColors.accentSoft : (done ? const Color(0xFFEEF9F2) : (active ? Colors.white : const Color(0xFFFAFAF8)));
    final border = active || running ? AppColors.accent : (done ? const Color(0xFFBFE8CF) : AppColors.line);
    final fg = running ? AppColors.accent : (placeholder ? const Color(0xFFA3A39C) : AppColors.text);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
          boxShadow: active ? const [BoxShadow(color: AppColors.accentSoft, spreadRadius: 2)] : null,
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: fg, fontFeatures: const [FontFeature.tabularFigures()])),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.on, required this.icon, required this.onTap});
  final bool on;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.accent : Colors.white,
      shape: CircleBorder(side: BorderSide(color: on ? AppColors.accent : AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 18, color: on ? Colors.white : AppColors.accent)),
      ),
    );
  }
}

/// Blue strip under a set to change the tapped value (− value + Done).
class _EditStrip extends StatelessWidget {
  const _EditStrip({required this.label, required this.value, required this.onMinus, required this.onPlus, required this.onDone});
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)))),
          _CircleIcon(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 60,
            child: Text(value, textAlign: TextAlign.center, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          _CircleIcon(Icons.add_rounded, onPlus),
          const SizedBox(width: 8),
          AppButton.dark('Done', small: true, onPressed: onDone),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFBFD3FB))),
      child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 17, color: AppColors.text2))),
    );
  }
}
