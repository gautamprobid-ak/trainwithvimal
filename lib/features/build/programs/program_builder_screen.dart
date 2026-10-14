import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/mock/programs_mock.dart';
import 'package:train_with_vimal/data/models/programs.dart';

import '../exercises/exercises_state.dart';
import 'programs_state.dart';
import 'widgets/build_widgets.dart';
import 'widgets/builder_sheets.dart';

/// Rough workout length in minutes (same formula as the design).
int workoutMinutes(List<ProgramExercise> xs) {
  final s = xs.fold<int>(0, (a, e) {
    final m = RegExp(r'^\d+').firstMatch(e.reps);
    final work = e.reps.contains('min') && m != null ? int.parse(m.group(0)!) * 60 : 40;
    return a + e.sets * (work + e.rest);
  });
  final r = (s / 300).round() * 5;
  return r < 5 ? 5 : r;
}

String daySummary(ProgramDay d) {
  if (d.rest) return d.note.isNotEmpty ? d.note : 'Rest day';
  if (d.exercises.isEmpty) return 'No exercises yet';
  return '${plural(d.exercises.length, 'exercise')} · ${workoutMinutes(d.exercises)} min';
}

/// Row tags: running numbers, supersets as A1, A2 ...
List<String> exerciseTags(List<ProgramExercise> xs) {
  var n = 0;
  return [
    for (var i = 0; i < xs.length; i++)
      if (xs[i].group.isEmpty)
        '${++n}'
      else
        '${xs[i].group}${xs.take(i).where((o) => o.group == xs[i].group).length + 1}',
  ];
}

/// Drops superset letters that are left with a single exercise.
List<ProgramExercise> cleanSupersets(List<ProgramExercise> xs) => [
      for (final e in xs)
        e.group.isNotEmpty && xs.where((o) => o.group == e.group).length < 2 ? e.copyWith(group: '') : e,
    ];

List<T> swapped<T>(List<T> xs, int a, int b) {
  if (b < 0 || b >= xs.length) return xs;
  final c = [...xs];
  final t = c[a];
  c[a] = c[b];
  c[b] = t;
  return c;
}

/// Design: ProgramBuilderMobile.dc.html — weeks, days, exercises with sets × reps,
/// exercise picker from the library, assign to clients.
class ProgramBuilderScreen extends ConsumerStatefulWidget {
  const ProgramBuilderScreen({super.key});

  @override
  ConsumerState<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  int _week = 1;
  int _sel = 1;

  ProgramsNotifier get _store => ref.read(programsProvider.notifier);

  Program? get _program => _store.byId(ref.read(selectedProgramProvider));

  // ---- state helpers -------------------------------------------------------

  /// Saves [next]; when [title] is given shows a toast, with Undo when [undo] is true.
  void _commit(Program next, {String? title, String? subtitle, bool undo = true, int? sel}) {
    final prev = _program;
    _store.put(next.copyWith(edited: 'just now'));
    if (sel != null) setState(() => _sel = sel);
    if (title == null) return;
    showToast(
      context,
      title,
      subtitle: subtitle == null || subtitle.isEmpty ? null : subtitle,
      kind: ToastKind.ok,
      onUndo: undo && prev != null
          ? () {
              _store.put(prev);
              if (sel != null) setState(() => _sel = _sel.clamp(0, prev.days.length - 1));
            }
          : null,
    );
  }

  void _updDay(Program p, int i, ProgramDay Function(ProgramDay) fn, {String? title, String? subtitle, bool undo = true}) {
    _commit(p.copyWith(days: [for (var j = 0; j < p.days.length; j++) j == i ? fn(p.days[j]) : p.days[j]]), title: title, subtitle: subtitle, undo: undo);
  }

  void _updEx(Program p, List<ProgramExercise> Function(List<ProgramExercise>) fn, {String? title, String? subtitle}) =>
      _updDay(p, _selOf(p), (d) => d.copyWith(exercises: fn(d.exercises)), title: title, subtitle: subtitle);

  int _selOf(Program p) => _sel.clamp(0, p.days.length - 1);

  String _dayHead(int i) => 'Week $_week · ${weekdayLong[i]}';

