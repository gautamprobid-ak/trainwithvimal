import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'builder_state.dart';
import 'food_editor_sheet.dart';
import 'library_widgets.dart';
import 'nutrition_state.dart';

const _defaultNote = 'Lunch: no paneer, use tofu. Dinner: 1 roti less.';

/// Every menu, sheet and dialog of the meal plan builder.
class BuilderActions {
  BuilderActions({required this.context, required this.ref, required this.plan, required this.setOption});

  final BuildContext context;
  final WidgetRef ref;
  final MealPlan plan;
  final void Function(String mealId, int option) setOption;

  String get _id => plan.id;
  MealPlan get _p => ref.read(mealPlansProvider.notifier).byId(_id) ?? plan;
  List<Meal> get _meals => mealsOf(_p);
  MealPlansController get _ctl => ref.read(mealPlansProvider.notifier);

  /// Snapshot for Undo.
  VoidCallback _undo() {
    final before = ref.read(mealPlansProvider);
    final ctl = _ctl;
    return () => ctl.restore(before);
  }

  void _toast(String t, [String? s, VoidCallback? undo]) => showToast(context, t, subtitle: s, kind: ToastKind.ok, onUndo: undo);

  // ---------------------------------------------------------------- plan ---

  void planMenu() {
    showActionSheet(context, title: _p.name, actions: [
      SheetAction('Rename plan', Icons.edit_outlined, () => _rename(
            title: 'Rename plan',
            subtitle: 'Clients see the new name',
            label: 'Plan name',
            value: _p.name,
            hint: 'e.g. Cut · Eggetarian',
            onSave: (v) {
              putPlan(ref, _id, (p) => p.copyWith(name: v, dirty: true));
              _toast('Plan renamed');
            },
          )),
      SheetAction('Duplicate plan · same meals, no clients', Icons.copy_rounded, () {
        final undo = _undo();
        _ctl.duplicate(_p);
        _toast('Plan duplicated', '${_p.name} (copy) · same meals, no clients', undo);
      }),
      SheetAction('Delete plan', Icons.delete_outline_rounded, _deletePlan, destructive: true),
    ]);
  }

  Future<void> _deletePlan() async {
    final p = _p;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this plan?',
      message: '${p.name} is removed for good and taken off ${plural(p.clients.length, 'client')}. Meals they already logged stay.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !context.mounted) return;
    final undo = _undo();
    final nav = GoRouter.of(context);
    showToast(context, 'Plan deleted', subtitle: p.name, kind: ToastKind.del, onUndo: undo);
    nav.pop();
    _ctl.remove(p.id);
  }

