import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import 'plans_tab.dart';

typedef _M = ClientProfileMock;

const _titles = {
  'workout': 'Fat Loss Phase 1',
  'meal': '1,650 kcal · high protein',
  'supp': 'Fat loss basics',
  'habit': 'Daily basics',
};

/// "Edit for Riya" / "Duplicate and edit" for any of the four plans.
class PlanEditor extends StatefulWidget {
  const PlanEditor({super.key, required this.kind});
  final String kind;
  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  bool saveToLibrary = false;
  late String starts = widget.kind == 'workout' ? 'After current plan ends · Mon, 23 Nov' : 'From tomorrow · replaces current';
  late String length = widget.kind == 'workout' ? '12 weeks' : 'Ongoing';

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final title = _titles[widget.kind]!;
    final caps = {
      'workout': 'Week 6 of 12 · changes start tomorrow · ${c.workoutDays.where((d) => d.edited).length} days changed from the master',
      'meal': 'Since 1 Sep · 1 change from the master',
      'supp': 'Since 1 Sep · 1 change from the master',
      'habit': 'Since 12 Jan · 1 change from the master',
    };
    return Spaced(
      children: [
        _Bar(dup: c.dup, title: title, kind: widget.kind),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(
                child: Text(
                  c.dup ? 'New plan for ${c.first}: copy of $title' : 'Edit $title for ${c.first}',
                  style: AppText.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              InfoTip(c.dup
                  ? 'A new plan only for ${c.first}. Her current plan keeps running until the copy starts. The master stays the same.'
                  : "Only ${c.first}'s copy changes. The master plan and other clients stay the same. Changed items get a blue dot."),
            ]),
            Text(c.dup ? 'Change what you need below, then pick when it starts.' : caps[widget.kind]!, style: AppText.caption),
          ],
        ),
        if (c.dup) _dupBar(c, title),
        switch (widget.kind) {
          'meal' => const _MealEditor(),
          'supp' => const _SuppEditor(),
          'habit' => const _HabitEditor(),
          _ => const _WorkoutEditor(),
        },
      ],
    );
  }

  Widget _dupBar(ClientProfileController c, String title) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(label: 'Plan name', initialValue: '$title · ${c.first} v2'),
          const SizedBox(height: 10),
          SelectField(
            label: 'Starts',
            value: starts,
            options: const ['After current plan ends · Mon, 23 Nov', 'From tomorrow · replaces current', 'Mon, 19 Oct'],
            onChanged: (v) => setState(() => starts = v),
          ),
          const SizedBox(height: 10),
          SelectField(
            label: 'Length',
            value: length,
            options: const ['4 weeks', '8 weeks', '12 weeks', 'Ongoing'],
            onChanged: (v) => setState(() => length = v),
          ),
          const SizedBox(height: 6),
          ToggleLine(
            title: 'Also save to the library as a new master plan',
            sub: 'Other clients can then get it too.',
            value: saveToLibrary,
            onChanged: (v) => setState(() => saveToLibrary = v),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.dup, required this.title, required this.kind});
  final bool dup;
  final String title;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.outline('Back to plan', icon: Icons.arrow_back_rounded, small: true, onPressed: c.closePlanEdit),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (!dup)
              CpTextButton('Reset to master', icon: Icons.restart_alt_rounded, size: 13, onTap: () {
                final oldW = c.workoutDays;
                final oldM = c.meals;
                if (kind == 'workout') c.restoreWorkout([..._M.workoutDays]);
                if (kind == 'meal') c.setMeals([..._M.editorMeals]);
                showToast(context, 'Reset to master', subtitle: title, kind: ToastKind.ok, onUndo: () {
                  c.restoreWorkout(oldW);
                  c.setMeals(oldM);
                });
              }),
            const Spacer(),
            AppButton.outline('Cancel', small: true, onPressed: c.closePlanEdit),
            const SizedBox(width: 8),
            AppButton(dup ? 'Assign copy' : 'Save for ${c.first}', icon: Icons.check_rounded, small: true, onPressed: () {
              c.closePlanEdit();
              showToast(
                context,
                dup ? 'Copy assigned to ${c.first}' : 'Saved for ${c.first}',
                subtitle: dup ? '$title · ${c.first} v2' : '$title · she sees the changes from tomorrow',
                kind: ToastKind.ok,
              );
            }),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────── Workout editor ─────────────────────────

