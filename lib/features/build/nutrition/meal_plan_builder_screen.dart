import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'builder_sheets.dart';
import 'builder_state.dart';
import 'library_widgets.dart';
import 'nutrition_state.dart';

const _okBar = Color(0xFF10B981);
const _overBar = Color(0xFFF59E0B);
const _underBar = Color(0xFF93B4FF);

/// Design: MealPlanBuilderMobile — a master meal plan: daily targets, meals
/// with options and foods, clients on the plan, permissions, publish.
class MealPlanBuilderScreen extends ConsumerStatefulWidget {
  const MealPlanBuilderScreen({super.key});

  @override
  ConsumerState<MealPlanBuilderScreen> createState() => _MealPlanBuilderScreenState();
}

class _MealPlanBuilderScreenState extends ConsumerState<MealPlanBuilderScreen> {
  /// Option shown per meal (the design's `oi`).
  final _oi = <String, int>{};

  int _optOf(Meal m) => (_oi[m.id] ?? m.defaultOption).clamp(0, m.options.length - 1);

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(openPlanProvider);
    final plans = ref.watch(mealPlansProvider);
    MealPlan? plan;
    for (final p in plans) {
      if (p.id == id) plan = p;
    }
    if (plan == null) {
      return PageScroll(children: [
        const SubPageHeader(title: 'Meal plan'),
        AppCard(
          child: EmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: 'This plan was deleted',
            message: 'Go back to Nutrition & foods to pick another plan.',
            action: AppButton.outline('Back', onPressed: () => context.pop()),
          ),
        ),
      ]);
    }
    final p = plan;
    final meals = mealsOf(p);
    final b = BuilderActions(context: context, ref: ref, plan: p, setOption: (mealId, i) => setState(() => _oi[mealId] = i));
    return PageScroll(
      children: [
        SubPageHeader(
          title: p.name,
          actions: [AppIconButton(Icons.more_horiz_rounded, tooltip: 'More options', onPressed: b.planMenu)],
        ),
        _TitleMeta(plan: p),
        _TopActions(plan: p, actions: b),
        if (p.dirty) _DraftBanner(clients: p.clients.length, onPublish: b.publish),
        _TargetsCard(targets: p.targets, planned: plannedOf(meals), onEdit: b.editTargets),
        for (final m in meals) _MealCard(meal: m, oi: _optOf(m), actions: b),
        DashedAddButton('Add meal', onTap: () => b.editMeal(null)),
        _ClientsCard(plan: p, onManage: b.clients),
        _PermsCard(plan: p),
        const GreyNote(
          icon: Icons.lightbulb_outline_rounded,
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'Meal options: ', style: TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(
                text: 'the client can pick any option of a meal. Keep every option within 5% of the meal target. Tap a food to set its portion and swaps.'),
          ])),
        ),
      ],
    );
  }
}

