import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'food_state.dart';
import 'meal_plan_sheets.dart';

/// Design: ClientFood.dc.html — Food tab root: Riya's meal plan for the week.
class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  static const _today = ClientMock.todayIndex;
  int _day = _today;

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(foodDayProvider);
    return PageScroll(
      children: [
        ClientTop(
          title: 'Meal plan',
          subtitle: 'Vegetarian · 1,650 kcal · by Aman',
          actions: [AppButton.dark('Log food', small: true, icon: Icons.add_rounded, onPressed: () => context.push(Routes.cFoodLog))],
        ),
        Align(alignment: Alignment.centerLeft, child: _MadeForYouButton(onTap: () => showMadeForYouSheet(context))),
        WeekStrip(
          selected: _day,
          onPick: (i) => setState(() => _day = i),
          days: [
            for (var i = 0; i < 7; i++)
              WeekDay(ClientMock.weekDays[i], 5 + i, today: i == _today, done: i < _today || (i == _today && day.allEaten)),
          ],
        ),
        _DayTotals(day: day, dayIndex: _day),
        for (var i = 0; i < FoodDay.plan.length; i++) _MealCard(day: day, mealIndex: i, dayIndex: _day),
        DashedButton(label: 'Ate something else', icon: Icons.search_rounded, onTap: () => context.push(Routes.cFoodLog)),
      ],
    );
  }
}

class _MadeForYouButton extends StatelessWidget {
  const _MadeForYouButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF8A5300);
    return Material(
      color: const Color(0xFFFFF8E6),
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFFF6D99B))),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: fg),
              const SizedBox(width: 6),
              Text('Personalised for you by Aman', style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 15, color: fg.withValues(alpha: .7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Totals card: kcal / protein / carbs / fat with bars, and the day line.
class _DayTotals extends StatelessWidget {
  const _DayTotals({required this.day, required this.dayIndex});
  final FoodDay day;
  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    const today = ClientMock.todayIndex;
    final isToday = dayIndex == today, past = dayIndex < today;
    final n = FoodDay.plan.length;
    final Macros? tot = isToday ? day.total : (past ? ClientMock.pastDays[dayIndex] : null);
    final dateL = '${ClientMock.weekDays[dayIndex]} ${5 + dayIndex} Oct';
    final String line;
    final String pill;
    final PillTone tone;
    if (isToday) {
      line = '${day.allEaten ? 'All $n meals logged · ' : '${day.eatenCount} of $n meals logged · '}${nf(tot!.kcal)} kcal';
      pill = day.allEaten ? 'Complete' : 'Today';
      tone = day.allEaten ? PillTone.green : PillTone.blue;
    } else if (past) {
      line = '$dateL · $n of $n meals logged · ${nf(tot!.kcal)} kcal';
      pill = 'Done';
      tone = PillTone.green;
    } else {
      line = '$dateL · planned';
      pill = 'Upcoming';
      tone = PillTone.gray;
    }
    const labels = ['kcal', 'Protein', 'Carbs', 'Fat'];
    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var k = 0; k < 4; k++) ...[
                if (k > 0) const SizedBox(width: 8),
                Expanded(child: _TotalCell(label: labels[k], index: k, value: tot?[k])),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(line, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2))),
              Pill(pill, tone: tone),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({required this.label, required this.index, required this.value});
  final String label;
  final int index;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final tg = FoodDay.targets[index];
    final v = value;
    final over = v != null && v > tg * 1.05;
    final valueText = v == null ? '—' : (index == 0 ? nf(v) : '${v.round()} g');
    final barColor = over ? const Color(0xFFF59E0B) : (index == 0 ? AppColors.accent : const Color(0xFF22C55E));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(valueText,
            maxLines: 1,
            style: AppText.bodyBold.copyWith(fontSize: 17, fontWeight: FontWeight.w800, color: over ? const Color(0xFFA15C00) : AppColors.text)),
        Text('of ${index == 0 ? nf(tg) : '${tg.round()} g'}', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
        if (v != null)
          Padding(padding: const EdgeInsets.only(top: 4, bottom: 2), child: ProgressBar(v / tg, height: 4, color: barColor, track: AppColors.sub)),
        Text(label.toUpperCase(), style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .5)),
      ],
    );
  }
}

