import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'food_log_sheets.dart';
import 'food_state.dart';

/// Design: ClientFoodLog.dc.html — search the food library and add foods to a meal.
class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

enum _Tab { all, recent, mine }

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  final _search = TextEditingController();
  int _meal = 3;
  bool _mealMenu = false;
  _Tab _tab = _Tab.all;
  bool _showAll = false;
  bool _off = false;
  String? _why;
  List<int> _quick = [0, 0, 0, 0];
  static const _quickSteps = [25, 1, 1, 1];
  static int _ids = 0;

  String get _q => _search.text.trim().toLowerCase();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.cFood);

  void _setQuery(String q) => setState(() {
        _search.text = q;
        _showAll = false;
      });

  FoodEntry _entry(String name, String amount, Macros m) => FoodEntry(
        id: 'log${_ids++}',
        name: name,
        amount: amount,
        macros: m,
        mealIndex: _meal,
        atMinute: ClientMock.nowMinute,
        offPlan: _off,
        reason: _why,
      );

  void _add(FoodEntry e) {
    final ctl = ref.read(foodDayProvider.notifier);
    final prev = ref.read(foodDayProvider);
    ctl.addEntries([e]);
    final meal = FoodDay.plan[_meal].name;
    showToast(context, '${e.name} added to $meal',
        subtitle: '${e.amount} · ${e.macros.kcal.round()} kcal${_off ? ' · marked off-plan' : ''}', kind: ToastKind.ok, onUndo: () => ctl.restore(prev));
  }

  void addFood(Food c, double q) => _add(_entry(c.name, amountOf(c.unit, q), c.macrosFor(q)));

  void _remove(FoodEntry e) {
    final ctl = ref.read(foodDayProvider.notifier);
    final prev = ref.read(foodDayProvider);
    ctl.removeEntry(e.id);
    showToast(context, '${e.name} removed', subtitle: 'Taken out of ${FoodDay.plan[_meal].name}', kind: ToastKind.del, onUndo: () => ctl.restore(prev));
  }

  void _quickAdd() {
    if (_quick[0] <= 0) {
      showToast(context, 'Enter the calories first', subtitle: 'Protein, carbs and fat are optional', kind: ToastKind.warn);
      return;
    }
    final q = _quick;
    final ctl = ref.read(foodDayProvider.notifier);
    final prev = ref.read(foodDayProvider);
    ctl.addEntries([_entry('Quick add', '1 entry', Macros(q[0].toDouble(), q[1].toDouble(), q[2].toDouble(), q[3].toDouble()))]);
    showToast(context, 'Quick add · ${q[0]} kcal to ${FoodDay.plan[_meal].name}',
        subtitle: '${q[1]} g protein', kind: ToastKind.ok, onUndo: () => ctl.restore(prev));
  }

  void _openCustom() => showCustomFoodSheet(context, ref, onSaved: (name) {
        setState(() {
          _tab = _Tab.mine;
          _search.clear();
        });
        showToast(context, '$name saved to My foods', subtitle: 'Tap + to log it', kind: ToastKind.ok);
      });

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(foodDayProvider);
    final meal = FoodDay.plan[_meal];
    final added = day.extrasFor(_meal, addedNow: true);
    return PageScroll(
      children: [
        _Top(
          meal: meal,
          onBack: _back,
          onMeal: () => setState(() => _mealMenu = !_mealMenu),
          open: _mealMenu,
        ),
        if (_mealMenu)
          _MealMenu(
            day: day,
            selected: _meal,
            onPick: (i) => setState(() {
              _meal = i;
              _mealMenu = false;
            }),
          ),
        _SearchBox(controller: _search, onChanged: (_) => setState(() => _showAll = false), onClear: () => _setQuery('')),
        if (_q.isEmpty)
          TryRow(label: 'Try', chips: [for (final t in ClientMock.searchTries) TryChip(t, onTap: () => _setQuery(t))]),
        SegmentedTabs<_Tab>(
          items: const [(_Tab.all, 'All'), (_Tab.recent, 'Recent'), (_Tab.mine, 'My foods')],
          value: _tab,
          onChanged: (t) => setState(() {
            _tab = t;
            _showAll = false;
          }),
        ),
        _resultsCard(day, added),
        _AddedCard(
          day: day,
          mealIndex: _meal,
          added: added,
          onRemove: _remove,
          onDone: _back,
        ),
        _ExtraCard(
          quick: _quick,
          onQuick: (k, dir) => setState(() {
            _quick = [for (var j = 0; j < 4; j++) j == k ? (_quick[j] + dir * _quickSteps[k]).clamp(0, 99999) : _quick[j]];
          }),
          onQuickAdd: _quickAdd,
          onCustom: _openCustom,
          off: _off,
          why: _why,
          onOff: () => setState(() {
            _off = !_off;
            _why = null;
          }),
          onWhy: (w) => setState(() => _why = _why == w ? null : w),
        ),
      ],
    );
  }

  Widget _resultsCard(FoodDay day, List<FoodEntry> added) {
    final q = _q;
    final catalog = ClientMock.catalog;
    final List<Food> pool = switch (_tab) {
      _Tab.recent => [for (final n in ClientMock.recentFoods) catalog.firstWhere((c) => c.name == n)],
      _Tab.mine => day.myFoods,
      _Tab.all => [...day.myFoods, ...catalog],
    };
    final hits = [for (final c in pool) if (q.isEmpty || c.name.toLowerCase().contains(q)) c];
    final showAll = _showAll || q.isNotEmpty;
    final rows = showAll ? hits : hits.take(8).toList();
    final count = q.isNotEmpty
        ? '${hits.length}${hits.length == 1 ? ' result for “' : ' results for “'}$q”'
        : switch (_tab) {
            _Tab.recent => 'Foods you logged lately',
            _Tab.mine => 'Foods you created',
            _Tab.all => '${catalog.length + day.myFoods.length} foods in Aman’s library and yours',
          };
    final emptyText = q.isNotEmpty
        ? 'Nothing found. Try Quick add or create a custom food.'
        : _tab == _Tab.mine
            ? 'You have not created a food yet.'
            : 'No foods here yet.';
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(count, style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final c in rows)
            _ResultRow(
              food: c,
              added: added.any((e) => e.name == c.name),
              onOpen: () => showPortionSheet(context, food: c, mealName: FoodDay.plan[_meal].name, onAdd: addFood),
              onToggle: () {
                final ix = added.indexWhere((e) => e.name == c.name);
                ix >= 0 ? _remove(added[ix]) : addFood(c, c.qty);
              },
            ),
          if (hits.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(emptyText, style: AppText.secondary, textAlign: TextAlign.center)),
          if (!showAll && hits.length > 8)
            TextButton(onPressed: () => setState(() => _showAll = true), child: Text('Show all ${hits.length} foods')),
        ],
      ),
    );
  }
}

