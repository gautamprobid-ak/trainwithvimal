import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'food_editor_sheet.dart';
import 'food_import_sheet.dart';
import 'food_library_tab.dart';
import 'library_widgets.dart';
import 'meal_plans_tab.dart';
import 'nutrition_state.dart';

enum _Tab { plans, foods }

/// Design: NutritionMobile — "Nutrition & foods": master meal plans and the
/// team food library (create, duplicate, delete, Excel import).
///
/// `?food=new` opens the "Create food" form on the Food library tab
/// (used by the builder's "Create custom food" link).
class NutritionLibraryScreen extends ConsumerStatefulWidget {
  const NutritionLibraryScreen({super.key});

  @override
  ConsumerState<NutritionLibraryScreen> createState() => _NutritionLibraryScreenState();
}

class _NutritionLibraryScreenState extends ConsumerState<NutritionLibraryScreen> {
  var _tab = _Tab.plans;
  final _foodsKey = GlobalKey<FoodLibraryTabState>();
  bool _handledQuery = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledQuery) return;
    _handledQuery = true;
    if (GoRouterState.of(context).uri.queryParameters['food'] == 'new') {
      _tab = _Tab.foods;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFood();
      });
    }
  }

  void _openFood([Food? food]) {
    showFoodEditor(
      context,
      food: food,
      onSaved: (isNew) {
        if (!isNew) return;
        setState(() => _tab = _Tab.foods);
        _foodsKey.currentState?.resetFilters();
      },
      onOpenPlan: _openPlanByName,
    );
  }

  void _openImport() {
    showFoodImport(context, onImported: () {
      setState(() => _tab = _Tab.foods);
      _foodsKey.currentState?.resetFilters();
    });
  }

  void _openPlanByName(String name) {
    for (final p in ref.read(mealPlansProvider)) {
      if (p.name == name) {
        ref.read(openPlanProvider.notifier).open(p.id);
        context.push(context.rolePath(Routes.mealPlanBuilder));
        return;
      }
    }
    showToast(context, name, subtitle: 'This plan is no longer in the library');
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(mealPlansProvider);
    final foods = ref.watch(foodsProvider);
    final isPlans = _tab == _Tab.plans;
    return PageScroll(
      children: [
        const SubPageHeader(title: 'Nutrition & foods'),
        Text(
          isPlans
              ? 'Master meal plans. Assign one to many clients and note what is different for each.'
              : 'Foods your team uses in meal plans. Clients see team foods first when they search.',
          style: AppText.secondary,
        ),
        _HeaderActions(
          isPlans: isPlans,
          onCreateFood: () => _openFood(),
          onNewPlan: () => showNewPlanSheet(context, ref),
          onImport: _openImport,
        ),
        CountTabs<_Tab>(
          items: [(_Tab.plans, 'Meal plans', plans.length), (_Tab.foods, 'Food library', foods.length)],
          value: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        if (isPlans) const MealPlansTab() else FoodLibraryTab(key: _foodsKey, onOpenFood: _openFood),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.isPlans, required this.onCreateFood, required this.onNewPlan, required this.onImport});
  final bool isPlans;
  final VoidCallback onCreateFood;
  final VoidCallback onNewPlan;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: isPlans
          ? [
              Expanded(child: AppButton.outline('Create food', icon: Icons.add_rounded, onPressed: onCreateFood, expand: true)),
              const SizedBox(width: 10),
              Expanded(child: AppButton('New plan', icon: Icons.add_rounded, onPressed: onNewPlan, expand: true)),
            ]
          : [
              Expanded(child: AppButton.outline('Import from Excel', icon: Icons.upload_file_rounded, onPressed: onImport, expand: true)),
              const SizedBox(width: 10),
              Expanded(child: AppButton('Create food', icon: Icons.add_rounded, onPressed: onCreateFood, expand: true)),
            ],
    );
  }
}
