import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

/// A food inside a plan meal as it stands today: the planned one or its swap,
/// with today's portion.
class PlannedFood {
  const PlannedFood({required this.base, required this.food, required this.swap, required this.qty, required this.key});
  final Food base;
  final Food food;
  final int? swap;
  final double qty;

  /// Portion key: "meal:food:p" for the planned food, "meal:food:N" for swap N.
  final String key;

  bool get swapped => swap != null;
  Macros get macros => food.macrosFor(qty);
}

/// Riya's food day (today, Fri 9 Oct). Shared by Meal plan, Log food and
/// Nutrition so eaten meals and logged foods show the same everywhere.
class FoodDay {
  const FoodDay({
    this.eatenAt = ClientMock.eatenAt0,
    this.skipped = const {},
    this.swaps = const {},
    this.portions = const {},
    this.extras = ClientMock.extras0,
    this.myFoods = ClientMock.myFoods0,
  });

  /// Meal index → minute of the day it was logged.
  final Map<int, int> eatenAt;
  final Set<int> skipped;

  /// "meal:food" → alt index (today only).
  final Map<String, int> swaps;

  /// Portion key → quantity (today only).
  final Map<String, double> portions;
  final List<FoodEntry> extras;
  final List<Food> myFoods;

  static const plan = ClientMock.plan;
  static const targets = ClientMock.targets;

  FoodDay copyWith({
    Map<int, int>? eatenAt,
    Set<int>? skipped,
    Map<String, int>? swaps,
    Map<String, double>? portions,
    List<FoodEntry>? extras,
    List<Food>? myFoods,
  }) =>
      FoodDay(
        eatenAt: eatenAt ?? this.eatenAt,
        skipped: skipped ?? this.skipped,
        swaps: swaps ?? this.swaps,
        portions: portions ?? this.portions,
        extras: extras ?? this.extras,
        myFoods: myFoods ?? this.myFoods,
      );

  bool isEaten(int i) => eatenAt.containsKey(i);
  bool isSkipped(int i) => skipped.contains(i);
  int get eatenCount => eatenAt.length;
  bool get allEaten => eatenAt.length == plan.length;

  /// First meal not eaten and not skipped (-1 when none).
  int get nextMeal {
    for (var i = 0; i < plan.length; i++) {
      if (!isEaten(i) && !isSkipped(i)) return i;
    }
    return -1;
  }

  PlannedFood foodAt(int mi, int fi) {
    final base = plan[mi].foods[fi];
    final s = swaps['$mi:$fi'];
    final food = s != null ? base.alts[s] : base;
    final key = '$mi:$fi:${s ?? 'p'}';
    return PlannedFood(base: base, food: food, swap: s, qty: portions[key] ?? food.qty, key: key);
  }

  /// Macros of a meal today; [draft] overrides portions (Edit portions sheet).
  Macros mealMacros(int mi, [Map<String, double>? draft]) {
    var m = Macros.zero;
    for (var fi = 0; fi < plan[mi].foods.length; fi++) {
      final o = foodAt(mi, fi);
      m = m + o.food.macrosFor(draft?[o.key] ?? o.qty);
    }
    return m;
  }

  /// Plan macros without today's swaps or portions.
  Macros planMacros(int mi) => plan[mi].foods.fold(Macros.zero, (a, f) => a + f.defaultMacros);

  /// Comma list of the meal's foods: "Oats, whey protein, banana".
  String foodsSummary(int mi) {
    final names = <String>[];
    for (var fi = 0; fi < plan[mi].foods.length; fi++) {
      final n = foodAt(mi, fi).food.name;
      names.add(fi == 0 ? n : n.toLowerCase());
    }
    return names.join(', ');
  }

  Macros get eatenMealsTotal => eatenAt.keys.fold(Macros.zero, (a, i) => a + mealMacros(i));
  Macros get extrasTotal => extras.fold(Macros.zero, (a, e) => a + e.macros);

  /// Everything eaten today (plan meals + extra entries).
  Macros get total => eatenMealsTotal + extrasTotal;

  List<FoodEntry> extrasFor(int mi, {bool addedNow = false}) =>
      [for (final e in extras) if (e.mealIndex == mi && (!addedNow || !e.seed)) e];
}

class FoodDayController extends Notifier<FoodDay> {
  @override
  FoodDay build() => const FoodDay();

  /// Undo: put a previous snapshot back.
  void restore(FoodDay s) => state = s;

  void eat(int i, {int at = ClientMock.nowMinute}) =>
      state = state.copyWith(eatenAt: {...state.eatenAt, i: at}, skipped: {...state.skipped}..remove(i));

  void uneat(int i) => state = state.copyWith(eatenAt: {...state.eatenAt}..remove(i));

  void skip(int i) => state = state.copyWith(skipped: {...state.skipped, i});

  void setSwap(int mi, int fi, int? alt) {
    final n = {...state.swaps};
    if (alt == null) {
      n.remove('$mi:$fi');
    } else {
      n['$mi:$fi'] = alt;
    }
    state = state.copyWith(swaps: n);
  }

  void savePortions(Map<String, double> draft) => state = state.copyWith(portions: {...state.portions, ...draft});

  void addEntries(List<FoodEntry> e) => state = state.copyWith(extras: [...state.extras, ...e]);

  void removeEntry(String id) => state = state.copyWith(extras: [for (final e in state.extras) if (e.id != id) e]);

  void addMyFood(Food f) => state = state.copyWith(myFoods: [...state.myFoods, f]);
}

final foodDayProvider = NotifierProvider<FoodDayController, FoodDay>(FoodDayController.new);

/// Water logged today in ml (Nutrition water card + Habits water habit).
class WaterController extends Notifier<int> {
  @override
  int build() => ClientMock.waterToday0;

  void set(int ml) => state = ml;
}

final clientWaterProvider = NotifierProvider<WaterController, int>(WaterController.new);
