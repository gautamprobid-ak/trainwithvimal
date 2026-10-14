import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../home/home_sheets.dart' show QuickPicks;
import '../train/training_widgets.dart';
import 'progress_state.dart';
import 'progress_widgets.dart';

abstract final class ProgressSheets {
  // ------------------------------------------------------------ log weight

  static Future<void> logWeight(BuildContext context, WidgetRef ref) {
    final st = ref.read(progressProvider);
    final today = ClientTrainingMock.today;
    var kg = st.last.kg;
    var day = today;
    return showLiveSheet<void>(
      context,
      builder: (ctx, setSheet) {
        final wts = ref.read(progressProvider).weighIns;
        final ex = wts.where((w) => w.date == day).firstOrNull;
        final before = wts.where((w) => w.date.isBefore(day)).toList();
        final prev = before.isEmpty ? null : before.last;
        final note = ex != null
            ? 'Replaces the ${TNum.kg(ex.kg)} you logged on ${TDate.wdm(day)}.'
            : prev != null
                ? '${TDate.wdm(day)} · ${TNum.change(kg - prev.kg, 'kg')} since ${TDate.dm(prev.date)} (${TNum.kg(prev.kg)}).'
                : 'Your first weigh-in.';
        void setKg(double v) => setSheet(() => kg = TNum.r1(v.clamp(30, 200)));
        final days = [for (var o = 0; o < 4; o++) DateTime(today.year, today.month, today.day - o)];
        String dayLabel(int o) => o == 0 ? 'Today' : (o == 1 ? 'Yesterday' : TDate.wdm(days[o]));
        return SheetContent(
          title: 'Log weight',
          subtitle: 'Morning, before eating, gives the steadiest numbers',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Weight', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
              const SizedBox(height: 6),
              Row(children: [
                AppIconButton(Icons.remove_rounded, tooltip: 'Less', onPressed: () => setKg(kg - .1)),
                Expanded(child: Text(TNum.kg(kg), textAlign: TextAlign.center, style: AppText.bigNumber.copyWith(fontSize: 30))),
                AppIconButton(Icons.add_rounded, tooltip: 'More', onPressed: () => setKg(kg + .1)),
              ]),
              const SizedBox(height: 10),
              QuickPicks(items: [
                for (final v in [-1.0, -.5, .5, 1.0]) ('${v > 0 ? '+' : '−'}${TNum.short(v.abs())} kg', () => setKg(kg + v)),
              ]),
              const SizedBox(height: 14),
              Text('Date', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
              const SizedBox(height: 6),
              QuickPicks(
                selected: dayLabel(days.indexOf(day)),
                items: [for (var o = 0; o < 4; o++) (dayLabel(o), () => setSheet(() => day = days[o]))],
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(child: Text(note, style: AppText.secondary.copyWith(fontSize: 12.5))),
              ]),
            ],
          ),
          actions: [
            AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
            AppButton('Save', icon: Icons.check_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              _saveWeight(context, ref, day, kg, replaced: ex != null);
            }),
          ],
        );
      },
    );
  }

  static void _saveWeight(BuildContext context, WidgetRef ref, DateTime day, double kg, {required bool replaced}) {
    final c = ref.read(progressProvider.notifier);
    final prev = ref.read(progressProvider);
    const start = ClientTrainingMock.startKg;
    final b4 = (start - prev.last.kg).floor();
    c.logWeight(day, kg);
    final af = (start - ref.read(progressProvider).last.kg).floor();
    void undo() => c.set((s) => s.copyWith(weighIns: prev.weighIns, selected: () => prev.selected));
    if (af > b4 && af >= 1) {
      showToast(context, 'New milestone: $af kg lost', subtitle: '${TNum.kg(kg)} · ${TDate.dm(day)} · Aman can see it', kind: ToastKind.star, onUndo: undo);
    } else {
      showToast(context, replaced ? 'Weight updated' : 'Weight logged', subtitle: '${TNum.kg(kg)} · ${TDate.wdm(day)}', kind: ToastKind.ok, onUndo: undo);
    }
  }

  // ------------------------------------------------------------ workouts / lift

  static Future<void> workouts(BuildContext context, {required VoidCallback onHistory, required String avg}) {
    return showAppSheet<void>(
      context,
      title: '25 workouts done',
      subtitle: 'Since 31 Aug · Fat Loss Phase 1',
      builder: (_) => Column(children: [
        const KvLine('This week', '3 of 5 · Cardio and core is today'),
        const KvLine('Planned so far', '28'),
        const KvLine('Missed', '3 · 17 Sep, 25 Sep, 1 Oct'),
        KvLine('Average adherence', avg),
      ]),
      actions: (ctx) => [
        AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('View past logs', onPressed: () {
          Navigator.of(ctx).pop();
          onHistory();
        }),
      ],
    );
  }

  static Future<void> lift(BuildContext context, LiftProgress l, {required VoidCallback onHistory}) {
    final f = l.points.first, e = l.points.last;
    return showAppSheet<void>(
      context,
      title: l.name,
      subtitle: 'Best ${TNum.amount(e.$2, 'kgs')} · ${TNum.change(e.$2 - f.$2, 'kgs')} since ${TDate.dm(f.$1)}',
      builder: (_) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KvLine('Started at', '${TNum.amount(f.$2, 'kgs')} · ${TDate.dm(f.$1)}'),
        KvLine('Best set', l.best),
        KvLine('Weight went up', '${l.points.length} times'),
        KvLine('Last logged', TDate.wdm(e.$1)),
        const SizedBox(height: 10),
        Text(l.caption, style: AppText.secondary),
      ]),
      actions: (ctx) => [
        AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('See every logged set', onPressed: () {
          Navigator.of(ctx).pop();
          onHistory();
        }),
      ],
    );
  }

  // ------------------------------------------------------------ photos

  static Future<void> photo(BuildContext context, WidgetRef ref, int si, String pose, {required void Function(int si, String pose) onCompare}) {
    var p = pose;
    return showLiveSheet<void>(
      context,
      builder: (ctx, setSheet) {
        final s = ref.read(progressProvider).photoSets[si];
        final none = !s.poses.contains(p);
        return SheetContent(
          title: '${TDate.wdm(s.date)} · $p',
          subtitle: '${TNum.kg(s.kg)} · ${s.label}',
          body: Column(children: [
            SegmentedTabs<String>(items: [for (final n in ClientTrainingMock.poses) (n, n)], value: p, onChanged: (v) => setSheet(() => p = v)),
            const SizedBox(height: 12),
            SizedBox(
              width: 250,
              child: PhotoTile(tint: s.tint, none: none, noneText: 'No ${p.toLowerCase()} photo in this set', tag: '${TDate.dm(s.date)} · $p', iconSize: 90),
            ),
          ]),
          actions: [
            AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
            AppButton('Compare with start', icon: Icons.compare_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              onCompare(si, p);
            }),
          ],
        );
      },
    );
  }

  static Future<void> addPhotos(BuildContext context, WidgetRef ref) {
    var pose = 'Front';
    String? src;
    const poses = [
      ('Front', 'Face the camera, arms relaxed by your sides'),
      ('Side', 'Turn to your right, stand tall'),
      ('Back', 'Back to the camera, feet hip-width apart'),
    ];
    return showLiveSheet<void>(
      context,
      builder: (ctx, setSheet) {
        final st = ref.read(progressProvider);
        final today = ClientTrainingMock.today;
        final todaySet = st.photoSets.last.date == today ? st.photoSets.last : null;
        return SheetContent(
          title: 'Add photos',
          subtitle: 'Adds to today’s set · ${TDate.wdm(today)} · ${TNum.kg(st.last.kg)}',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pose', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
              const SizedBox(height: 6),
              for (final (n, s) in poses)
                _PoseOption(name: n, sub: s, on: pose == n, added: todaySet?.poses.contains(n) ?? false, onTap: () => setSheet(() => pose = n)),
              const SizedBox(height: 8),
              Text('Photo', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 84, child: PhotoTile(tint: PhotoTint.t3, none: src == null, noneText: '')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final n in ['Take photo', 'Choose from gallery']) ...[
                      ChoicePill(n, selected: src == n, icon: n == 'Take photo' ? Icons.photo_camera_outlined : Icons.photo_library_outlined, onTap: () => setSheet(() => src = n)),
                      const SizedBox(height: 6),
                    ],
                    Text(src == null ? 'No photo yet' : '$pose photo ready · ${src == 'Take photo' ? 'taken just now' : 'IMG_2041.jpg'}', style: AppText.caption),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Text('Same spot, same light, in the morning before eating. Only you and Aman can see it.', style: AppText.secondary.copyWith(fontSize: 12.5)),
            ],
          ),
          actions: [
            AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
            Opacity(
              opacity: src == null ? .5 : 1,
              child: AppButton('Save photo', icon: Icons.check_rounded, onPressed: () {
                if (src == null) {
                  showToast(context, 'Take or choose a photo first', subtitle: 'Then save it to today’s set', kind: ToastKind.warn);
                  return;
                }
                Navigator.of(ctx).pop();
                final prev = ref.read(progressProvider);
                final rep = ref.read(progressProvider.notifier).addPhoto(pose);
                showToast(context, '$pose photo ${rep ? 'replaced' : 'added'}',
                    subtitle: '${TDate.wdm(today)} · only you and Aman can see it',
                    kind: ToastKind.ok,
                    onUndo: () => ref.read(progressProvider.notifier).set((s) => s.copyWith(photoSets: prev.photoSets, pick: prev.pick)));
              }),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------ history day

  static Future<void> day(BuildContext context, HistDay d) {
    final types = d.entries.map((e) => e.type).toSet();
    final (goLabel, route) = types.contains(HistType.workout)
        ? ('Open training', Routes.cTrain)
        : types.contains(HistType.checkin)
            ? ('Open check-ins', Routes.cCheckins)
            : ('Open meal plan', Routes.cFood);
    return showAppSheet<void>(
      context,
      title: TDate.wdm(d.date),
      subtitle: '${d.score}% adherence · ${d.entries.length} ${d.entries.length == 1 ? 'log' : 'logs'}',
      builder: (_) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final e in d.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              HistEntryRow(e: e),
              for (final (k, v) in e.details) KvLine(k, v),
              if (e.note.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                  child: Text(e.note, style: AppText.secondary.copyWith(color: AppColors.text2)),
                ),
            ]),
          ),
      ]),
      actions: (ctx) => [
        AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
        AppButton(goLabel, onPressed: () {
          Navigator.of(ctx).pop();
          context.go(route);
        }),
      ],
    );
  }
}

class _PoseOption extends StatelessWidget {
  const _PoseOption({required this.name, required this.sub, required this.on, required this.added, required this.onTap});
  final String name;
  final String sub;
  final bool on;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: on ? AppColors.accentSoft : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: on ? AppColors.accent : AppColors.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: on ? 4.5 : 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    if (added) ...[const SizedBox(width: 8), const AppChip('Added today')],
                  ]),
                  Text(sub, style: AppText.caption),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One log line in history (px-e).
class HistEntryRow extends StatelessWidget {
  const HistEntryRow({super.key, required this.e});
  final HistEntry e;

  static (IconData, String) iconOf(HistType t) => switch (t) {
        HistType.workout => (Icons.fitness_center_rounded, 'blue'),
        HistType.meal => (Icons.restaurant_rounded, 'green'),
        HistType.checkin => (Icons.assignment_outlined, 'purple'),
        HistType.weight => (Icons.monitor_weight_outlined, 'amber'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = iconOf(e.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        TintIcon(icon, tint: tintOf(tint), size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
            Text(e.sub, style: AppText.caption),
          ]),
        ),
        if (e.badge.isNotEmpty) Pill(e.badge, tone: e.badgeTone),
      ]),
    );
  }
}