  void publish() {
    final p = _p;
    final n = p.clients.length;
    final cu = p.clients.where((c) => c.custom).length;
    final lines = [
      cu > 0 ? '${plural(cu, 'custom version')} ${cu == 1 ? 'keeps its' : 'keep their'} changes' : 'Everyone follows the master plan',
      'Meals already logged stay as they are',
      'Their trainers get a notice',
    ];
    showAppSheet(
      context,
      title: 'Publish master plan?',
      subtitle: n > 0 ? '${plural(n, 'client gets', 'clients get')} the new version on their phone.' : 'Nobody is on this plan yet. It is saved as ready to assign.',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded, size: 17, color: AppColors.okText),
              const SizedBox(width: 8),
              Expanded(child: Text(l, style: AppText.body)),
            ]),
          ),
        SheetButtons(children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
          AppButton('Publish', icon: Icons.send_rounded, onPressed: () {
            Navigator.of(ctx).pop();
            putPlan(ref, _id, (p) => p.copyWith(dirty: false, published: true));
            _toast('Master plan published', n > 0 ? 'Sent to ${plural(n, 'client')}' : 'Ready to assign');
          }),
        ]),
      ]),
    );
  }

  void editTargets() {
    showAppSheet(
      context,
      title: 'Edit targets',
      subtitle: 'Daily targets for every client on this plan',
      builder: (ctx) => _TargetsForm(
        initial: _p.targets,
        onSave: (t) {
          Navigator.of(ctx).pop();
          final undo = _undo();
          putPlan(ref, _id, (p) => p.copyWith(targets: t, dirty: true));
          _toast('Targets updated', '${fmtN(t.kcal)} kcal · P ${t.protein} g · C ${t.carbs} g · F ${t.fat} g', undo);
        },
      ),
    );
  }

  // ------------------------------------------------------------- clients ---

  void clients() {
    showAppSheet(
      context,
      title: 'Clients on this plan',
      subtitle: 'Changes to the master reach everyone',
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        ref.watch(mealPlansProvider);
        final p = _p;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final c in p.clients) _clientRow(ctx, c),
          if (p.clients.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text('Not assigned to anyone yet.', textAlign: TextAlign.center, style: AppText.secondary)),
          const SizedBox(height: 10),
          const GreyNote(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Master', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' follows this plan as it is. '),
              TextSpan(text: 'Custom version', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' has a note with what is different for that client. The master plan and the other clients stay as they are.'),
            ])),
          ),
          SheetButtons(note: plural(p.clients.length, 'client'), children: [
            AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
            AppButton('Assign to clients', icon: Icons.person_add_alt_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              assign();
            }),
          ]),
        ]);
      }),
    );
  }

  Widget _clientRow(BuildContext ctx, PlanClient c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Avatar(Avatar.initialsOf(c.name), size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: AppText.bodyBold),
              Text(c.custom ? 'Has changes only for them' : 'Follows the master plan', style: AppText.caption),
            ]),
          ),
          c.custom ? const AppBadge('Custom version', tone: BadgeTone.warn) : const AppBadge('Master', tone: BadgeTone.info),
          DotsButton(tooltip: 'Client options', onPressed: () => _clientMenu(ctx, c)),
        ]),
        if (c.custom) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppColors.warnText),
              const SizedBox(width: 8),
              Expanded(child: Text(c.note, style: AppText.secondary.copyWith(color: AppColors.warnText, fontSize: 12.5))),
            ]),
          ),
        ],
      ]),
    );
  }

  void _clientMenu(BuildContext ctx, PlanClient c) {
    final first = c.name.split(' ').first;
    showActionSheet(ctx, title: c.name, actions: [
      SheetAction(c.custom ? 'Edit version note' : 'Add version note', Icons.sticky_note_2_outlined, () => _versionNote(ctx, c)),
      if (c.custom)
        SheetAction('Reset to master · removes the version note', Icons.restart_alt_rounded, () {
          final undo = _undo();
          putPlan(ref, _id, (p) => p.copyWith(clients: [for (final x in p.clients) x.name == c.name ? PlanClient(x.name) : x]));
          _toast('$first follows the master again', 'Version note removed', undo);
        }),
      SheetAction('Open client profile', Icons.person_outline_rounded, () {
        Navigator.of(ctx).pop();
        openClientByName(context, c.name);
      }),
      SheetAction('Remove from plan', Icons.person_remove_outlined, () {
        final undo = _undo();
        putPlan(ref, _id, (p) => p.copyWith(clients: p.clients.where((x) => x.name != c.name).toList(), dirty: true));
        _toast('Removed from plan', c.name, undo);
      }, destructive: true),
    ]);
  }

  void _versionNote(BuildContext ctx, PlanClient c) {
    final first = c.name.split(' ').first;
    final ctl = TextEditingController(text: c.custom ? c.note : _defaultNote);
    showAppSheet(
      ctx,
      title: 'Custom version for ${c.name}',
      subtitle: 'The master plan and the other clients stay as they are',
      builder: (sheet) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldBlock(
          label: 'What is different for $first?',
          hint: 'Only for this client. The trainer and the client see it on the plan.',
          child: PlainInput(controller: ctl, maxLines: 4),
        ),
        SheetButtons(children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(sheet).pop()),
          AppButton('Save version note', icon: Icons.check_rounded, onPressed: () {
            Navigator.of(sheet).pop();
            final note = ctl.text.trim().isEmpty ? _defaultNote : ctl.text.trim();
            putPlan(ref, _id, (p) => p.copyWith(clients: [for (final x in p.clients) x.name == c.name ? PlanClient(x.name, note) : x]));
            _toast('Custom version saved', 'Only for $first');
          }),
        ]),
      ]),
    );
  }

  void assign() {
    final p = _p;
    showAppSheet(
      context,
      title: 'Assign to clients',
      subtitle: '${p.name} · ${fmtN(p.targets.kcal)} kcal / day',
      builder: (ctx) => _AssignForm(
        planName: p.name,
        initial: [for (final c in p.clients) c.name],
        onSave: (sel) {
          Navigator.of(ctx).pop();
          final undo = _undo();
          putPlan(ref, _id, (p) {
            String noteOf(String n) => p.clients.firstWhere((c) => c.name == n, orElse: () => PlanClient(n)).note;
            return p.copyWith(clients: [for (final n in sel) PlanClient(n, noteOf(n))], dirty: true);
          });
          _toast('Plan assigned', '${plural(sel.length, 'client')} on ${p.name}', undo);
        },
      ),
    );
  }

  // --------------------------------------------------------------- meals ---

  void mealMenu(Meal m) {
    showActionSheet(context, title: m.name, actions: [
      SheetAction('Edit meal · name, time and calorie target', Icons.edit_outlined, () => editMeal(m)),
      SheetAction('Delete meal', Icons.delete_outline_rounded, () async {
        final ok = await showConfirmDialog(
          context,
          title: 'Delete ${m.name.toLowerCase()}?',
          message: 'All ${plural(m.options.length, 'option')} of this meal are removed for every client on the plan.',
          confirmLabel: 'Delete',
          destructive: true,
          icon: Icons.delete_outline_rounded,
        );
        if (!ok || !context.mounted) return;
        final undo = _undo();
        putMeals(ref, _id, _meals.where((x) => x.id != m.id).toList());
        showToast(context, '${m.name} deleted', kind: ToastKind.del, onUndo: undo);
      }, destructive: true),
    ]);
  }

  /// Edit a meal, or add one when [m] is null.
  void editMeal(Meal? m) {
    showAppSheet(
      context,
      title: m == null ? 'Add meal' : 'Edit ${m.name.toLowerCase()}',
      subtitle: m == null ? 'It starts with one empty option' : 'Name, time and calorie target',
      builder: (ctx) => _MealForm(
        meal: m,
        onSave: (name, time, kcal) {
          Navigator.of(ctx).pop();
          if (m != null) {
            putMeals(ref, _id, editMeal2(m.id, (x) => x.copyWith(name: name, time: time, target: kcal)));
            _toast('$name saved', 'Target ${fmtN(kcal)} kcal');
          } else {
            final list = [..._meals];
            final meal = Meal(id: 'm${list.length}x${DateTime.now().millisecondsSinceEpoch}', name: name, time: time, target: kcal, options: const [MealOption('Option A', [])]);
            list.insert(list.length < 2 ? list.length : 2, meal);
            putMeals(ref, _id, list);
            _toast('Meal added', '$name · $time');
          }
        },
      ),
    );
  }

  List<Meal> editMeal2(String id, Meal Function(Meal) fn) => editMeal_(_meals, id, fn);

  static List<Meal> editMeal_(List<Meal> ms, String id, Meal Function(Meal) fn) => [for (final m in ms) m.id == id ? fn(m) : m];

  void addOptionMenu(Meal m, int oi) {
    final o = m.options[oi];
    showActionSheet(context, title: 'Add option to ${m.name}', actions: [
      SheetAction('Blank · add the foods yourself', Icons.add_box_outlined, () {
        final name = 'Option ${String.fromCharCode(65 + m.options.length)}';
        putMeals(ref, _id, editMeal2(m.id, (x) => x.copyWith(options: [...x.options, MealOption(name, const [])])));
        setOption(m.id, m.options.length);
        _toast('Blank option added', 'Use Add food to open the food library');
      }),
      SheetAction('Duplicate current option · copy of ${o.name}', Icons.copy_rounded, () => _dupOption(m, oi, 'Copy of ${o.name}')),
    ]);
  }

  void _dupOption(Meal m, int oi, String sub) {
    final o = m.options[oi];
    putMeals(ref, _id, editMeal2(m.id, (x) => x.copyWith(options: [...x.options, MealOption('${o.name} copy', o.foods)])));
    setOption(m.id, m.options.length);
    _toast('Option duplicated', sub);
  }

  void optionMenu(Meal m, int oi) {
    final o = m.options[oi];
    showActionSheet(context, title: o.name, actions: [
      SheetAction('Rename', Icons.edit_outlined, () => _rename(
            title: 'Rename ${o.name}',
            subtitle: m.name,
            label: 'Option name',
            value: o.name,
            hint: 'Veg, Non-veg, Eating out…',
            onSave: (v) {
              putMeals(ref, _id, editOption(_meals, m.id, oi, (x) => x.copyWith(name: v)));
              _toast('Option renamed', '${m.name} · $v');
            },
          )),
      SheetAction('Duplicate · same foods, new option', Icons.copy_rounded, () => _dupOption(m, oi, 'Same foods, new option')),
      if (oi != m.defaultOption)
        SheetAction('Set as default · the client sees this one first', Icons.star_outline_rounded, () {
          putMeals(ref, _id, editMeal2(m.id, (x) => x.copyWith(defaultOption: oi)));
          _toast('${o.name} is the default', 'The client sees this one first');
        }),
      SheetAction('Delete option', Icons.delete_outline_rounded, () {
        if (m.options.length < 2) {
          showToast(context, 'A meal needs at least one option', subtitle: 'Delete the meal instead', kind: ToastKind.warn);
          return;
        }
        final undo = _undo();
        putMeals(
          ref,
          _id,
          editMeal2(m.id, (x) {
            final opts = [...x.options]..removeAt(oi);
            final def = x.defaultOption >= opts.length || x.defaultOption == oi ? 0 : (x.defaultOption > oi ? x.defaultOption - 1 : x.defaultOption);
            return x.copyWith(options: opts, defaultOption: def);
          }),
        );
        setOption(m.id, 0);
        showToast(context, 'Option deleted', subtitle: o.name, kind: ToastKind.del, onUndo: undo);
      }, destructive: true),
    ]);
  }

  void _rename({
    required String title,
    required String subtitle,
    required String label,
    required String value,
    required String hint,
    required ValueChanged<String> onSave,
  }) {
    final ctl = TextEditingController(text: value);
    showAppSheet(
      context,
      title: title,
      subtitle: subtitle,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldBlock(label: label, hint: hint, child: PlainInput(controller: ctl, autofocus: true)),
        SheetButtons(children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
          AppButton('Save name', icon: Icons.check_rounded, onPressed: () {
            final v = ctl.text.trim();
            if (v.isEmpty) return;
            Navigator.of(ctx).pop();
            onSave(v);
          }),
        ]),
      ]),
    );
  }

  // --------------------------------------------------------------- foods ---

  void addFood(Meal m, int oi) {
    showAppSheet(
      context,
      title: 'Add to ${m.name}',
      subtitle: 'Food library · option ${m.options[oi].name}',
      builder: (ctx) => _FoodPicker(
        mealId: m.id,
        oi: oi,
        planId: _id,
        onAdd: (f) {
          final t = LibraryMock.pickerTemplates[f.name];
          if (t == null) return;
          putMeals(ref, _id, editOption(_meals, m.id, oi, (o) => o.copyWith(foods: [...o.foods, t])));
          _toast('Added ${f.name}', '${m.name} · ${m.options[oi].name}');
        },
        onCustom: () {
          Navigator.of(ctx).pop();
          showFoodEditor(context, onSaved: (_) {}, onOpenPlan: (_) {});
        },
      ),
    );
  }

  void portion(Meal m, int oi, int fi) {
    showAppSheet(
      context,
      title: 'Portion and swaps',
      subtitle: '${m.name} · ${m.options[oi].name}',
      builder: (ctx) => _PortionPanel(
        actions: this,
        mealId: m.id,
        oi: oi,
        fi: fi,
        close: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void updateFood(String mealId, int oi, int fi, PlanFood Function(PlanFood) fn) => putMeals(ref, _id, editFood(_meals, mealId, oi, fi, fn));

  void removeFood(String mealId, int oi, int fi) {
    final m = _meals.firstWhere((x) => x.id == mealId);
    final f = m.options[oi].foods[fi];
    final undo = _undo();
    putMeals(ref, _id, editOption(_meals, mealId, oi, (o) => o.copyWith(foods: [...o.foods]..removeAt(fi))));
    showToast(context, 'Removed from ${m.name}', subtitle: f.name, kind: ToastKind.del, onUndo: undo);
  }
}

// ---------------------------------------------------------------------------
// Forms
// ---------------------------------------------------------------------------

class _TargetsForm extends StatefulWidget {
  const _TargetsForm({required this.initial, required this.onSave});
  final PlanTargets initial;
  final ValueChanged<PlanTargets> onSave;

  @override
  State<_TargetsForm> createState() => _TargetsFormState();
}

class _TargetsFormState extends State<_TargetsForm> {
  late final _v = <double>[
    widget.initial.kcal.toDouble(),
    widget.initial.protein.toDouble(),
    widget.initial.carbs.toDouble(),
    widget.initial.fat.toDouble(),
    widget.initial.fibre.toDouble(),
    widget.initial.water,
  ];
  static const _spec = [('Calories', 'kcal', 50.0, 1000.0, 5000.0), ('Protein', 'g', 5.0, 30.0, 400.0), ('Carbs', 'g', 5.0, 20.0, 600.0), ('Fat', 'g', 5.0, 20.0, 200.0), ('Fibre', 'g', 1.0, 10.0, 80.0), ('Water', 'L', .5, 1.0, 6.0)];

  Widget _field(int i) {
    final (k, u, d, lo, hi) = _spec[i];
    return FieldBlock(
      label: k,
      child: NumStepper(
        value: i == 5 ? fq(_v[i]) : fmtN(_v[i]),
        unit: u,
        onMinus: () => setState(() => _v[i] = (_v[i] - d).clamp(lo, hi)),
        onPlus: () => setState(() => _v[i] = (_v[i] + d).clamp(lo, hi)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromM = _v[1] * 4 + _v[2] * 4 + _v[3] * 9;
    final ok = (fromM - _v[0]).abs() / _v[0] <= .05;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var r = 0; r < 3; r++) ...[
        Row(children: [Expanded(child: _field(r * 2)), const SizedBox(width: 10), Expanded(child: _field(r * 2 + 1))]),
        const SizedBox(height: 12),
      ],
      InfoBanner(
        icon: ok ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
        bg: ok ? AppColors.okBg : AppColors.warnBg,
        fg: ok ? AppColors.okText : AppColors.warnText,
        text: 'Macros add up to ${fmtN(fromM)} kcal',
      ),
      SheetButtons(children: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Update targets', icon: Icons.check_rounded, onPressed: () {
          widget.onSave(PlanTargets(_v[0].round(), _v[1].round(), _v[2].round(), _v[3].round(), _v[4].round(), _v[5]));
        }),
      ]),
    ]);
  }
}