  // ---- program actions ------------------------------------------------------

  void _programMenu(Program p) {
    showMenuSheet(context, title: 'Program options', subtitle: p.name, items: [
      MenuItem('Rename', Icons.edit_outlined, () => _rename(p)),
      MenuItem('Duplicate program', Icons.copy_rounded, () {
        final c = _store.duplicate(p);
        ref.read(selectedProgramProvider.notifier).select(c.id);
        showToast(context, 'Program duplicated', subtitle: 'Now editing ${c.name}', kind: ToastKind.ok);
      }),
      MenuItem(p.archived ? 'Restore' : 'Archive', p.archived ? Icons.unarchive_rounded : Icons.archive_rounded, () => _toggleArchive(p)),
      MenuItem('Delete', Icons.delete_outline_rounded, () => _delete(p), destructive: true),
    ]);
  }

  void _toggleArchive(Program p) =>
      _commit(p.copyWith(archived: !p.archived), title: p.archived ? 'Program restored' : 'Program archived', subtitle: 'Assigned clients keep their plan');

  void _rename(Program p) {
    showAppSheet<void>(
      context,
      title: 'Rename program',
      subtitle: 'Clients see the new name in their app',
      builder: (ctx) => NameForm(
        label: 'Program name',
        initial: p.name,
        button: 'Save',
        onSave: (v) {
          Navigator.of(ctx).pop();
          _commit(p.copyWith(name: v), title: 'Program renamed', undo: false);
        },
      ),
    );
  }

