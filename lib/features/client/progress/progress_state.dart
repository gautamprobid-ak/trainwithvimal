import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

enum ProgressView { main, history, photos, compare }

/// Progress tab state (kept while switching tabs).
class ProgressState {
  const ProgressState({
    required this.weighIns,
    required this.photoSets,
    this.view = ProgressView.main,
    this.tab = 'Weight',
    this.compareOn = false,
    this.range = 1,
    this.selected,
    this.openMeasure = 'Waist',
    this.adhWeek = 5,
    this.pose = 'Front',
    this.pick = const [0, 4],
    this.histRange = 0,
    this.histType,
    this.histShown = 7,
  });

  final List<WeighIn> weighIns;
  final List<PhotoSet> photoSets;
  final ProgressView view;
  final String tab;
  final bool compareOn;

  /// Weight chart range index (4 wk, 12 wk, 6 mo, All).
  final int range;

  /// Selected weigh-in date on the chart.
  final DateTime? selected;
  final String? openMeasure;
  final int adhWeek;
  final String pose;

  /// Photo sets picked to compare (indexes, sorted).
  final List<int> pick;
  final int histRange;
  final String? histType;
  final int histShown;

  WeighIn get last => weighIns.last;

  ProgressState copyWith({
    List<WeighIn>? weighIns,
    List<PhotoSet>? photoSets,
    ProgressView? view,
    String? tab,
    bool? compareOn,
    int? range,
    DateTime? Function()? selected,
    String? Function()? openMeasure,
    int? adhWeek,
    String? pose,
    List<int>? pick,
    int? histRange,
    String? Function()? histType,
    int? histShown,
  }) =>
      ProgressState(
        weighIns: weighIns ?? this.weighIns,
        photoSets: photoSets ?? this.photoSets,
        view: view ?? this.view,
        tab: tab ?? this.tab,
        compareOn: compareOn ?? this.compareOn,
        range: range ?? this.range,
        selected: selected != null ? selected() : this.selected,
        openMeasure: openMeasure != null ? openMeasure() : this.openMeasure,
        adhWeek: adhWeek ?? this.adhWeek,
        pose: pose ?? this.pose,
        pick: pick ?? this.pick,
        histRange: histRange ?? this.histRange,
        histType: histType != null ? histType() : this.histType,
        histShown: histShown ?? this.histShown,
      );
}

