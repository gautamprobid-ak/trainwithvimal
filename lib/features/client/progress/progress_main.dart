import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/training_widgets.dart';
import 'progress_charts.dart';
import 'progress_sheets.dart';
import 'progress_state.dart';
import 'progress_widgets.dart';

const _ranges = [('4 wk', 28), ('12 wk', 84), ('6 mo', 182), ('All', 0)];

class GoalCard extends ConsumerWidget {
  const GoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(progressProvider.select((s) => s.last));
    const start = ClientTrainingMock.startKg, goal = ClientTrainingMock.goalKg;
    final lost = start - last.kg;
    final gp = (lost / (start - goal)).clamp(0.0, 1.0);
    final reached = last.kg <= goal;
    final cells = [('Start', TNum.kg(start), '12 Jan'), ('Now', TNum.kg(last.kg), TDate.dm(last.date)), ('Goal', TNum.kg(goal), 'Feb 2027')];
    return AppCard(
      child: Spaced(gap: 10, children: [
        Row(children: [
          Text('Goal weight', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          const Tooltip(
            message: 'Set with Aman when you joined. It was 70 kg until July. Target date: Feb 2027.',
            triggerMode: TooltipTriggerMode.tap,
            child: Icon(Icons.info_outline_rounded, size: 16, color: AppColors.muted),
          ),
          const Spacer(),
          Pill(reached ? 'Goal reached' : '${TNum.k1(last.kg - goal)} kg to go', tone: reached ? 'green' : 'blue'),
        ]),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(color: i == 1 ? AppColors.accentSoft : AppColors.sub, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cells[i].$1, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  FittedBox(
                    child: Text(cells[i].$2,
                        style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800, color: i == 1 ? AppColors.accentText : AppColors.text)),
                  ),
                  Text(cells[i].$3, style: AppText.caption.copyWith(fontSize: 11.5)),
                ]),
              ),
            ),
          ],
        ]),
        ProgressBar(gp, height: 8, track: AppColors.sub),
        Row(children: [
          Expanded(child: Text('${lost >= 0 ? '${TNum.k1(lost)} kg lost' : '${TNum.k1(-lost)} kg up'} since 12 Jan', style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
          Text('${(gp * 100).round()}% of the way', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class TabsRow extends ConsumerWidget {
  const TabsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(progressProvider);
    final c = ref.read(progressProvider.notifier);
    return Row(children: [
      Expanded(
        child: SegmentedTabs<String>(
          items: const [('Weight', 'Weight'), ('Body', 'Body'), ('Strength', 'Strength')],
          value: s.tab,
          onChanged: (v) => c.set((x) => x.copyWith(tab: v)),
        ),
      ),
      const SizedBox(width: 8),
      ChoicePill('Compare', icon: Icons.compare_arrows_rounded, selected: s.compareOn, accent: true, onTap: () => c.set((x) => x.copyWith(compareOn: !x.compareOn))),
    ]);
  }
}

class FirstVsNowCard extends ConsumerWidget {
  const FirstVsNowCard({super.key, required this.onPhotos});
  final VoidCallback onPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(progressProvider.select((s) => s.last));
    final weeks = (TDate.daysBetween(ClientTrainingMock.startDate, last.date) / 7).round();
    return AppCard(
      child: Spaced(gap: 10, children: [
        PxHead(title: 'First day vs now', subtitle: '12 Jan → ${TDate.dm(last.date)} · $weeks weeks'),
        CompareTable(ha: '12 Jan', hb: 'Now', rows: [
          CmpRow('Weight', ClientTrainingMock.startKg, last.kg, 'kg'),
          const CmpRow('Waist', 88, 78, 'cm'),
          const CmpRow('Hips', 104, 98, 'cm'),
          const CmpRow('Body fat', 32, 27, '%'),
        ]),
        AppButton.outline('Compare photos side by side', icon: Icons.photo_library_outlined, small: true, onPressed: onPhotos),
      ]),
    );
  }
}

class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(progressProvider);
    final c = ref.read(progressProvider.notifier);
    final wts = s.weighIns, last = s.last;
    final days = _ranges[s.range].$2;
    final from = days == 0 ? DateTime(1900) : DateTime(last.date.year, last.date.month, last.date.day - days + 1);
    final shown = wts.where((w) => !w.date.isBefore(from)).toList();
    final wks = (TDate.daysBetween(shown.first.date, shown.last.date) / 7).round().clamp(1, 9999);
    final sel = s.selected != null && shown.any((w) => w.date == s.selected) ? s.selected : null;
    final mid = shown.first.date.add(Duration(days: TDate.daysBetween(shown.first.date, shown.last.date) ~/ 2));
    return AppCard(
      child: Spaced(gap: 10, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
              Text(TNum.kg(last.kg), style: AppText.bigNumber),
            ]),
          ),
          Text(shown.length < 2 ? 'First weigh-in' : '${TNum.change(last.kg - shown.first.kg, 'kg')} in $wks ${wks == 1 ? 'wk' : 'wks'}',
              style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.okText)),
        ]),
        WeightChart(
          shown: shown,
          selected: sel,
          onPick: (d) => c.set((x) => x.copyWith(selected: () => x.selected == d ? null : d)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final d in [shown.first.date, mid, shown.last.date]) Text(TDate.dm(d), style: AppText.caption.copyWith(fontSize: 11)),
          ]),
        ),
        if (sel != null) _SelectedWeighIn(date: sel, wts: wts, onClose: () => c.set((x) => x.copyWith(selected: () => null))) else Text('Tap a dot to see that weigh-in.', style: AppText.secondary.copyWith(fontSize: 12.5)),
        SegmentedTabs<int>(
          items: [for (var i = 0; i < _ranges.length; i++) (i, _ranges[i].$1)],
          value: s.range,
          onChanged: (v) => c.set((x) => x.copyWith(range: v)),
        ),
      ]),
    );
  }
}

