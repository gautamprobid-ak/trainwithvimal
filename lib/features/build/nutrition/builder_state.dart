import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'nutrition_state.dart';

/// Meals of a plan. Plans that were never opened start from the design's
/// master meals (the builder in the design always shows them).
List<Meal> mealsOf(MealPlan p) => p.meals ?? LibraryMock.meals;

/// kcal, protein, carbs, fat of a list of foods.
List<double> totalsOf(List<PlanFood> foods) => foods.fold(
      [0.0, 0.0, 0.0, 0.0],
      (a, f) => [a[0] + f.totalKcal, a[1] + f.totalProtein, a[2] + f.totalCarbs, a[3] + f.totalFat],
    );

/// What the default options of every meal add up to.
List<double> plannedOf(List<Meal> meals) => meals.fold([0.0, 0.0, 0.0, 0.0], (a, m) {
      final t = totalsOf(m.options[m.defaultOption.clamp(0, m.options.length - 1)].foods);
      return [for (var i = 0; i < 4; i++) a[i] + t[i]];
    });

/// Saves edited meals into the plan and marks it as changed (draft).
void putMeals(WidgetRef ref, String planId, List<Meal> meals) {
  ref.read(mealPlansProvider.notifier).update(
        planId,
        (p) => p.copyWith(
          meals: meals,
          mealNames: [for (final m in meals) m.name],
          optionCount: meals.fold<int>(0, (a, m) => a + m.options.length),
          dirty: true,
          edited: 'just now',
        ),
      );
}

/// Updates one plan without touching its meals.
void putPlan(WidgetRef ref, String planId, MealPlan Function(MealPlan) fn) => ref.read(mealPlansProvider.notifier).update(planId, fn);

List<Meal> editMeal(List<Meal> ms, String mealId, Meal Function(Meal) fn) => [for (final m in ms) m.id == mealId ? fn(m) : m];

List<Meal> editOption(List<Meal> ms, String mealId, int oi, MealOption Function(MealOption) fn) => editMeal(
      ms,
      mealId,
      (m) => m.copyWith(options: [for (var i = 0; i < m.options.length; i++) i == oi ? fn(m.options[i]) : m.options[i]]),
    );

List<Meal> editFood(List<Meal> ms, String mealId, int oi, int fi, PlanFood Function(PlanFood) fn) =>
    editOption(ms, mealId, oi, (o) => o.copyWith(foods: [for (var i = 0; i < o.foods.length; i++) i == fi ? fn(o.foods[i]) : o.foods[i]]));
