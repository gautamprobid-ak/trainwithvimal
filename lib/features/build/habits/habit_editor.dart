import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import '../nutrition/library_widgets.dart';
import 'habits_state.dart';

/// "Edit habit" sheet: settings, live client preview, assigned clients.
void showHabitEditor(BuildContext context, String habitId) {
  showAppSheet(context, title: 'Edit habit', builder: (ctx) => _HabitEditor(habitId: habitId, hostContext: context));
}

class _HabitEditor extends ConsumerStatefulWidget {
  const _HabitEditor({required this.habitId, required this.hostContext});
  final String habitId;
  final BuildContext hostContext;

  @override
  ConsumerState<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<_HabitEditor> {
  late String _id = widget.habitId;

  /// List before the first unsaved change (for Discard).
  List<Habit>? _snap;
  int _pv = 0;
  late final _name = TextEditingController();
  late final _unit = TextEditingController();
  late final _why = TextEditingController();

  late final HabitsController _ctl = ref.read(habitsProvider.notifier);

  @override
  void initState() {
    super.initState();
    _ctl;
    _syncText();
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _why.dispose();
    super.dispose();
  }

  Habit? _find(List<Habit> l) => l.where((h) => h.id == _id).firstOrNull;

  void _syncText() {
    final h = _find(ref.read(habitsProvider));
    if (h == null) return;
    _name.text = h.name;
    _unit.text = h.unit;
    _why.text = h.why;
  }

  void _set(Habit Function(Habit) fn, {bool resetPreview = false}) {
    _snap ??= ref.read(habitsProvider);
    _ctl.update(_id, fn);
    if (resetPreview) setState(() => _pv = 0);
  }

  void _save(Habit h) {
    setState(() => _snap = null);
    showToast(widget.hostContext, 'Changes saved',
        subtitle: h.clients.isNotEmpty ? 'Sent to ${plural(h.clients.length, 'client')} on this habit' : 'Not assigned to anyone yet', kind: ToastKind.ok);
  }

  void _discard() {
    final s = _snap;
    if (s == null) return;
    _ctl.restore(s);
    setState(() {
      _snap = null;
      _pv = 0;
    });
    _syncText();
    showToast(widget.hostContext, 'Changes discarded');
  }

  void _menu(Habit h) {
    showActionSheet(context, title: h.name, actions: [
      SheetAction('Duplicate habit', Icons.copy_rounded, () {
        final before = ref.read(habitsProvider);
        final copy = h.copyWith(id: '${h.id}c${before.length}', name: '${h.name} (copy)', clients: const []);
        _ctl.add(copy);
        setState(() {
          _id = copy.id;
          _snap = null;
          _pv = 0;
        });
        _syncText();
        showToast(widget.hostContext, 'Habit duplicated', subtitle: 'Same settings, no clients', kind: ToastKind.ok, onUndo: () => _ctl.restore(before));
      }),
      SheetAction('Delete habit', Icons.delete_outline_rounded, () async {
        final n = h.clients.length;
        final ok = await showConfirmDialog(
          context,
          title: 'Delete this habit?',
          message: '${h.name} is removed${n > 0 ? ' from ${plural(n, 'client')}' : ''}. Their past logs stay.',
          confirmLabel: 'Delete',
          destructive: true,
          icon: Icons.delete_outline_rounded,
        );
        if (!ok || !mounted || !widget.hostContext.mounted) return;
        final List<Habit> before = _snap ?? ref.read(habitsProvider);
        final ctl = _ctl;
        final host = widget.hostContext;
        Navigator.of(context).pop();
        ctl.remove(h.id);
        showToast(host, 'Habit deleted', subtitle: h.name, kind: ToastKind.del, onUndo: () => ctl.restore(before));
      }, destructive: true),
    ]);
  }

  void _assign(Habit h) {
    showAssignClients(context, subtitle: h.name, current: h.clients, onSave: (sel) {
      _set((x) => x.copyWith(clients: sel));
      showToast(widget.hostContext, 'Habit assigned', subtitle: plural(sel.length, 'client'), kind: ToastKind.ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = _find(ref.watch(habitsProvider));
    if (h == null) return const SizedBox.shrink();
    final n = h.clients.length;
    return Spaced(
      gap: 12,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child: Row(children: [
                HabitIconBox(habitIcon(h.icon), tone: habitTone(h.icon), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.name, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('${kindLabel(h)} · ${freqLabel(h)} · ${n > 0 ? plural(n, 'client') : 'not assigned'}', style: AppText.caption),
                  ]),
                ),
                AppIconButton(Icons.more_horiz_rounded, tooltip: 'Habit options', onPressed: () => _menu(h)),
              ]),
            ),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(14), child: _fields(h)),
            SaveBar(dirty: _snap != null, onDiscard: _discard, onSave: () => _save(h)),
          ]),
        ),
        _Preview(habit: h, value: _pv, onLog: (inc) => setState(() => _pv += inc), onReset: () => setState(() => _pv = 0)),
        AssignedCard(
          clients: h.clients,
          line: 'Sees it on Today',
          empty: 'Not assigned yet. Assign it to clients to show it on their Today screen.',
          onAssign: () => _assign(h),
          onOpen: (name) {
            Navigator.of(context).pop();
            openClientByName(widget.hostContext, name);
          },
        ),
      ],
    );
  }

  Widget _fields(Habit h) {
    final step = h.target >= 1000 ? 1000 : (h.target >= 100 ? 25 : (h.target >= 20 ? 5 : 1));
    return Spaced(gap: 16, children: [
      FieldBlock(label: 'Habit name', child: PlainInput(controller: _name, onChanged: (v) => _set((x) => x.copyWith(name: v)))),
      FieldBlock(
        label: 'Type',
        child: Column(children: [
          for (final (k, t, s) in const [(HabitKind.tick, 'Tick', 'Done or not done'), (HabitKind.counter, 'Counter', 'Glasses, steps…')])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TypeCard(
                title: t,
                subtitle: s,
                on: h.kind == k,
                onTap: () {
                  _set((x) => x.kind == k
                      ? x
                      : (k == HabitKind.counter && x.target < 2 ? x.copyWith(kind: k, target: 8, unit: 'glasses') : x.copyWith(kind: k)),
                      resetPreview: true);
                  if (k == HabitKind.counter && h.target < 2) _unit.text = 'glasses';
                },
              ),
            ),
        ]),
      ),
      if (h.kind == HabitKind.counter)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: FieldBlock(
              label: 'Daily target',
              child: NumStepper(
                value: fmtCount(h.target),
                onMinus: () => _set((x) => x.copyWith(target: (x.target - step).clamp(1, 1000000))),
                onPlus: () => _set((x) => x.copyWith(target: x.target + step)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FieldBlock(label: 'Unit', hint: 'Glasses, steps, min…', child: PlainInput(controller: _unit, onChanged: (v) => _set((x) => x.copyWith(unit: v)))),
          ),
        ])
      else
        const GreyNote(icon: Icons.check_circle_outline_rounded, child: Text('The client gets a simple tick: "Done today?". Streaks are counted for you.')),
      FieldBlock(
        label: 'Frequency',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PillTabs<HabitFreq>(
            expand: true,
            items: const [(HabitFreq.daily, 'Daily', null), (HabitFreq.specificDays, 'Specific days', null), (HabitFreq.timesPerWeek, 'Times per week', null)],
            value: h.freq,
            onChanged: (f) => _set((x) => x.copyWith(freq: f)),
          ),
          if (h.freq == HabitFreq.specificDays) ...[
            const SizedBox(height: 10),
            DayCircles(days: h.days, onToggle: (d) => _set((x) => x.copyWith(days: toggleDay(x.days, d)))),
          ],
          if (h.freq == HabitFreq.timesPerWeek) ...[
            const SizedBox(height: 10),
            NumStepper(
              value: '${h.timesPerWeek}',
              unit: 'times a week',
              onMinus: () => _set((x) => x.copyWith(timesPerWeek: (x.timesPerWeek - 1).clamp(1, 7))),
              onPlus: () => _set((x) => x.copyWith(timesPerWeek: (x.timesPerWeek + 1).clamp(1, 7))),
            ),
            const SizedBox(height: 5),
            Text('Any days. The week resets on Monday.', style: AppText.caption),
          ],
        ]),
      ),
      FieldBlock(
        label: 'Icon',
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final i in HabitIcon.values)
            Tooltip(
              message: i.label,
              child: InkWell(
                onTap: () => _set((x) => x.copyWith(icon: i)),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: h.icon == i ? AppColors.accent : AppColors.line2, width: h.icon == i ? 2 : 1),
                  ),
                  child: h.icon == i
                      ? Padding(padding: const EdgeInsets.all(1), child: HabitIconBox(habitIcon(i), tone: habitTone(i), size: 36))
                      : Icon(habitIcon(i), size: 20, color: AppColors.muted),
                ),
              ),
            ),
        ]),
      ),
      FieldBlock(label: 'Why it matters (the client sees this)', child: PlainInput(controller: _why, maxLines: 3, onChanged: (v) => _set((x) => x.copyWith(why: v)))),
    ]);
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.title, required this.subtitle, required this.on, required this.onTap});
  final String title;
  final String subtitle;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : null,
          border: Border.all(color: on ? AppColors.accent : AppColors.line2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(shape: BoxShape.circle, color: on ? AppColors.accent : Colors.white, border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: 1.5)),
            child: on ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
          const SizedBox(width: 8),
          Text(subtitle, style: AppText.caption),
        ]),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.habit, required this.value, required this.onLog, required this.onReset});
  final Habit habit;
  final int value;
  final ValueChanged<int> onLog;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final h = habit;
    final tick = h.kind == HabitKind.tick;
    final inc = tick ? 1 : (h.target / 4).round().clamp(1, 1000000);
    final done = value >= h.target;
    return PreviewCard(
      title: 'Client preview',
      footer: [
        Text(done ? 'Preview: the client sees this celebration.' : 'Tap the button to log in the preview.', style: AppText.caption),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: onReset, icon: const Icon(Icons.restart_alt_rounded, size: 17), label: const Text('Reset preview')),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: done ? const Color(0xFFBFE5CF) : AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            HabitIconBox(habitIcon(h.icon), tone: habitTone(h.icon)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.name, style: AppText.bodyBold),
                Text(tick ? (done ? 'Done today' : 'Done today?') : freqLabel(h), style: AppText.caption),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          ProgressBar(h.target == 0 ? 0 : value / h.target, color: done ? const Color(0xFF10B981) : AppColors.accent, height: 8, track: AppColors.sub),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(fmtCount(value.clamp(0, h.target)), style: AppText.bigNumber.copyWith(fontSize: 20)),
            const SizedBox(width: 4),
            Text('/ ${fmtCount(h.target)} ${h.unit}', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          if (done)
            Container(
              height: 36,
              decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.okText),
                const SizedBox(width: 6),
                Text(tick ? 'Done today · streak 6 days' : 'Goal complete', style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.okText)),
              ]),
            )
          else
            AppButton(tick ? 'Mark as done' : '+ ${fmtCount(inc)} ${h.unit}', expand: true, onPressed: () => onLog(inc)),
          const SizedBox(height: 8),
          Text(h.why, style: AppText.caption.copyWith(height: 1.5)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared with the supplement editor
// ---------------------------------------------------------------------------

List<int> toggleDay(List<int> days, int d) => days.contains(d) ? days.where((x) => x != d).toList() : ([...days, d]..sort());

/// Unsaved changes bar (hb-save).
class SaveBar extends StatelessWidget {
  const SaveBar({super.key, required this.dirty, required this.onDiscard, required this.onSave});
  final bool dirty;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF9),
        border: Border(top: BorderSide(color: AppColors.line)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
      ),
      child: Row(children: [
        if (dirty)
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle))
        else
          const Icon(Icons.check_rounded, size: 15, color: AppColors.okText),
        const SizedBox(width: 8),
        Expanded(child: Text(dirty ? 'Unsaved changes' : 'All changes saved', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600))),
        if (dirty) ...[AppButton.outline('Discard', small: true, onPressed: onDiscard), const SizedBox(width: 8)],
        AppButton('Save changes', icon: Icons.check_rounded, small: true, onPressed: dirty ? onSave : null),
      ]),
    );
  }
}