  Future<void> _delete(Program p) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this program?',
      message: '${p.name} will be removed for good and unassigned from ${plural(p.clients.length, 'client')}. Workouts they already logged stay safe.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    final prev = ref.read(programsProvider);
    _store.remove(p.id);
    showToast(context, 'Program deleted', subtitle: p.name, kind: ToastKind.del, onUndo: () => _store.restore(prev));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(context.rolePath(Routes.programs));
    }
  }

  String? _otherProgram(Program p, String client) {
    for (final o in ref.read(programsProvider)) {
      if (o.id != p.id && o.clients.contains(client)) return 'On ${o.shortName ?? o.name}';
    }
    return null;
  }

  void _assign(Program p) {
    showAppSheet<void>(
      context,
      title: 'Assign to clients',
      subtitle: '${p.name} · ${p.weeks} weeks',
      builder: (ctx) => AssignForm(
        assigned: p.clients,
        otherProgramOf: (c) => _otherProgram(p, c),
        onSave: (sel) {
          Navigator.of(ctx).pop();
          final added = sel.where((x) => !p.clients.contains(x)).length;
          final removed = p.clients.where((x) => !sel.contains(x)).length;
          _commit(
            p.copyWith(clients: sel),
            title: sel.isEmpty ? 'Program unassigned' : 'Assigned to ${plural(sel.length, 'client')}',
            subtitle: '$added added · $removed removed',
          );
        },
      ),
    );
  }

  void _assignedClients(Program p) {
    final list = ProgramsMock.clients.where((c) => p.clients.contains(c.name)).toList();
    final sub = '${p.clients.length} ${p.clients.length == 1 ? 'follows' : 'follow'} ${p.name}';
    showAppSheet<void>(
      context,
      title: 'Assigned clients',
      subtitle: sub,
      builder: (ctx) => AssignedList(
        clients: list,
        onOpen: (c) {
          Navigator.of(ctx).pop();
          context.push(Routes.clientProfile(context, _clientId(c.name)));
        },
        onChange: () {
          Navigator.of(ctx).pop();
          _assign(p);
        },
      ),
    );
  }

  String _clientId(String name) {
    for (final c in PeopleMock.clients) {
      if (c.name == name) return c.id;
    }
    return name.split(' ').first.toLowerCase();
  }

  void _copyWeek(Program p) {
    if (_week == p.weeks) {
      _commit(p.copyWith(weeks: p.weeks + 1), title: 'Week ${p.weeks + 1} added', subtitle: '${p.days.length} days · all exercises and notes');
    } else {
      showToast(context, 'Week $_week copied to week ${_week + 1}', subtitle: '${p.days.length} days · all exercises and notes', kind: ToastKind.ok);
    }
  }

  // ---- day actions ----------------------------------------------------------

  void _dayMenu(Program p) {
    final i = _selOf(p);
    final d = p.days[i];
    showMenuSheet(context, title: _dayHead(i), subtitle: d.title, items: [
      MenuItem('Rename', Icons.edit_outlined, () => _renameDay(p)),
      MenuItem('Move earlier', Icons.arrow_upward_rounded, () => _commit(p.copyWith(days: swapped(p.days, i, i - 1)), sel: i - 1),
          subtitle: i > 0 ? 'Swap with ${weekdayLong[i - 1]}' : 'Already the first day', enabled: i > 0),
      MenuItem('Move later', Icons.arrow_downward_rounded, () => _commit(p.copyWith(days: swapped(p.days, i, i + 1)), sel: i + 1),
          subtitle: i < p.days.length - 1 ? 'Swap with ${weekdayLong[i + 1]}' : 'Already the last day', enabled: i < p.days.length - 1),
      MenuItem(d.rest ? 'Make workout day' : 'Make rest day', d.rest ? Icons.fitness_center_rounded : Icons.bedtime_outlined, () => _toggleRest(p)),
      MenuItem('Remove day', Icons.delete_outline_rounded, () {
        _commit(
          p.copyWith(days: [...p.days]..removeAt(i)),
          title: '${d.title} removed',
          subtitle: 'Later days of the week moved up',
          sel: (i - 1).clamp(0, 6),
        );
      }, destructive: true, enabled: p.days.length > 1),
    ]);
  }

  void _toggleRest(Program p) {
    final i = _selOf(p);
    final d = p.days[i];
    _updDay(
      p,
      i,
      (d) => d.copyWith(rest: !d.rest, title: d.rest && d.title == 'Rest' ? 'Workout' : d.title),
      title: d.rest ? 'Changed to a workout day' : '${d.title} is now a rest day',
      subtitle: d.rest ? null : 'Its exercises are kept if you change it back',
    );
  }

  void _renameDay(Program p) {
    final i = _selOf(p);
    showAppSheet<void>(
      context,
      title: 'Rename day',
      subtitle: _dayHead(i),
      builder: (ctx) => NameForm(
        label: 'Workout name',
        initial: p.days[i].title,
        button: 'Save',
        onSave: (v) {
          Navigator.of(ctx).pop();
          _updDay(p, i, (d) => d.copyWith(title: v), title: 'Day renamed', undo: false);
        },
      ),
    );
  }

  void _addDay(Program p) {
    showAppSheet<void>(
      context,
      title: 'Add day',
      subtitle: 'Week $_week',
      builder: (ctx) => NameForm(
        label: 'Workout name',
        initial: 'Upper B',
        hint: 'e.g. Upper B',
        button: 'Add day',
        onSave: (v) {
          Navigator.of(ctx).pop();
          final n = p.days.length;
          _commit(
            p.copyWith(days: [...p.days, ProgramDay(id: 'n${DateTime.now().microsecondsSinceEpoch}', title: v)]),
            title: '$v added',
            subtitle: weekdayLong[n],
            undo: false,
            sel: n,
          );
        },
      ),
    );
  }

  // ---- exercise actions -----------------------------------------------------

  void _openPicker(Program p, int dayIndex) {
    setState(() => _sel = dayIndex);
    final d = p.days[dayIndex];
    showAppSheet<void>(
      context,
      title: 'Add exercises',
      subtitle: '${_dayHead(dayIndex)} · ${d.title}',
      builder: (ctx) => ExercisePicker(
        library: ref.read(exercisesProvider),
        onDay: [for (final e in d.exercises) e.name],
        onAdd: (picked) {
          Navigator.of(ctx).pop();
          final cur = _program!;
          _updEx(
            cur,
            (xs) => [
              ...xs,
              for (final e in picked)
                e.muscle == 'Cardio' ? ProgramExercise(e.name, 1, '20 min', 0) : ProgramExercise(e.name, e.sets, e.reps, e.rest, rpe: e.rpe, tempo: e.tempo),
            ],
            title: picked.length > 1 ? '${picked.length} exercises added' : '${picked.first.name} added',
            subtitle: 'Default sets and reps from the exercise · tap a row to change them',
          );
        },
      ),
    );
  }

  void _editPrescription(Program p, int i) {
    final e = p.days[_selOf(p)].exercises[i];
    showAppSheet<void>(
      context,
      title: e.shownName,
      subtitle: 'Sets, reps and rest for this day',
      builder: (ctx) => PrescriptionForm(
        exercise: e,
        onSave: (next) {
          Navigator.of(ctx).pop();
          _updEx(_program!, (xs) => [for (var j = 0; j < xs.length; j++) j == i ? next : xs[j]],
              title: '${e.name} updated', subtitle: '${next.sets} × ${next.reps} · Rest ${restLabel(next.rest)}');
        },
      ),
    );
  }

  void _customize(Program p, int i) {
    final e = p.days[_selOf(p)].exercises[i];
    void reset() => _updEx(_program!, (xs) => [for (var j = 0; j < xs.length; j++) j == i ? xs[j].copyWith(clearCustom: true) : xs[j]],
        title: '${e.name} reset to the library version', subtitle: 'Library changes reach it again');
    showAppSheet<void>(
      context,
      title: 'Edit for this program',
      subtitle: '${e.name} · ${_dayHead(_selOf(p))}',
      builder: (ctx) => CustomizeForm(
        exercise: e,
        library: ref.read(exercisesProvider).byName(e.name),
        programName: p.name,
        onReset: () {
          Navigator.of(ctx).pop();
          reset();
        },
        onSave: (o) {
          Navigator.of(ctx).pop();
          _updEx(_program!, (xs) => [for (var j = 0; j < xs.length; j++) j == i ? xs[j].copyWith(custom: o) : xs[j]],
              title: '${o.name} edited for this program', subtitle: 'The library and other programs stay the same');
        },
      ),
    );
  }

  void _exerciseMenu(Program p, int i) {
    final day = p.days[_selOf(p)];
    final xs = day.exercises;
    final e = xs[i];
    final next = i + 1 < xs.length ? xs[i + 1] : null;
    showMenuSheet(context, title: e.shownName, subtitle: '${e.sets} × ${e.reps} · Rest ${restLabel(e.rest)}', items: [
      MenuItem('Edit sets and rest', Icons.tune_rounded, () => _editPrescription(p, i)),
      MenuItem('Edit for this program', Icons.edit_note_rounded, () => _customize(p, i)),
      if (e.custom != null)
        MenuItem('Reset to library version', Icons.restart_alt_rounded, () {
          _updEx(p, (xs) => [for (var j = 0; j < xs.length; j++) j == i ? xs[j].copyWith(clearCustom: true) : xs[j]],
              title: '${e.shownName} reset to the library version', subtitle: 'Library changes reach it again');
        }),
      MenuItem('Exercise details', Icons.info_outline_rounded, () {
        final lib = ref.read(exercisesProvider).byName(e.name);
        if (lib != null) context.push(context.rolePath(Routes.exercise(lib.id)));
      }),
      MenuItem('Move up', Icons.arrow_upward_rounded, () => _updEx(p, (xs) => swapped(xs, i, i - 1)), enabled: i > 0),
      MenuItem('Move down', Icons.arrow_downward_rounded, () => _updEx(p, (xs) => swapped(xs, i, i + 1)), enabled: next != null),
      if (e.group.isEmpty && next != null)
        MenuItem('Make superset with next', Icons.link_rounded, () => _superset(p, i)),
      if (e.group.isNotEmpty) MenuItem('Remove from superset', Icons.link_off_rounded, () => _superset(p, i)),
      MenuItem('Remove', Icons.delete_outline_rounded, () {
        _updEx(p, (xs) => cleanSupersets([...xs]..removeAt(i)), title: '${e.name} removed', subtitle: day.title);
      }, destructive: true),
    ]);
  }

  void _superset(Program p, int i) {
    final xs = p.days[_selOf(p)].exercises;
    final e = xs[i];
    if (e.group.isNotEmpty) {
      _updEx(p, (xs) => cleanSupersets([for (var j = 0; j < xs.length; j++) j == i ? xs[j].copyWith(group: '') : xs[j]]));
      return;
    }
    final next = xs[i + 1];
    final used = xs.map((o) => o.group).toSet();
    final letter = 'ABCDEFGH'.split('').firstWhere((c) => !used.contains(c), orElse: () => 'A');
    final g = next.group.isNotEmpty ? next.group : letter;
    _updEx(p, (xs) => [
          for (var j = 0; j < xs.length; j++)
            j == i || j == i + 1 || (next.group.isNotEmpty && xs[j].group == next.group) ? xs[j].copyWith(group: g) : xs[j],
        ]);
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(selectedProgramProvider);
    final programs = ref.watch(programsProvider);
    final p = programs.where((x) => x.id == id).firstOrNull;
    if (p == null) {
      return const PageScroll(children: [
        SubPageHeader(title: 'Master plan'),
        AppCard(child: EmptyState(icon: Icons.fitness_center_rounded, title: 'Program not found', message: 'It may have been deleted.')),
      ]);
    }
    final week = _week.clamp(1, p.weeks);
    final sel = _selOf(p);
    final n = p.clients.length;
    return PageScroll(
      children: [
        SubPageHeader(
          title: p.name,
          subtitle: '${p.weeks} weeks · ${p.daysPerWeek} days / week · edited ${p.edited}',
          actions: [AppIconButton(Icons.more_horiz_rounded, tooltip: 'Program options', onPressed: () => _programMenu(p))],
        ),
        Row(
          children: [
            Expanded(
              child: AppButton.outline(n > 0 ? plural(n, 'client') : 'No clients yet',
                  icon: Icons.group_outlined, expand: true, onPressed: () => _assignedClients(p)),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Assign', icon: Icons.person_add_alt_rounded, expand: true, onPressed: () => _assign(p))),
          ],
        ),
        if (p.archived) _ArchivedBanner(onRestore: () => _toggleArchive(p)),
        _WeekCard(
          program: p,
          week: week,
          selected: sel,
          onWeek: (w) => setState(() => _week = w),
          onCopy: () => _copyWeek(p),
          onDay: (i) => setState(() => _sel = i),
          onAdd: (i) => _openPicker(p, i),
          onAddDay: () => _addDay(p),
        ),
        _DayPanel(
          key: ValueKey('${p.id}-${p.days[sel].id}'),
          day: p.days[sel],
          head: _dayHead(sel),
          library: ref.watch(exercisesProvider),
          onMenu: () => _dayMenu(p),
          onAdd: () => _openPicker(p, sel),
          onMakeWorkout: () => _toggleRest(p),
          onEdit: (i) => _editPrescription(p, i),
          onExMenu: (i) => _exerciseMenu(p, i),
          onNote: (v) => _updDay(_program!, sel, (d) => d.copyWith(note: v)),
        ),
      ],
    );
  }
}

