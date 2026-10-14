import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'food_state.dart';

/// Design: ClientNutrition.dc.html — today's calories, the week, water and the food log.
class NutritionOverviewScreen extends ConsumerStatefulWidget {
  const NutritionOverviewScreen({super.key});

  @override
  ConsumerState<NutritionOverviewScreen> createState() => _NutritionOverviewScreenState();
}

class _NutritionOverviewScreenState extends ConsumerState<NutritionOverviewScreen> {
  int _week = ClientMock.todayIndex;
  bool _logTab = false;

  FoodDayController get _ctl => ref.read(foodDayProvider.notifier);

  void _toFoodLog() => context.push(Routes.cFoodLog);

  void _toMealPlan() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.cFood);
    }
  }

  void _eat(int i) {
    final prev = ref.read(foodDayProvider);
    final mm = prev.mealMacros(i);
    _ctl.eat(i);
    final now = ref.read(foodDayProvider);
    final nt = now.total;
    final tg = FoodDay.targets.kcal;
    if (now.allEaten) {
      showToast(context, 'All meals logged for today',
          subtitle: '${nf(nt.kcal)} kcal${nt.kcal > tg ? ' · ${nf(nt.kcal - tg)} kcal over' : ''} · ${nt.protein.round()} g protein',
          kind: ToastKind.star,
          onUndo: () => _ctl.restore(prev));
    } else {
      final left = tg - nt.kcal;
      showToast(context, '${FoodDay.plan[i].name} logged',
          subtitle: '${nf(mm.kcal)} kcal · ${left >= 0 ? '${nf(left)} kcal left' : '${nf(-left)} kcal over'}',
          kind: ToastKind.ok,
          onUndo: () => _ctl.restore(prev));
    }
  }

  void _uneat(int i) {
    final prev = ref.read(foodDayProvider);
    final mm = prev.mealMacros(i);
    _ctl.uneat(i);
    showToast(context, '${FoodDay.plan[i].name} marked as not eaten',
        subtitle: '${nf(mm.kcal)} kcal removed from today', kind: ToastKind.del, onUndo: () => _ctl.restore(prev));
  }

  void _copyYesterday() {
    final prev = ref.read(foodDayProvider);
    final add = [for (final y in ClientMock.yesterday) if (!prev.extras.any((e) => e.id == y.id)) y];
    if (add.isEmpty) {
      showToast(context, 'Nothing to copy', subtitle: 'Yesterday’s extra foods are already in today’s log', kind: ToastKind.info);
      return;
    }
    _ctl.addEntries(add);
    setState(() => _logTab = true);
    showToast(context, 'Copied ${add.length}${add.length == 1 ? ' food' : ' foods'} from yesterday',
        subtitle: '${add.map((y) => y.name).join(', ')} · ${nf(add.fold<double>(0, (a, y) => a + y.macros.kcal))} kcal',
        kind: ToastKind.ok,
        onUndo: () => _ctl.restore(prev));
  }

  void _openMeal(int i) {
    final day = ref.read(foodDayProvider);
    final e = day.isEaten(i);
    final meal = FoodDay.plan[i];
    final mm = day.mealMacros(i);
    final canSwap = !e && meal.foods.any((f) => f.canSwap);
    showClientSheet<void>(
      context,
      builder: (ctx) {
        void then(VoidCallback f) {
          Navigator.of(ctx).pop();
          f();
        }

        return ClientSheet(
          title: e ? 'Add to ${meal.name}' : 'Log ${meal.name.toLowerCase()}',
          subtitle: e ? 'Already logged: ${mm.line}' : 'Plan: ${day.foodsSummary(i)}',
          body: MenuList(card: false, children: [
            if (!e)
              MenuRow(
                icon: Icons.check_rounded,
                iconBg: AppColors.okBg,
                iconFg: AppColors.okText,
                title: 'Ate as planned',
                subtitle: '${nf(mm.kcal)} kcal · ${mm.protein.round()} g P · one tap',
                onTap: () => then(() => _eat(i)),
              ),
            if (canSwap)
              MenuRow(
                icon: Icons.swap_horiz_rounded,
                title: 'Swap a food first',
                subtitle: 'Pick an option Aman approved',
                onTap: () => then(_toMealPlan),
              ),
            MenuRow(
              icon: Icons.search_rounded,
              title: 'Search food',
              subtitle: 'Log something that is not in the plan',
              onTap: () => then(_toFoodLog),
            ),
            if (e)
              MenuRow(
                icon: Icons.undo_rounded,
                title: 'Mark as not eaten',
                subtitle: 'Removes it from today’s totals',
                danger: true,
                onTap: () => then(() => _uneat(i)),
              ),
          ]),
        );
      },
    );
  }

  void _openEntry(FoodEntry en) {
    final meal = FoodDay.plan[en.mealIndex].name;
    showClientSheet<void>(
      context,
      builder: (ctx) => ClientSheet(
        title: en.name,
        subtitle: '$meal · ${en.amount} · ${nf(en.macros.kcal)} kcal',
        body: MenuList(card: false, children: [
          MenuRow(
            icon: Icons.add_rounded,
            title: 'Log more to $meal',
            subtitle: 'Search and add another food',
            onTap: () {
              Navigator.of(ctx).pop();
              _toFoodLog();
            },
          ),
          MenuRow(
            icon: Icons.delete_outline_rounded,
            title: 'Delete entry',
            subtitle: 'You can undo this',
            danger: true,
            onTap: () {
              Navigator.of(ctx).pop();
              final prev = ref.read(foodDayProvider);
              _ctl.removeEntry(en.id);
              showToast(context, 'Entry deleted', subtitle: '${en.name} · ${nf(en.macros.kcal)} kcal', kind: ToastKind.del, onUndo: () => _ctl.restore(prev));
            },
          ),
        ]),
      ),
    );
  }

  void _openCalories(Macros tot) {
    final tg = FoodDay.targets;
    final left = tg.kcal - tot.kcal;
    showClientSheet<void>(
      context,
      builder: (ctx) => ClientSheet(
        title: 'Today’s calories',
        subtitle: 'Target 1,650 kcal · set by Aman',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KvList([
              ('Eaten', '${nf(tot.kcal)} kcal'),
              (left < 0 ? 'Over' : 'Left', '${nf(left.abs())} kcal'),
              ('Protein', '${tot.protein.round()} / ${tg.protein.round()} g'),
              ('Carbs', '${tot.carbs.round()} / ${tg.carbs.round()} g'),
              ('Fat', '${tot.fat.round()} / ${tg.fat.round()} g'),
            ]),
            const SizedBox(height: 8),
            const Caption('Workout calories are not added back. Your plan already accounts for training.'),
          ],
        ),
        actions: [AppButton('Got it', onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(foodDayProvider);
    final tot = day.total;
    final rows = _logRows(day);
    return PageScroll(
      children: [
        ClientTop(
          title: 'Nutrition',
          subtitle: 'Today · ${nf(tot.kcal)} of ${nf(FoodDay.targets.kcal)} kcal',
          onBack: context.canPop() ? () => context.pop() : null,
          actions: [AppButton.dark('Log food', small: true, icon: Icons.add_rounded, onPressed: _toFoodLog)],
        ),
        _CaloriesCard(total: tot, onTap: () => _openCalories(tot)),
        _WeekCard(today: tot, selected: _week, onPick: (i) => setState(() => _week = i)),
        const _WaterCard(),
        SegmentedTabs<bool>(
          items: [(false, 'My plan'), (true, 'Food log · ${rows.length}')],
          value: _logTab,
          onChanged: (v) => setState(() => _logTab = v),
        ),
        if (!_logTab) ...[
          _PlanList(day: day, onTap: _openMeal),
          DashedButton(label: 'Open full meal plan · options and portions', icon: Icons.restaurant_menu_rounded, onTap: _toMealPlan),
        ] else ...[
          _LogList(rows: rows),
          Row(
            children: [
              Expanded(child: AppButton.dark('Log food', icon: Icons.add_rounded, onPressed: _toFoodLog)),
              const SizedBox(width: 10),
              Expanded(child: AppButton.outline('Copy yesterday', icon: Icons.copy_rounded, onPressed: _copyYesterday)),
            ],
          ),
        ],
      ],
    );
  }

  List<_LogRow> _logRows(FoodDay day) {
    final rows = <_LogRow>[
      for (final MapEntry(key: i, value: at) in day.eatenAt.entries)
        _LogRow(at, day.foodsSummary(i), '${FoodDay.plan[i].name} · from plan', '${nf(day.mealMacros(i).kcal)} kcal', () => _openMeal(i)),
      for (final e in day.extras)
        _LogRow(e.atMinute, e.name, '${FoodDay.plan[e.mealIndex].name} · ${e.amount}', '${nf(e.macros.kcal)} kcal', () => _openEntry(e)),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return rows;
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.total, required this.onTap});
  final Macros total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = FoodDay.targets;
    final left = tg.kcal - total.kcal;
    final over = left < 0;
    const macroColors = [AppColors.protein, Color(0xFFD9A100), Color(0xFFDB2777)];
    const names = ['Protein', 'Carbs', 'Fat'];
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Today’s calories', style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800))),
              Text('Target 1,650 kcal', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RingProgress(
                value: total.kcal / tg.kcal,
                size: 96,
                stroke: 10,
                color: over ? AppColors.warn : AppColors.accent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nf(left.abs()), style: AppText.bodyBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: over ? AppColors.warnText : AppColors.text)),
                    Text(over ? 'kcal over' : 'kcal left', style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (var k = 0; k < 3; k++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(names[k], style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                                Text('${total[k + 1].round()} / ${tg[k + 1].round()} g', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ProgressBar(total[k + 1] / tg[k + 1], color: macroColors[k]),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.today, required this.selected, required this.onPick});
  final Macros today;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final tg = FoodDay.targets.kcal;
    final wk = <(double, double)?>[
      for (final p in ClientMock.pastDays) (p.kcal, p.protein),
      (today.kcal.roundToDouble(), today.protein.roundToDouble()),
      null,
      null,
    ];
    final logged = [for (final d in wk) if (d != null && d.$1 > 0) d];
    final top = logged.fold<double>(tg, (a, d) => math.max(a, d.$1)) * 1.08;
    final ws = wk[selected];
    final isToday = selected == ClientMock.todayIndex;
    final sel = '${ClientMock.weekDays[selected]} ${5 + selected} Oct${isToday ? ' · today' : ''}';
    final selV = ws != null && ws.$1 > 0
        ? '${nf(ws.$1)} kcal · ${ws.$2.round()} g protein'
        : isToday
            ? 'Nothing logged yet today'
            : 'Not logged yet';
    final avg = logged.isEmpty
        ? 'Nothing logged this week yet'
        : 'Average ${nf(logged.fold<double>(0, (a, d) => a + d.$1) / logged.length)} kcal · '
            '${(logged.fold<double>(0, (a, d) => a + d.$2) / logged.length).round()} g protein on ${logged.length} logged days';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('This week', style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800))),
              Text('Target 1,650 kcal', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: LayoutBuilder(builder: (context, c) {
              final barArea = c.maxHeight - 18;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18 + barArea * tg / top,
                    child: Container(height: 1.5, color: AppColors.okText.withValues(alpha: .45)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _Bar(
                            label: ClientMock.weekDays[i][0],
                            frac: wk[i] == null ? 0 : math.max(.04, wk[i]!.$1 / top),
                            on: i == selected,
                            today: i == ClientMock.todayIndex,
                            none: wk[i] == null,
                            high: wk[i] != null && wk[i]!.$1 > tg * 1.03,
                            onTap: () => onPick(i),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(sel, style: AppText.bodyBold.copyWith(fontSize: 13)),
              const Spacer(),
              Text(selV, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Caption(avg),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.frac, required this.on, required this.today, required this.none, required this.high, required this.onTap});
  final String label;
  final double frac;
  final bool on;
  final bool today;
  final bool none;
  final bool high;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color c;
    if (none) {
      c = const Color(0xFFEDEDE9);
    } else if (on) {
      c = high ? const Color(0xFFF59E0B) : AppColors.accent;
    } else if (high) {
      c = const Color(0xFFFCD38A);
    } else if (today) {
      c = const Color(0xFF93B4F5);
    } else {
      c = const Color(0xFFD7DEEA);
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: on ? AppColors.sub : null, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, cs) => Container(
                  width: math.min(30, cs.maxWidth * .7),
                  height: none ? 4 : cs.maxHeight * frac,
                  decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppText.caption.copyWith(
                  fontSize: 11, fontWeight: FontWeight.w700, color: on ? AppColors.text : (today ? AppColors.accentText : AppColors.muted))),
        ],
      ),
    );
  }
}

/// Water: 250 ml glasses, goal 3 L (shared with the Habits water habit).
class _WaterCard extends ConsumerWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const goal = ClientMock.waterGoalMl;
    final ml = ref.watch(clientWaterProvider);
    final gl = (ml / 250).round();
    final leftG = math.max(0, ((goal - ml) / 250).ceil());
    String glasses(int n) => '$n${n == 1 ? ' glass' : ' glasses'}';

    void setWater(int d) {
      if (d < 0 && ml == 0) {
        showToast(context, 'Nothing to remove', subtitle: 'No water logged yet', kind: ToastKind.info);
        return;
      }
      final now = ml + d, lw = goal - now, g = (lw / 250).ceil();
      ref.read(clientWaterProvider.notifier).set(now);
      if (d > 0 && ml < goal && now >= goal) {
        showToast(context, 'Water goal complete!', subtitle: '${litres(now)} today', kind: ToastKind.star);
      } else if (lw > 0) {
        showToast(context, d > 0 ? '${litres(lw)} to go' : 'Removed 250 ml · ${litres(now)} logged',
            subtitle: '${glasses(g)} more', kind: d > 0 ? ToastKind.water : ToastKind.info);
      } else {
        showToast(context, '${litres(now)} today', subtitle: 'Goal complete', kind: ToastKind.water);
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHead(
            icon: Icons.water_drop_rounded,
            tint: Tint.orange,
            title: 'Water',
            subtitle: ml >= goal ? 'Goal complete · nice work' : '${litres(goal - ml)} to go · ${glasses(leftG)} more',
          ),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: litres(ml), style: AppText.bigNumber.copyWith(fontSize: 26)),
            TextSpan(text: '  / 3 L · ${glasses(gl)}', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 12; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(color: i < gl ? const Color(0xFF60A5FA) : const Color(0xFFEDEDE9), borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppButton.outline('−250 ml', small: true, onPressed: () => setWater(-250))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: AppButton.dark('+250 ml · 1 glass', small: true, onPressed: () => setWater(250))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.day, required this.onTap});
  final FoodDay day;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final next = day.eatenAt.length == FoodDay.plan.length ? -1 : List.generate(FoodDay.plan.length, (i) => i).firstWhere((i) => !day.isEaten(i));
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < FoodDay.plan.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _PlanRow(day: day, index: i, next: i == next, onTap: () => onTap(i)),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.day, required this.index, required this.next, required this.onTap});
  final FoodDay day;
  final int index;
  final bool next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = FoodDay.plan[index];
    final e = day.isEaten(index);
    final mm = day.mealMacros(index);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: e ? const Color(0xFF22C55E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: e ? const Color(0xFF22C55E) : (next ? AppColors.accent : AppColors.line2), width: 1.5),
              ),
              child: e ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: m.name, style: AppText.bodyBold),
                    TextSpan(text: ' · ${m.time}', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  ])),
                  Text(day.foodsSummary(index), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.text2)),
                  Text(
                    e ? 'Logged ${clock(day.eatenAt[index]!)} · ${nf(mm.kcal)} kcal' : 'Plan: ${nf(mm.kcal)} kcal · ${mm.protein.round()} g P',
                    style: AppText.caption.copyWith(fontSize: 11.5, color: e ? AppColors.okText : AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!e)
              next ? AppButton('Log', small: true, onPressed: onTap) : AppButton.outline('Log', small: true, onPressed: onTap)
            else
              const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _LogRow {
  const _LogRow(this.at, this.title, this.subtitle, this.kcal, this.onTap);
  final int at;
  final String title;
  final String subtitle;
  final String kcal;
  final VoidCallback onTap;
}

class _LogList extends StatelessWidget {
  const _LogList({required this.rows});
  final List<_LogRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: rows.isEmpty
          ? Padding(padding: const EdgeInsets.all(16), child: Text('Nothing logged yet today.', style: AppText.secondary, textAlign: TextAlign.center))
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  InkWell(
                    onTap: rows[i].onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 58, child: Text(clock(rows[i].at), style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rows[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                                Text(rows[i].subtitle, style: AppText.caption),
                              ],
                            ),
                          ),
                          Text(rows[i].kcal, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