class _WorkoutEditor extends StatelessWidget {
  const _WorkoutEditor();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final day = c.currentEditDay;
    final tags = exerciseTags(day.exercises);
    return Spaced(
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CpRows([
            for (final d in c.workoutDays)
              CpRow(
                selected: d.day == c.editDay,
                leading: SizedBox(width: 34, child: Text(d.day, style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text2))),
                title: d.name,
                sub: d.isRest ? 'Rest day' : '${d.exercises.length} exercises',
                trailing: d.edited ? const ChangeDot() : null,
                onTap: () => c.setEditDay(d.day),
              ),
          ]),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: EditCell(day.name, onTap: () => showToast(context, 'Day names come from the master plan', kind: ToastKind.info))),
                    const SizedBox(width: 8),
                    SizedBox(width: 120, child: EditCell(day.kind, select: true, onTap: () => showToast(context, 'Day type comes from the master plan', kind: ToastKind.info))),
                  ]),
                  const SizedBox(height: 6),
                  Text(day.isRest ? 'No exercises' : '${day.exercises.length} exercises · drag to reorder', style: AppText.caption),
                ]),
              ),
              if (day.isRest)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(children: [
                    Expanded(child: Text('Rest day. ${c.first} sees only her step goal.', style: AppText.secondary)),
                    AppButton.outline('Make it a workout day', small: true, onPressed: () => _openPicker(context, c, 'add')),
                  ]),
                )
              else ...[
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (a, b) {
                    final l = [...day.exercises];
                    final x = l.removeAt(a);
                    l.insert(b > a ? b - 1 : b, x);
                    c.updateEditDay(l);
                  },
                  children: [
                    for (var i = 0; i < day.exercises.length; i++)
                      _ExerciseEditCard(key: ValueKey('${day.day}-$i-${day.exercises[i].name}'), index: i, e: day.exercises[i], tag: tags[i]),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(child: AddButton('Add exercise', onTap: () => _openPicker(context, c, 'add'))),
                    const SizedBox(width: 8),
                    Expanded(child: AddButton('Add superset', onTap: () => _openPicker(context, c, 'ss'))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseEditCard extends StatelessWidget {
  const _ExerciseEditCard({super.key, required this.index, required this.e, required this.tag});
  final int index;
  final WorkoutExercise e;
  final (String, bool) tag;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    Future<void> edit(String label, String value, WorkoutExercise Function(String v) apply) async {
      final v = await editText(context, title: label, value: value == '–' ? '' : value);
      if (v == null) return;
      final l = [...c.currentEditDay.exercises];
      l[index] = apply(v).copyWith(was: l[index].was ?? 'Was: $label $value');
      c.updateEditDay(l);
    }

    final noteText = e.note ?? (e.changed && index == 0 ? 'Keep the box low, go slow' : 'Add a note');
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(padding: EdgeInsets.only(top: 2, right: 6), child: Icon(Icons.drag_indicator_rounded, size: 18, color: AppColors.muted)),
              ),
              NumTag(tag.$1, superset: tag.$2),
              const SizedBox(width: 6),
              if (e.changed) const Padding(padding: EdgeInsets.only(top: 8), child: ChangeDot()),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.shownName, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  if (e.programEdit != null) Text('Edited in the program', style: AppText.caption),
                  if (e.changed) Text(c.r(e.was!), style: AppText.caption),
                ]),
              ),
              IconButton(
                tooltip: 'Swap exercise',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.swap_horiz_rounded, size: 19, color: AppColors.text2),
                onPressed: () => _openPicker(context, c, 'swap', index: index, name: e.shownName),
              ),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.text2),
                onPressed: () {
                  final before = c.workoutDays;
                  final l = [...c.currentEditDay.exercises]..removeAt(index);
                  c.updateEditDay(l);
                  showToast(context, 'Removed for ${c.first}', subtitle: e.shownName, kind: ToastKind.del, onUndo: () => c.restoreWorkout(before));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: EditCell(noteText, onTap: () => edit('Note', e.note ?? '', (v) => e.copyWith(note: v))),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LayoutBuilder(builder: (context, box) {
              final w = (box.maxWidth - 16) / 3;
              final cells = <(String, String, WorkoutExercise Function(String))>[
                ('Sets', e.sets, (v) => e.copyWith(sets: v)),
                ('Reps', e.reps, (v) => e.copyWith(reps: v)),
                ('RPE', e.rpe?.toString() ?? '–', (v) => e.copyWith(rpe: int.tryParse(v))),
                ('Tempo', e.tempo ?? '–', (v) => e.copyWith(tempo: v)),
                ('Rest', e.rest, (v) => e.copyWith(rest: v)),
                ('Load', e.load, (v) => e.copyWith(load: v)),
              ];
              return Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (l, v, f) in cells)
                  SizedBox(
                    width: w,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      EditCell(v, onTap: () => edit(l, v, f)),
                    ]),
                  ),
              ]);
            }),
          ),
        ],
      ),
    );
  }
}

