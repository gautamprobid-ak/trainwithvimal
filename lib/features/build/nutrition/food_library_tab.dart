import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'library_widgets.dart';
import 'nutrition_state.dart';

/// Thumbnail tone per food group (nu-fic t1…t4).
int toneForGroup(String g) => switch (g) {
      'Carbs' || 'Fats' || 'Indian dishes' => 3,
      'Veg' || 'Fruits' => 2,
      'Dairy' => 4,
      _ => 1,
    };

/// Food library tab: search, per serving / per 100 g, diet, groups, list, pager.
class FoodLibraryTab extends ConsumerStatefulWidget {
  const FoodLibraryTab({super.key, required this.onOpenFood});
  final void Function(Food food) onOpenFood;

  @override
  ConsumerState<FoodLibraryTab> createState() => FoodLibraryTabState();
}

class FoodLibraryTabState extends ConsumerState<FoodLibraryTab> {
  static const _pageSize = 10;
  String _group = 'All';
  Diet? _diet;
  bool _per100 = false;
  int _page = 0;
  String _q = '';

  void resetFilters() => setState(() {
        _group = 'All';
        _diet = null;
        _page = 0;
      });

  bool _inGroup(Food f, String g) => g == 'All' || (g == 'My foods' ? f.custom : f.group == g);
  bool _okDiet(Food f) => _diet == null || f.diet == _diet;
  bool _okQuery(Food f) => _q.isEmpty || f.name.toLowerCase().contains(_q.toLowerCase());

  void _menu(Food f) {
    final ctl = ref.read(foodsProvider.notifier);
    showActionSheet(context, title: f.name, actions: [
      SheetAction('Edit', Icons.edit_outlined, () => widget.onOpenFood(f)),
      SheetAction('Duplicate', Icons.copy_rounded, () {
        final before = ref.read(foodsProvider);
        final prevGroup = _group;
        ctl.add(f.copyWith(id: '${f.id}c${before.length}', name: '${f.name} (copy)', group: 'My foods', custom: true, usedIn: const [], source: 'Your team'));
        setState(() {
          _group = 'My foods';
          _page = 0;
        });
        showToast(context, 'Food duplicated', subtitle: '${f.name} (copy) is in My foods', kind: ToastKind.ok, onUndo: () {
          ctl.restore(before);
          if (mounted) setState(() => _group = prevGroup);
        });
      }),
      if (f.custom)
        SheetAction('Delete', Icons.delete_outline_rounded, () async {
          final n = f.usedIn.length;
          final ok = await showConfirmDialog(
            context,
            title: 'Delete this food?',
            message: '${f.name} is removed from My foods.${n > 0 ? ' It stays in the $n plans that use it.' : ''}',
            confirmLabel: 'Delete',
            destructive: true,
            icon: Icons.delete_outline_rounded,
          );
          if (!ok || !mounted) return;
          final before = ref.read(foodsProvider);
          ctl.remove(f.id);
          showToast(context, 'Food deleted', subtitle: f.name, kind: ToastKind.del, onUndo: () => ctl.restore(before));
        }, destructive: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider);
    final groups = [
      ...LibraryMock.foodGroups,
      ...{for (final f in foods) f.group}.where((g) => !LibraryMock.foodGroups.contains(g) && g != 'My foods'),
      'My foods',
    ];
    final shown = foods.where((f) => _inGroup(f, _group) && _okDiet(f) && _okQuery(f)).toList();
    final pages = (shown.length / _pageSize).ceil().clamp(1, 9999);
    final pg = _page.clamp(0, pages - 1);
    final rows = shown.skip(pg * _pageSize).take(_pageSize).toList();

    return Spaced(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  children: [
                    SearchField(hint: 'Search paneer, dal, chicken…', onChanged: (v) => setState(() {
                          _q = v;
                          _page = 0;
                        })),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: PillTabs<bool>(
                            items: const [(false, 'Per serving', null), (true, 'Per 100 g', null)],
                            value: _per100,
                            onChanged: (v) => setState(() => _per100 = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DietSelect(value: _diet, onChanged: (d) => setState(() {
                              _diet = d;
                              _page = 0;
                            })),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in groups)
                      CountChip(g,
                          count: foods.where((f) => _inGroup(f, g) && _okDiet(f)).length,
                          selected: g == _group,
                          onTap: () => setState(() {
                                _group = g;
                                _page = 0;
                              })),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _FoodRow(food: rows[i], per100: _per100, onTap: () => widget.onOpenFood(rows[i]), onMenu: () => _menu(rows[i])),
              ],
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Nothing found. Remove a filter, or make your own food.', textAlign: TextAlign.center, style: AppText.secondary),
                ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                shown.isEmpty ? '0 foods' : '${pg * _pageSize + 1}–${(pg * _pageSize + _pageSize).clamp(0, shown.length)} of ${shown.length} foods',
                style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous page', onPressed: pg > 0 ? () => setState(() => _page = pg - 1) : null),
            const SizedBox(width: 6),
            AppIconButton(Icons.chevron_right_rounded,
                small: true, tooltip: 'Next page', onPressed: pg < pages - 1 ? () => setState(() => _page = pg + 1) : null),
          ],
        ),
      ],
    );
  }
}

