import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

/// Master meal plans (Nutrition & foods → Meal plans tab, and the builder).
class MealPlansController extends Notifier<List<MealPlan>> {
  @override
  List<MealPlan> build() => LibraryMock.plans;

  MealPlan? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  void add(MealPlan p) => state = [p, ...state];

  void remove(String id) => state = state.where((p) => p.id != id).toList();

  void update(String id, MealPlan Function(MealPlan) fn) => state = [for (final p in state) p.id == id ? fn(p) : p];

  void restore(List<MealPlan> list) => state = list;

  /// Same meals, no clients. Returns the copy.
  MealPlan duplicate(MealPlan p) {
    final copy = p.copyWith(
      id: '${p.id}c${state.length}',
      name: '${p.name} (copy)',
      clients: const [],
      published: false,
      dirty: false,
      edited: 'just now',
    );
    final i = state.indexWhere((x) => x.id == p.id);
    final list = [...state];
    list.insert(i < 0 ? 0 : i, copy);
    state = list;
    return copy;
  }
}

final mealPlansProvider = NotifierProvider<MealPlansController, List<MealPlan>>(MealPlansController.new);

/// The plan open in the meal plan builder.
class OpenPlanController extends Notifier<String> {
  @override
  String build() => LibraryMock.plans.first.id;

  void open(String id) => state = id;
}

final openPlanProvider = NotifierProvider<OpenPlanController, String>(OpenPlanController.new);

/// Team food library.
class FoodsController extends Notifier<List<Food>> {
  @override
  List<Food> build() => LibraryMock.foods;

  void add(Food f) => state = [f, ...state];

  void replace(Food f) => state = [for (final x in state) x.id == f.id ? f : x];

  void remove(String id) => state = state.where((f) => f.id != id).toList();

  void restore(List<Food> list) => state = list;
}

final foodsProvider = NotifierProvider<FoodsController, List<Food>>(FoodsController.new);
