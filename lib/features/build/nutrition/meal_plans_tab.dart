import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'library_widgets.dart';
import 'nutrition_state.dart';

const _fatColor = Color(0xFF10B981);

/// Opens the meal plan builder for [id] in the current role's shell.
void openPlanBuilder(BuildContext context, WidgetRef ref, String id) {
  ref.read(openPlanProvider.notifier).open(id);
  context.push(context.rolePath(Routes.mealPlanBuilder));
}

/// Meal plans tab: search, diet filter, plan cards.
class MealPlansTab extends ConsumerStatefulWidget {
  const MealPlansTab({super.key});

  @override
  ConsumerState<MealPlansTab> createState() => _MealPlansTabState();
}

class _MealPlansTabState extends ConsumerState<MealPlansTab> {
  String _diet = 'All';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(mealPlansProvider);
    final items = plans
        .where((p) => (_diet == 'All' || p.diet == _diet) && p.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return Spaced(
      children: [
        SearchField(hint: 'Search plans', onChanged: (v) => setState(() => _q = v)),
        PillTabs<String>(
          items: [
            for (final d in LibraryMock.planDiets) (d, d, d == 'All' ? plans.length : plans.where((p) => p.diet == d).length),
          ],
          value: _diet,
          onChanged: (d) => setState(() => _diet = d),
        ),
        for (final p in items) _PlanCard(plan: p),
        if (items.isEmpty)
          const AppCard(
            child: EmptyState(icon: Icons.restaurant_menu_rounded, title: 'No plans found', message: 'Try another diet, or make a new plan.'),
          ),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});
  final MealPlan plan;

  void _menu(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(mealPlansProvider.notifier);
    showActionSheet(context, title: plan.name, actions: [
      SheetAction('Open in builder', Icons.open_in_new_rounded, () => openPlanBuilder(context, ref, plan.id)),
      SheetAction('Duplicate · same meals, no clients', Icons.copy_rounded, () {
        final before = ref.read(mealPlansProvider);
        ctl.duplicate(plan);
        showToast(context, 'Plan duplicated', subtitle: 'Same meals, no clients', kind: ToastKind.ok, onUndo: () => ctl.restore(before));
      }),
      SheetAction('Delete', Icons.delete_outline_rounded, () async {
        final n = plan.clients.length;
        final ok = await showConfirmDialog(
          context,
          title: 'Delete this plan?',
          message: '${plan.name} is removed for good${n > 0 ? ' and taken off ${plural(n, 'client')}' : ''}. Meals they already logged stay.',
          confirmLabel: 'Delete',
          destructive: true,
          icon: Icons.delete_outline_rounded,
        );
        if (!ok || !context.mounted) return;
        final before = ref.read(mealPlansProvider);
        ctl.remove(plan.id);
        showToast(context, 'Plan deleted', subtitle: plan.name, kind: ToastKind.del, onUndo: () => ctl.restore(before));
      }, destructive: true),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = plan.targets;
    final custom = plan.clients.where((c) => c.custom).length;
    return AppCard(
      onTap: () => openPlanBuilder(context, ref, plan.id),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TintIcon(Icons.restaurant_menu_rounded, tint: Tint.green, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${plan.diet} · ${plan.mealNames.length} meals · ${plan.optionCount} meal options',
                        style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              DotsButton(onPressed: () => _menu(context, ref), tooltip: 'Plan options'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(fmtN(t.kcal), style: AppText.bigNumber.copyWith(fontSize: 24)),
                    const SizedBox(width: 6),
                    Text('kcal / day', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    plan.isLive ? const AppBadge('Published', tone: BadgeTone.ok) : const AppBadge('Draft', tone: BadgeTone.warn),
                  ],
                ),
                const SizedBox(height: 10),
                MacroBar(protein: t.protein, carbs: t.carbs, fat: t.fat),
                const SizedBox(height: 10),
                Wrap(spacing: 14, runSpacing: 4, children: [
                  _Legend(AppColors.protein, 'Protein', t.protein),
                  _Legend(AppColors.carbs, 'Carbs', t.carbs),
                  _Legend(_fatColor, 'Fat', t.fat),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final m in plan.mealNames) GreyTag(m)]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _PlanFoot(plan: plan, custom: custom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFoot extends StatelessWidget {
  const _PlanFoot({required this.plan, required this.custom});
  final MealPlan plan;
  final int custom;

  @override
  Widget build(BuildContext context) {
    final cl = plan.clients;
    return Row(
      children: [
        if (cl.isNotEmpty) ...[
          AvatarStack([for (final c in cl.take(3)) Avatar.initialsOf(c.name)], size: 24),
          const SizedBox(width: 6),
          Flexible(
            child: Text('${plural(cl.length, 'client')}${custom > 0 ? ' · $custom custom' : ''}',
                overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
          ),
        ] else ...[
          const Icon(Icons.person_off_outlined, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text('Not assigned yet', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
        const Spacer(),
        Text('Edited ${plan.edited}', style: AppText.caption.copyWith(fontSize: 12.5)),
      ],
    );
  }
}

/// Protein / carbs / fat split bar (nu-mb), by calories.
class MacroBar extends StatelessWidget {
  const MacroBar({super.key, required this.protein, required this.carbs, required this.fat});
  final int protein;
  final int carbs;
  final int fat;

  @override
  Widget build(BuildContext context) {
    final tot = protein * 4 + carbs * 4 + fat * 9;
    final wp = tot == 0 ? 1 : (protein * 400 / tot).round();
    final wc = tot == 0 ? 1 : (carbs * 400 / tot).round();
    final wf = tot == 0 ? 1 : 100 - wp - wc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(children: [
          Expanded(flex: wp.clamp(1, 100), child: const ColoredBox(color: AppColors.protein)),
          const SizedBox(width: 2),
          Expanded(flex: wc.clamp(1, 100), child: const ColoredBox(color: AppColors.carbs)),
          const SizedBox(width: 2),
          Expanded(flex: wf.clamp(1, 100), child: const ColoredBox(color: _fatColor)),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label, this.grams);
  final Color color;
  final String label;
  final int grams;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '$label '),
            TextSpan(text: '$grams g', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
          ]),
          style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// New meal plan
// ---------------------------------------------------------------------------

/// "New meal plan" sheet. Creates a draft with four empty meals and opens it
/// in the builder.
void showNewPlanSheet(BuildContext context, WidgetRef ref) {
  showAppSheet(
    context,
    title: 'New meal plan',
    subtitle: 'Starts with four empty meals. You can change everything.',
    builder: (ctx) => _NewPlanForm(onCreate: (name, diet, kcal) {
      Navigator.of(ctx).pop();
      final plan = _newPlan(ref.read(mealPlansProvider).length, name, diet, kcal);
      ref.read(mealPlansProvider.notifier).add(plan);
      showToast(context, 'Plan created', subtitle: '${plan.name} · draft', kind: ToastKind.ok);
      openPlanBuilder(context, ref, plan.id);
    }),
  );
}

MealPlan _newPlan(int n, String name, String diet, int kcal) {
  int r5(double v) => (v / 5).round() * 5;
  const split = [('Breakfast', '8:00 am', .25), ('Lunch', '1:30 pm', .30), ('Snack', '5:00 pm', .15), ('Dinner', '8:30 pm', .30)];
  final id = 'np-new-$n';
  final meals = [
    for (var i = 0; i < split.length; i++)
      Meal(id: '$id-m$i', name: split[i].$1, time: split[i].$2, target: r5(kcal * split[i].$3), options: const [MealOption('Option A', [])]),
  ];
  return MealPlan(
    id: id,
    name: name,
    diet: diet,
    targets: PlanTargets(kcal, r5(kcal * .3 / 4), r5(kcal * .45 / 4), r5(kcal * .25 / 9)),
    mealNames: [for (final m in meals) m.name],
    optionCount: meals.length,
    dirty: true,
    meals: meals,
  );
}

class _NewPlanForm extends StatefulWidget {
  const _NewPlanForm({required this.onCreate});
  final void Function(String name, String diet, int kcal) onCreate;

  @override
  State<_NewPlanForm> createState() => _NewPlanFormState();
}

class _NewPlanFormState extends State<_NewPlanForm> {
  final _name = TextEditingController();
  String _diet = 'Veg';
  int _kcal = 2000;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Give the plan a name');
      return;
    }
    widget.onCreate(n, _diet, _kcal);
  }

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 14,
      children: [
        LabeledField(label: 'Plan name *', hint: 'e.g. Cut · Veg', controller: _name, error: _error, onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        }),
        FieldBlock(
          label: 'Diet type',
          child: PillTabs<String>(
            expand: true,
            items: const [('Veg', 'Veg', null), ('Eggetarian', 'Eggetarian', null), ('Non-veg', 'Non-veg', null), ('Vegan', 'Vegan', null)],
            value: _diet,
            onChanged: (d) => setState(() => _diet = d),
          ),
        ),
        FieldBlock(
          label: 'Calories per day',
          hint: 'Breakfast, Lunch, Snack and Dinner split this target. Protein, carbs and fat can be set in the builder.',
          child: NumStepper(
            value: fmtN(_kcal),
            unit: 'kcal',
            onMinus: () => setState(() => _kcal = (_kcal - 50).clamp(1200, 4000)),
            onPlus: () => setState(() => _kcal = (_kcal + 50).clamp(1200, 4000)),
          ),
        ),
        SheetButtons(children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
          AppButton('Create plan', icon: Icons.check_rounded, onPressed: _create),
        ]),
      ],
    );
  }
}
