import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/programs.dart';

import '../programs/programs_state.dart';
import '../programs/widgets/build_widgets.dart';
import '../programs/widgets/builder_sheets.dart';
import 'exercises_state.dart';

/// "Add to program": pick an active program, the exercise goes on its first
/// workout day with the exercise's default sets and reps.
void showAddToProgram(BuildContext context, WidgetRef ref, Exercise e) {
  final programs = ref.read(programsProvider).where((p) => !p.archived).toList();
  showAppSheet<void>(
    context,
    title: 'Add to program',
    subtitle: '${e.name} · ${e.sets} × ${e.reps}',
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in programs)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: TintIcon(Icons.fitness_center_rounded, tint: Tint.values[(p.tone - 1) % 4]),
            title: Text(p.name, style: AppText.bodyBold),
            subtitle: Text('${p.weeks} weeks · ${p.daysPerWeek} days / week', style: AppText.caption),
            trailing: const Icon(Icons.add_rounded, color: AppColors.accent),
            onTap: () {
              Navigator.of(ctx).pop();
              _addTo(context, ref, p, e);
            },
          ),
      ],
    ),
  );
}

void _addTo(BuildContext context, WidgetRef ref, Program p, Exercise e) {
  final i = p.days.indexWhere((d) => !d.rest && !d.exercises.any((x) => x.name == e.name));
  if (i < 0) {
    showToast(context, 'Already in ${p.name}', subtitle: 'Every workout day has ${e.name}', kind: ToastKind.info);
    return;
  }
  final store = ref.read(programsProvider.notifier);
  final day = p.days[i];
  store.put(p.copyWith(
    edited: 'just now',
    days: [
      for (var j = 0; j < p.days.length; j++)
        j == i ? day.copyWith(exercises: [...day.exercises, ProgramExercise(e.name, e.sets, e.reps, e.rest, rpe: e.rpe, tempo: e.tempo)]) : p.days[j],
    ],
  ));
  showToast(context, '${e.name} added', subtitle: '${p.name} · ${day.title}', kind: ToastKind.ok, onUndo: () => store.put(p));
}

/// Design: ExerciseDetailMobile.dc.html — default sets and reps, video, How to /
/// Form cues / Muscles tabs, details and the programs that use it.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  int _tab = 2; // Muscles

  void _more(Exercise e) {
    showMenuSheet(context, title: e.name, subtitle: '${e.muscle} · ${e.equipment}', items: [
      MenuItem('Edit', Icons.edit_outlined, () {
        showToast(context, 'Built-in exercises can’t be changed', subtitle: 'Duplicate it to make your own version', kind: ToastKind.info);
      }, enabled: true),
      MenuItem('Duplicate', Icons.copy_rounded, () => context.push(context.rolePath(Routes.exerciseNew))),
      MenuItem('Add to program', Icons.playlist_add_rounded, () => showAddToProgram(context, ref, e)),
      MenuItem('Delete', Icons.delete_outline_rounded, () => _delete(e), destructive: true, enabled: e.custom),
    ]);
  }

  Future<void> _delete(Exercise e) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this exercise?',
      message: '${e.name} will be removed from the library. Programs that use it keep their copy.',
      confirmLabel: 'Delete exercise',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    final prev = ref.read(exercisesProvider);
    ref.read(exercisesProvider.notifier).remove(e.id);
    showToast(context, 'Exercise deleted', subtitle: e.name, kind: ToastKind.del, onUndo: () => ref.read(exercisesProvider.notifier).restore(prev));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final e = ref.watch(exercisesProvider).byId(widget.exerciseId);
    if (e == null) {
      return const PageScroll(children: [
        SubPageHeader(title: 'Exercise'),
        AppCard(child: EmptyState(icon: Icons.fitness_center_rounded, title: 'Exercise not found', message: 'It may have been deleted.')),
      ]);
    }
    final programs = ref.watch(programsProvider).where((p) => p.days.any((d) => d.exercises.any((x) => x.name == e.name))).toList();
    return PageScroll(
      children: [
        SubPageHeader(
          title: e.name,
          subtitle: '${e.muscle} · ${e.equipment} · ${e.custom ? 'Custom' : 'Built-in'} exercise',
          actions: [AppIconButton(Icons.more_horiz_rounded, tooltip: 'More actions', onPressed: () => _more(e))],
        ),
        Row(
          children: [
            Expanded(
              child: AppButton.outline('Duplicate to edit', icon: Icons.copy_rounded, expand: true, onPressed: () => context.push(context.rolePath(Routes.exerciseNew))),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Add to program', icon: Icons.add_rounded, expand: true, onPressed: () => showAddToProgram(context, ref, e))),
          ],
        ),
        _DefaultsCard(e: e),
        _VideoCard(e: e),
        _TabsCard(e: e, tab: _tab, onTab: (i) => setState(() => _tab = i)),
        _DetailsCard(e: e),
        _UsedInCard(
          exercise: e,
          programs: programs,
          onOpen: (p) {
            ref.read(selectedProgramProvider.notifier).select(p.id);
            context.push(context.rolePath(Routes.programBuilder));
          },
        ),
      ],
    );
  }
}

class _DefaultsCard extends StatelessWidget {
  const _DefaultsCard({required this.e});
  final Exercise e;

