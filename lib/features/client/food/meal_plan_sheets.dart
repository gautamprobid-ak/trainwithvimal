import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'food_state.dart';

/// "Made for you" sheet: what Aman changed in the plan.
void showMadeForYouSheet(BuildContext context) {
  showClientSheet<void>(
    context,
    builder: (ctx) => ClientSheet(
      title: 'Made for you',
      subtitle: 'Aman adjusted this plan for you',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KvList(ClientMock.madeForYou),
          const SizedBox(height: 8),
          const Caption('Want something changed? Tell Aman in your weekly check-in.'),
        ],
      ),
      actions: [AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop())],
    ),
  );
}

/// Meal plan actions (eat, undo, skip, swap, portions) with their toasts.
class MealActions {
  MealActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  FoodDayController get _ctl => ref.read(foodDayProvider.notifier);
  FoodDay get _day => ref.read(foodDayProvider);

  void eat(int i) {
    final prev = _day;
    final m = prev.mealMacros(i);
    _ctl.eat(i);
    final now = _day;
    if (now.allEaten) {
      final t = now.eatenMealsTotal;
      showToast(context, 'All meals logged for today',
          subtitle: '${nf(t.kcal)} kcal · ${t.protein.round()} g protein', kind: ToastKind.star, onUndo: () => _ctl.restore(prev));
    } else {
      showToast(context, '${FoodDay.plan[i].name} logged', subtitle: '${nf(m.kcal)} kcal', kind: ToastKind.ok, onUndo: () => _ctl.restore(prev));
    }
  }

  void undoEaten(int i) {
    final prev = _day;
    final m = prev.mealMacros(i);
    _ctl.uneat(i);
    showToast(context, '${FoodDay.plan[i].name} un-logged',
        subtitle: '${nf(m.kcal)} kcal removed from today', kind: ToastKind.del, onUndo: () => _ctl.restore(prev));
  }

  void skip(int i) {
    final prev = _day;
    _ctl.skip(i);
    showToast(context, '${FoodDay.plan[i].name} skipped',
        subtitle: 'Try to get your protein in the next meal', kind: ToastKind.warn, onUndo: () => _ctl.restore(prev));
  }