class _DietSelect extends StatelessWidget {
  const _DietSelect({required this.value, required this.onChanged});
  final Diet? value;
  final ValueChanged<Diet?> onChanged;

  @override
  Widget build(BuildContext context) {
    const opts = <Diet?>[null, Diet.veg, Diet.egg, Diet.nonVeg, Diet.vegan];
    String label(Diet? d) => d == null ? 'Any diet' : d.label;
    return PopupMenuButton<int>(
      tooltip: 'Diet',
      onSelected: (i) => onChanged(opts[i]),
      itemBuilder: (_) => [
        for (var i = 0; i < opts.length; i++)
          PopupMenuItem(
            value: i,
            child: Row(children: [
              DietMark(opts[i]),
              const SizedBox(width: 10),
              Expanded(child: Text(label(opts[i]), style: AppText.body)),
              if (opts[i] == value) const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
            ]),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(left: 10, right: 6),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Diet ', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            Text(label(value), style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
            const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.per100, required this.onTap, required this.onMenu});
  final Food food;
  final bool per100;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  String get _sub {
    final f = food;
    final parts = [
      f.brand,
      f.custom ? (f.source == 'Your team' ? 'Made by your team' : 'Imported · ${f.source}') : '',
      f.units.length > 2 ? '${f.units.length - 1} units' : '',
      f.swaps.isNotEmpty ? plural(f.swaps.length, 'swap') : '',
    ].where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'Built-in food' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final f = food;
    final g = per100 ? 100.0 : f.defaultGrams;
    double at(double v) => v * g / 100;
    final muted = AppText.caption.copyWith(fontWeight: FontWeight.w600);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Column(
          children: [
            Row(
              children: [
                FoodThumb(tone: toneForGroup(f.group)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold),
                      Text(_sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '${at(f.kcal).round()}', style: AppText.bodyBold.copyWith(fontSize: 13)),
                  TextSpan(text: ' kcal', style: muted.copyWith(fontSize: 11.5)),
                ])),
                DotsButton(onPressed: onMenu, tooltip: 'Food options'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 8, top: 2),
              child: Row(
                children: [
                  Flexible(
                    child: Text(per100 ? '100 g' : servingLabel(f),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.text2, fontSize: 12.5)),
                  ),
                  const SizedBox(width: 10),
                  Text('P ${nf(at(f.protein))} g · C ${nf(at(f.carbs))} g · F ${nf(at(f.fat))} g', style: muted),
                  const Spacer(),
                  DietMark(f.diet),
                  const SizedBox(width: 5),
                  Text(f.diet.short, style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