/// One meal of the selected day with its foods and actions.
class _MealCard extends ConsumerWidget {
  const _MealCard({required this.day, required this.mealIndex, required this.dayIndex});
  final FoodDay day;
  final int mealIndex;
  final int dayIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const today = ClientMock.todayIndex;
    final i = mealIndex;
    final meal = FoodDay.plan[i];
    final isToday = dayIndex == today, past = dayIndex < today, future = dayIndex > today;
    final eaten = isToday ? day.isEaten(i) : past;
    final skipped = isToday && day.isSkipped(i);
    final next = isToday && i == day.nextMeal;
    final mac = isToday ? day.mealMacros(i) : day.planMacros(i);
    final pill = past ? 'Logged' : future ? 'Planned' : eaten ? 'Logged' : skipped ? 'Skipped' : next ? 'Next' : 'Planned';
    final tone = switch (pill) { 'Logged' => PillTone.green, 'Skipped' => PillTone.amber, 'Next' => PillTone.blue, _ => PillTone.gray };
    final open = isToday && !eaten && !skipped;
    final actions = MealActions(context, ref);

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: next ? const Color(0xFFBFD3FB) : AppColors.line),
        boxShadow: next ? const [BoxShadow(color: AppColors.accentSoft, spreadRadius: 3)] : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: meal.name, style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                      TextSpan(text: ' · ${meal.time}', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
                    ])),
                    const SizedBox(height: 1),
                    Text(skipped ? 'Skipped · not counted today' : mac.line, style: AppText.caption),
                  ],
                ),
              ),
              Pill(pill, tone: tone),
              if (isToday) ...[
                const SizedBox(width: 6),
                AppIconButton(Icons.more_horiz_rounded, small: true, tooltip: 'Meal options', onPressed: () => actions.openMenu(i)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          for (var fi = 0; fi < meal.foods.length; fi++) _FoodRow(day: day, mealIndex: i, foodIndex: fi, isToday: isToday, canSwapMeal: open),
          if (open) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: AppButton.outline('Edit portions', small: true, icon: Icons.tune_rounded, onPressed: () => actions.openPortions(i))),
                const SizedBox(width: 8),
                Expanded(
                  child: next
                      ? AppButton('Mark as eaten', small: true, icon: Icons.check_rounded, onPressed: () => actions.eat(i))
                      : AppButton.dark('Mark as eaten', small: true, icon: Icons.check_rounded, onPressed: () => actions.eat(i)),
                ),
              ],
            ),
          ],
          if (isToday && eaten) ...[
            const SizedBox(height: 8),
            AppButton.outline('Logged · Undo', small: true, icon: Icons.check_circle_rounded, onPressed: () => actions.undoEaten(i)),
          ],
          if (skipped) ...[
            const SizedBox(height: 8),
            AppButton.outline('Eaten after all', small: true, icon: Icons.undo_rounded, onPressed: () => actions.eat(i)),
          ],
        ],
      ),
    );
    return skipped ? Opacity(opacity: .75, child: card) : card;
  }
}

class _FoodRow extends ConsumerWidget {
  const _FoodRow({required this.day, required this.mealIndex, required this.foodIndex, required this.isToday, required this.canSwapMeal});
  final FoodDay day;
  final int mealIndex;
  final int foodIndex;
  final bool isToday;
  final bool canSwapMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = FoodDay.plan[mealIndex].foods[foodIndex];
    final o = isToday ? day.foodAt(mealIndex, foodIndex) : null;
    final food = o?.food ?? base;
    final qty = o?.qty ?? base.qty;
    final canSwap = canSwapMeal && base.canSwap;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text.rich(TextSpan(
                  style: AppText.caption,
                  children: [
                    TextSpan(text: amountOf(food.unit, qty)),
                    if (o != null && o.swapped)
                      TextSpan(text: ' · swapped from ${base.name}', style: const TextStyle(color: AppColors.accentText, fontWeight: FontWeight.w600)),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${(food.per.kcal * qty).round()} kcal', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          if (canSwap) ...[
            const SizedBox(width: 8),
            AppButton.outline('Swap', small: true, icon: Icons.swap_horiz_rounded, onPressed: () => MealActions(context, ref).openSwap(mealIndex, foodIndex)),
          ],
        ],
      ),
    );
  }
}