  /// Meal options sheet (⋯ on a meal card).
  void openMenu(int i) {
    final day = _day;
    final meal = FoodDay.plan[i];
    final firstSwap = meal.foods.indexWhere((f) => f.canSwap);
    showClientSheet<void>(
      context,
      builder: (ctx) {
        void then(VoidCallback f) {
          Navigator.of(ctx).pop();
          f();
        }

        return ClientSheet(
          title: '${meal.name} · ${meal.time}',
          subtitle: '${nf(day.mealMacros(i).kcal)} kcal planned',
          body: MenuList(
            card: false,
            children: [
              if (firstSwap >= 0)
                MenuRow(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Swap a food',
                  subtitle: 'Similar macros, different dish',
                  onTap: () => then(() => openSwap(i, firstSwap)),
                ),
              MenuRow(
                icon: Icons.tune_rounded,
                title: 'Edit portions',
                subtitle: 'Change grams, pieces or katori',
                onTap: () => then(() => openPortions(i)),
              ),
              MenuRow(
                icon: Icons.search_rounded,
                title: 'Log something different',
                subtitle: 'Ate outside the plan? No stress',
                onTap: () => then(() => context.push(Routes.cFoodLog)),
              ),
              if (!day.isSkipped(i))
                MenuRow(
                  icon: Icons.block_rounded,
                  title: 'Skip meal',
                  subtitle: 'It will not count towards today',
                  danger: true,
                  onTap: () => then(() => skip(i)),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Swap sheet: pick one of the coach-approved alternatives (today only).
  void openSwap(int mi, int fi0) {
    var fi = fi0;
    var pick = _day.swaps['$mi:$fi'] ?? -1;
    showClientSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final meal = FoodDay.plan[mi];
          final base = meal.foods[fi];
          final cur = _day.swaps['$mi:$fi'] ?? -1;
          final bm = base.defaultMacros;
          final swappable = [for (var j = 0; j < meal.foods.length; j++) if (meal.foods[j].canSwap) j];
          final opts = <(Food, int)>[(base, -1), for (var j = 0; j < base.alts.length; j++) (base.alts[j], j)];
          final same = pick == cur;
          final label = pick == -1 && cur != -1 ? 'Back to ${base.name}' : 'Swap';

          void go() {
            if (same) return;
            final prev = _day;
            final alt = pick >= 0 ? base.alts[pick] : null;
            _ctl.setSwap(mi, fi, alt == null ? null : pick);
            Navigator.of(ctx).pop();
            if (alt != null) {
              showToast(context, 'Swapped: ${base.name} → ${alt.name}',
                  subtitle: '${amountOf(alt.unit, alt.qty)} · ${alt.defaultMacros.kcal.round()} kcal · today only',
                  kind: ToastKind.ok,
                  onUndo: () => _ctl.restore(prev));
            } else {
              showToast(context, '${base.name} is back in your ${meal.name}', subtitle: 'Swap removed', kind: ToastKind.info, onUndo: () => _ctl.restore(prev));
            }
          }

          return ClientSheet(
            title: 'Swap from ${meal.name}',
            subtitle: '${base.name} · ${amountOf(base.unit, base.qty)} · ${bm.kcal.round()} kcal · ${bm.protein.round()} g P',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (swappable.length > 1) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final j in swappable)
                        ChoicePill(meal.foods[j].name, selected: j == fi, onTap: () => setSheet(() {
                              fi = j;
                              pick = _day.swaps['$mi:$j'] ?? -1;
                            })),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const _ApprovedLine(),
                const SizedBox(height: 10),
                for (final (f, idx) in opts) ...[
                  RadioOption(
                    selected: idx == pick,
                    onTap: () => setSheet(() => pick = idx),
                    title: Row(children: [
                      Flexible(child: Text(f.name)),
                      if (idx == -1) ...[const SizedBox(width: 8), const Tag('Planned')],
                    ]),
                    subtitle: '${amountOf(f.unit, f.qty)} · ${f.defaultMacros.kcal.round()} kcal · ${f.defaultMacros.protein.round()} g P',
                    trailing: f.match == null ? null : _MatchBadge(f.match!),
                  ),
                  const SizedBox(height: 8),
                ],
                DashedButton(
                  label: 'Search any other food',
                  icon: Icons.search_rounded,
                  small: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(Routes.cFoodLog);
                  },
                ),
              ],
            ),
            footer: Row(
              children: [
                Expanded(child: Text('Applies to today’s plan only', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                AppButton(label, icon: Icons.swap_horiz_rounded, onPressed: same ? null : go),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Edit portions sheet (draft until Save; today only).
  void openPortions(int mi) {
    final draft = <String, double>{};
    showClientSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final day = _day;
          final meal = FoodDay.plan[mi];
          final plan = day.mealMacros(mi), now = day.mealMacros(mi, draft);
          final d = (now.kcal - plan.kcal).round();
          final diff = d == 0 ? 'Same as now' : '${d > 0 ? '+' : '−'}${d.abs()} kcal';
          return ClientSheet(
            title: 'Edit portions · ${meal.name}',
            subtitle: '${meal.time} · ${nf(plan.kcal)} kcal now',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var fi = 0; fi < meal.foods.length; fi++)
                  Builder(builder: (_) {
                    final o = day.foodAt(mi, fi);
                    final q = draft[o.key] ?? o.qty;
                    final step = o.food.unit == 'g' ? 10.0 : o.food.step;
                    void set(int dir) => setSheet(() {
                          final v = ((q + dir * step) * 10).round() / 10;
                          draft[o.key] = v < step ? step : v;
                        });
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(border: fi == 0 ? null : const Border(top: BorderSide(color: AppColors.line))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.food.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                                Text('${(o.food.per.kcal * q).round()} kcal · ${(o.food.per.protein * q).round()} g P', style: AppText.caption),
                              ],
                            ),
                          ),
                          QtyStepper(value: amountOf(o.food.unit, q), onMinus: () => set(-1), onPlus: () => set(1)),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(child: Text(now.line, style: AppText.bodyBold.copyWith(fontSize: 13))),
                      const SizedBox(width: 8),
                      Text(diff, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Caption('Calories and macros follow your portions. This changes today only.'),
              ],
            ),
            actions: [
              AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
              AppButton('Save portions', onPressed: () {
                final prev = _day;
                _ctl.savePortions(draft);
                Navigator.of(ctx).pop();
                showToast(context, '${meal.name} portions saved',
                    subtitle: 'Now ${nf(now.kcal)} kcal · ${now.protein.round()} g protein', kind: ToastKind.ok, onUndo: () => _ctl.restore(prev));
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ApprovedLine extends StatelessWidget {
  const _ApprovedLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_rounded, size: 16, color: AppColors.okText),
        const SizedBox(width: 6),
        Expanded(
          child: Text('Approved by Aman · portions matched to your plan',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.okText)),
        ),
        const Tooltip(
          message: 'Each option is portioned to match the planned food. Match % compares calories, protein and fat.',
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline_rounded, size: 16, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge(this.match);
  final int match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(99)),
      child: Text('$match% match', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.okText)),
    );
  }
}
