import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'food_library_tab.dart';
import 'library_widgets.dart';
import 'nutrition_state.dart';

/// "Create food" / "Edit food" form (the design's food drawer).
/// Recipes are parked in the design (RECIPES_ON = false), so only foods.
void showFoodEditor(
  BuildContext context, {
  Food? food,
  required void Function(bool isNew) onSaved,
  required void Function(String planName) onOpenPlan,
}) {
  showAppSheet(
    context,
    title: food == null ? 'Create food' : 'Edit food',
    subtitle: food == null ? 'For the team food library' : '${food.name} · ${servingLabel(food)}',
    builder: (ctx) => _FoodEditor(
      food: food,
      hostContext: context,
      onSaved: onSaved,
      onOpenPlan: (name) {
        Navigator.of(ctx).pop();
        onOpenPlan(name);
      },
    ),
  );
}

class _FoodEditor extends ConsumerStatefulWidget {
  const _FoodEditor({required this.food, required this.hostContext, required this.onSaved, required this.onOpenPlan});
  final Food? food;
  final BuildContext hostContext;
  final void Function(bool isNew) onSaved;
  final void Function(String planName) onOpenPlan;

  @override
  ConsumerState<_FoodEditor> createState() => _FoodEditorState();
}

class _FoodEditorState extends ConsumerState<_FoodEditor> {
  static const _defaults = [161.1, 12.2, 4.4, 10.6, 1.1];
  static const _nutKeys = [('Calories', 'kcal'), ('Protein', 'g'), ('Carbs', 'g'), ('Fat', 'g'), ('Fibre', 'g')];

  late final _name = TextEditingController(text: widget.food?.name ?? '');
  late final _brand = TextEditingController(text: widget.food?.brand ?? '');
  late final _nut = List.generate(5, (_) => TextEditingController());
  late final _mic = List.generate(4, (_) => TextEditingController());

  late Diet _diet = widget.food?.diet ?? Diet.veg;
  late List<FoodUnit> _units = widget.food?.units ?? const [FoodUnit('g', 1), FoodUnit('1 plate', 180)];
  late int _du = widget.food?.defaultUnit ?? 1;
  late double _dq = widget.food?.defaultQty ?? 1;
  bool _per100Basis = true;
  late List<String> _swaps = widget.food?.swaps ?? const [];
  bool _swOpen = false;
  bool _swAll = false;

  /// kcal, protein, carbs, fat, fibre per 100 g (null until typed for a new food).
  late List<double>? _p100 = widget.food == null ? null : [widget.food!.kcal, widget.food!.protein, widget.food!.carbs, widget.food!.fat, widget.food!.fibre];

  bool get _isNew => widget.food == null;
  FoodUnit get _dU => _units[_du.clamp(0, _units.length - 1)];
  double get _dG => _dU.grams * _dq;
  double get _basisG => _per100Basis ? 100 : _dG;

  @override
  void initState() {
    super.initState();
    _fillNutrition();
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, ..._nut, ..._mic]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillNutrition() {
    final p = _p100;
    for (var i = 0; i < 5; i++) {
      _nut[i].text = p == null ? '' : nf(p[i] * _basisG / 100);
    }
  }

  void _onNutChanged() {
    final vals = [for (final c in _nut) double.tryParse(c.text.trim())];
    if (vals.every((v) => v == null)) {
      if (_isNew) setState(() => _p100 = null);
      return;
    }
    setState(() => _p100 = [for (final v in vals) (v ?? 0) * 100 / _basisG]);
  }

  /// Changes the serving and refreshes the numbers shown for "per serving".
  void _setServing(void Function() fn) {
    setState(fn);
    if (!_per100Basis) _fillNutrition();
  }

  void _pickUnit(int i) {
    final u = _units[i];
    final g = _dG;
    _setServing(() {
      _du = i;
      _dq = u.isGrams ? ((g / 5).round() * 5).clamp(5, 100000).toDouble() : ((g / u.grams * 2).round() / 2).clamp(.5, 1000).toDouble();
    });
  }

