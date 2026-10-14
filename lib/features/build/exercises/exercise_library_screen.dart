import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/programs_mock.dart';
import 'package:train_with_vimal/data/models/programs.dart';

import '../programs/programs_state.dart';
import '../programs/widgets/build_widgets.dart';
import 'exercise_detail_screen.dart';
import 'exercises_state.dart';

/// Number of programs that use an exercise ("2 programs", "No program yet").
String usedLabel(List<Program> programs, String name) {
  final n = programs.where((p) => p.days.any((d) => d.exercises.any((e) => e.name == name))).length;
  return n == 0 ? 'No program yet' : plural(n, 'program');
}

enum _Sort { az, za, level }

/// Filter categories (Muscle, Equipment, Level, Source).
const _cats = [
  ('muscle', 'Muscle', ProgramsMock.muscles),
  ('equipment', 'Equipment', ProgramsMock.equipment),
  ('level', 'Level', ProgramsMock.levels),
  ('source', 'Source', ProgramsMock.sources),
];

String _valueOf(Exercise e, String cat) => switch (cat) {
      'muscle' => e.muscle,
      'equipment' => e.equipment,
      'level' => e.level,
      _ => e.source,
    };

/// Design: ExerciseLibraryMobile.dc.html — search, Filter (chips), sort, 2-column grid.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  Map<String, List<String>> _picked = {
    'muscle': ['Chest'],
    'equipment': [],
    'level': [],
    'source': [],
  };
  String _q = '';
  _Sort _sort = _Sort.az;

  int get _filterCount => _picked.values.fold(0, (a, l) => a + l.length);

  void _clear() => setState(() => _picked = {for (final c in _cats) c.$1: <String>[]});

  void _openFilter(List<Exercise> all) {
    showAppSheet<void>(
      context,
      title: 'Filter',
      subtitle: 'Pick one or more in each group',
      builder: (ctx) => _FilterSheet(
        all: all,
        picked: _picked,
        onChanged: (m) => setState(() => _picked = m),
      ),
    );
  }

  void _openSort() {
    const labels = {_Sort.az: 'Name A–Z', _Sort.za: 'Name Z–A', _Sort.level: 'Level'};
    showActionSheet(context, title: 'Sort', actions: [
      for (final s in _Sort.values)
        SheetAction(labels[s]!, s == _sort ? Icons.check_rounded : Icons.sort_rounded, () => setState(() => _sort = s)),
    ]);
  }

  void _menu(Exercise e) {
    showActionSheet(context, title: e.name, subtitle: '${e.muscle} · ${e.equipment}', actions: [
      SheetAction('Open', Icons.open_in_new_rounded, () => context.push(context.rolePath(Routes.exercise(e.id)))),
      SheetAction('Duplicate to edit', Icons.copy_rounded, () => context.push(context.rolePath(Routes.exerciseNew))),
      SheetAction('Add to program', Icons.playlist_add_rounded, () => showAddToProgram(context, ref, e)),
      if (e.custom)
        SheetAction('Delete', Icons.delete_outline_rounded, () {
          final prev = ref.read(exercisesProvider);
          ref.read(exercisesProvider.notifier).remove(e.id);
          showToast(context, 'Exercise deleted', subtitle: e.name, kind: ToastKind.del, onUndo: () => ref.read(exercisesProvider.notifier).restore(prev));
        }, destructive: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(exercisesProvider);
    final programs = ref.watch(programsProvider);
    final q = _q.trim().toLowerCase();
    final items = all
        .where((e) => _picked.entries.every((m) => m.value.isEmpty || m.value.contains(_valueOf(e, m.key))))
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => switch (_sort) {
            _Sort.az => a.name.compareTo(b.name),
            _Sort.za => b.name.compareTo(a.name),
            _Sort.level => a.level.compareTo(b.level),
          });
    final builtIn = all.where((e) => !e.custom).length;
    final fc = _filterCount;
    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Exercise library',
          subtitle: '$builtIn built-in · ${all.length - builtIn} custom by your team',
          actions: [AppIconButton(Icons.add_rounded, filled: true, tooltip: 'New exercise', onPressed: () => context.push(context.rolePath(Routes.exerciseNew)))],
        ),
        SearchField(hint: 'Search exercises', onChanged: (v) => setState(() => _q = v)),
        Row(
          children: [
            fc > 0
                ? AppButton.soft('Filter · $fc', icon: Icons.filter_list_rounded, small: true, onPressed: () => _openFilter(all))
                : AppButton.outline('Filter', icon: Icons.filter_list_rounded, small: true, onPressed: () => _openFilter(all)),
            const SizedBox(width: 8),
            const Spacer(),
            Flexible(
              flex: 3,
              child: AppButton.outline(
              'Sort  ${switch (_sort) { _Sort.az => 'Name A–Z', _Sort.za => 'Name Z–A', _Sort.level => 'Level' }}',
              icon: Icons.unfold_more_rounded,
              small: true,
              onPressed: _openSort,
              ),
            ),
          ],
        ),
        if (fc > 0) _Chips(picked: _picked, onRemove: (c, v) => setState(() => _picked = {..._picked, c: _picked[c]!.where((x) => x != v).toList()}), onClear: _clear, shown: items.length, total: all.length),
        if (items.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No exercise matches',
              message: 'Change the filters or create a new exercise.',
              action: AppButton.outline('Clear filters', small: true, onPressed: _clear),
            ),
          )
        else
          _Grid(items: items, used: (e) => usedLabel(programs, e.name), onOpen: (e) => context.push(context.rolePath(Routes.exercise(e.id))), onMenu: _menu),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.picked, required this.onRemove, required this.onClear, required this.shown, required this.total});
  final Map<String, List<String>> picked;
  final void Function(String cat, String value) onRemove;
  final VoidCallback onClear;
  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in _cats)
              for (final v in picked[c.$1]!)
                Container(
                  height: 30,
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(children: [TextSpan(text: '${c.$2} '), TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text))]),
                        style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.text2),
                      ),
                      InkWell(
                        onTap: () => onRemove(c.$1, v),
                        customBorder: const CircleBorder(),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 14, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ),
            TextButton(onPressed: onClear, child: const Text('Clear all')),
          ],
        ),
        Padding(padding: const EdgeInsets.only(left: 2), child: Text('$shown of $total exercises', style: AppText.caption)),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.used, required this.onOpen, required this.onMenu});
  final List<Exercise> items;
  final String Function(Exercise) used;
  final ValueChanged<Exercise> onOpen;
  final ValueChanged<Exercise> onMenu;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ExerciseCard(e: items[i], used: used(items[i]), onOpen: onOpen, onMenu: onMenu)),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < items.length ? _ExerciseCard(e: items[i + 1], used: used(items[i + 1]), onOpen: onOpen, onMenu: onMenu) : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 10), rows[i]],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.e, required this.used, required this.onOpen, required this.onMenu});
  final Exercise e;
  final String used;
  final ValueChanged<Exercise> onOpen;
  final ValueChanged<Exercise> onMenu;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => onOpen(e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: MediaThumb(
              tone: e.tone,
              radius: 0,
              iconSize: 28,
              duration: e.hasVideo ? e.videoDur : null,
              label: e.hasVideo ? null : 'Image',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13, height: 1.3)),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: e.muscle, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text2)),
                      TextSpan(text: ' · ${e.equipment}'),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11.5),
                  ),
                  const Spacer(),
                  const SizedBox(height: 6),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: FittedBox(fit: BoxFit.scaleDown, child: AppBadge(e.level, tone: e.level == 'Beginner' ? BadgeTone.ok : BadgeTone.warn)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(flex: 4, child: Text(used, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5))),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'More actions',
                          onPressed: () => onMenu(e),
                          icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter sheet: category tabs on top, ticked options with counts under them.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.all, required this.picked, required this.onChanged});
  final List<Exercise> all;
  final Map<String, List<String>> picked;
  final ValueChanged<Map<String, List<String>>> onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int _cat = 0;
  late Map<String, List<String>> _p = widget.picked;

  void _set(Map<String, List<String>> m) {
    setState(() => _p = m);
    widget.onChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    final (key, _, opts) = _cats[_cat];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _cats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                ChoicePill(
                  _cats[i].$2,
                  selected: i == _cat,
                  count: _p[_cats[i].$1]!.isEmpty ? null : _p[_cats[i].$1]!.length,
                  onTap: () => setState(() => _cat = i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        JoinedList(children: [
          for (final o in opts)
            PickRow(
              selected: _p[key]!.contains(o),
              onTap: () {
                final cur = _p[key]!;
                _set({..._p, key: cur.contains(o) ? cur.where((x) => x != o).toList() : [...cur, o]});
              },
              child: Row(
                children: [
                  Expanded(child: Text(o, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w600))),
                  Text('${widget.all.where((e) => _valueOf(e, key) == o).length}', style: AppText.caption),
                ],
              ),
            ),
        ]),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton.outline('Clear filters', expand: true, onPressed: () => _set({for (final c in _cats) c.$1: <String>[]})),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Done', expand: true, onPressed: () => Navigator.of(context).pop())),
          ],
        ),
      ],
    );
  }
}