void _openPicker(BuildContext context, ClientProfileController c, String mode, {int? index, String? name}) {
  final day = c.currentEditDay;
  showCpSheet(
    context,
    title: mode == 'swap' ? 'Swap $name' : (mode == 'ss' ? 'Add a superset' : 'Add exercises'),
    subtitle: '${_M.fullDay[day.day]} · ${day.name} · only for ${c.first}',
    builder: (_) => _ExercisePicker(c: c, mode: mode, index: index, name: name),
  );
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.c, required this.mode, this.index, this.name});
  final ClientProfileController c;
  final String mode;
  final int? index;
  final String? name;
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final picked = <String>[];
  String muscle = 'All';
  String q = '';

  bool get single => widget.mode == 'swap';
  int get need => widget.mode == 'ss' ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final day = c.currentEditDay;
    final onDay = day.exercises.map((e) => e.name).toSet();
    const lib = _M.exerciseLibrary;
    final muscles = ['All', ...{for (final e in lib) e.muscle}];
    final list = lib.where((e) => (muscle == 'All' || e.muscle == muscle) && e.name.toLowerCase().contains(q.toLowerCase())).toList();
    final btn = single ? 'Swap' : widget.mode == 'ss' ? 'Add superset' : (picked.length > 1 ? 'Add ${picked.length} exercises' : 'Add exercise');
    final hint = single
        ? 'Pick one exercise. Sets, reps and rest stay the same.'
        : widget.mode == 'ss'
            ? 'Pick 2 exercises. ${c.first} does them back to back.'
            : null;
    return SheetBody(
      note: picked.isNotEmpty ? '${picked.length} selected' : (single ? 'Pick one' : 'Tick the exercises to add'),
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton(btn, icon: Icons.check_rounded, onPressed: () => _add(context, day)),
      ],
      children: [
        SheetSearch('Search exercises', onChanged: (v) => setState(() => q = v)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final m in muscles) ...[
              FChip(m, selected: m == muscle, count: m == 'All' ? lib.length : lib.where((e) => e.muscle == m).length, onTap: () => setState(() => muscle = m)),
              const SizedBox(width: 6),
            ],
          ]),
        ),
        if (hint != null) HintLine(hint) else const SizedBox(height: 10),
        OptionList([
          for (var i = 0; i < list.length; i++)
            OptionTile(
              multi: !single,
              selected: picked.contains(list[i].name),
              disabled: onDay.contains(list[i].name),
              leading: MediaBox(tone: i, width: 44, height: 44, icon: Icons.play_arrow_rounded, radius: 8),
              title: list[i].name,
              titleExtras: [if (onDay.contains(list[i].name)) const AppBadge('On this day', tone: BadgeTone.info)],
              sub: '${list[i].muscle} · ${list[i].level}',
              trailing: Text(list[i].equipment, style: AppText.caption),
              onTap: () => setState(() {
                final n = list[i].name;
                if (single) {
                  picked
                    ..clear()
                    ..add(n);
                } else {
                  picked.contains(n) ? picked.remove(n) : picked.add(n);
                }
              }),
            ),
        ]),
        const SizedBox(height: 12),
      ],
    );
  }

  void _add(BuildContext context, WorkoutDay day) {
    final c = widget.c;
    if (picked.length < need) {
      showToast(context, single ? 'Pick an exercise' : 'Pick $need exercises', kind: ToastKind.warn);
      return;
    }
    final before = c.workoutDays;
    final l = [...day.exercises];
    final full = _M.fullDay[day.day]!;
    String title;
    String sub;
    if (single) {
      final old = l[widget.index!];
      l[widget.index!] = WorkoutExercise(picked.first, old.sets, old.reps, old.rest, old.load,
          was: 'Was: ${old.name}', rpe: old.rpe, tempo: old.tempo, superset: old.superset);
      title = 'Swapped for ${c.first}';
      sub = '${widget.name} → ${picked.first}';
    } else {
      final used = l.map((e) => e.superset).whereType<String>().toSet();
      final g = widget.mode == 'ss' ? ['A', 'B', 'C', 'D'].firstWhere((x) => !used.contains(x)) : null;
      for (final n in picked) {
        l.add(WorkoutExercise(n, '3', g != null ? '12' : '10', g != null ? '60 s' : '90 s', '—', was: 'Added for Riya', superset: g));
      }
      title = g != null ? 'Superset added' : '${picked.length} ${picked.length == 1 ? 'exercise' : 'exercises'} added';
      sub = '$full · only for ${c.first}';
    }
    c.updateEditDay(l);
    Navigator.of(context).pop();
    showToast(context, title, subtitle: sub, kind: ToastKind.ok, onUndo: () => c.restoreWorkout(before));
  }
}