  void _addUnit(FoodUnit u, {bool custom = false}) {
    setState(() => _units = [..._units, u]);
    if (custom) showToast(context, 'Unit added', subtitle: 'Name it and set its weight in grams', kind: ToastKind.ok);
  }

  void _save() {
    final ctl = ref.read(foodsProvider.notifier);
    final before = ref.read(foodsProvider);
    final p = _p100 ?? _defaults;
    final host = widget.hostContext;
    Navigator.of(context).pop();
    if (_isNew) {
      final name = _name.text.trim().isEmpty ? 'Paneer bhurji' : _name.text.trim();
      ctl.add(Food(
        id: 'n${before.length}',
        name: name,
        units: _units,
        kcal: p[0],
        protein: p[1],
        carbs: p[2],
        fat: p[3],
        fibre: p[4],
        group: 'My foods',
        diet: _diet,
        brand: _brand.text.trim(),
        custom: true,
        swaps: _swaps,
        defaultUnit: _du,
        defaultQty: _dq,
        source: 'Your team',
      ));
      showToast(host, 'Saved to the food library', subtitle: '$name · in My foods', kind: ToastKind.ok, onUndo: () => ctl.restore(before));
    } else {
      final f = widget.food!;
      final name = _name.text.trim().isEmpty ? f.name : _name.text.trim();
      ctl.replace(f.copyWith(
        name: name,
        units: _units,
        kcal: p[0],
        protein: p[1],
        carbs: p[2],
        fat: p[3],
        fibre: p[4],
        diet: _diet,
        swaps: _swaps,
        defaultUnit: _du,
        defaultQty: _dq,
      ));
      final n = f.usedIn.length;
      showToast(host, 'Food updated',
          subtitle: n > 0 ? 'The ${plural(n, 'plan')} using it are updated' : f.name, kind: ToastKind.ok, onUndo: () => ctl.restore(before));
    }
    widget.onSaved(_isNew);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    return Spaced(
      gap: 16,
      children: [
        LabeledField(label: 'Food name *', hint: 'e.g. Paneer bhurji', controller: _name, onChanged: (_) => setState(() {})),
        LabeledField(label: 'Brand (optional)', hint: 'Only for packaged food', controller: _brand),
        FieldBlock(
          label: 'Diet',
          child: PillTabs<Diet>(
            items: [for (final d in Diet.values) (d, d.label, null)],
            value: _diet,
            onChanged: (d) => setState(() => _diet = d),
          ),
        ),
        Row(children: [
          Expanded(child: FieldBlock(label: 'Group in the food library', child: _ReadBox(f?.group ?? 'My foods'))),
          const SizedBox(width: 10),
          Expanded(child: FieldBlock(label: 'Source', child: _ReadBox(f?.source ?? 'Your team'))),
        ]),
        _unitsBlock(),
        _nutritionBlock(),
        FieldBlock(
          label: 'More nutrients  ·  optional · ${_per100Basis ? 'per 100 g' : 'per ${portionLabel(_dq, _dU.name)}'}',
          child: _NutGrid(children: [
            for (final (i, k) in const ['Sodium', 'Iron', 'Calcium', 'Potassium'].indexed)
              FieldBlock(label: k, child: PlainInput(controller: _mic[i], hint: '0', suffix: 'mg', keyboardType: TextInputType.number)),
          ]),
        ),
        _swapsBlock(),
        if (f != null && f.usedIn.isNotEmpty)
          FieldBlock(
            label: 'Used in ${plural(f.usedIn.length, 'plan')}',
            info: 'Changing the numbers updates these plans for every client on them.',
            child: Column(children: [
              for (final u in f.usedIn)
                InkWell(
                  onTap: () => widget.onOpenPlan(u.plan),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Row(children: [
                      const Icon(Icons.restaurant_menu_rounded, size: 18, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.plan, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                          Text(u.meals, style: AppText.caption),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                    ]),
                  ),
                ),
            ]),
          ),
        FieldBlock(
          label: 'Client sees in search',
          info: 'Team foods come first when a client searches. The numbers are for the default serving.',
          child: _SearchPreview(
            name: _name.text.trim().isEmpty ? 'Paneer bhurji' : _name.text.trim(),
            serving: portionLabel(_dq, _dU.name) + (_dU.isGrams ? '' : ' (${fq(_dG)} g)'),
            line: () {
              final v = _p100 ?? _defaults;
              double at(double x) => x * _dG / 100;
              return '${at(v[0]).round()} kcal · P ${nf(at(v[1]))} g · C ${nf(at(v[2]))} g · F ${nf(at(v[3]))} g';
            }(),
          ),
        ),
        SheetButtons(note: 'Saved to the team food library', children: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
          AppButton(_isNew ? 'Save to library' : 'Save changes', icon: Icons.check_rounded, onPressed: _save),
        ]),
      ],
    );
  }

  Widget _unitsBlock() {
    final p = _p100;
    final sugg = LibraryMock.unitSuggestions.where((u) => !_units.any((x) => x.name == u.name)).take(6).toList();
    final qStep = _dU.isGrams ? 5.0 : .5;
    final dqS = (_dU.isGrams ? '' : '= ${fq(_dG)} g') + (p == null ? '' : '${_dU.isGrams ? '' : ' · '}${(p[0] * _dG / 100).round()} kcal');
    return FieldBlock(
      label: 'Serving units',
      required: true,
      info: 'A unit is only its weight in grams. Pick the one clients see first with the round button.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < _units.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _UnitRow(
                  key: ValueKey('u$i-${_units.length}'),
                  unit: _units[i],
                  selected: i == _du,
                  kcal: p == null ? '— kcal' : '${(p[0] * _units[i].grams / 100).round()} kcal',
                  onPick: () => _pickUnit(i),
                  onRename: (v) => _units = [for (var j = 0; j < _units.length; j++) j == i ? FoodUnit(v, _units[j].grams) : _units[j]],
                  onWeight: (d) => _setServing(() {
                    final u = _units[i];
                    final step = u.grams < 20 ? 1.0 : 5.0;
                    _units = [for (var j = 0; j < _units.length; j++) j == i ? FoodUnit(u.name, (u.grams + d * step).clamp(1, 2000)) : _units[j]];
                  }),
                  onRemove: _units[i].isGrams || i == _du
                      ? null
                      : () => _setServing(() {
                            _units = [..._units]..removeAt(i);
                            if (i < _du) _du--;
                          }),
                ),
              ],
            ]),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<int>(
              tooltip: 'Add unit',
              onSelected: (i) => i < 0 ? _addUnit(const FoodUnit('1 serving', 100), custom: true) : _addUnit(sugg[i]),
              itemBuilder: (_) => [
                for (var i = 0; i < sugg.length; i++)
                  PopupMenuItem(
                    value: i,
                    child: Row(children: [
                      const Icon(Icons.straighten_rounded, size: 17, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text(sugg[i].name)),
                      Text('${fq(sugg[i].grams)} g', style: AppText.caption),
                    ]),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: -1, child: Row(children: [Icon(Icons.add_rounded, size: 17), SizedBox(width: 10), Text('Custom unit')])),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, size: 17, color: AppColors.accentText),
                  const SizedBox(width: 4),
                  Text('Add unit', style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.accentText)),
                ]),
              ),
            ),
          ),
          Row(children: [
            Text('Default serving', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
            const SizedBox(width: 10),
            Expanded(
              child: NumStepper(
                value: fq(_dq),
                unit: _dU.isGrams ? 'g' : '× ${_dU.name}',
                onMinus: () => _setServing(() => _dq = (_dq - qStep).clamp(qStep, 100000)),
                onPlus: () => _setServing(() => _dq = _dq + qStep),
              ),
            ),
          ]),
          if (dqS.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: Text(dqS, style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
          ],
        ],
      ),
    );
  }

  Widget _nutritionBlock() {
    final p = _p100;
    final calc = p == null ? 0 : (p[1] * 4 + p[2] * 4 + p[3] * 9).round();
    final ok = p != null && (calc - p[0]).abs() <= (p[0] * .1 > 10 ? p[0] * .1 : 10);
    final help = p == null
        ? 'Type the numbers from the pack or your sheet. They are saved per 100 g.'
        : _per100Basis
            ? 'Saved per 100 g. Every unit above is worked out from these numbers.'
            : 'You are typing for ${portionLabel(_dq, _dU.name)} (${fq(_dG)} g). Saved as per 100 g: ${p[0].round()} kcal · P ${nf(p[1])} g · C ${nf(p[2])} g · F ${nf(p[3])} g.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: FieldLabel('Nutrition', info: help)),
          if (p != null)
            Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: 'Per 100 g: 4 × P + 4 × C + 9 × F = $calc kcal. You entered ${p[0].round()} kcal.${ok ? ' Close enough.' : ' Check the numbers on the pack.'}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AppBadge(ok ? 'Calories match' : 'Check calories',
                    tone: ok ? BadgeTone.ok : BadgeTone.warn, icon: ok ? Icons.check_rounded : Icons.warning_amber_rounded),
              ),
            ),
        ]),
        PillTabs<bool>(
          items: [(true, 'Per 100 g', null), (false, 'Per ${portionLabel(_dq, _dU.name)}', null)],
          value: _per100Basis,
          onChanged: (v) {
            setState(() => _per100Basis = v);
            _fillNutrition();
          },
        ),
        const SizedBox(height: 10),
        _NutGrid(children: [
          for (final (i, (k, u)) in _nutKeys.indexed)
            FieldBlock(
              label: k,
              child: PlainInput(controller: _nut[i], hint: '0', suffix: u, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _onNutChanged()),
            ),
        ]),
      ],
    );
  }

  Widget _swapsBlock() {
    final foods = ref.watch(foodsProvider);
    final f = widget.food;
    final base = f == null ? [12.2, 4.4, 10.6] : [f.protein, f.carbs, f.fat];
    final baseGroup = f?.group ?? 'Protein';
    final baseName = f?.name ?? '';
    final cands = foods
        .where((x) => x.name != baseName && !_swaps.contains(x.name) && (_swAll || x.group == baseGroup))
        .map((x) => (macroMatch(base, [x.protein, x.carbs, x.fat]), x))
        .toList()
      ..sort((a, b) => b.$1.compareTo(a.$1));
    return FieldBlock(
      label: 'Swap group · alternatives',
      info: 'The client gets these choices when they tap Swap on this food in their meal plan. The amount is changed to give about the same calories.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_swaps.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in _swaps)
                Container(
                  height: 32,
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.swap_horiz_rounded, size: 15, color: AppColors.muted),
                    const SizedBox(width: 5),
                    Text(s, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.text)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      tooltip: 'Remove',
                      onPressed: () => setState(() => _swaps = _swaps.where((x) => x != s).toList()),
                      icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    ),
                  ]),
                ),
            ]),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _swOpen = !_swOpen),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Add alternative'),
            ),
          ),
          if (_swOpen)
            AltPicker(
              all: _swAll,
              onScope: (v) => setState(() => _swAll = v),
              footnote: 'Match = how close protein, carbs and fat are, per calorie.',
              options: [
                for (final (m, x) in cands.take(6))
                  AltOption(
                    name: x.name,
                    tone: toneForGroup(x.group),
                    match: m,
                    line: '${servingLabel(x)} · ${(x.kcal * x.defaultGrams / 100).round()} kcal · P ${nf(x.protein * x.defaultGrams / 100)} g',
                    onAdd: () {
                      setState(() {
                        _swaps = [..._swaps, x.name];
                        _swOpen = false;
                      });
                      showToast(context, 'Alternative added', subtitle: x.name, kind: ToastKind.ok);
                    },
                  ),
              ],
            ),
          if (_swaps.isEmpty) Text('No swaps yet. The client has to eat this food as planned.', style: AppText.caption),
        ],
      ),
    );
  }
}