/// Weekday circles (hb-days).
class DayCircles extends StatelessWidget {
  const DayCircles({super.key, required this.days, required this.onToggle});
  final List<int> days;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (var d = 0; d < 7; d++)
        InkWell(
          onTap: () => onToggle(d),
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: days.contains(d) ? AppColors.accent : Colors.white,
              border: Border.all(color: days.contains(d) ? AppColors.accent : AppColors.line2),
            ),
            child: Text(weekLetters[d], style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: days.contains(d) ? Colors.white : AppColors.text2)),
          ),
        ),
    ]);
  }
}

/// Card with a grey "phone" area (hb-pv / hb-phone).
class PreviewCard extends StatelessWidget {
  const PreviewCard({super.key, required this.title, required this.child, this.footer = const []});
  final String title;
  final Widget child;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: AppText.cardTitle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF4F4F1), borderRadius: BorderRadius.circular(16)), child: child),
        if (footer.isNotEmpty) ...[const SizedBox(height: 8), ...footer],
      ]),
    );
  }
}

/// "Assigned to" card.
class AssignedCard extends StatelessWidget {
  const AssignedCard({super.key, required this.clients, required this.line, required this.empty, required this.onAssign, required this.onOpen});
  final List<String> clients;
  final String line;
  final String empty;
  final VoidCallback onAssign;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Assigned to', style: AppText.cardTitle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800))),
          TextButton.icon(onPressed: onAssign, icon: const Icon(Icons.person_add_alt_rounded, size: 17), label: const Text('Assign')),
        ]),
        for (final c in clients) ClientLinkRow(name: c, subtitle: line, onTap: () => onOpen(c)),
        if (clients.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: SideEmpty(empty)),
      ]),
    );
  }
}