class _TitleMeta extends StatelessWidget {
  const _TitleMeta({required this.plan});
  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final n = plan.clients.length;
    final cu = plan.clients.where((c) => c.custom).length;
    final sub = '${plan.diet} · ${n > 0 ? 'Master plan · ${plural(n, 'client')}${cu > 0 ? ', ${plural(cu, 'custom version')}' : ''}' : 'Master plan · not assigned yet'}';
    return Row(
      children: [
        plan.dirty ? const AppBadge('Draft', tone: BadgeTone.warn) : const AppBadge('Published', tone: BadgeTone.ok),
        const SizedBox(width: 8),
        Expanded(child: Text(sub, style: AppText.secondary)),
      ],
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions({required this.plan, required this.actions});
  final MealPlan plan;
  final BuilderActions actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AppButton.outline(plural(plan.clients.length, 'client'), icon: Icons.group_outlined, expand: true, small: true, onPressed: actions.clients)),
        const SizedBox(width: 8),
        Expanded(child: AppButton.outline('Assign', icon: Icons.person_add_alt_rounded, expand: true, small: true, onPressed: actions.assign)),
        if (plan.dirty) ...[
          const SizedBox(width: 8),
          Expanded(child: AppButton('Publish', icon: Icons.send_rounded, expand: true, small: true, onPressed: actions.publish)),
        ],
      ],
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.clients, required this.onPublish});
  final int clients;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.warnText),
          const SizedBox(width: 8),
          Expanded(
            child: Text('You have changes the clients have not received yet. Publish to send them to ${plural(clients, 'client')}.',
                style: AppText.secondary.copyWith(color: AppColors.warnText, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          AppButton.outline('Publish now', small: true, onPressed: onPublish),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Targets
// ---------------------------------------------------------------------------

class _TargetsCard extends StatelessWidget {
  const _TargetsCard({required this.targets, required this.planned, required this.onEdit});
  final PlanTargets targets;
  final List<double> planned;
  final VoidCallback onEdit;

  Widget _cell(int i) {
    const keys = [('Calories', 'kcal'), ('Protein', 'g'), ('Carbs', 'g'), ('Fat', 'g')];
    final want = [targets.kcal, targets.protein, targets.carbs, targets.fat][i];
    final have = planned[i];
    final d = have - want;
    final ok = want == 0 || d.abs() / want <= .05;
    final (k, u) = keys[i];
    return _TargetCell(
      label: k,
      value: fmtN(want),
      unit: ' $u',
      fill: want == 0 ? 0 : (have / want).clamp(0, 1).toDouble(),
      color: ok ? _okBar : (d > 0 ? _overBar : _underBar),
      status: '${i == 0 ? 'Meals add up to ' : 'Planned '}${fmtN(have)} $u',
      statusColor: ok ? AppColors.okText : AppColors.warnText,
    );
  }

  @override
  Widget build(BuildContext context) {
    const v = VerticalDivider(width: 1);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: _cell(0)), v, Expanded(child: _cell(1)), v, Expanded(child: _cell(2))])),
          const Divider(height: 1),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _cell(3)),
              v,
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Fibre · Water', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${targets.fibre} g · ${fq(targets.water)} L', style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Daily', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppButton.outline('Edit targets', icon: Icons.tune_rounded, small: true, expand: true, onPressed: onEdit),
          ),
        ],
      ),
    );
  }
}