class _MealForm extends StatefulWidget {
  const _MealForm({required this.meal, required this.onSave});
  final Meal? meal;
  final void Function(String name, String time, int kcal) onSave;

  @override
  State<_MealForm> createState() => _MealFormState();
}

class _MealFormState extends State<_MealForm> {
  late final _name = TextEditingController(text: widget.meal?.name ?? '');
  late String _time = widget.meal?.time ?? '11:00 am';
  late int _kcal = widget.meal?.target ?? 300;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final times = {...LibraryMock.mealTimes, _time}.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldBlock(label: 'Meal name', required: true, child: PlainInput(controller: _name, hint: 'e.g. Pre-workout')),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: FieldBlock(
            label: 'Time',
            child: DropdownButtonFormField<String>(
              initialValue: _time,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: [for (final t in times) DropdownMenuItem(value: t, child: Text(t, style: AppText.body))],
              onChanged: (v) => setState(() => _time = v ?? _time),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FieldBlock(
            label: 'Calorie target',
            child: NumStepper(
              value: fmtN(_kcal),
              unit: 'kcal',
              onMinus: () => setState(() => _kcal = (_kcal - 50).clamp(50, 2000)),
              onPlus: () => setState(() => _kcal = (_kcal + 50).clamp(50, 2000)),
            ),
          ),
        ),
      ]),
      SheetButtons(children: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Save meal', icon: Icons.check_rounded, onPressed: () {
          final n = _name.text.trim();
          widget.onSave(n.isEmpty ? (widget.meal?.name ?? 'Pre-workout') : n, _time, _kcal);
        }),
      ]),
    ]);
  }
}