class _SelectedWeighIn extends StatelessWidget {
  const _SelectedWeighIn({required this.date, required this.wts, required this.onClose});
  final DateTime date;
  final List<WeighIn> wts;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final w = wts.firstWhere((x) => x.date == date);
    final before = wts.where((x) => x.date.isBefore(date)).toList();
    final prev = before.isEmpty ? null : before.last;
    const start = ClientTrainingMock.startKg, goal = ClientTrainingMock.goalKg;
    final cells = [
      ('Vs previous', prev != null ? TNum.change(w.kg - prev.kg, 'kg') : '—', prev != null ? '${TDate.dm(prev.date)} · ${TNum.kg(prev.kg)}' : 'First weigh-in', prev == null ? null : w.kg <= prev.kg),
      ('Since start', TNum.change(w.kg - start, 'kg'), '12 Jan · ${TNum.kg(start)}', w.kg <= start),
      ('To goal', w.kg <= goal ? 'Reached' : '${TNum.k1(w.kg - goal)} kg', 'Goal ${TNum.kg(goal)}', null),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(children: [
          const TintIcon(Icons.monitor_weight_outlined, tint: Tint.amber, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(TDate.wdm(w.date), style: AppText.bodyBold),
              Text('${TNum.kg(w.kg)}${w.date == wts.last.date ? ' · latest weigh-in' : ''}', style: AppText.caption),
            ]),
          ),
          AppIconButton(Icons.close_rounded, small: true, tooltip: 'Close', onPressed: onClose),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cells[i].$1, style: AppText.caption.copyWith(fontSize: 11)),
                  Text(cells[i].$2,
                      style: AppText.bodyBold.copyWith(color: cells[i].$4 == null ? AppColors.text : (cells[i].$4! ? AppColors.okText : AppColors.warnText))),
                  Text(cells[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
                ]),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class BodyCard extends ConsumerWidget {
  const BodyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(progressProvider.select((s) => s.openMeasure));
    final c = ref.read(progressProvider.notifier);
    final dates = ClientTrainingMock.measurementDates;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PxHead(title: 'Body measurements', subtitle: 'Measured every 2 weeks with your photo check-in'),
        const SizedBox(height: 6),
        for (var r = 0; r < ClientTrainingMock.measurements.length; r++) ...[
          if (r > 0) const Divider(height: 1),
          Builder(builder: (_) {
            final m = ClientTrainingMock.measurements[r];
            final d = m.values.last - m.values.first;
            final mx = m.values.reduce((a, b) => a > b ? a : b);
            final isOpen = open == m.name;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              InkWell(
                onTap: () => c.set((x) => x.copyWith(openMeasure: () => isOpen ? null : m.name)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.name, style: AppText.bodyBold),
                        Text('From ${TNum.amount(m.values.first, m.unit)} on 12 Jan', style: AppText.caption),
                      ]),
                    ),
                    Text(TNum.amount(m.values.last, m.unit), style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Pill(TNum.change(d, m.unit), tone: d < 0 ? 'green' : (d > 0 ? 'amber' : 'gray')),
                    AnimatedRotation(
                      turns: isOpen ? .5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.muted),
                    ),
                  ]),
                ),
              ),
              if (isOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(children: [
                    MeasureChart(m: m),
                    const SizedBox(height: 6),
                    for (var i = dates.length - 1; i >= 0; i--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          SizedBox(width: 52, child: Text(TDate.dm(dates[i]), style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                          Expanded(child: ProgressBar(m.values[i] / mx, color: i == dates.length - 1 ? AppColors.accent : const Color(0xFF93B4F8), track: AppColors.sub)),
                          SizedBox(
                            width: 52,
                            child: Text(TNum.amount(m.values[i], m.unit), textAlign: TextAlign.right, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
                          ),
                        ]),
                      ),
                  ]),
                ),
            ]);
          }),
        ],
        const SizedBox(height: 6),
        Text('Next measurements are due with your week 7 check-in on Sun, 11 Oct.', style: AppText.secondary.copyWith(fontSize: 12.5)),
      ]),
    );
  }
}