class _TargetCell extends StatelessWidget {
  const _TargetCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.fill,
    required this.color,
    required this.status,
    required this.statusColor,
  });
  final String label;
  final String value;
  final String unit;
  final double fill;
  final Color color;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: value),
              TextSpan(text: unit, style: AppText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyBold.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ProgressBar(fill, color: color, height: 5, track: AppColors.sub),
          const SizedBox(height: 5),
          Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meals
// ---------------------------------------------------------------------------

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.oi, required this.actions});
  final Meal meal;
  final int oi;
  final BuilderActions actions;

  @override
  Widget build(BuildContext context) {
    final m = meal;
    final o = m.options[oi];
    final t = totalsOf(o.foods);
    final diff = t[0] - m.target;
    final onTarget = m.target == 0 || diff.abs() / m.target <= .05;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
            child: Row(children: [
              const TintIcon(Icons.restaurant_rounded, tint: Tint.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name, style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  Text('${m.time} · target ${fmtN(m.target)} kcal', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
              AppBadge(onTarget ? 'On target' : (diff > 0 ? '${fmtN(diff)} kcal over' : '${fmtN(-diff)} kcal under'),
                  tone: onTarget ? BadgeTone.ok : BadgeTone.warn),
              DotsButton(onPressed: () => actions.mealMenu(m), tooltip: 'Meal options'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 4, 10),
            child: Row(children: [
              Expanded(
                child: Wrap(spacing: 4, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  for (var i = 0; i < m.options.length; i++)
                    _OptionPill(label: m.options[i].name, on: i == oi, isDefault: i == m.defaultOption, onTap: () => actions.setOption(m.id, i)),
                  _AddOptionButton(onTap: () => actions.addOptionMenu(m, oi)),
                ]),
              ),
              DotsButton(onPressed: () => actions.optionMenu(m, oi), tooltip: 'Option options'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              for (var fi = 0; fi < o.foods.length; fi++) _FoodLine(food: o.foods[fi], onTap: () => actions.portion(m, oi, fi)),
              if (o.foods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  child: Text('No foods yet. Use Add food to pick from the food library.', textAlign: TextAlign.center, style: AppText.secondary),
                ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBF9),
              border: Border(top: BorderSide(color: AppColors.line)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  TextButton.icon(onPressed: () => actions.addFood(m, oi), icon: const Icon(Icons.add_rounded, size: 17), label: const Text('Add food')),
                  const Spacer(),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${fmtN(t[0])} ', style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800)),
                    TextSpan(text: '/ ${fmtN(m.target)} kcal', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  ])),
                ]),
                Text('P ${t[1].round()} g · C ${t[2].round()} g · F ${t[3].round()} g', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.label, required this.on, required this.isDefault, required this.onTap});
  final String label;
  final bool on;
  final bool isDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? const Color(0xFFD5E1FB) : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: on ? AppColors.accentText : AppColors.text2)),
          if (isDefault) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: on ? Colors.white : AppColors.sub, borderRadius: BorderRadius.circular(5)),
              child: Text('Default', style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: on ? AppColors.accentText : AppColors.muted)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _AddOptionButton extends StatelessWidget {
  const _AddOptionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: DashedBorderPainter(radius: 8, strokeWidth: 1),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Text('Option', style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _FoodLine extends StatelessWidget {
  const _FoodLine({required this.food, required this.onTap});
  final PlanFood food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final f = food;
    final por = portionLabel(f.qty, f.unit) + (f.unit == 'g' ? '' : ' · ${fq(f.qty * f.unitGrams)} g');
    final muted = AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600);
    final n = f.alts.length;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoodThumb(tone: f.name.length % 4 + 1, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: fmtN(f.totalKcal), style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      TextSpan(text: ' kcal', style: muted.copyWith(fontSize: 11.5)),
                    ])),
                  ]),
                  Text(por, style: AppText.caption),
                  const SizedBox(height: 4),
                  Row(children: [
                    GreyTag(n > 0 ? plural(n, 'swap') : 'No swap', blue: n > 0, icon: Icons.swap_horiz_rounded),
                    const Spacer(),
                    Text('P ${f.totalProtein.round()}', style: muted),
                    const SizedBox(width: 10),
                    Text('C ${f.totalCarbs.round()}', style: muted),
                    const SizedBox(width: 10),
                    Text('F ${f.totalFat.round()}', style: muted),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Side cards
// ---------------------------------------------------------------------------

class _ClientsCard extends StatelessWidget {
  const _ClientsCard({required this.plan, required this.onManage});
  final MealPlan plan;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text('Clients on this plan', style: AppText.cardTitle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800))),
            TextButton(onPressed: onManage, child: const Text('Manage')),
          ]),
          for (final c in plan.clients)
            ClientLinkRow(
              name: c.name,
              subtitle: c.custom ? c.note : 'Follows the master plan',
              trailing: c.custom ? const AppBadge('Custom version', tone: BadgeTone.warn) : const AppBadge('Master', tone: BadgeTone.info),
              onTap: () => openClientByName(context, c.name),
            ),
          if (plan.clients.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: SideEmpty('Not assigned to anyone yet.')),
          const SizedBox(height: 8),
          Text('Changes to the master reach everyone. A version note keeps one client\'s changes.', style: AppText.caption.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _PermsCard extends ConsumerWidget {
  const _PermsCard({required this.plan});
  final MealPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Client permissions', style: AppText.cardTitle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final (i, t) in LibraryMock.planPermissions.indexed)
            InkWell(
              onTap: () => putPlan(ref, plan.id, (p) {
                final perms = [...p.perms];
                perms[i] = !perms[i];
                return p.copyWith(perms: perms, dirty: true);
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Text(t, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2))),
                  const SizedBox(width: 10),
                  TogSwitch(plan.perms[i]),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
