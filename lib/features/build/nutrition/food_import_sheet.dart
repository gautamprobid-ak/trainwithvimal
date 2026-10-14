import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

import 'library_widgets.dart';
import 'nutrition_state.dart';

/// "Import foods from Excel": step 1 choose the file, step 2 check and import.
/// (The design's column-matching step is switched off: columns match by name.)
void showFoodImport(BuildContext context, {required VoidCallback onImported}) {
  showAppSheet(
    context,
    title: 'Import foods from Excel',
    builder: (ctx) => _ImportFlow(hostContext: context, onImported: onImported),
  );
}

enum _Dup { skip, update, add }

enum _Filter { all, fresh, dup, check }

class _ImportFlow extends ConsumerStatefulWidget {
  const _ImportFlow({required this.hostContext, required this.onImported});
  final BuildContext hostContext;
  final VoidCallback onImported;

  @override
  ConsumerState<_ImportFlow> createState() => _ImportFlowState();
}

class _ImportFlowState extends ConsumerState<_ImportFlow> {
  static const _rows = LibraryMock.importRows;
  static const _pageSize = 6;
  int _step = 1;
  bool _file = false;
  _Dup _dup = _Dup.skip;
  _Filter _filter = _Filter.all;
  int _page = 0;
  bool _egg = true;
  final _gmap = <String, String>{...LibraryMock.importGroups};
  final _dmap = <String, Diet>{...LibraryMock.importDiets};

  String _status(ImportRow r) => !r.isDuplicate
      ? 'New'
      : switch (_dup) {
          _Dup.skip => 'Skip',
          _Dup.update => 'Update',
          _Dup.add => 'New',
        };

  Diet _dietOf(ImportRow r) => _egg && r.category == 'Egg' ? Diet.egg : (_dmap[r.mainCategory] ?? Diet.veg);
  String _groupOf(ImportRow r) => _gmap[r.category] ?? 'Indian dishes';

  List<ImportRow> get _ready => _rows.where((r) => _status(r) != 'Skip').toList();
  int get _dupN => _rows.where((r) => r.isDuplicate).length;
  int get _checkN => _rows.where((r) => r.kcalDiffers).length;

  void _next() {
    if (_step == 1) {
      if (!_file) {
        showToast(context, 'Choose a file first', subtitle: 'Excel or CSV', kind: ToastKind.warn);
        return;
      }
      setState(() => _step = 3);
      return;
    }
    _import();
  }