class _ArchivedBanner extends StatelessWidget {
  const _ArchivedBanner({required this.onRestore});
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          const AppBadge('Archived', tone: BadgeTone.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Hidden from the programs list. You can still edit it.',
                style: AppText.secondary.copyWith(color: AppColors.warnText, fontWeight: FontWeight.w600)),
          ),
          AppButton.outline('Restore', small: true, onPressed: onRestore),
        ],
      ),
    );
  }
}

/// Week pills + copy week + the seven day rows.
class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.program,
    required this.week,
    required this.selected,
    required this.onWeek,
    required this.onCopy,
    required this.onDay,
    required this.onAdd,
    required this.onAddDay,
  });
  final Program program;
  final int week;
  final int selected;
  final ValueChanged<int> onWeek;
  final VoidCallback onCopy;
  final ValueChanged<int> onDay;
  final ValueChanged<int> onAdd;
  final VoidCallback onAddDay;

  @override
  Widget build(BuildContext context) {
    final p = program;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var w = 1; w <= p.weeks; w++) ...[
                  if (w > 1) const SizedBox(width: 6),
                  _WeekPill(label: 'W$w', on: w == week, onTap: () => onWeek(w)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton.outline(
              week == p.weeks ? 'Copy week $week → new week' : 'Copy week $week → ${week + 1}',
              icon: Icons.copy_rounded,
              small: true,
              onPressed: onCopy,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < 7; i++)
            if (i < p.days.length)
              _DayRow(
                weekday: weekdayShort[i].toUpperCase(),
                day: p.days[i],
                on: i == selected,
                onTap: () => onDay(i),
                onAdd: () => onAdd(i),
              )
            else if (i == p.days.length)
              _SlotRow(weekday: weekdayShort[i].toUpperCase(), onTap: onAddDay),
        ],
      ),
    );
  }
}