class _ReadBox extends StatelessWidget {
  const _ReadBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(10), color: Colors.white),
      child: Row(children: [
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body)),
        const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
      ]),
    );
  }
}

class _NutGrid extends StatelessWidget {
  const _NutGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 16) / 3;
      return Wrap(spacing: 8, runSpacing: 10, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
    });
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    super.key,
    required this.unit,
    required this.selected,
    required this.kcal,
    required this.onPick,
    required this.onRename,
    required this.onWeight,
    this.onRemove,
  });
  final FoodUnit unit;
  final bool selected;
  final String kcal;
  final VoidCallback onPick;
  final ValueChanged<String> onRename;
  final ValueChanged<int> onWeight;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? AppColors.accentSoft : null,
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Show this first',
            child: InkWell(
              onTap: onPick,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: selected ? AppColors.accent : AppColors.line2, width: 1.5)),
                  child: selected ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)) : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: unit.isGrams
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Grams', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                            Text('Always on', style: AppText.caption.copyWith(fontSize: 11.5)),
                          ])
                        : SizedBox(
                            height: 36,
                            child: TextFormField(
                              initialValue: unit.name,
                              onChanged: onRename,
                              style: AppText.body.copyWith(fontSize: 13.5),
                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(kcal, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                ]),
                const SizedBox(height: 6),
                if (unit.isGrams)
                  Text('1 g', style: AppText.caption)
                else
                  NumStepper(value: fq(unit.grams), unit: 'g', onMinus: () => onWeight(-1), onPlus: () => onWeight(1)),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            child: onRemove == null
                ? null
                : IconButton(
                    tooltip: 'Remove unit',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

class _SearchPreview extends StatelessWidget {
  const _SearchPreview({required this.name, required this.serving, required this.line});
  final String name;
  final String serving;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const FoodThumb(tone: 1),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
              const SizedBox(width: 6),
              const AppBadge('Team', tone: BadgeTone.info),
            ]),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '$serving  ', style: const TextStyle(fontStyle: FontStyle.italic)),
                TextSpan(text: line),
              ]),
              style: AppText.caption,
            ),
          ]),
        ),
        const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.muted),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// "Pick an alternative" panel — shared with the meal plan builder.