  void _import() {
    final ctl = ref.read(foodsProvider.notifier);
    final before = ref.read(foodsProvider);
    var list = [...before];
    var nNew = 0, nUp = 0, nSkip = 0;
    for (final (i, r) in _rows.indexed) {
      final s = _status(r);
      final ug = r.unit == 'g' ? 1.0 : r.unitGrams;
      final v = r.per100;
      if (s == 'Skip') {
        nSkip++;
        continue;
      }
      if (s == 'Update') {
        nUp++;
        list = [
          for (final f in list)
            f.name != r.existing
                ? f
                : f.copyWith(
                    units: f.units.any((u) => u.name == r.unit) ? f.units : [...f.units, FoodUnit(r.unit, ug)],
                    kcal: v[0],
                    protein: v[1],
                    carbs: v[2],
                    fat: v[3],
                    fibre: v[4],
                    source: r.source,
                  ),
        ];
        continue;
      }
      nNew++;
      list = [
        Food(
          id: 'x$i',
          name: r.name,
          units: r.unit == 'g' ? const [FoodUnit('g', 1)] : [const FoodUnit('g', 1), FoodUnit(r.unit, ug)],
          kcal: v[0],
          protein: v[1],
          carbs: v[2],
          fat: v[3],
          fibre: v[4],
          group: _groupOf(r),
          diet: _dietOf(r),
          custom: true,
          defaultUnit: r.unit == 'g' ? 0 : 1,
          defaultQty: r.qty,
          source: r.source,
        ),
        ...list,
      ];
    }
    ctl.restore(list);
    Navigator.of(context).pop();
    widget.onImported();
    showToast(
      widget.hostContext,
      '$nNew foods imported',
      subtitle: nUp > 0 ? '$nUp library foods updated' : (nSkip > 0 ? '$nSkip already in the library were skipped' : 'From Indian foods.xlsx'),
      kind: ToastKind.ok,
      onUndo: () => ctl.restore(before),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _step == 1 ? (_file ? '${_rows.length} rows found' : 'Nothing is saved until the last step') : '${_ready.length} of ${_rows.length} rows will be saved';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_step == 1 ? 'Step 1 of 2 · Choose the file' : 'Step 2 of 2 · Check and import', style: AppText.secondary.copyWith(fontSize: 12.5)),
        const SizedBox(height: 10),
        _Steps(step: _step),
        const SizedBox(height: 14),
        if (_step == 1) _stepOne() else _stepTwo(),
        SheetButtons(note: note, children: [
          if (_step > 1)
            AppButton.ghost('Back', icon: Icons.arrow_back_rounded, onPressed: () => setState(() => _step = 1))
          else
            AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
          AppButton(
            _step == 3 ? 'Import ${_ready.where((r) => _status(r) == 'New').length} foods' : 'Next',
            icon: _step == 3 ? Icons.download_done_rounded : Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ]),
      ],
    );
  }

  Widget _stepOne() {
    return Spaced(
      gap: 16,
      children: [
        FieldBlock(
          label: 'Your file',
          child: _file
              ? FileRow(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFE3F4EA), borderRadius: BorderRadius.circular(9)),
                    child: Text('XLS', style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.okText)),
                  ),
                  title: 'Indian foods.xlsx',
                  subtitle: '${_rows.length} rows · 15 columns · sheet 1',
                  trailing: IconButton(
                      tooltip: 'Remove file', onPressed: () => setState(() => _file = false), icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted)),
                )
              : DropZone(
                  title: 'Drop an Excel or CSV file here',
                  subtitle: 'or click to choose · .xlsx, .xls, .csv · up to 5,000 rows',
                  onTap: () => setState(() => _file = true),
                ),
        ),
        FieldBlock(
          label: 'What each row needs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JoinedList(children: [
                for (final (t, s, req) in LibraryMock.importNeeds)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(t, style: AppText.bodyBold.copyWith(fontSize: 13))),
                        if (req) const AppBadge('Required', tone: BadgeTone.info),
                      ]),
                      Text(s, style: AppText.caption),
                    ]),
                  ),
              ]),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showToast(context, 'Template downloaded', subtitle: 'food-import-template.xlsx · same columns as your sheet', kind: ToastKind.ok),
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: const Text('Download the template'),
                ),
              ),
            ],
          ),
        ),
        const GreyNote(
          child: Text('Write nutrition for the serving in Portion_g, like your sheet does. We turn it into per 100 g, so any unit works later.'),
        ),
      ],
    );
  }

  Widget _stepTwo() {
    final dups = _rows.where((r) => r.isDuplicate).toList();
    final bad = _rows.where((r) => r.kcalDiffers).toList();
    final units = {for (final r in _rows) if (r.unit != 'g') r.unit};
    final know = [
      '${units.length} serving units are made from Portion/Quantity, like 1 tsp, 1 medium and 1 cup. Rows with only grams get Grams.',
      '${_rows.where((r) => r.raw).length} raw foods (rice, oats, chicken, dal…) stay separate from cooked foods. Their grams are very different.',
      '${_rows.where((r) => r.ml).map((r) => r.name).join(' and ')} are in ml. 1 ml is counted as 1 g.',
      'Only the exact same name counts as already in your library. Foods with a different name, like Egg (whole, raw) and Egg (whole), are both imported.',
    ];
    final kpis = [
      ('${_rows.length}', 'Rows in the file', null),
      ('${_rows.where((r) => !r.isDuplicate).length + (_dup == _Dup.add ? _dupN : 0)}', 'New foods', AppColors.okText),
      ('$_dupN', switch (_dup) { _Dup.skip => 'Skipped · already there', _Dup.update => 'Will update', _Dup.add => 'Added again' }, null),
      ('$_checkN', 'Calories differ', _checkN > 0 ? AppColors.warnText : null),
    ];
    return Spaced(
      gap: 16,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            for (final (v, k, c) in kpis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(v, style: AppText.bigNumber.copyWith(fontSize: 20, color: c)),
                  Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
          ],
        ),
        FieldBlock(
          label: 'Already in your library · $_dupN',
          hint: switch (_dup) {
            _Dup.skip => 'Your library keeps its numbers. Nothing changes in meal plans.',
            _Dup.update => 'Library foods get the numbers from your sheet. Meal plans that use them change too.',
            _Dup.add => 'You get two foods with the same name. Clients may pick the wrong one.',
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PillTabs<_Dup>(
              items: const [(_Dup.skip, 'Skip them', null), (_Dup.update, 'Update the numbers', null), (_Dup.add, 'Add as new', null)],
              value: _dup,
              onChanged: (d) => setState(() => _dup = d),
            ),
            const SizedBox(height: 8),
            for (final d in dups)
              Row(children: [
                Flexible(child: Text(d.name, style: AppText.caption)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.muted)),
                Flexible(child: Text(d.existing, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text))),
              ]),
          ]),
        ),
        _mappings(),
        if (bad.isNotEmpty)
          InfoBanner(
            icon: Icons.warning_amber_rounded,
            bg: AppColors.warnBg,
            fg: AppColors.warnText,
            text: '${plural(bad.length, 'food has', 'foods have')} calories that do not match protein, carbs and fat. '
                '${bad.map((r) => r.name).join(', ')}. The calories from your sheet are saved. You can fix them later in the food.',
          ),
        FieldBlock(
          label: 'Good to know',
          child: Column(children: [
            for (final k in know)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.okText)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(k, style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2))),
                ]),
              ),
          ]),
        ),
        _preview(),
      ],
    );
  }

  Widget _mapRow(String name, String example, String value, List<String> opts, ValueChanged<String> onPick) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13)),
            Text(example, style: AppText.caption),
          ]),
        ),
        PopupMenuButton<String>(
          tooltip: name,
          onSelected: onPick,
          itemBuilder: (_) => [
            for (final o in opts)
              PopupMenuItem(
                value: o,
                child: Row(children: [
                  Expanded(child: Text(o == 'Beverages' ? 'Beverages (new group)' : o)),
                  if (o == value) const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
                ]),
              ),
          ],
          child: Container(
            width: 150,
            height: 36,
            padding: const EdgeInsets.only(left: 10, right: 6),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.text))),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _mappings() {
    String count(int n) => plural(n, 'food');
    final cats = {for (final r in _rows) r.category}.toList();
    const groups = ['Protein', 'Carbs', 'Fats', 'Veg', 'Fruits', 'Dairy', 'Indian dishes', 'Beverages'];
    final dietByLabel = {for (final d in Diet.values) d.label: d};
    return Spaced(gap: 16, children: [
      FieldBlock(
        label: 'Category → food library group',
        hint: 'Egg and egg are treated as one. A group that does not exist yet is created.',
        child: JoinedList(children: [
          for (final c in cats)
            _mapRow(c, count(_rows.where((r) => r.category == c).length), _gmap[c] ?? 'Indian dishes', groups, (v) => setState(() => _gmap[c] = v)),
        ]),
      ),
      FieldBlock(
        label: 'Main_Category → diet',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          JoinedList(children: [
            for (final c in const ['Vegetarian', 'Non-Vegetarian', 'Dairy'])
              _mapRow(c, count(_rows.where((r) => r.mainCategory == c).length), (_dmap[c] ?? Diet.veg).label, [for (final d in Diet.values) d.label],
                  (v) => setState(() => _dmap[c] = dietByLabel[v]!)),
          ]),
          const SizedBox(height: 8),
          ToggleRow(
            on: _egg,
            title: 'Egg rows are Eggetarian',
            subtitle: 'Your sheet marks eggs as Non-Vegetarian. ${_rows.where((r) => r.category == 'Egg').length} rows.',
            onTap: () => setState(() => _egg = !_egg),
          ),
        ]),
      ),
    ]);
  }

  Widget _preview() {
    bool inF(ImportRow r) => switch (_filter) {
          _Filter.all => true,
          _Filter.fresh => !r.isDuplicate,
          _Filter.dup => r.isDuplicate,
          _Filter.check => r.kcalDiffers,
        };
    final list = _rows.where(inF).toList();
    final pages = (list.length / _pageSize).ceil().clamp(1, 999);
    final pg = _page.clamp(0, pages - 1);
    final shown = list.skip(pg * _pageSize).take(_pageSize).toList();
    return FieldBlock(
      label: 'Preview · per 100 g',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillTabs<_Filter>(
            items: [
              (_Filter.all, 'All', _rows.length),
              (_Filter.fresh, 'New', _rows.length - _dupN),
              (_Filter.dup, 'Already there', _dupN),
              (_Filter.check, 'Check', _checkN),
            ],
            value: _filter,
            onChanged: (f) => setState(() {
              _filter = f;
              _page = 0;
            }),
          ),
          const SizedBox(height: 8),
          JoinedList(children: [for (final r in shown) _PreviewRow(row: r, status: _status(r), diet: _dietOf(r), group: _groupOf(r))]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text(list.isEmpty ? 'Nothing here' : '${pg * _pageSize + 1}–${(pg * _pageSize + _pageSize).clamp(0, list.length)} of ${list.length}',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ),
            AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous page', onPressed: pg > 0 ? () => setState(() => _page = pg - 1) : null),
            const SizedBox(width: 6),
            AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next page', onPressed: pg < pages - 1 ? () => setState(() => _page = pg + 1) : null),
          ]),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget item(String n, String t, bool on, bool done) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? AppColors.accent : (done ? AppColors.okBg : Colors.white),
              border: Border.all(color: on ? AppColors.accent : (done ? AppColors.okBg : AppColors.line2)),
            ),
            child: Text(done ? '✓' : n,
                style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? Colors.white : (done ? AppColors.okText : AppColors.text2))),
          ),
          const SizedBox(width: 6),
          Text(t, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: on ? AppColors.text : AppColors.muted)),
        ]);
    return Row(children: [
      item('1', 'Upload', step == 1, step > 1),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: SizedBox(width: 20, child: Divider())),
      item('2', 'Check and import', step == 3, false),
    ]);
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.row, required this.status, required this.diet, required this.group});
  final ImportRow row;
  final String status;
  final Diet diet;
  final String group;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final differs = r.kcalDiffers && status != 'Skip';
    final tone = status == 'Skip'
        ? BadgeTone.neutral
        : differs
            ? BadgeTone.warn
            : status == 'Update'
                ? BadgeTone.info
                : BadgeTone.ok;
    final sv = r.unit == 'g' ? '${fq(r.qty)} g' : '${r.unit} · ${fq(r.unitGrams)} g';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13))),
          const SizedBox(width: 6),
          AppBadge(differs ? '$status · kcal differs' : status, tone: tone),
        ]),
        const SizedBox(height: 3),
        Text('$sv · ${r.per100[0].round()} kcal · P ${nf(r.per100[1])} · C ${nf(r.per100[2])} · F ${nf(r.per100[3])}', style: AppText.caption),
        const SizedBox(height: 2),
        Row(children: [
          Text(group, style: AppText.caption.copyWith(color: AppColors.text2, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          DietMark(diet),
          const SizedBox(width: 5),
          Text(diet.label, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