  @override
  Widget build(BuildContext context) {
    final rest = e.rest >= 120 && e.rest % 60 == 0 ? ('${e.rest ~/ 60}', 'min') : ('${e.rest}', 's');
    final tiles = [
      ('Client logs', e.logType.label, ''),
      ('Sets', '${e.sets}', ''),
      (e.logType == LogType.weightReps ? 'Reps' : (e.logType == LogType.time ? 'Time' : 'Minutes'), e.reps, ''),
      ('Rest', rest.$1, rest.$2),
      ('RPE', e.rpe > 0 ? '${e.rpe}' : '–', e.rpe > 0 ? '/ 10' : ''),
      ('Tempo', e.tempo.isEmpty ? '–' : e.tempo, ''),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead('Default sets and reps', caption: 'Filled in when added to a program'),
          const SizedBox(height: 10),
          for (var r = 0; r < 2; r++)
            Container(
              decoration: BoxDecoration(border: r == 1 ? const Border(top: BorderSide(color: AppColors.line)) : null),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var c = 0; c < 3; c++) Expanded(child: _tile(tiles[r * 3 + c], c > 0))],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile((String, String, String) t, bool line) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(border: line ? const Border(left: BorderSide(color: AppColors.line)) : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.$1, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: t.$2),
                if (t.$3.isNotEmpty) TextSpan(text: ' ${t.$3}', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.e});
  final Exercise e;

  @override
  Widget build(BuildContext context) {
    final title = e.videoTitle ?? '${e.name} · demo · ${e.videoDur}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead('Video', caption: 'From content library'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => showToast(context, 'Video started', subtitle: title, kind: ToastKind.info),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(child: MediaThumb(tone: e.tone, radius: 12, iconSize: 34, duration: e.hasVideo ? e.videoDur : null)),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: Color(0xE6FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, size: 30, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          DetailField('Video', e.videoTitle != null ? '${e.videoTitle} · ${e.videoDur}' : title),
          const DetailField('Cover image', 'Frame at 0:12', last: true),
        ],
      ),
    );
  }
}

class _TabsCard extends StatelessWidget {
  const _TabsCard({required this.e, required this.tab, required this.onTab});
  final Exercise e;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MiniTabs(
            labels: const ['How to', 'Form cues', 'Muscles'],
            counts: [e.howTo.length, e.cues.length, 1 + e.also.length],
            index: tab,
            expand: true,
            onChanged: onTab,
          ),
          const SizedBox(height: 14),
          switch (tab) {
            0 => _Steps(items: e.howTo, numbered: true),
            1 => _Steps(items: e.cues, numbered: false),
            _ => _Muscles(e: e),
          },
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.items, required this.numbered});
  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text('Nothing added yet.', style: AppText.secondary);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                numbered
                    ? CountBubble(i + 1)
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.check_rounded, size: 14, color: AppColors.accentText),
                      ),
                const SizedBox(width: 10),
                Expanded(child: Text(items[i], style: AppText.body)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter(this.on, {this.big = false});
  final int on;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(left: 3),
            width: 16,
            height: 6,
            decoration: BoxDecoration(
              color: i < on ? AppColors.accent : (big ? const Color(0xFFC9D8FA) : AppColors.line),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _Muscles extends StatelessWidget {
  const _Muscles({required this.e});
  final Exercise e;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD5E1FB))),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.accessibility_new_rounded, size: 19, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRIMARY MUSCLE', style: AppText.overline.copyWith(fontSize: 10.5, color: AppColors.accentText)),
                    Text(e.muscle, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    Text('${e.primaryNote} · decides where this exercise shows in the library filter', style: AppText.caption),
                  ],
                ),
              ),
              const _Meter(3, big: true),
            ],
          ),
        ),
        if (e.also.isNotEmpty) ...[
          const SizedBox(height: 10),
          Overline('Also works', padding: const EdgeInsets.only(left: 2, bottom: 4)),
          for (final m in e.also)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                        if (m.note.isNotEmpty) Text(m.note, style: AppText.caption),
                      ],
                    ),
                  ),
                  _Meter(m.strong ? 2 : 1),
                  const SizedBox(width: 8),
                  SizedBox(width: 44, child: Text(m.strong ? 'Strong' : 'Light', style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.e});
  final Exercise e;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Details', style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          DetailField('Muscle group', e.muscle),
          DetailField('Equipment', e.equipment),
          DetailField('Level', e.level),
          DetailField('Source', e.source, last: true),
        ],
      ),
    );
  }
}

class _UsedInCard extends StatelessWidget {
  const _UsedInCard({required this.exercise, required this.programs, required this.onOpen});
  final Exercise exercise;
  final List<Program> programs;
  final ValueChanged<Program> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: Text(
              programs.isEmpty ? 'Not used in a program yet' : 'Used in ${plural(programs.length, 'program')}',
              style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
          ),
          for (final p in programs)
            NavRow(
              label: p.name,
              subtitle: '${p.days.firstWhere((d) => d.exercises.any((x) => x.name == exercise.name)).title} · '
                  '${p.weeks} workouts · ${plural(p.clients.length, 'client')}',
              onTap: () => onOpen(p),
            ),
          if (programs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text('Add it to a program and it shows here.', style: AppText.secondary),
            ),
        ],
      ),
    );
  }
}