class _Top extends StatelessWidget {
  const _Top({required this.meal, required this.onBack, required this.onMeal, required this.open});
  final PlanMeal meal;
  final VoidCallback onBack;
  final VoidCallback onMeal;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(Icons.arrow_back_rounded, small: true, tooltip: 'Back to meal plan', onPressed: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log food', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
              InkWell(
                onTap: onMeal,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Add to ${meal.name}', style: AppText.sectionTitle.copyWith(fontSize: 20)),
                    Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealMenu extends StatelessWidget {
  const _MealMenu({required this.day, required this.selected, required this.onPick});
  final FoodDay day;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: Text('ADD TO', style: AppText.overline.copyWith(fontSize: 11)),
          ),
          for (var i = 0; i < FoodDay.plan.length; i++)
            Builder(builder: (context) {
              final m = FoodDay.plan[i];
              final now = day.extrasFor(i, addedNow: true);
              final sub = now.isNotEmpty
                  ? '${now.fold<double>(0, (a, e) => a + e.macros.kcal).round()} kcal added now'
                  : 'Plan: ${m.foods.map((f) => f.name).join(', ')}';
              return InkWell(
                onTap: () => onPick(i),
                child: Container(
                  color: i == selected ? AppColors.accentSoft : null,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m.name} · ${m.time}', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                          ],
                        ),
                      ),
                      if (i == selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppText.bodyBold,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search food, e.g. paneer, dal, roti',
        prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.muted),
        suffixIcon: controller.text.isEmpty ? null : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded, size: 18), onPressed: onClear),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.food, required this.added, required this.onOpen, required this.onToggle});
  final Food food;
  final bool added;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final m = food.defaultMacros;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(food.name, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                      if (food.mine) ...[const SizedBox(width: 6), const Tag('Mine')],
                    ]),
                    Text('${amountOf(food.unit, food.qty)} · ${m.kcal.round()} kcal · ${m.protein.round()} g P', style: AppText.caption),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: added ? AppColors.accent : Colors.white,
            shape: CircleBorder(side: BorderSide(color: added ? AppColors.accent : AppColors.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(added ? Icons.check_rounded : Icons.add_rounded, size: 17, color: added ? Colors.white : AppColors.text2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddedCard extends StatelessWidget {
  const _AddedCard({required this.day, required this.mealIndex, required this.added, required this.onRemove, required this.onDone});
  final FoodDay day;
  final int mealIndex;
  final List<FoodEntry> added;
  final ValueChanged<FoodEntry> onRemove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final meal = FoodDay.plan[mealIndex];
    final addK = added.fold<double>(0, (a, e) => a + e.macros.kcal);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${meal.name} · ${meal.time}', style: AppText.bodyBold.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Plan: ${meal.foods.map((f) => f.name).join(', ')} · ${day.planMacros(mealIndex).kcal.round()} kcal', style: AppText.caption),
                  ],
                ),
              ),
              if (added.isNotEmpty) Text('+${addK.round()} kcal', style: AppText.bodyBold.copyWith(color: AppColors.accentText)),
            ],
          ),
          const SizedBox(height: 6),
          for (final e in added)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(child: Text(e.name, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                          if (e.offPlan) ...[const SizedBox(width: 6), const Tag('Off-plan', amber: true)],
                        ]),
                        Text(
                          '${e.amount} · ${e.macros.kcal.round()} kcal · ${e.macros.protein.round()} g P${e.reason != null ? ' · ${e.reason}' : ''}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(Icons.close_rounded, small: true, tooltip: 'Remove', onPressed: () => onRemove(e)),
                ],
              ),
            ),
          if (added.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Nothing added yet. Tap + on a food.', style: AppText.secondary, textAlign: TextAlign.center),
            )
          else ...[
            const SizedBox(height: 8),
            AppButton('Done · back to meal plan', icon: Icons.check_rounded, expand: true, onPressed: onDone),
          ],
        ],
      ),
    );
  }
}