// ───────────────────────── Meal editor ─────────────────────────

String _fq(double q) {
  final r = (q * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
}

String _portion(double q, String u) => u == 'g' ? '${_fq(q)} g' : (q == 1 ? u : '${_fq(q)} × $u');

String _por(PlanFood f) => _portion(f.qty, f.unit) + (f.unit == 'g' ? '' : ' · ${_fq(f.qty * f.unitGrams)} g');

String _fmt(num n) {
  final v = n.round();
  return v.abs() >= 1000 ? '${v ~/ 1000},${(v.abs() % 1000).toString().padLeft(3, '0')}' : '$v';
}

List<double> _tot(List<PlanFood> fs) => fs.fold([0.0, 0.0, 0.0, 0.0], (a, f) => [a[0] + f.kcal * f.qty, a[1] + f.p * f.qty, a[2] + f.c * f.qty, a[3] + f.f * f.qty]);

class _MealEditor extends StatelessWidget {
  const _MealEditor();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final all = c.meals.fold([0.0, 0.0, 0.0, 0.0], (a, m) {
      final t = _tot(m.foods);
      return [for (var i = 0; i < 4; i++) a[i] + t[i]];
    });
    final changed = c.meals.fold(0, (a, m) => a + m.foods.where((f) => f.was != null).length);
    final diff = all[0] - 1650;
    final ok = diff.abs() <= 1650 * .05;
    return Spaced(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Daily target', style: AppText.bodyBold.copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: const [
                EditCell('1,650 kcal', width: 100),
                EditCell('120 g protein', width: 112),
                EditCell('170 g carbs', width: 100),
                EditCell('52 g fat', width: 84),
              ]),
              const SizedBox(height: 10),
              Text.rich(TextSpan(style: AppText.secondary, children: [
                const TextSpan(text: 'Plan adds up to '),
                TextSpan(text: '${_fmt(all[0])} kcal', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                TextSpan(text: ' · P ${all[1].round()} g · C ${all[2].round()} g · F ${all[3].round()} g'),
              ])),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 6, children: [
                AppBadge(ok ? 'On target' : (diff > 0 ? '${_fmt(diff)} kcal over' : '${_fmt(-diff)} kcal under'), tone: ok ? BadgeTone.ok : BadgeTone.warn),
                if (changed > 0)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const ChangeDot(),
                    Text('$changed ${changed == 1 ? 'food' : 'foods'} changed for ${c.first}', style: AppText.caption.copyWith(color: AppColors.accentText)),
                  ]),
              ]),
            ],
          ),
        ),
        for (var mi = 0; mi < c.meals.length; mi++) _MealCard(mi),
        AppCard(
          color: const Color(0xFFFAFAF8),
          child: Row(children: [
            const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(child: Text('Tap a food to change how much ${c.first} eats, its unit, or the swaps she may use.', style: AppText.secondary)),
          ]),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(this.mi);
  final int mi;

  static const _icons = {'Breakfast': Icons.free_breakfast_outlined, 'Lunch': Icons.lunch_dining_outlined, 'Dinner': Icons.dinner_dining_outlined};

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final m = c.meals[mi];
    final t = _tot(m.foods);
    final diff = t[0] - m.target;
    final ok = diff.abs() / m.target <= .05;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              TintIcon(_icons[m.name] ?? Icons.cookie_outlined, tint: Tint.amber, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name, style: AppText.bodyBold),
                  Text('${m.time} · target ${_fmt(m.target)} kcal', style: AppText.caption),
                ]),
              ),
              AppBadge(ok ? 'On target' : (diff > 0 ? '${_fmt(diff)} kcal over' : '${_fmt(-diff)} kcal under'), tone: ok ? BadgeTone.ok : BadgeTone.warn),
            ]),
          ),
          if (m.foods.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text('No foods yet. Use Add food to pick from the food library.', style: AppText.caption),
            ),
          for (var fi = 0; fi < m.foods.length; fi++) _FoodRow(mi, fi),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 14, 10),
            child: Row(children: [
              CpTextButton('Add food', icon: Icons.add_rounded, size: 13, onTap: () => _openFoodPicker(context, c, mi)),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: _fmt(t[0]), style: AppText.bodyBold.copyWith(fontSize: 13)),
                  TextSpan(text: ' / ${_fmt(m.target)} kcal', style: AppText.caption),
                ])),
                Text('P ${t[1].round()} g · C ${t[2].round()} g · F ${t[3].round()} g', style: AppText.caption.copyWith(fontSize: 11)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow(this.mi, this.fi);
  final int mi;
  final int fi;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final f = c.meals[mi].foods[fi];
    final sw = f.swaps.isEmpty ? 'No swap' : '${f.swaps.length} ${f.swaps.length == 1 ? 'swap' : 'swaps'}';
    return InkWell(
      onTap: () => _openPortion(context, c, mi, fi),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaBox(tone: f.name.length, width: 28, height: 28, icon: Icons.restaurant_rounded, radius: 7),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (f.was != null) const ChangeDot(),
                  Flexible(child: Text(f.name, style: AppText.bodyBold.copyWith(fontSize: 13))),
                ]),
                Text.rich(TextSpan(style: AppText.caption, children: [
                  TextSpan(text: _por(f)),
                  if (f.was != null) TextSpan(text: ' · Was: ${f.was}', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.accentText)),
                ])),
                const SizedBox(height: 3),
                Wrap(spacing: 10, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.swap_horiz_rounded, size: 13, color: f.swaps.isEmpty ? AppColors.muted : AppColors.accentText),
                    const SizedBox(width: 3),
                    Text(sw, style: AppText.caption.copyWith(fontSize: 11, color: f.swaps.isEmpty ? AppColors.muted : AppColors.accentText)),
                  ]),
                  Text('P ${(f.p * f.qty).round()}  C ${(f.c * f.qty).round()}  F ${(f.f * f.qty).round()}', style: AppText.caption.copyWith(fontSize: 11)),
                ]),
              ]),
            ),
            Text(_fmt(f.kcal * f.qty), style: AppText.bodyBold.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Portion and swaps for one food (cpm-side panel, as a sheet on the phone).
void _openPortion(BuildContext context, ClientProfileController c, int mi, int fi) {
  final m = c.meals[mi];
  showCpSheet(context, title: 'Portion and swaps', subtitle: '${m.name} · ${m.time}', builder: (_) => ProfileScope(controller: c, child: _Portion(mi, fi)));
}

class _Portion extends StatelessWidget {
  const _Portion(this.mi, this.fi);
  final int mi;
  final int fi;

  void _update(ClientProfileController c, PlanFood Function(PlanFood) fn) {
    final meals = [...c.meals];
    final m = meals[mi];
    final foods = [...m.foods];
    final old = foods[fi];
    var nf = fn(old);
    if (nf.was == null) nf = nf.copyWith(was: _por(old));
    foods[fi] = nf;
    meals[mi] = m.copyWith(foods: foods);
    c.setMeals(meals);
  }

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    if (fi >= c.meals[mi].foods.length) return const SizedBox.shrink();
    final f = c.meals[mi].foods[fi];
    final step = f.unit == 'g' ? 5.0 : .5;
    final gTot = f.qty * f.unitGrams;
    return SheetBody(
      lead: Align(
        alignment: Alignment.centerLeft,
        child: CpTextButton('Remove from this meal', danger: true, icon: Icons.delete_outline_rounded, size: 13, onTap: () {
          final before = c.meals;
          final meals = [...c.meals];
          meals[mi] = meals[mi].copyWith(foods: [...meals[mi].foods]..removeAt(fi));
          c.setMeals(meals);
          Navigator.of(context).pop();
          showToast(context, 'Removed from ${before[mi].name}', subtitle: f.name, kind: ToastKind.del, onUndo: () => c.setMeals(before));
        }),
      ),
      actions: [AppButton('Done', onPressed: () => Navigator.of(context).pop())],
      children: [
        Row(children: [
          MediaBox(tone: f.name.length, width: 40, height: 40, icon: Icons.restaurant_rounded, radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: AppText.bodyBold),
              Text(
                '${f.per100[0].round()} kcal per 100 g · ${f.units.length - 1} ${f.units.length == 2 ? 'unit' : 'units'} + grams',
                style: AppText.caption,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text('Amount', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          const InfoTip('Changing the unit keeps the same amount in grams. Change the number to give more or less.'),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          AppIconButton(Icons.remove_rounded, small: true, onPressed: () => _update(c, (x) => x.copyWith(qty: math.max(step, x.qty - step)))),
          SizedBox(width: 56, child: Text(_fq(f.qty), textAlign: TextAlign.center, style: AppText.bodyBold.copyWith(fontSize: 16))),
          AppIconButton(Icons.add_rounded, small: true, onPressed: () => _update(c, (x) => x.copyWith(qty: math.min(f.unit == 'g' ? 2000 : 20, x.qty + step)))),
          const SizedBox(width: 10),
          Expanded(
            child: SelectField(
              value: f.unit == 'g' ? 'Grams' : f.unit,
              onTap: () => _pickUnit(context, c, f, gTot),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('${_fq(gTot)} g', style: AppText.bodyBold.copyWith(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_fmt(f.kcal * f.qty)} kcal · P ${(f.p * f.qty).round()} g · C ${(f.c * f.qty).round()} g · F ${(f.f * f.qty).round()} g',
              style: AppText.caption,
            ),
          ),
        ]),
        if (f.was != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Was ${f.was} in the master plan.', style: AppText.caption)),
        const SizedBox(height: 16),
        Row(children: [
          Text('Swaps ${c.first} may use', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          const InfoTip('She can eat one of these instead. The amount gives about the same calories.'),
        ]),
        const SizedBox(height: 6),
        for (final a in [...f.swaps]..sort((x, y) => y.match.compareTo(x.match)))
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: AppText.bodyBold.copyWith(fontSize: 13)),
                  Text(a.portion, style: AppText.caption),
                ]),
              ),
              AppBadge('${a.match}% match', tone: a.match >= 80 ? BadgeTone.ok : BadgeTone.warn),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.muted),
                onPressed: () => _update(c, (x) => x.copyWith(swaps: x.swaps.where((y) => y.name != a.name).toList())),
              ),
            ]),
          ),
        if (f.swaps.isEmpty) Text('No swaps. ${c.first} has to eat this food.', style: AppText.caption),
        Align(
          alignment: Alignment.centerLeft,
          child: CpTextButton('Add alternative', icon: Icons.add_rounded, size: 13, onTap: () => _pickSwap(context, c, f)),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _pickUnit(BuildContext context, ClientProfileController c, PlanFood f, double gTot) async {
    final labels = [for (final u in f.units) u.label == 'g' ? 'Grams' : '${u.label} · ${_fq(u.grams)} g'];
    final cur = labels[f.units.indexWhere((u) => u.label == f.unit)];
    final v = await pickOption(context, title: 'Units of ${f.name}', options: labels, current: cur);
    if (v == null || v == cur) return;
    final u = f.units[labels.indexOf(v)];
    final nq = u.label == 'g' ? math.max(5.0, (gTot / 5).round() * 5.0) : math.max(.5, (gTot / u.grams * 2).round() / 2);
    _update(
      c,
      (x) => x.copyWith(
        unit: u.label,
        qty: nq,
        kcal: x.per100[0] * u.grams / 100,
        p: x.per100[1] * u.grams / 100,
        c: x.per100[2] * u.grams / 100,
        f: x.per100[3] * u.grams / 100,
      ),
    );
    if (context.mounted) {
      showToast(context, '${f.name} in ${u.label == 'g' ? 'grams' : u.label}', subtitle: '${_portion(f.qty, f.unit)} → ${_portion(nq, u.label)} · same grams', kind: ToastKind.ok);
    }
  }

  Future<void> _pickSwap(BuildContext context, ClientProfileController c, PlanFood f) async {
    final picked = await showCpSheet<(LibraryFood, String, int)>(
      context,
      title: 'Pick an alternative',
      subtitle: 'Amounts give the same calories as ${_portion(f.qty, f.unit)}.',
      builder: (_) => _SwapPicker(f),
    );
    if (picked == null) return;
    _update(c, (x) => x.copyWith(swaps: [...x.swaps, FoodSwap(picked.$1.name, picked.$2, picked.$3)]));
    if (context.mounted) showToast(context, 'Swap added for ${c.first}', subtitle: '${picked.$1.name} for ${f.name}', kind: ToastKind.ok);
  }
}

