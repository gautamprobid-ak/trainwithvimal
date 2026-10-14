import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import '../nutrition/library_widgets.dart';
import 'habit_editor.dart';
import 'habits_state.dart';

/// "Edit supplement plan" sheet: items, quick add, note, client preview.
void showSupplementEditor(BuildContext context, String planId) {
  showAppSheet(context, title: 'Edit supplement plan', builder: (ctx) => _SupplementEditor(planId: planId, hostContext: context));
}

class _SupplementEditor extends ConsumerStatefulWidget {
  const _SupplementEditor({required this.planId, required this.hostContext});
  final String planId;
  final BuildContext hostContext;

  @override
  ConsumerState<_SupplementEditor> createState() => _SupplementEditorState();
}

class _SupplementEditorState extends ConsumerState<_SupplementEditor> {
  late String _id = widget.planId;
  List<SupplementPlan>? _snap;
  final _note = TextEditingController();

  SupplementsController get _ctl => ref.read(supplementsProvider.notifier);

  @override
  void initState() {
    super.initState();
    _note.text = _find(ref.read(supplementsProvider))?.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  SupplementPlan? _find(List<SupplementPlan> l) => l.where((p) => p.id == _id).firstOrNull;

  void _set(SupplementPlan Function(SupplementPlan) fn) {
    setState(() => _snap ??= ref.read(supplementsProvider));
    _ctl.update(_id, fn);
  }

  void _toast(String t, [String? s, VoidCallback? undo]) =>
      showToast(widget.hostContext, t, subtitle: s, kind: undo == null ? ToastKind.ok : ToastKind.del, onUndo: undo);

  void _menu(SupplementPlan p) {
    showActionSheet(context, title: p.name, actions: [
      SheetAction('Rename plan', Icons.edit_outlined, () => _rename(p)),
      SheetAction('Duplicate plan · same items, no clients', Icons.copy_rounded, () {
        final before = ref.read(supplementsProvider);
        final copy = p.copyWith(id: '${p.id}c${before.length}', name: '${p.name} (copy)', clients: const []);
        _ctl.add(copy);
        setState(() {
          _id = copy.id;
          _snap = null;
        });
        showToast(widget.hostContext, 'Plan duplicated', subtitle: 'Same items, no clients', kind: ToastKind.ok, onUndo: () => _ctl.restore(before));
      }),
      SheetAction('Delete plan', Icons.delete_outline_rounded, () async {
        final n = p.clients.length;
        final ok = await showConfirmDialog(
          context,
          title: 'Delete supplement plan?',
          message: '${p.name} is removed${n > 0 ? ' from ${plural(n, 'client')}' : ''}.',
          confirmLabel: 'Delete',
          destructive: true,
          icon: Icons.delete_outline_rounded,
        );
        if (!ok || !mounted) return;
        final List<SupplementPlan> before = _snap ?? ref.read(supplementsProvider);
        final ctl = _ctl;
        final host = widget.hostContext;
        Navigator.of(context).pop();
        ctl.remove(p.id);
        showToast(host, 'Plan deleted', subtitle: p.name, kind: ToastKind.del, onUndo: () => ctl.restore(before));
      }, destructive: true),
    ]);
  }

  void _rename(SupplementPlan p) {
    final ctl = TextEditingController(text: p.name);
    showAppSheet(
      context,
      title: 'Rename plan',
      subtitle: 'Clients see the new name',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldBlock(label: 'Plan name', child: PlainInput(controller: ctl, autofocus: true)),
        SheetButtons(children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
          AppButton('Save name', icon: Icons.check_rounded, onPressed: () {
            final v = ctl.text.trim();
            if (v.isEmpty) return;
            Navigator.of(ctx).pop();
            _set((x) => x.copyWith(name: v));
            _toast('Plan renamed', v);
          }),
        ]),
      ]),
    );
  }

  /// Edit item [index], or add a custom one when null.
  void _item(int? index) {
    final p = _find(ref.read(supplementsProvider));
    if (p == null) return;
    final item = index == null ? const SupplementItem('Glutamine', '5 g', 'Post-workout', false, [0, 1, 2, 3, 4, 5, 6]) : p.items[index];
    showAppSheet(
      context,
      title: index == null ? 'Custom supplement' : item.name,
      subtitle: 'Dose and timing',
      builder: (ctx) => _ItemForm(
        item: item,
        isNew: index == null,
        onSave: (it) {
          Navigator.of(ctx).pop();
          _set((x) => x.copyWith(items: index == null ? [...x.items, it] : [for (var i = 0; i < x.items.length; i++) i == index ? it : x.items[i]]));
          _toast(index == null ? 'Added ${it.name}' : 'Updated', '${it.dose} · ${it.timing}');
        },
      ),
    );
  }

  void _itemMenu(SupplementPlan p, int j) {
    final it = p.items[j];
    showActionSheet(context, title: it.name, actions: [
      SheetAction('Edit dose and timing', Icons.edit_outlined, () => _item(j)),
      SheetAction('Remove', Icons.delete_outline_rounded, () {
        final before = ref.read(supplementsProvider);
        _set((x) => x.copyWith(items: [...x.items]..removeAt(j)));
        _toast('Removed', it.name, () => _ctl.restore(before));
      }, destructive: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = _find(ref.watch(supplementsProvider));
    if (p == null) return const SizedBox.shrink();
    final n = p.clients.length;
    return Spaced(gap: 12, children: [
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(children: [
              const HabitIconBox(Icons.medication_outlined, tone: 3, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('${plural(p.items.length, 'supplement')} · ${n > 0 ? plural(n, 'client') : 'not assigned'}', style: AppText.caption),
                ]),
              ),
              AppButton.outline('Assign', small: true, icon: Icons.person_add_alt_rounded, onPressed: () => _assign(p)),
              AppIconButton(Icons.more_horiz_rounded, small: true, tooltip: 'Plan options', onPressed: () => _menu(p)),
            ]),
          ),
          const Divider(height: 1),
          for (var j = 0; j < p.items.length; j++) ...[
            if (j > 0) const Divider(height: 1),
            _ItemRow(item: p.items[j], onTap: () => _item(j), onMenu: () => _itemMenu(p, j)),
          ],
          if (p.items.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text('No supplements yet. Use quick add below.', textAlign: TextAlign.center, style: AppText.secondary)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Spaced(gap: 16, children: [
              FieldBlock(
                label: 'Quick add from library',
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final s in LibraryMock.supplementLibrary)
                    _QuickChip(
                      label: s,
                      disabled: p.items.any((x) => x.name == s),
                      onTap: () {
                        _set((x) => x.copyWith(items: [...x.items, SupplementItem(s, '1 serving', 'Breakfast', true, const [0, 1, 2, 3, 4, 5, 6])]));
                        _toast('Added $s', 'Tap the row to set dose and timing');
                      },
                    ),
                  _QuickChip(label: 'Custom', solid: true, icon: Icons.edit_outlined, onTap: () => _item(null)),
                ]),
              ),
              FieldBlock(
                label: 'Note to client',
                child: PlainInput(controller: _note, maxLines: 3, hint: 'e.g. Take creatine every day, rest days too.', onChanged: (v) => _set((x) => x.copyWith(note: v))),
              ),
            ]),
          ),
          SaveBar(
            dirty: _snap != null,
            onDiscard: () {
              final s = _snap;
              if (s == null) return;
              _ctl.restore(s);
              setState(() => _snap = null);
              _note.text = _find(s)?.note ?? '';
              showToast(widget.hostContext, 'Changes discarded');
            },
            onSave: () {
              setState(() => _snap = null);
              _toast('Changes saved', n > 0 ? 'Sent to ${plural(n, 'client')} on this plan' : 'Not assigned to anyone yet');
            },
          ),
        ]),
      ),
      _ClientSees(plan: p),
      AssignedCard(
        clients: p.clients,
        line: 'Sees it in the app',
        empty: 'Not assigned yet. Assign the plan to show it in the client app.',
        onAssign: () => _assign(p),
        onOpen: (name) {
          Navigator.of(context).pop();
          openClientByName(widget.hostContext, name);
        },
      ),
    ]);
  }

  void _assign(SupplementPlan p) {
    showAssignClients(context, subtitle: p.name, current: p.clients, onSave: (sel) {
      _set((x) => x.copyWith(clients: sel));
      _toast('Plan assigned', plural(sel.length, 'client'));
    });
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap, required this.onMenu});
  final SupplementItem item;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(children: [
          const HabitIconBox(Icons.medication_outlined, tone: 3, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              Text(item.withFood ? 'With food' : 'Empty stomach is fine', style: AppText.caption),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(item.dose, style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                GreyTag(item.timing),
                Text(daysLabel(item.days), style: AppText.caption),
              ]),
            ]),
          ),
          DotsButton(onPressed: onMenu, tooltip: 'Supplement options'),
        ]),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap, this.disabled = false, this.solid = false, this.icon = Icons.add_rounded});
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final bool solid;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(label, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
      ]),
    );
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: solid
            ? DecoratedBox(decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(15)), child: chip)
            : CustomPaint(painter: DashedBorderPainter(radius: 15, strokeWidth: 1), child: chip),
      ),
    );
  }
}