class _ExtraCard extends StatelessWidget {
  const _ExtraCard({
    required this.quick,
    required this.onQuick,
    required this.onQuickAdd,
    required this.onCustom,
    required this.off,
    required this.why,
    required this.onOff,
    required this.onWhy,
  });
  final List<int> quick;
  final void Function(int k, int dir) onQuick;
  final VoidCallback onQuickAdd;
  final VoidCallback onCustom;
  final bool off;
  final String? why;
  final VoidCallback onOff;
  final ValueChanged<String> onWhy;

  static const _labels = ['Calories', 'Protein (g)', 'Carbs (g)', 'Fat (g)'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Can’t find the exact food?', style: AppText.bodyBold.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Caption('Quick add the numbers, or save a custom food for next time.'),
          const SizedBox(height: 8),
          for (var k = 0; k < 4; k++) MacroStepRow(label: _labels[k], value: quick[k], onMinus: () => onQuick(k, -1), onPlus: () => onQuick(k, 1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AppButton.outline('Create custom food', small: true, icon: Icons.add_rounded, onPressed: onCustom)),
              const SizedBox(width: 8),
              Expanded(child: AppButton.dark('Quick add', small: true, onPressed: onQuickAdd)),
            ],
          ),
          const SizedBox(height: 10),
          CheckRow(
            on: off,
            title: 'Off-plan meal',
            subtitle: 'Party or eating out: what you add is marked off-plan for Aman.',
            onTap: onOff,
          ),
          if (off) ...[
            const SizedBox(height: 8),
            TryRow(chips: [for (final w in ClientMock.offPlanReasons) TryChip(w, selected: why == w, onTap: () => onWhy(w))]),
          ],
        ],
      ),
    );
  }
}

/// Label + stepper row (fl-q) used by Quick add and Create custom food.
class MacroStepRow extends StatelessWidget {
  const MacroStepRow({super.key, required this.label, required this.value, required this.onMinus, required this.onPlus});
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2))),
          QtyStepper(value: '$value', onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}
