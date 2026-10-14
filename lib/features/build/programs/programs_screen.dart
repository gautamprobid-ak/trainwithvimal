import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/programs.dart';

import 'programs_state.dart';
import 'widgets/build_widgets.dart';

/// Design: ProgramsMobile.dc.html — master plans list (Active / Archived),
/// card menu (Open, Duplicate, Archive / Restore, Delete), New program modal.
class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  bool _archivedTab = false;
  String _query = '';

  ProgramsNotifier get _store => ref.read(programsProvider.notifier);

  void _open(Program p) {
    ref.read(selectedProgramProvider.notifier).select(p.id);
    context.push(context.rolePath(Routes.programBuilder));
  }

  /// Applies a change and shows a toast whose Undo puts the list back.
  void _change(VoidCallback fn, String title, String subtitle, {ToastKind kind = ToastKind.ok}) {
    final prev = ref.read(programsProvider);
    fn();
    showToast(context, title, subtitle: subtitle, kind: kind, onUndo: () => _store.restore(prev));
  }

  void _menu(Program p) {
    showActionSheet(context, title: p.name, subtitle: p.goal, actions: [
      SheetAction('Open', Icons.open_in_new_rounded, () => _open(p)),
      SheetAction('Duplicate', Icons.copy_rounded, () => _change(() => _store.duplicate(p), 'Program duplicated', '${p.name} (copy)')),
      SheetAction(
        p.archived ? 'Restore' : 'Archive',
        p.archived ? Icons.unarchive_rounded : Icons.archive_rounded,
        () => _change(
          () => _store.put(p.copyWith(archived: !p.archived)),
          '${p.name} ${p.archived ? 'restored' : 'archived'}',
          'Assigned clients keep their plan',
        ),
      ),
      SheetAction('Delete', Icons.delete_outline_rounded, () => _delete(p), destructive: true),
    ]);
  }

  Future<void> _delete(Program p) async {
    final n = p.clients.length;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this program?',
      message: '${p.name} will be removed for good${n > 0 ? ' and unassigned from ${plural(n, 'client')}' : ''}. Workouts they already logged stay safe.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    _change(() => _store.remove(p.id), 'Program deleted', p.name, kind: ToastKind.del);
  }

  void _new() {
    showAppSheet<void>(
      context,
      title: 'New program',
      subtitle: 'A master plan you can assign to any client',
      builder: (ctx) => _NewProgramForm(
        onCreate: (name, weeks, days) {
          Navigator.of(ctx).pop();
          final p = _store.create(name: name, weeks: weeks, daysPerWeek: days);
          showToast(context, 'Program created', subtitle: '$name · $weeks weeks', kind: ToastKind.ok);
          _open(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(programsProvider);
    final nArch = all.where((p) => p.archived).length;
    final q = _query.trim().toLowerCase();
    final shown = all.where((p) => p.archived == _archivedTab && (q.isEmpty || p.name.toLowerCase().contains(q) || p.goal.toLowerCase().contains(q))).toList();

    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Programs',
          actions: [AppButton('New program', icon: Icons.add_rounded, small: true, onPressed: _new)],
        ),
        Text('Master plans for your clients. Change one and everyone following it gets the update.', style: AppText.secondary),
        SearchField(hint: 'Search programs', onChanged: (v) => setState(() => _query = v)),
        Align(
          alignment: Alignment.centerRight,
          child: MiniTabs(
            labels: const ['Active', 'Archived'],
            counts: [all.length - nArch, nArch],
            index: _archivedTab ? 1 : 0,
            onChanged: (i) => setState(() => _archivedTab = i == 1),
          ),
        ),
        for (final p in shown) _ProgramCard(program: p, onOpen: () => _open(p), onMenu: () => _menu(p)),
        if (shown.isEmpty) _EmptyCard(archived: _archivedTab, searching: q.isNotEmpty),
      ],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.onOpen, required this.onMenu});
  final Program program;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final p = program;
    final tone = programTones[(p.tone - 1) % 4];
    return AppCard(
      onTap: onOpen,
      color: p.archived ? const Color(0xFFFBFBF9) : AppColors.card,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tone.$1, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.fitness_center_rounded, size: 20, color: tone.$2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(p.goal, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMenu,
                tooltip: 'More actions',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppBadge('${p.weeks} weeks', tone: BadgeTone.info),
              AppBadge('${p.daysPerWeek} days / week'),
              if (p.archived) const AppBadge('Archived', tone: BadgeTone.warn),
            ],
          ),
          const SizedBox(height: 8),
          WeekStrip(p.pattern, muted: p.archived),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _Foot(program: p),
        ],
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.program});
  final Program program;

  @override
  Widget build(BuildContext context) {
    final cl = program.clients;
    final initials = [for (final n in cl) n.split(' ').map((w) => w[0]).take(2).join()];
    return Row(
      children: [
        if (cl.isNotEmpty) ...[
          AvatarStack(initials, max: 3),
          const SizedBox(width: 6),
          Flexible(
            child: Text(plural(cl.length, 'client'),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
          ),
        ] else ...[
          const Icon(Icons.person_off_outlined, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Flexible(child: Text('Not assigned', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
        const SizedBox(width: 8),
        const Spacer(),
        Flexible(
          flex: 2,
          child: Text('Edited ${program.edited}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: AppText.caption.copyWith(fontSize: 12.5)),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.archived, required this.searching});
  final bool archived;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: EmptyState(
        icon: archived ? Icons.archive_outlined : Icons.fitness_center_rounded,
        title: searching ? 'No program matches' : (archived ? 'Nothing archived' : 'No programs yet'),
        message: searching
            ? 'Try another name.'
            : archived
                ? 'Programs you archive are kept here and can be restored any time.'
                : 'Build your first master plan and assign it to clients.',
      ),
    );
  }
}

/// Body of the New program sheet: name, length, training days + week preview.
class _NewProgramForm extends StatefulWidget {
  const _NewProgramForm({required this.onCreate});
  final void Function(String name, int weeks, int days) onCreate;

  @override
  State<_NewProgramForm> createState() => _NewProgramFormState();
}

class _NewProgramFormState extends State<_NewProgramForm> {
  final _name = TextEditingController();
  int _weeks = 8;
  int _days = 4;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Give the program a name');
      return;
    }
    widget.onCreate(n, _weeks, _days);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Program name', required: true),
        TextField(
          controller: _name,
          autofocus: true,
          style: AppText.body,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _error == null ? null : setState(() => _error = null),
          decoration: InputDecoration(hintText: 'e.g. Strength Base', errorText: _error),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StepperField(
                label: 'Length',
                value: '$_weeks',
                unit: 'weeks',
                onMinus: () => setState(() => _weeks = (_weeks - 1).clamp(1, 24)),
                onPlus: () => setState(() => _weeks = (_weeks + 1).clamp(1, 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StepperField(
                label: 'Training days per week',
                value: '$_days',
                unit: 'days',
                onMinus: () => setState(() => _days = (_days - 1).clamp(1, 7)),
                onPlus: () => setState(() => _days = (_days + 1).clamp(1, 7)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeekStrip([for (var i = 0; i < 7; i++) i < _days], large: true),
        const HintText('The other days start as rest days. You can change every week later.', top: 8),
        SheetButtons(label: 'Create program', icon: Icons.check_rounded, onPressed: _create),
      ],
    );
  }
}
