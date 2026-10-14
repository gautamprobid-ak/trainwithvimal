import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/library.dart';

import '../nutrition/library_widgets.dart';
import 'habit_editor.dart';
import 'habits_state.dart';
import 'supplement_editor.dart';

enum _Tab { habits, supplements }

/// Design: HabitsMobile — "Habits & supplements": habit templates and
/// supplement plans; tapping one opens its editor with a live client preview.
class HabitsLibraryScreen extends ConsumerStatefulWidget {
  const HabitsLibraryScreen({super.key});

  @override
  ConsumerState<HabitsLibraryScreen> createState() => _HabitsLibraryScreenState();
}

class _HabitsLibraryScreenState extends ConsumerState<HabitsLibraryScreen> {
  var _tab = _Tab.habits;
  String _q = '';

  void _newHabit() {
    showAppSheet(
      context,
      title: 'New habit template',
      subtitle: 'You can set the target, days and icon next',
      builder: (ctx) => _NewHabitForm(onCreate: (name, kind) {
        Navigator.of(ctx).pop();
        final list = ref.read(habitsProvider);
        final h = Habit(
          id: 'hb-n${list.length}',
          name: name.isEmpty ? 'New habit' : name,
          kind: kind,
          target: kind == HabitKind.counter ? 8 : 1,
          unit: kind == HabitKind.counter ? 'glasses' : '',
          freq: HabitFreq.daily,
          why: 'Small steps every day add up.',
          icon: HabitIcon.habit,
        );
        ref.read(habitsProvider.notifier).add(h);
        showToast(context, 'Template created', subtitle: 'Set the target, days and icon', kind: ToastKind.ok);
        showHabitEditor(context, h.id);
      }),
    );
  }

  void _newPlan() {
    final ctl = TextEditingController();
    showAppSheet(
      context,
      title: 'New supplement plan',
      subtitle: 'Add supplements with dose and timing next',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldBlock(label: 'Plan name', required: true, child: PlainInput(controller: ctl, hint: 'e.g. Recovery stack', autofocus: true)),
        SheetButtons(children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
          AppButton('Create plan', icon: Icons.check_rounded, onPressed: () {
            Navigator.of(ctx).pop();
            final list = ref.read(supplementsProvider);
            final p = SupplementPlan(id: 'sp-n${list.length}', name: ctl.text.trim().isEmpty ? 'Recovery stack' : ctl.text.trim());
            ref.read(supplementsProvider.notifier).add(p);
            showToast(context, 'Plan created', subtitle: 'Use quick add to fill it', kind: ToastKind.ok);
            showSupplementEditor(context, p.id);
          }),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final plans = ref.watch(supplementsProvider);
    final isH = _tab == _Tab.habits;
    final shown = habits.where((h) => h.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return PageScroll(
      children: [
        const SubPageHeader(title: 'Habits & supplements'),
        Text(
          isH
              ? 'Build a habit once and assign it to many clients. Saved changes reach everyone on it.'
              : 'Supplement plans with dose and timing. Save to send changes to every client on the plan.',
          style: AppText.secondary,
        ),
        AppButton(isH ? 'New habit' : 'New plan', icon: Icons.add_rounded, expand: true, onPressed: isH ? _newHabit : _newPlan),
        CountTabs<_Tab>(
          items: [(_Tab.habits, 'Habits', habits.length), (_Tab.supplements, 'Supplements', plans.length)],
          value: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        if (isH)
          AppCard(
            padding: const EdgeInsets.all(6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(padding: const EdgeInsets.all(6), child: SearchField(hint: 'Search habits', onChanged: (v) => setState(() => _q = v))),
              for (final h in shown)
                _ListRow(
                  leading: HabitIconBox(habitIcon(h.icon), tone: habitTone(h.icon)),
                  title: h.name,
                  subtitle: '${kindLabel(h)} · ${freqLabel(h)}',
                  count: h.clients.length,
                  onTap: () => showHabitEditor(context, h.id),
                ),
              if (shown.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text('No habits match your search.', textAlign: TextAlign.center, style: AppText.secondary)),
            ]),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final p in plans)
                _ListRow(
                  leading: const HabitIconBox(Icons.medication_outlined, tone: 3),
                  title: p.name,
                  subtitle: plural(p.items.length, 'supplement'),
                  count: p.clients.length,
                  onTap: () => showSupplementEditor(context, p.id),
                ),
              if (plans.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text('No supplement plans yet.', textAlign: TextAlign.center, style: AppText.secondary)),
            ]),
          ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.leading, required this.title, required this.subtitle, required this.count, required this.onTap});
  final Widget leading;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.person_outline_rounded, size: 14, color: count > 0 ? AppColors.muted : AppColors.line2),
          const SizedBox(width: 3),
          Text('$count', style: AppText.caption.copyWith(fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w600, color: count > 0 ? AppColors.text2 : AppColors.muted)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class _NewHabitForm extends StatefulWidget {
  const _NewHabitForm({required this.onCreate});
  final void Function(String name, HabitKind kind) onCreate;

  @override
  State<_NewHabitForm> createState() => _NewHabitFormState();
}

class _NewHabitFormState extends State<_NewHabitForm> {
  final _name = TextEditingController();
  var _kind = HabitKind.tick;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldBlock(label: 'Name', required: true, child: PlainInput(controller: _name, hint: 'e.g. Drink 3 L water', autofocus: true)),
      const SizedBox(height: 14),
      FieldBlock(
        label: 'Type',
        hint: _kind == HabitKind.tick ? 'Done or not done, once a day.' : 'Counted up to a daily target, like 12 glasses.',
        child: PillTabs<HabitKind>(
          expand: true,
          items: const [(HabitKind.tick, 'Tick', null), (HabitKind.counter, 'Counter', null)],
          value: _kind,
          onChanged: (k) => setState(() => _kind = k),
        ),
      ),
      SheetButtons(children: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Create', icon: Icons.check_rounded, onPressed: () => widget.onCreate(_name.text.trim(), _kind)),
      ]),
    ]);
  }
}