class _AssignForm extends StatefulWidget {
  const _AssignForm({required this.planName, required this.initial, required this.onSave});
  final String planName;
  final List<String> initial;
  final ValueChanged<List<String>> onSave;

  @override
  State<_AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<_AssignForm> {
  late final _sel = [...widget.initial];
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = LibraryMock.assignable.where((c) => c.$1.toLowerCase().contains(_q.toLowerCase())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SearchField(hint: 'Search clients', onChanged: (v) => setState(() => _q = v)),
      const SizedBox(height: 10),
      JoinedList(children: [
        for (final (n, on) in list)
          ClientPickRow(
            name: n,
            subtitle: on.isEmpty ? 'No meal plan' : 'On $on',
            selected: _sel.contains(n),
            tag: on.isNotEmpty && on != widget.planName ? 'Moves here' : null,
            onTap: () => setState(() => _sel.contains(n) ? _sel.remove(n) : _sel.add(n)),
          ),
      ]),
      const SizedBox(height: 8),
      Text('Clients on another meal plan move to this one. Their logged meals stay.', style: AppText.caption),
      SheetButtons(children: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Save · ${plural(_sel.length, 'client')}', icon: Icons.check_rounded, onPressed: () => widget.onSave(_sel)),
      ]),
    ]);
  }
}