class _WeekPill extends StatelessWidget {
  const _WeekPill({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.text : AppColors.sub,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Text(label, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.text2)),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.weekday, required this.day, required this.on, required this.onTap, required this.onAdd});
  final String weekday;
  final ProgramDay day;
  final bool on;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final rest = day.rest;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 38, child: Text(weekday, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .9))),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: on ? const Color(0xFFF5F8FF) : (rest ? const Color(0xFFFAFAF8) : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: on ? AppColors.accent : (rest ? AppColors.line : AppColors.line2), width: on ? 1.5 : 1),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold),
                            const SizedBox(height: 1),
                            Text(daySummary(day), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                            if (!rest && day.exercises.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              for (final e in day.exercises.take(3))
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(e.shownName,
                                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5, color: AppColors.text2)),
                                    ),
                                    Text('${e.sets}×${e.reps}', style: AppText.caption.copyWith(fontSize: 11.5, fontStyle: FontStyle.normal)),
                                  ],
                                ),
                              if (day.exercises.length > 3)
                                Text('+${day.exercises.length - 3} more',
                                    style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentText)),
                            ],
                          ],
                        ),
                      ),
                      if (rest) const Icon(Icons.bedtime_outlined, size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 62,
            child: rest
                ? null
                : TextButton.icon(
                    onPressed: onAdd,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 32)),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentText)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.weekday, required this.onTap});
  final String weekday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 38, child: Text(weekday, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .9))),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line2, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 17, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text('Day', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selected day: header, exercise rows (or rest box) and coach note.
class _DayPanel extends StatelessWidget {
  const _DayPanel({
    super.key,
    required this.day,
    required this.head,
    required this.library,
    required this.onMenu,
    required this.onAdd,
    required this.onMakeWorkout,
    required this.onEdit,
    required this.onExMenu,
    required this.onNote,
  });
  final ProgramDay day;
  final String head;
  final List<Exercise> library;
  final VoidCallback onMenu;
  final VoidCallback onAdd;
  final VoidCallback onMakeWorkout;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onExMenu;
  final ValueChanged<String> onNote;

  @override
  Widget build(BuildContext context) {
    final xs = day.exercises;
    final sets = xs.fold<int>(0, (a, e) => a + e.sets);
    final sum = day.rest
        ? 'Rest day'
        : xs.isEmpty
            ? 'No exercises yet'
            : '≈ ${workoutMinutes(xs)} min · $sets sets · ${plural(xs.length, 'exercise')}';
    final tags = exerciseTags(xs);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(head.toUpperCase(), style: AppText.overline.copyWith(fontSize: 11, letterSpacing: .9)),
                          const SizedBox(height: 2),
                          Text(day.title, style: AppText.sectionTitle.copyWith(fontSize: 18)),
                          Text(sum, style: AppText.secondary),
                        ],
                      ),
                    ),
                    AppIconButton(Icons.more_horiz_rounded, tooltip: 'Day options', onPressed: onMenu),
                  ],
                ),
                if (!day.rest) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppButton.outline('Add exercise', icon: Icons.add_rounded, expand: true, onPressed: onAdd),
                  ),
                ],
              ],
            ),
          ),
          if (!day.rest)
            if (xs.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                child: Text('No exercises yet. Add one from the exercise library.', style: AppText.secondary, textAlign: TextAlign.center),
              )
            else
              for (var i = 0; i < xs.length; i++)
                _ExerciseRow(
                  exercise: xs[i],
                  tag: tags[i],
                  works: library.where((e) => e.name == xs[i].name).firstOrNull?.works ?? '',
                  ssStart: xs[i].group.isNotEmpty && (i == 0 || xs[i - 1].group != xs[i].group),
                  onTap: () => onEdit(i),
                  onMenu: () => onExMenu(i),
                ),
          if (day.rest) _RestBox(onMakeWorkout: onMakeWorkout),
          _NoteField(initial: day.note, rest: day.rest, onChanged: onNote, border: !day.rest),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.tag, required this.works, required this.ssStart, required this.onTap, required this.onMenu});
  final ProgramExercise exercise;
  final String tag;
  final String works;
  final bool ssStart;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final ss = e.group.isNotEmpty;
    final cu = e.custom;
    final mus = works + (cu != null && cu.name != e.name ? ' · library: ${e.name}' : '');
    return Material(
      color: ss ? const Color(0xFFFBF9FF) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ss && !ssStart ? Colors.transparent : AppColors.line),
              left: BorderSide(color: ss ? const Color(0xFFA78BFA) : Colors.transparent, width: 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(11, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tag(tag, superset: ss),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(e.shownName, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                            if (cu != null) const FittedBox(fit: BoxFit.scaleDown, child: AppBadge('Edited for this program', tone: BadgeTone.warn)),
                          ],
                        ),
                        if (mus.isNotEmpty) Text(mus, style: AppText.caption),
                        if (e.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.chat_bubble_outline_rounded, size: 13, color: AppColors.muted)),
                              const SizedBox(width: 5),
                              Expanded(child: Text(e.note, style: AppText.caption.copyWith(color: AppColors.text2))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Exercise options',
                      onPressed: onMenu,
                      icon: const Icon(Icons.more_horiz_rounded, size: 19, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 34, right: 6),
                child: Row(
                  children: [
                    _Cell('Sets', '${e.sets}', flex: 8, bold: true, white: ss),
                    _Cell('Reps', e.reps, flex: 13, bold: true, white: ss),
                    _Cell('RPE', e.rpe > 0 ? '${e.rpe}' : '–', flex: 8, white: ss),
                    _Cell('Tempo', e.tempo.isEmpty ? '–' : e.tempo, flex: 10, white: ss),
                    _Cell('Rest', restLabel(e.rest), flex: 12, white: ss, last: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.superset});
  final String text;
  final bool superset;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: superset ? const Color(0xFFF1EAFE) : AppColors.sub, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: superset ? const Color(0xFF5B21B6) : AppColors.text2)),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {required this.flex, this.bold = false, this.white = false, this.last = false});
  final String label;
  final String value;
  final int flex;
  final bool bold;
  final bool white;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.only(right: last ? 0 : 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: white ? Colors.white : AppColors.sub, borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600)),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _RestBox extends StatelessWidget {
  const _RestBox({required this.onMakeWorkout});
  final VoidCallback onMakeWorkout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bedtime_outlined, size: 22, color: AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rest day', style: AppText.bodyBold),
                    const SizedBox(height: 2),
                    Text('Clients see no workout on this day. Use the note below for steps, mobility or a check-in reminder.',
                        style: AppText.secondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton.outline('Make workout day', icon: Icons.fitness_center_rounded, expand: true, onPressed: onMakeWorkout),
        ],
      ),
    );
  }
}

/// "Coach note for the client" — saved as you type.
class _NoteField extends StatefulWidget {
  const _NoteField({required this.initial, required this.rest, required this.onChanged, required this.border});
  final String initial;
  final bool rest;
  final ValueChanged<String> onChanged;
  final bool border;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(border: widget.border ? const Border(top: BorderSide(color: AppColors.line)) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Coach note for the client'),
          TextField(
            controller: _c,
            minLines: 2,
            maxLines: 4,
            style: AppText.body,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.rest ? 'e.g. 8k steps and 10 minutes of mobility' : 'e.g. Slow on the way down, pause at the bottom',
            ),
          ),
          const HintText('Saved as you type. Clients see it on this day.'),
        ],
      ),
    );
  }
}
