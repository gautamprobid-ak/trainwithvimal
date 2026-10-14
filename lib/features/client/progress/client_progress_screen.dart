import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

import 'progress_main.dart';
import 'progress_sheets.dart';
import 'progress_state.dart';
import 'progress_views.dart';

/// Design: ClientProgress.dc.html — goal, weight / body / strength tabs,
/// first day vs now, photos, stat tiles, adherence; plus History, Photos
/// timeline and Compare views and the log weight / add photo sheets.
class ClientProgressScreen extends ConsumerWidget {
  const ClientProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(progressProvider.select((s) => s.view));
    return switch (view) {
      ProgressView.history => const HistoryView(),
      ProgressView.photos => const PhotosView(),
      ProgressView.compare => const CompareView(),
      ProgressView.main => const _MainView(),
    };
  }
}

class _MainView extends ConsumerWidget {
  const _MainView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(progressProvider);
    final c = ref.read(progressProvider.notifier);
    void toHistory({String? type}) => c.set((x) => x.copyWith(view: ProgressView.history, histType: () => type, histRange: type == null ? x.histRange : 2, histShown: 7));
    void toPhotos() => c.set((x) => x.copyWith(view: ProgressView.photos));
    void toCompare() => c.set((x) => x.copyWith(view: ProgressView.compare, pick: [0, x.photoSets.length - 1]));
    return PageScroll(
      children: [
        PageHeader(
          title: 'Progress',
          subtitle: 'Weight, body and strength',
          actions: [
            AppIconButton(Icons.history_rounded, small: true, tooltip: 'View past logs', onPressed: toHistory),
            AppButton('Log weight', icon: Icons.add_rounded, small: true, onPressed: () => ProgressSheets.logWeight(context, ref)),
          ],
        ),
        const GoalCard(),
        const TabsRow(),
        if (s.compareOn) FirstVsNowCard(onPhotos: toCompare),
        switch (s.tab) {
          'Body' => const BodyCard(),
          'Strength' => StrengthCard(onHistory: () => toHistory(type: 'workout')),
          _ => const WeightCard(),
        },
        PhotosCard(onAll: toPhotos, onCompare: toCompare),
        StatTiles(onWorkouts: () => ProgressSheets.workouts(context, avg: adherenceAvg(), onHistory: () => toHistory(type: 'workout'))),
        const AdherenceCard(),
      ],
    );
  }
}