class _FoodPicker extends ConsumerStatefulWidget {
  const _FoodPicker({required this.mealId, required this.oi, required this.planId, required this.onAdd, required this.onCustom});
  final String mealId;
  final int oi;
  final String planId;
  final ValueChanged<LibraryFood> onAdd;
  final VoidCallback onCustom;

  @override
  ConsumerState<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends ConsumerState<_FoodPicker> {
  static const _groups = ['All', 'Protein', 'Carbs', 'Fats', 'Veg', 'Fruits', 'Dairy', 'Indian dishes', 'My foods'];
  String _group = 'All';
  String _q = '';
  int _added = 0;

  bool _inG(LibraryFood f, String g) => g == 'All' || (g == 'My foods' ? f.team : f.group == g);

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(mealPlansProvider);
    final plan = plans.firstWhere((p) => p.id == widget.planId, orElse: () => plans.first);
    final meal = mealsOf(plan).where((m) => m.id == widget.mealId).firstOrNull;
    final inOpt = meal == null || widget.oi >= meal.options.length ? <String>{} : {for (final f in meal.options[widget.oi].foods) f.name};
    final all = LibraryMock.pickerFoods;
    final list = all.where((f) => _inG(f, _group) && f.name.toLowerCase().contains(_q.toLowerCase())).toList()..sort((a, b) => b.protein.compareTo(a.protein));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SearchField(hint: 'Search paneer, dal, chicken…', onChanged: (v) => setState(() => _q = v)),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final g in _groups) CountChip(g, count: all.where((f) => _inG(f, g)).length, selected: g == _group, onTap: () => setState(() => _group = g)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Text('${list.length} foods', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
        Text('Most protein first', style: AppText.caption),
      ]),
      for (final f in list)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Row(children: [
            FoodThumb(tone: f.name.length % 4 + 1, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                  if (f.team) ...[const SizedBox(width: 6), const AppBadge('Team', tone: BadgeTone.info)],
                ]),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${f.serving}  ', style: const TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: '${f.kcal} kcal · P ${f.protein} g · C ${f.carbs} g · F ${f.fat} g'),
                  ]),
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            if (inOpt.contains(f.name))
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_rounded, size: 15, color: AppColors.okText),
                const SizedBox(width: 3),
                Text('Added', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.okText)),
              ])
            else
              AppButton.outline('Add', icon: Icons.add_rounded, small: true, onPressed: () {
                widget.onAdd(f);
                setState(() => _added++);
              }),
          ]),
        ),
      SheetButtons(note: _added > 0 ? '$_added added' : null, children: [
        AppButton.ghost('Create custom food', icon: Icons.add_rounded, onPressed: widget.onCustom),
        AppButton('Done', onPressed: () => Navigator.of(context).pop()),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Portion and swaps
// ---------------------------------------------------------------------------

class _PortionPanel extends ConsumerStatefulWidget {
  const _PortionPanel({required this.actions, required this.mealId, required this.oi, required this.fi, required this.close});
  final BuilderActions actions;
  final String mealId;
  final int oi;
  final int fi;
  final VoidCallback close;

  @override
  ConsumerState<_PortionPanel> createState() => _PortionPanelState();
}

class _PortionPanelState extends ConsumerState<_PortionPanel> {
  bool _swOpen = false;
  bool _swAll = false;

  PlanFood? _food() {
    final p = ref.watch(mealPlansProvider).where((x) => x.id == widget.actions.plan.id).firstOrNull;
    if (p == null) return null;
    final m = mealsOf(p).where((x) => x.id == widget.mealId).firstOrNull;
    if (m == null || widget.oi >= m.options.length) return null;
    final foods = m.options[widget.oi].foods;
    return widget.fi < foods.length ? foods[widget.fi] : null;
  }

  void _upd(PlanFood Function(PlanFood) fn) => widget.actions.updateFood(widget.mealId, widget.oi, widget.fi, fn);

  void _pickUnit(PlanFood f, FoodUnit u) {
    final gTot = f.qty * f.unitGrams;
    final nq = u.isGrams ? ((gTot / 5).round() * 5).clamp(5, 100000).toDouble() : ((gTot / u.grams * 2).round() / 2).clamp(.5, 1000).toDouble();
    _upd((x) => x.copyWith(
          unit: u.name,
          qty: nq,
          kcal: x.per100[0] * u.grams / 100,
          protein: x.per100[1] * u.grams / 100,
          carbs: x.per100[2] * u.grams / 100,
          fat: x.per100[3] * u.grams / 100,
        ));
    showToast(context, '${f.name} in ${u.isGrams ? 'grams' : u.name}', subtitle: '${portionLabel(f.qty, f.unit)} → ${portionLabel(nq, u.name)}', kind: ToastKind.ok);
  }

  void _openLibraryFood(String name) {
    final host = widget.actions.context;
    widget.close();
    Food? food;
    for (final f in ref.read(foodsProvider)) {
      if (f.name == name) food = f;
    }
    showFoodEditor(host, food: food, onSaved: (_) {}, onOpenPlan: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final f = _food();
    if (f == null) return Padding(padding: const EdgeInsets.all(20), child: Text('This food was removed.', style: AppText.secondary));
    final gTot = f.qty * f.unitGrams;
    final stepQ = f.unit == 'g' ? 5.0 : .5;
    final maxQ = f.unit == 'g' ? 2000.0 : 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const FoodThumb(tone: 1),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: AppText.bodyBold),
              Text('${f.per100[0].round()} kcal per 100 g · ${plural(f.units.length - 1, 'unit')} + grams', style: AppText.caption),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        FieldBlock(
          label: 'Amount',
          info: 'Changing the unit keeps the same amount in grams. Change the number to give more or less.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: NumStepper(
                  value: fq(f.qty),
                  onMinus: () => _upd((x) => x.copyWith(qty: (x.qty - stepQ).clamp(stepQ, maxQ))),
                  onPlus: () => _upd((x) => x.copyWith(qty: (x.qty + stepQ).clamp(stepQ, maxQ))),
                ),
              ),
              const SizedBox(width: 8),
              _UnitMenu(food: f, onPick: (u) => _pickUnit(f, u), onLibrary: () => _openLibraryFood(f.name)),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(8)),
              child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('${fq(gTot)} g', style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800)),
                Text('${fmtN(f.totalKcal)} kcal · P ${f.totalProtein.round()} g · C ${f.totalCarbs.round()} g · F ${f.totalFat.round()} g',
                    style: AppText.caption.copyWith(color: AppColors.text2, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _swaps(f),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            onPressed: () {
              widget.close();
              widget.actions.removeFood(widget.mealId, widget.oi, widget.fi);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Remove from meal'),
          ),
        ),
      ],
    );
  }

  Widget _swaps(PlanFood f) {
    final lib = LibraryMock.pickerFoods;
    final me = lib.where((x) => x.name == f.name).firstOrNull;
    final kTot = f.totalKcal;
    final base = [f.protein, f.carbs, f.fat];
    final cands = <(int, LibraryFood, String, int, int)>[];
    for (final x in lib) {
      if (x.name == f.name || f.alts.any((a) => a.name == x.name)) continue;
      if (!_swAll && me != null && x.group != me.group) continue;
      final c = LibraryMock.pickerTemplates[x.name];
      if (c == null || c.kcal == 0) continue;
      final m = macroMatch(base, [x.protein.toDouble(), x.carbs.toDouble(), x.fat.toDouble()]);
      final q = c.unit == 'g' ? ((kTot / c.kcal / 5).round() * 5).clamp(5, 100000).toDouble() : ((kTot / c.kcal * 2).round() / 2).clamp(.5, 1000).toDouble();
      cands.add((m, x, portionLabel(q, c.unit), (q * c.kcal).round(), (q * c.protein).round()));
    }
    cands.sort((a, b) => b.$1.compareTo(a.$1));
    final alts = [...f.alts]..sort((a, b) => b.match.compareTo(a.match));
    return FieldBlock(
      label: 'Swaps the client may use',
      info: 'The client can eat one of these instead. The amount is set to give about the same calories.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final a in alts)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
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
                onPressed: () => _upd((x) => x.copyWith(alts: x.alts.where((y) => y.name != a.name).toList())),
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
              ),
            ]),
          ),
        if (alts.isEmpty) Text('No swaps. The client has to eat this food.', style: AppText.caption),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => setState(() => _swOpen = !_swOpen), icon: const Icon(Icons.add_rounded, size: 17), label: const Text('Add alternative')),
        ),
        if (_swOpen)
          AltPicker(
            all: _swAll,
            onScope: (v) => setState(() => _swAll = v),
            footnote: 'Amounts give the same calories as ${portionLabel(f.qty, f.unit)}.',
            options: [
              for (final (m, x, por, k, p) in cands.take(6))
                AltOption(
                  name: x.name,
                  tone: x.name.length % 4 + 1,
                  match: m,
                  line: '$por · $k kcal · P $p g',
                  onAdd: () {
                    _upd((y) => y.copyWith(alts: [...y.alts, FoodAlt(x.name, por, m)]));
                    setState(() => _swOpen = false);
                    showToast(context, 'Alternative added', subtitle: '${x.name} for ${f.name}', kind: ToastKind.ok);
                  },
                ),
            ],
          ),
      ]),
    );
  }
}