class _ClientSees extends StatelessWidget {
  const _ClientSees({required this.plan});
  final SupplementPlan plan;

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final t in LibraryMock.supplementTimings) (t, plan.items.where((x) => x.timing == t).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();
    return PreviewCard(
      title: 'Client sees',
      footer: [if (plan.note.isNotEmpty) Text(plan.note, style: AppText.caption.copyWith(height: 1.5))],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: groups.isEmpty
            ? const SideEmpty('Nothing yet. Add a supplement.', icon: Icons.medication_outlined)
            : Spaced(gap: 12, children: [
                for (final (t, items) in groups)
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Overline(t, padding: EdgeInsets.zero),
                    const SizedBox(height: 6),
                    for (final x in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.line2, width: 1.5), borderRadius: BorderRadius.circular(5)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(x.name, style: AppText.bodyBold.copyWith(fontSize: 13)),
                              Text('${x.dose}${x.withFood ? ' · with food' : ''} · ${daysLabel(x.days)}', style: AppText.caption.copyWith(fontSize: 11.5)),
                            ]),
                          ),
                        ]),
                      ),
                  ]),
              ]),
      ),
    );
  }
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({required this.item, required this.isNew, required this.onSave});
  final SupplementItem item;
  final bool isNew;
  final ValueChanged<SupplementItem> onSave;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _dose = TextEditingController(text: widget.item.dose);
  late String _timing = widget.item.timing;
  late List<int> _days = widget.item.days;
  late bool _withFood = widget.item.withFood;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Spaced(gap: 16, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: FieldBlock(label: 'Name', required: true, child: PlainInput(controller: _name))),
        const SizedBox(width: 10),
        Expanded(child: FieldBlock(label: 'Dose', hint: 'e.g. 5 g, 1 tablet', child: PlainInput(controller: _dose))),
      ]),
      FieldBlock(
        label: 'Timing',
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final t in LibraryMock.supplementTimings) ChoicePill(t, selected: _timing == t, onTap: () => setState(() => _timing = t)),
        ]),
      ),
      FieldBlock(
        label: 'Days',
        hint: daysLabel(_days),
        child: DayCircles(days: _days, onToggle: (d) => setState(() => _days = toggleDay(_days, d))),
      ),
      ToggleRow(on: _withFood, title: 'Take with food', subtitle: 'The client sees "with food" next to it', onTap: () => setState(() => _withFood = !_withFood)),
      SheetButtons(children: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton(widget.isNew ? 'Add supplement' : 'Update', icon: Icons.check_rounded, onPressed: () {
          widget.onSave(SupplementItem(
            _name.text.trim().isEmpty ? widget.item.name : _name.text.trim(),
            _dose.text.trim().isEmpty ? widget.item.dose : _dose.text.trim(),
            _timing,
            _withFood,
            _days,
          ));
        }),
      ]),
    ]);
  }
}
