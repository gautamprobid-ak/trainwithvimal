import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/training_widgets.dart';
import 'progress_sheets.dart';
import 'progress_state.dart';
import 'progress_widgets.dart';

const _histRanges = [('This week', 7), ('Month', 30), ('3 months', 91)];
const _histTypes = <(String, HistType?)>[('All', null), ('Workouts', HistType.workout), ('Meals', HistType.meal), ('Check-ins', HistType.checkin), ('Weight', HistType.weight)];

// ---------------------------------------------------------------- history

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(progressProvider);
    final c = ref.read(progressProvider.notifier);
    final today = ClientTrainingMock.today;
    final all = buildHistory(s.weighIns, s.photoSets);
    final span = _histRanges[s.histRange].$2;
    final ht = s.histType == null ? null : HistType.values.byName(s.histType!);
    final inR = all.where((x) => TDate.daysBetween(x.date, today) < span).toList();
    final days = [
      for (final x in inR)
        if (x.entries.any((e) => ht == null || e.type == ht)) HistDay(x.date, x.entries.where((e) => ht == null || e.type == ht).toList(), x.score),
    ];
    final allE = inR.expand((x) => x.entries).toList();
    final wo = allE.where((e) => e.type == HistType.workout).toList();
    final ml = allE.where((e) => e.type == HistType.meal && !e.partial).toList();
    final wIn = s.weighIns.where((w) => TDate.daysBetween(w.date, today) < span).toList();
    double avg(Iterable<num> a) => a.isEmpty ? 0 : a.fold<num>(0, (p, x) => p + x) / a.length;
    final rangeLbl = inR.isEmpty ? 'No logs yet' : '${TDate.dm(inR.last.date)} – ${TDate.dm(inR.first.date)} 2026';
    final tName = (_histTypes.firstWhere((t) => t.$2 == ht, orElse: () => ('logs', null)).$1).toLowerCase();
    final sum = [
      ('Workouts done', '${wo.where((e) => !e.missed).length}/${wo.length}', 'sessions'),
      ('Avg calories', TNum.n(avg(ml.map((e) => e.kcal))), '/ 1,650 kcal'),
      ('Avg protein', '${avg(ml.map((e) => e.protein)).round()} g', '/ 120 g'),
      (
        'Weight change',
        wIn.length > 1 ? TNum.change(wIn.last.kg - wIn.first.kg, 'kg') : '—',
        wIn.length > 1 ? '${TNum.k1(wIn.first.kg)} → ${TNum.k1(wIn.last.kg)}' : 'not enough weigh-ins',
      ),
    ];
    final shown = days.take(s.histShown).toList();
    final showScore = ht == null || ht == HistType.workout || ht == HistType.meal;
    return PageScroll(children: [
      BackLink('Progress', onTap: () => c.set((x) => x.copyWith(view: ProgressView.main))),
      PageHeader(title: 'History', subtitle: 'All your logs in one place · $rangeLbl'),
      SegmentedTabs<int>(
        items: [for (var i = 0; i < _histRanges.length; i++) (i, _histRanges[i].$1)],
        value: s.histRange,
        onChanged: (v) => c.set((x) => x.copyWith(histRange: v, histShown: 7)),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final t in _histTypes) ...[
            ChoicePill(t.$1, selected: t.$2 == ht, onTap: () => c.set((x) => x.copyWith(histType: () => t.$2?.name, histShown: 7))),
            const SizedBox(width: 6),
          ],
        ]),
      ),
      AppCard(
        child: Spaced(gap: 10, children: [
          Row(children: [
            Text('SUMMARY', style: AppText.overline.copyWith(fontSize: 11)),
            const SizedBox(width: 8),
            Expanded(child: Text('${_histRanges[s.histRange].$1} · ${inR.length} days', style: AppText.bodyBold.copyWith(fontSize: 13.5))),
            Pill('${avg(inR.map((x) => x.score)).round()}% adherence', tone: 'green'),
          ]),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              for (final (n, v, u) in sum)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(n, style: AppText.caption.copyWith(fontSize: 11)),
                    Text(v, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                    Text(u, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
                  ]),
                ),
            ],
          ),
        ]),
      ),
      for (final d in shown) _DayBlock(d: d, showScore: showScore, today: today),
      if (days.isEmpty)
        AppCard(
          child: EmptyState(
            icon: Icons.history_rounded,
            title: 'No $tName in this range',
            message: 'Nothing was logged in this range. Try a longer range or show every type.',
            action: Wrap(spacing: 8, children: [
              if (s.histRange != 2) AppButton.outline('Try 3 months', small: true, onPressed: () => c.set((x) => x.copyWith(histRange: 2, histShown: 7))),
              if (ht != null) AppButton.outline('Show all types', small: true, onPressed: () => c.set((x) => x.copyWith(histType: () => null, histShown: 7))),
            ]),
          ),
        ),
      if (days.length > s.histShown)
        Center(
          child: AppButton.outline(
            'Show ${(days.length - s.histShown).clamp(0, 10)} more days · ${days.length - s.histShown} left',
            onPressed: () => c.set((x) => x.copyWith(histShown: x.histShown + 10)),
          ),
        ),
      if (days.isNotEmpty && days.length <= s.histShown)
        Center(child: Text('That’s everything for $rangeLbl', style: AppText.secondary.copyWith(fontSize: 12.5))),
    ]);
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.d, required this.showScore, required this.today});
  final HistDay d;
  final bool showScore;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final diff = TDate.daysBetween(d.date, today);
    final tag = diff == 0 ? 'Today' : (diff == 1 ? 'Yesterday' : null);
    final sc = d.score >= 90 ? AppColors.okText : (d.score >= 75 ? AppColors.text2 : const Color(0xFFA15C00));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Row(children: [
          Text(TDate.wdm(d.date), style: AppText.bodyBold),
          if (tag != null) ...[const SizedBox(width: 8), AppChip(tag)],
          const Spacer(),
          if (showScore) Text('${d.score}%', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: sc)),
        ]),
      ),
      AppCard(
        onTap: () => ProgressSheets.day(context, d),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(children: [for (final e in d.entries) HistEntryRow(e: e)]),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- photos timeline

class PhotosView extends ConsumerWidget {
  const PhotosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(progressProvider);
    final c = ref.read(progressProvider.notifier);
    final ps = s.photoSets;
    final pick = s.pick.where((i) => i < ps.length).toList();
    final ready = pick.length == 2;
    final nPh = ps.fold(0, (a, x) => a + x.poses.length);
    // group by month, newest first
    final months = <String, List<int>>{};
    for (var i = ps.length - 1; i >= 0; i--) {
      months.putIfAbsent(TDate.month(ps[i].date), () => []).add(i);
    }
    final latest = ps.last;
    final today = ClientTrainingMock.today;
    return Stack(children: [
      PageScroll(padding: const EdgeInsets.fromLTRB(16, 6, 16, 96), children: [
        BackLink('Progress', onTap: () => c.set((x) => x.copyWith(view: ProgressView.main))),
        PageHeader(
          title: 'Progress photos',
          subtitle: '${ps.length} sets · $nPh photos · since ${TDate.dm(ps.first.date)}',
          actions: [AppButton.outline('Add photos', icon: Icons.add_a_photo_outlined, small: true, onPressed: () => ProgressSheets.addPhotos(context, ref))],
        ),
        SegmentedTabs<String>(items: [for (final p in ClientTrainingMock.poses) (p, p)], value: s.pose, onChanged: (v) => c.set((x) => x.copyWith(pose: v))),
        const InfoBanner(icon: Icons.lock_outline_rounded, text: 'Only you and Coach Aman can see these. Tap two sets to compare.'),
        for (final m in months.entries)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(m.key, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text('${m.value.length} ${m.value.length == 1 ? 'set' : 'sets'}', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              childAspectRatio: .52,
              children: [
                for (final i in m.value)
                  GestureDetector(
                    onTap: () => c.togglePick(i),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      PhotoTile(
                        tint: ps[i].tint,
                        none: !ps[i].poses.contains(s.pose),
                        selected: pick.contains(i),
                        badge: pick.contains(i) ? 'AB'[pick.indexOf(i)] : null,
                        tag: s.pose,
                      ),
                      const SizedBox(height: 4),
                      Text(TDate.wdm(ps[i].date), style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                      Text('${TNum.kg(ps[i].kg)} · ${ps[i].label}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
                    ]),
                  ),
              ],
            ),
          ]),
        AppCard(
          child: Row(children: [
            const TintIcon(Icons.photo_camera_outlined, tint: Tint.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(latest.date == today ? 'Today’s set · ${latest.poses.length} of 3 poses added' : 'Next set due Sun, 11 Oct', style: AppText.bodyBold),
                Text('Same spot, same light, in the morning before eating', style: AppText.caption),
              ]),
            ),
            AppButton.outline('Add', small: true, onPressed: () => ProgressSheets.addPhotos(context, ref)),
          ]),
        ),
      ]),
      Positioned(
        left: 12,
        right: 12,
        bottom: 12,
        child: Material(
          color: Colors.white,
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${pick.length} of 2 selected', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(
                    ready
                        ? '${TDate.dm(ps[pick[0]].date)} vs ${TDate.dm(ps[pick[1]].date)} · ${TNum.change(ps[pick[1]].kg - ps[pick[0]].kg, 'kg')}'
                        : (pick.isNotEmpty ? 'Pick one more set' : 'Tap two sets to compare'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ]),
              ),
              Opacity(
                opacity: ready ? 1 : .5,
                child: AppButton('Compare', icon: Icons.compare_rounded, small: true, onPressed: () {
                  if (ready) {
                    c.set((x) => x.copyWith(view: ProgressView.compare));
                  } else {
                    showToast(context, 'Pick two sets first', subtitle: 'Tap two photos in the timeline');
                  }
                }),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- compare

class CompareView extends ConsumerWidget {
  const CompareView({super.key});

  int _mAt(DateTime d) {
    var k = 0;
    final md = ClientTrainingMock.measurementDates;
    for (var i = 0; i < md.length; i++) {
      if (!md[i].isAfter(d)) k = i;
    }
    return k;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(progressProvider);
    final c = ref.read(progressProvider.notifier);
    final ps = s.photoSets;
    final a = s.pick[0], b = s.pick[1];
    final aa = ps[a], bb = ps[b];
    final days = TDate.daysBetween(aa.date, bb.date);
    final ma = _mAt(aa.date), mb = _mAt(bb.date);
    final rows = [
      CmpRow('Weight', aa.kg, bb.kg, 'kg'),
      for (final m in ClientTrainingMock.measurements) CmpRow(m.name, m.values[ma], m.values[mb], m.unit),
    ];
    final sum = 'In $days days: ${rows.take(3).map((r) => '${r.label.toLowerCase()} ${TNum.change(r.b - r.a, r.unit)}').join(', ')}.';
    Widget side(int j) {
      final i = j == 0 ? a : b;
      final p = ps[i];
      final lo = j == 0 ? 0 : a + 1, hi = j == 0 ? b - 1 : ps.length - 1;
      void setP(int n) => c.set((x) => x.copyWith(pick: j == 0 ? [n, b] : [a, n]));
      return Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PhotoTile(
            tint: p.tint,
            none: !p.poses.contains(s.pose),
            aspect: 4 / 5,
            badge: j == 0 ? 'A' : 'B',
            badgeAccent: j == 1,
            tag: '${TDate.dm(p.date)} · ${s.pose}',
            iconSize: 56,
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(TDate.wdm(p.date), style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                Text('${TNum.kg(p.kg)} · ${p.label.replaceAll(' check-in', '')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Earlier set', onPressed: i > lo ? () => setP(i - 1) : null),
            const SizedBox(width: 6),
            AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Later set', onPressed: i < hi ? () => setP(i + 1) : null),
          ]),
        ]),
      );
    }

    return PageScroll(children: [
      BackLink('Timeline', onTap: () => c.set((x) => x.copyWith(view: ProgressView.photos))),
      PageHeader(title: 'Compare', subtitle: '${s.pose} · ${TDate.dm(aa.date)} → ${TDate.dm(bb.date)}'),
      SegmentedTabs<String>(items: [for (final p in ClientTrainingMock.poses) (p, p)], value: s.pose, onChanged: (v) => c.set((x) => x.copyWith(pose: v))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [side(0), const SizedBox(width: 10), side(1)]),
      AppCard(
        child: Spaced(gap: 10, children: [
          PxHead(title: 'Measurements', subtitle: '$days days apart · measured on the nearest check-in'),
          CompareTable(ha: TDate.dm(aa.date), hb: TDate.dm(bb.date), rows: rows),
          Text(sum, style: AppText.secondary.copyWith(fontSize: 12.5)),
        ]),
      ),
      const SizedBox.shrink(),
    ]);
  }
}