class _UnitMenu extends StatelessWidget {
  const _UnitMenu({required this.food, required this.onPick, required this.onLibrary});
  final PlanFood food;
  final ValueChanged<FoodUnit> onPick;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final f = food;
    return PopupMenuButton<int>(
      tooltip: 'Units of ${f.name}',
      onSelected: (i) => i < 0 ? onLibrary() : onPick(f.units[i]),
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text('Units of ${f.name}', style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
        for (var i = 0; i < f.units.length; i++)
          PopupMenuItem(
            value: i,
            child: Row(children: [
              Expanded(child: Text(f.units[i].isGrams ? 'Grams' : f.units[i].name)),
              if (!f.units[i].isGrams) Text('${fq(f.units[i].grams)} g', style: AppText.caption),
              if (f.units[i].name == f.unit) ...[const SizedBox(width: 8), const Icon(Icons.check_rounded, size: 18, color: AppColors.accent)],
            ]),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: -1, child: Row(children: [Icon(Icons.add_rounded, size: 17), SizedBox(width: 8), Text('Add a unit in the food library')])),
      ],
      child: Container(
        height: 42,
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(10), color: Colors.white),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(f.unit == 'g' ? 'Grams' : f.unit, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text))),
          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
        ]),
      ),
    );
  }
}