class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() => ProgressState(
        weighIns: ClientTrainingMock.weighIns,
        photoSets: ClientTrainingMock.photoSets,
        adhWeek: ClientTrainingMock.adherence.length - 1,
        pick: [0, ClientTrainingMock.photoSets.length - 1],
      );

  void set(ProgressState Function(ProgressState s) f) => state = f(state);

  void togglePick(int i) {
    var n = List.of(state.pick);
    if (n.contains(i)) {
      n.remove(i);
    } else {
      if (n.length >= 2) n.removeAt(0);
      n.add(i);
    }
    n.sort();
    state = state.copyWith(pick: n);
  }

  /// Saves a weigh-in (replaces one on the same day).
  void logWeight(DateTime d, double kg) {
    final n = [...state.weighIns.where((w) => w.date != d), WeighIn(d, kg)]..sort((a, b) => a.date.compareTo(b.date));
    state = state.copyWith(weighIns: n, selected: () => d, tab: 'Weight');
  }

  /// Adds a photo to today's set (creates it when needed). Returns true if it replaced one.
  bool addPhoto(String pose) {
    final today = ClientTrainingMock.today;
    final sets = List.of(state.photoSets);
    final latest = sets.last;
    var replaced = false;
    if (latest.date == today) {
      replaced = latest.poses.contains(pose);
      if (!replaced) {
        sets[sets.length - 1] = latest.copyWith(poses: [for (final p in ClientTrainingMock.poses) if (latest.poses.contains(p) || p == pose) p]);
      }
    } else {
      sets.add(PhotoSet(date: today, kg: state.last.kg, label: 'Added by you', poses: [pose], tint: PhotoTint.t3));
    }
    state = state.copyWith(photoSets: sets, pose: pose);
    return replaced;
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressState>(ProgressController.new);

// ---------------------------------------------------------------- history

enum HistType { workout, meal, checkin, weight }

class HistEntry {
  const HistEntry({
    required this.type,
    required this.title,
    required this.sub,
    this.badge = '',
    this.badgeTone = '',
    this.missed = false,
    this.details = const [],
    this.note = '',
    this.kcal = 0,
    this.protein = 0,
    this.partial = false,
  });
  final HistType type;
  final String title;
  final String sub;
  final String badge;
  final String badgeTone;
  final bool missed;
  final List<(String, String)> details;
  final String note;
  final int kcal;
  final int protein;
  final bool partial;
}

class HistDay {
  const HistDay(this.date, this.entries, this.score);
  final DateTime date;
  final List<HistEntry> entries;
  final int score;
}

/// Last 3 months of logs, built from her plan, meals, check-ins and weigh-ins.
List<HistDay> buildHistory(List<WeighIn> wts, List<PhotoSet> photos) {
  final today = ClientTrainingMock.today;
  final jan1 = DateTime(2026, 1, 1);
  final out = <HistDay>[];
  WeighIn wAt(DateTime d) => wts.lastWhere((w) => !w.date.isAfter(d), orElse: () => wts.first);
  for (var o = 0; o <= 90; o++) {
    final d = DateTime(today.year, today.month, today.day - o);
    final di = TDate.daysBetween(jan1, d);
    final wd = d.weekday;
    final es = <HistEntry>[];
    final p = ClientTrainingMock.historyPlan[wd];
    if (p != null && d.isBefore(today)) {
      final miss = ClientTrainingMock.missedWorkouts[d];
      final time = p.summary.split(' · ').first;
      es.add(miss != null
          ? HistEntry(type: HistType.workout, title: p.name, sub: 'Missed · $miss', badge: 'Missed', badgeTone: 'amber', missed: true, details: [('Reason', miss), ('Planned', time)])
          : HistEntry(type: HistType.workout, title: p.name, sub: 'Done · ${p.summary}', details: [...p.lines, ('Time', time)]));
    }
    final isToday = o == 0;
    final kc = isToday ? 1010 : 1650 + ((di * 37) % 140) - 70;
    final pr = isToday ? 68 : 118 + ((di * 13) % 12) - 6;
    final nm = isToday ? 3 : 5;
    es.add(HistEntry(
      type: HistType.meal,
      title: 'Meals · $nm of 5 logged',
      sub: '${TNum.n(kc)} kcal · $pr g protein',
      kcal: kc,
      protein: pr,
      partial: isToday,
      details: [for (final m in ClientTrainingMock.historyMeals.take(nm)) ('${m.$1} · ${m.$2}', m.$3)],
    ));
    if (wd == DateTime.sunday) {
      final wk = (TDate.daysBetween(ClientTrainingMock.checkinWeekZero, d) / 7).round();
      final hasPhotos = photos.any((s) => s.date == d);
      es.add(HistEntry(
        type: HistType.checkin,
        title: wk >= 1 ? 'Week $wk check-in' : 'Weekly check-in',
        sub: 'Sent · Aman replied',
        badge: 'Reply',
        badgeTone: 'green',
        details: [
          ('Weight', TNum.kg(wAt(d).kg)),
          ('Sleep avg', '${(6.6 + (di % 5) * 0.2).toStringAsFixed(1)} h'),
          ('Energy', '${3 + (di % 3 == 0 ? 1 : 0)} / 5'),
          ('Stress', '${2 + (di % 2)} / 5'),
          ('Photos', hasPhotos ? '3 photos' : 'None this week'),
        ],
        note: 'Aman: ${ClientTrainingMock.coachReplies[di % ClientTrainingMock.coachReplies.length]}',
      ));
    }
    final ww = wts.where((w) => w.date == d).firstOrNull;
    if (ww != null) {
      final before = wts.where((w) => w.date.isBefore(d)).toList();
      final pw = before.isEmpty ? null : before.last;
      es.add(HistEntry(
        type: HistType.weight,
        title: 'Weight · ${TNum.kg(ww.kg)}',
        sub: pw != null ? 'Weigh-in · ${TNum.change(ww.kg - pw.kg, 'kg')} vs ${TDate.dm(pw.date)}' : 'First weigh-in',
        details: [('Weigh-in', TNum.kg(ww.kg)), ('Since start', TNum.change(ww.kg - ClientTrainingMock.startKg, 'kg'))],
      ));
    }
    final score = isToday ? 60 : (es.any((e) => e.missed) ? 70 : 88 + ((di * 7) % 13));
    out.add(HistDay(d, es, score));
  }
  return out;
}