// ---------------------------------------------------------------------------

class AltOption {
  const AltOption({required this.name, required this.tone, required this.match, required this.line, required this.onAdd});
  final String name;
  final int tone;
  final int match;
  final String line;
  final VoidCallback onAdd;
}

class AltPicker extends StatelessWidget {
  const AltPicker({super.key, required this.all, required this.onScope, required this.options, required this.footnote});
  final bool all;
  final ValueChanged<bool> onScope;
  final List<AltOption> options;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text('Pick an alternative', style: AppText.bodyBold.copyWith(fontSize: 13.5))),
            PillTabs<bool>(items: const [(false, 'Same group', null), (true, 'All foods', null)], value: all, onChanged: onScope),
          ]),
          const SizedBox(height: 6),
          for (final o in options)
            InkWell(
              onTap: o.onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                child: Row(children: [
                  FoodThumb(tone: o.tone, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13)),
                      Text(o.line, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5)),
                    ]),
                  ),
                  const SizedBox(width: 6),
                  AppBadge('${o.match}% match',
                      tone: o.match >= 85
                          ? BadgeTone.ok
                          : o.match >= 65
                              ? BadgeTone.warn
                              : BadgeTone.neutral),
                ]),
              ),
            ),
          if (options.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No other foods in this group.', textAlign: TextAlign.center, style: AppText.secondary)),
          const SizedBox(height: 4),
          Text(footnote, style: AppText.caption.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}