/// "Assign to clients" multi-select sheet.
void showAssignClients(BuildContext context, {required String subtitle, required List<String> current, required ValueChanged<List<String>> onSave}) {
  showAppSheet(
    context,
    title: 'Assign to clients',
    subtitle: subtitle,
    builder: (ctx) => _AssignForm(current: current, onSave: (sel) {
      Navigator.of(ctx).pop();
      onSave(sel);
    }),
  );
}

class _AssignForm extends StatefulWidget {
  const _AssignForm({required this.current, required this.onSave});
  final List<String> current;
  final ValueChanged<List<String>> onSave;

  @override
  State<_AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<_AssignForm> {
  late final _sel = [...widget.current];
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = LibraryMock.assignClients.where((n) => n.toLowerCase().contains(_q.toLowerCase()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SearchField(hint: 'Search clients', onChanged: (v) => setState(() => _q = v)),
      const SizedBox(height: 10),
      JoinedList(children: [
        for (final n in list)
          ClientPickRow(
            name: n,
            subtitle: widget.current.contains(n) ? 'On it now' : 'Not on it',
            selected: _sel.contains(n),
            onTap: () => setState(() => _sel.contains(n) ? _sel.remove(n) : _sel.add(n)),
          ),
      ]),
      SheetButtons(children: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Save · ${plural(_sel.length, 'client')}', icon: Icons.check_rounded, onPressed: () => widget.onSave(_sel)),
      ]),
    ]);
  }
}