class _SwapPicker extends StatefulWidget {
  const _SwapPicker(this.f);
  final PlanFood f;
  @override
  State<_SwapPicker> createState() => _SwapPickerState();
}

class _SwapPickerState extends State<_SwapPicker> {
  String group = 'grp';

  List<double> _split(num p, num c, num f) {
    final t = math.max(1, p * 4 + c * 4 + f * 9);
    return [p * 4 / t, c * 4 / t, f * 9 / t];
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.f;
    final me = _M.foodLibrary.where((x) => x.name == f.name).firstOrNull;
    final kTot = f.kcal * f.qty;
    final sA = _split(f.p, f.c, f.f);
    final rows = <(int, LibraryFood, String, int, int)>[];
    for (final x in _M.foodLibrary) {
      if (!x.isVeg || x.name == f.name || f.swaps.any((y) => y.name == x.name)) continue;
      if (group == 'grp' && me != null && x.group != me.group) continue;
      final cat = _M.foodCatalog[x.name]!;
      final sB = _split(x.p, x.c, x.f);
      final mt = math.max(0, (100 - 50 * ((sA[0] - sB[0]).abs() + (sA[1] - sB[1]).abs() + (sA[2] - sB[2]).abs())).round());
      final q = cat.unit == 'g' ? math.max(5.0, (kTot / cat.kcal / 5).round() * 5.0) : math.max(.5, (kTot / cat.kcal * 2).round() / 2);
      rows.add((mt, x, _portion(q, cat.unit), (q * cat.kcal).round(), (q * cat.p).round()));
    }
    rows.sort((a, b) => b.$1.compareTo(a.$1));
    final top = rows.take(6).toList();
    return SheetBody(
      actions: [AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())],
      children: [
        SegmentedTabs<String>(items: const [('grp', 'Same group'), ('all', 'All foods')], value: group, onChanged: (v) => setState(() => group = v)),
        const SizedBox(height: 10),
        if (top.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text('No other foods in this group.', style: AppText.secondary)),
        for (final (mt, x, por, k, pp) in top)
          CpRow(
            leading: MediaBox(tone: x.name.length, width: 28, height: 28, icon: Icons.restaurant_rounded, radius: 7),
            title: x.name,
            sub: '$por · $k kcal · P $pp g',
            trailing: AppBadge('$mt% match', tone: mt >= 85 ? BadgeTone.ok : (mt >= 65 ? BadgeTone.warn : BadgeTone.bad)),
            onTap: () => Navigator.of(context).pop((x, por, mt)),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

void _openFoodPicker(BuildContext context, ClientProfileController c, int mi) {
  final m = c.meals[mi];
  showCpSheet(context, title: 'Add to ${m.name} · ${m.time}', subtitle: 'Food library · only for ${c.first}', builder: (_) => ProfileScope(controller: c, child: _FoodPicker(mi)));
}

class _FoodPicker extends StatefulWidget {
  const _FoodPicker(this.mi);
  final int mi;
  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  String group = 'All';
  int added = 0;
  String q = '';

  bool _inG(LibraryFood x, String g) => g == 'All' || (g == 'My foods' ? x.team : x.group == g);

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final m = c.meals[widget.mi];
    final veg = _M.foodLibrary.where((x) => x.isVeg).toList();
    final list = veg.where((x) => _inG(x, group) && x.name.toLowerCase().contains(q.toLowerCase())).toList()..sort((a, b) => b.p.compareTo(a.p));
    final inMeal = m.foods.map((f) => f.name).toSet();
    return SheetBody(
      lead: Align(
        alignment: Alignment.centerLeft,
        child: CpTextButton('Create custom food', icon: Icons.add_rounded, size: 13, onTap: () {
          Navigator.of(context).pop();
          showToast(context, 'Opened the food library', subtitle: 'Create the food there, then add it here', kind: ToastKind.info);
        }),
      ),
      note: added > 0 ? '$added added' : null,
      actions: [AppButton('Done', onPressed: () => Navigator.of(context).pop())],
      children: [
        SheetSearch('Search paneer, dal, chicken…', onChanged: (v) => setState(() => q = v)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final g in _M.foodGroups) ...[
              FChip(g, selected: g == group, count: veg.where((x) => _inG(x, g)).length, onTap: () => setState(() => group = g)),
              const SizedBox(width: 6),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Text('${list.length} foods', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('Most protein first · veg foods for ${c.first}', style: AppText.caption),
          ]),
        ),
        for (final x in list)
          CpRow(
            leading: MediaBox(tone: x.name.length, width: 28, height: 28, icon: Icons.restaurant_rounded, radius: 7),
            title: x.name,
            titleWidget: Wrap(spacing: 6, children: [
              Text(x.name, style: AppText.bodyBold.copyWith(fontSize: 13)),
              if (x.team) const AppBadge('Team', tone: BadgeTone.info),
            ]),
            sub: '${x.serving} · ${x.kcal} kcal · P ${x.p} g · C ${x.c} g · F ${x.f} g',
            trailing: inMeal.contains(x.name)
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_rounded, size: 15, color: AppColors.okText),
                    Text('Added', style: AppText.caption.copyWith(color: AppColors.okText, fontWeight: FontWeight.w700)),
                  ])
                : AppButton.outline('Add', icon: Icons.add_rounded, small: true, onPressed: () {
                    final meals = [...c.meals];
                    meals[widget.mi] = m.copyWith(foods: [...m.foods, _M.foodCatalog[x.name]!.copyWith(was: 'not in the master')]);
                    c.setMeals(meals);
                    setState(() => added++);
                    showToast(context, 'Added ${x.name}', subtitle: '${m.name} · only for ${c.first}', kind: ToastKind.ok);
                  }),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ───────────────────────── Supplements / habits editors ─────────────────────────

class _SuppEditor extends StatefulWidget {
  const _SuppEditor();
  @override
  State<_SuppEditor> createState() => _SuppEditorState();
}

class _SuppEditorState extends State<_SuppEditor> {
  late List<SupplementItem> items = [..._M.supplements];

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PfCards(
            columns: 2,
            [
              for (var i = 0; i < items.length; i++)
                PfItem(
                  head: Row(children: [if (items[i].changed) const ChangeDot(), Text(items[i].name)]),
                  action: _removeBtn(context, c, items[i].name, () => items.removeAt(i), (x) => items.insert(i, x), items[i]),
                  fields: [
                    ('Dose', EditCell(items[i].dose, changed: items[i].changed)),
                    ('When', EditCell(items[i].when, select: true, onTap: () => pickOption(context, title: 'When', options: const ['Morning', 'Afternoon', 'Night'], current: items[i].when))),
                    ('How to take', EditCell(items[i].how)),
                    ('Stock at home', EditCell(items[i].stock)),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AddButton('Add supplement', onTap: () => showToast(context, 'Opened the supplement library', subtitle: 'Pick one to add for ${c.first}', kind: ToastKind.info)),
          ),
        ],
      ),
    );
  }

  Widget _removeBtn(BuildContext context, ClientProfileController c, String name, VoidCallback remove, void Function(SupplementItem) undo, SupplementItem x) {
    return IconButton(
      tooltip: 'Remove',
      icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.text2),
      onPressed: () {
        setState(remove);
        showToast(context, 'Removed for ${c.first}', subtitle: name, kind: ToastKind.del, onUndo: () {
          if (mounted) setState(() => undo(x));
        });
      },
    );
  }
}

class _HabitEditor extends StatefulWidget {
  const _HabitEditor();
  @override
  State<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<_HabitEditor> {
  late List<HabitItem> items = [..._M.habits];

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PfCards(
            columns: 2,
            [
              for (var i = 0; i < items.length; i++)
                PfItem(
                  head: Row(children: [if (items[i].changed) const ChangeDot(), Expanded(child: EditCell(items[i].habit, changed: items[i].changed))]),
                  action: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.text2),
                    onPressed: () {
                      final x = items[i];
                      setState(() => items.removeAt(i));
                      showToast(context, 'Removed for ${c.first}', subtitle: x.title, kind: ToastKind.del, onUndo: () {
                        if (mounted) setState(() => items.insert(i, x));
                      });
                    },
                  ),
                  fields: [
                    ('Target', EditCell(items[i].target)),
                    ('How often', EditCell(items[i].often, select: true, onTap: () => pickOption(context, title: 'How often', options: const ['Every day', 'Every night', 'Weekdays', '3 times a week'], current: items[i].often))),
                    ('Starts', EditCell(items[i].starts)),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AddButton('Add habit', onTap: () => showToast(context, 'Opened the habit library', subtitle: 'Pick one to add for ${c.first}', kind: ToastKind.info)),
          ),
        ],
      ),
    );
  }
}