class StrengthCard extends StatelessWidget {
  const StrengthCard({super.key, required this.onHistory});
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PxHead(title: 'Strength', subtitle: 'Your best working set per lift'),
        const SizedBox(height: 6),
        for (var i = 0; i < ClientTrainingMock.lifts.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Builder(builder: (_) {
            final l = ClientTrainingMock.lifts[i];
            final f = l.points.first, e = l.points.last;
            final w = (TDate.daysBetween(f.$1, e.$1) / 7).round().clamp(1, 999);
            return InkWell(
              onTap: () => ProgressSheets.lift(context, l, onHistory: onHistory),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.name, style: AppText.bodyBold),
                      Text('Best set ${l.best}', style: AppText.caption),
                    ]),
                  ),
                  Sparkline(points: l.points),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(TNum.amount(e.$2, 'kgs'), style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                      Text('${TNum.change(e.$2 - f.$2, 'kgs')} in $w wks', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.okText)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }
}

class PhotosCard extends ConsumerWidget {
  const PhotosCard({super.key, required this.onAll, required this.onCompare});
  final VoidCallback onAll;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(progressProvider.select((s) => s.photoSets));
    final latest = sets.last;
    return AppCard(
      child: Spaced(gap: 10, children: [
        PxHead(
          title: 'Photos',
          subtitle: 'Latest set · ${TDate.dm(latest.date)} · ${TNum.kg(latest.kg)}',
          trailing: TextButton(onPressed: onAll, child: const Text('All photos')),
        ),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => ProgressSheets.photo(context, ref, sets.length - 1, ClientTrainingMock.poses[i], onCompare: (si, p) {
                  ref.read(progressProvider.notifier).set((x) => x.copyWith(view: ProgressView.compare, pick: si == 0 ? [0, x.photoSets.length - 1] : [0, si], pose: p));
                }),
                child: Column(children: [
                  PhotoTile(tint: latest.tint, none: !latest.poses.contains(ClientTrainingMock.poses[i])),
                  const SizedBox(height: 4),
                  Text(ClientTrainingMock.poses[i], style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ]),
        Row(children: [
          Expanded(child: AppButton.outline('Add photos', icon: Icons.add_a_photo_outlined, small: true, expand: true, onPressed: () => ProgressSheets.addPhotos(context, ref))),
          const SizedBox(width: 8),
          Expanded(child: AppButton.outline('Compare', icon: Icons.compare_rounded, small: true, expand: true, onPressed: onCompare)),
        ]),
      ]),
    );
  }
}

class StatTiles extends ConsumerWidget {
  const StatTiles({super.key, required this.onWorkouts});
  final VoidCallback onWorkouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(progressProvider.notifier);
    final tiles = [
      ('Waist', '78 cm', () => c.set((x) => x.copyWith(tab: 'Body', openMeasure: () => 'Waist'))),
      ('Workouts', '25', onWorkouts),
      ('Bench best', '45 kg', () => c.set((x) => x.copyWith(tab: 'Strength'))),
    ];
    return Row(children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            onTap: tiles[i].$3,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tiles[i].$1, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
              Text(tiles[i].$2, style: AppText.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ],
    ]);
  }
}

String adherenceAvg() {
  final a = ClientTrainingMock.adherence;
  return '${(a.fold(0, (s, w) => s + w.pct) / a.length).round()}%';
}

class AdherenceCard extends ConsumerWidget {
  const AdherenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aw = ref.watch(progressProvider.select((s) => s.adhWeek));
    final c = ref.read(progressProvider.notifier);
    final ad = ClientTrainingMock.adherence;
    final a = ad[aw];
    final lastI = ad.length - 1;
    final line = '${aw == lastI ? 'This week · ${a.done} of ${a.planned} workouts so far' : 'Week of ${TDate.dm(a.start)} · ${a.done} of ${a.planned} workouts'}'
        ' · ${a.pct}% of the plan followed';
    return AppCard(
      child: Spaced(gap: 12, children: [
        PxHead(title: 'Adherence', subtitle: 'Fat Loss Phase 1 · 25 of 28 workouts so far', trailing: Pill('${adherenceAvg()} avg', tone: 'green')),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < ad.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _AdhBar(w: ad[i], on: i == aw, label: i == lastI ? 'This wk' : TDate.dm(ad[i].start), onTap: () => c.set((x) => x.copyWith(adhWeek: i)))),
          ],
        ]),
        Row(children: [
          const Icon(Icons.insights_rounded, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(line, style: AppText.secondary.copyWith(fontSize: 12.5))),
        ]),
      ]),
    );
  }
}

class _AdhBar extends StatelessWidget {
  const _AdhBar({required this.w, required this.on, required this.label, required this.onTap});
  final AdherenceWeek w;
  final bool on;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lo = w.pct < 85;
    final color = on ? (lo ? const Color(0xFFE39B12) : AppColors.accent) : (lo ? const Color(0xFFF5C46B) : const Color(0xFFA8C2F7));
    final txt = on ? AppColors.text : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Text('${w.pct}%', style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: txt)),
        const SizedBox(height: 4),
        Container(
          height: 72,
          constraints: const BoxConstraints(maxWidth: 40),
          decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: w.pct / 100,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: txt)),
      ]),
    );
  }
}
