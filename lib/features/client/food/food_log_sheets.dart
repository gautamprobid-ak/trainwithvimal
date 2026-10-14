import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'food_log_screen.dart';
import 'food_state.dart';

/// Portion sheet: quantity + unit (switching unit keeps the same grams).
void showPortionSheet(BuildContext context, {required Food food, required String mealName, required void Function(Food food, double qty) onAdd}) {
  var unit = food.unit;
  var qty = food.qty;
  showClientSheet<void>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final cx = food.inUnit(unit);
        final m = cx.macrosFor(qty);
        final step = unit == 'g' ? 10.0 : 0.5;
        final grams = cx.gramsFor(qty);
        return ClientSheet(
          title: food.name,
          subtitle: 'Default ${amountOf(food.unit, food.qty)} · ${food.defaultMacros.kcal.round()} kcal',
          body: Column(
            children: [
              QtyStepper(
                large: true,
                value: amountOf(unit, qty),
                onMinus: () => setSheet(() {
                  final v = ((qty - step) * 10).round() / 10;
                  qty = v < step ? step : v;
                }),
                onPlus: () => setSheet(() => qty = ((qty + step) * 10).round() / 10),
              ),
              if (unit != 'g') ...[
                const SizedBox(height: 4),
                Text('= ${grams.round()} g', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final u in food.units)
                    ChoicePill(
                      u.name == 'g' ? 'grams' : u.name.replaceFirst(RegExp(r'^1 '), ''),
                      selected: u.name == unit,
                      onTap: () {
                        if (u.name == unit) return;
                        setSheet(() {
                          if (u.name == 'g') {
                            qty = (grams / 10).round() * 10;
                          } else {
                            final v = (grams / u.grams * 2).round() / 2;
                            qty = v < .5 ? .5 : v;
                          }
                          unit = u.name;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              StatCells([
                ('${m.kcal.round()}', 'kcal'),
                ('${m.protein.round()} g', 'Protein'),
                ('${m.carbs.round()} g', 'Carbs'),
                ('${m.fat.round()} g', 'Fat'),
              ]),
            ],
          ),
          actions: [
            AppButton('Add to $mealName', icon: Icons.add_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              onAdd(cx, qty);
            }),
          ],
        );
      },
    ),
  );
}

/// Create custom food sheet (saved to My foods).
void showCustomFoodSheet(BuildContext context, WidgetRef ref, {required ValueChanged<String> onSaved}) {
  final values = [...ClientMock.customFood0];
  const steps = [25, 1, 1, 1];
  const labels = ['Calories', 'Protein (g)', 'Carbs (g)', 'Fat (g)'];
  final name = TextEditingController(text: ClientMock.customFoodName);
  final serving = TextEditingController(text: ClientMock.customFoodServing);
  showClientSheet<void>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => ClientSheet(
        title: 'Create custom food',
        subtitle: 'Saved to My foods, only you see it',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(label: 'Name', controller: name),
            const SizedBox(height: 12),
            LabeledField(label: 'Serving', controller: serving),
            const SizedBox(height: 8),
            for (var k = 0; k < 4; k++)
              MacroStepRow(
                label: labels[k],
                value: values[k],
                onMinus: () => setSheet(() => values[k] = (values[k] - steps[k]).clamp(0, 99999)),
                onPlus: () => setSheet(() => values[k] += steps[k]),
              ),
          ],
        ),
        actions: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
          AppButton('Save food', onPressed: () {
            final mine = ref.read(foodDayProvider).myFoods;
            final base = name.text.trim().isEmpty ? ClientMock.customFoodName : name.text.trim();
            final n = mine.any((f) => f.name == base) ? '$base (${mine.length + 1})' : base;
            final u = serving.text.trim().isEmpty ? ClientMock.customFoodServing : serving.text.trim();
            final unit = u.startsWith('1 ') ? u : '1 $u';
            ref.read(foodDayProvider.notifier).addMyFood(Food(
                  name: n,
                  unit: unit,
                  qty: 1,
                  per: Macros(values[0].toDouble(), values[1].toDouble(), values[2].toDouble(), values[3].toDouble()),
                  units: [const ServingUnit('g', 1), ServingUnit(unit, 150)],
                  mine: true,
                ));
            Navigator.of(ctx).pop();
            onSaved(n);
          }),
        ],
      ),
    ),
  );
}
