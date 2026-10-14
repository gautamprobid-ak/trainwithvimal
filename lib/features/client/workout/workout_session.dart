import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

/// One logged set. [values] holds one value per column (weight: [kg or ± kg on
/// bodyweight, reps]). [at] is the workout time (s) when the set was ticked.
class LoggedSet {
  const LoggedSet({required this.values, this.bw = false, this.warmup = false, this.done = false, this.touched = false, this.at});

  final List<double> values;
  final bool bw;
  final bool warmup;
  final bool done;
  final bool touched;
  final int? at;

  LoggedSet copyWith({List<double>? values, bool? bw, bool? warmup, bool? done, bool? touched, int? Function()? at}) => LoggedSet(
        values: values ?? this.values,
        bw: bw ?? this.bw,
        warmup: warmup ?? this.warmup,
        done: done ?? this.done,
        touched: touched ?? this.touched,
        at: at != null ? at() : this.at,
      );
}

enum WorkoutStatus { notStarted, live, finished }

/// A one-off message from the timers (rest over, hold done) for the screen to toast.
class WorkoutEvent {
  const WorkoutEvent(this.id, this.title, this.subtitle);
  final int id;
  final String title;
  final String subtitle;
}

/// Today's workout (Cardio and core): status, timer, sets, rest and the
/// "done" form. Shared by Home, Train and the logger.
class WorkoutSession {
  const WorkoutSession({
    required this.status,
    required this.sets,
    this.cur = 0,
    this.elapsed = 0,
    this.paused = false,
    this.lastActivity = 0,
    this.restLeft = 0,
    this.restMax = 45,
    this.restPaused = false,
    this.restOpen = false,
    this.restAt = (0, -1),
    this.restUsed = 0,
    this.hold,
    this.effort = 0,
    this.note,
    this.sent = false,
    this.event,
  });

  final WorkoutStatus status;
  final List<List<LoggedSet>> sets;
  final int cur;
  final int elapsed;
  final bool paused;
  final int lastActivity;
  final int restLeft;
  final int restMax;
  final bool restPaused;
  final bool restOpen;

  /// (exercise, set) the rest belongs to; set = -1 when started by hand.
  final (int, int) restAt;
  final int restUsed;

  /// Hold countdown on a time set: (exercise, set, seconds left).
  final (int, int, int)? hold;
  final int effort;
  final String? note;
  final bool sent;
  final WorkoutEvent? event;

  static List<LogExercise> get exercises => ClientTrainingMock.todayExercises;

  static List<LoggedSet> freshSets(int i) {
    final e = exercises[i];
    return [for (final v in e.start) LoggedSet(values: List.of(v), bw: e.bodyweight)];
  }

  static WorkoutSession initial() =>
      WorkoutSession(status: WorkoutStatus.notStarted, sets: [for (var i = 0; i < exercises.length; i++) freshSets(i)]);

  bool get isLive => status == WorkoutStatus.live;
  bool get isFinished => status == WorkoutStatus.finished;
  bool get isNotStarted => status == WorkoutStatus.notStarted;

  int get setsDone => sets.fold(0, (a, xs) => a + xs.where((x) => x.done).length);
  int get setsTotal => sets.fold(0, (a, xs) => a + xs.length);
  bool exerciseDone(int i) => sets[i].isNotEmpty && sets[i].every((x) => x.done);
  int get exercisesDone => [for (var i = 0; i < sets.length; i++) exerciseDone(i)].where((d) => d).length;

  /// Workout time of the last ticked set, or -1.
  int get lastTickAt => sets.fold(-1, (a, xs) => xs.fold(a, (b, x) => x.done && x.at != null && x.at! > b ? x.at! : b));

  double kgOf(LoggedSet x) => x.bw ? ClientTrainingMock.bodyweightKg + x.values[0] : x.values[0];

  double volumeOf(int i) => exercises[i].isWeight
      ? sets[i].where((x) => x.done && !x.warmup).fold(0.0, (a, x) => a + kgOf(x) * x.values[1])
      : 0;

  int get totalVolume => [for (var i = 0; i < exercises.length; i++) volumeOf(i)].fold(0.0, (a, b) => a + b).round();

  WorkoutSession copyWith({
    WorkoutStatus? status,
    List<List<LoggedSet>>? sets,
    int? cur,
    int? elapsed,
    bool? paused,
    int? lastActivity,
    int? restLeft,
    int? restMax,
    bool? restPaused,
    bool? restOpen,
    (int, int)? restAt,
    int? restUsed,
    (int, int, int)? Function()? hold,
    int? effort,
    String? Function()? note,
    bool? sent,
    WorkoutEvent? Function()? event,
  }) =>
      WorkoutSession(
        status: status ?? this.status,
        sets: sets ?? this.sets,
        cur: cur ?? this.cur,
        elapsed: elapsed ?? this.elapsed,
        paused: paused ?? this.paused,
        lastActivity: lastActivity ?? this.lastActivity,
        restLeft: restLeft ?? this.restLeft,
        restMax: restMax ?? this.restMax,
        restPaused: restPaused ?? this.restPaused,
        restOpen: restOpen ?? this.restOpen,
        restAt: restAt ?? this.restAt,
        restUsed: restUsed ?? this.restUsed,
        hold: hold != null ? hold() : this.hold,
        effort: effort ?? this.effort,
        note: note != null ? note() : this.note,
        sent: sent ?? this.sent,
        event: event != null ? event() : this.event,
      );
}

/// "18:24" or "1:02:05".
String fmtWorkoutTime(int s) {
  final ss = (s % 60).toString().padLeft(2, '0');
  if (s >= 3600) return '${s ~/ 3600}:${((s ~/ 60) % 60).toString().padLeft(2, '0')}:$ss';
  return '${s ~/ 60}:$ss';
}

class WorkoutSessionController extends Notifier<WorkoutSession> {
  Timer? _timer;
  int _eventId = 0;

  @override
  WorkoutSession build() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(() => _timer?.cancel());
    return WorkoutSession.initial();
  }

  List<LogExercise> get _ex => WorkoutSession.exercises;

  WorkoutEvent _ev(String t, String s) => WorkoutEvent(++_eventId, t, s);

  List<List<LoggedSet>> _copySets() => [for (final xs in state.sets) List.of(xs)];

  // ---------------------------------------------------------------- timer

  void _tick() {
    final s = state;
    if (!s.isLive || s.paused) return;
    var n = s.copyWith(elapsed: s.elapsed + 1);
    if (n.restLeft > 0 && !n.restPaused) {
      final r = n.restLeft - 1;
      n = n.copyWith(restLeft: r, restUsed: n.restUsed + 1);
      if (r == 0) n = n.copyWith(restOpen: false, event: () => _ev('Rest is over', 'Next: ${nextUp(n)}'));
    }
    final h = n.hold;
    if (h != null) {
      if (h.$3 - 1 <= 0) {
        state = n.copyWith(hold: () => null);
        final x = state.sets[h.$1][h.$2];
        _tickSet(h.$1, h.$2, extra: ('Hold done', '${_ex[h.$1].name} · set ${h.$2 + 1} · ${TNum.short(x.values[0])} s'));
        return;
      }
      n = n.copyWith(hold: () => (h.$1, h.$2, h.$3 - 1));
    }
    state = n;
  }

  // ---------------------------------------------------------------- lifecycle

  /// Opening the logger starts the workout if it is not running.
  void ensureStarted() {
    if (state.isNotStarted) state = WorkoutSession.initial().copyWith(status: WorkoutStatus.live);
  }

  /// "Log more sets" after finishing.
  void reopen() {
    if (state.isFinished) state = state.copyWith(status: WorkoutStatus.live, lastActivity: state.elapsed);
  }

  void restore(WorkoutSession s) => state = s.copyWith(event: () => null);

  void togglePause() => state = state.copyWith(paused: !state.paused);
  void addMinutes(int m) => state = state.copyWith(elapsed: (state.elapsed + m * 60).clamp(0, 1 << 30));

  void keepGoing() => state = state.copyWith(lastActivity: state.elapsed);

  void finish() => state = state.copyWith(status: WorkoutStatus.finished, restLeft: 0, restOpen: false, hold: () => null);

  /// Finish at the last ticked set so idle minutes don't count.
  void finishAtLastSet() {
    final at = state.lastTickAt;
    state = state.copyWith(status: WorkoutStatus.finished, elapsed: at < 0 ? state.elapsed : at, restLeft: 0, restOpen: false, hold: () => null);
  }

  void restart() => state = WorkoutSession.initial().copyWith(status: WorkoutStatus.live);

  /// Discard everything: back to not started.
  void discardAll() => state = WorkoutSession.initial();

  void clearExercise() {
    final n = _copySets();
    n[state.cur] = WorkoutSession.freshSets(state.cur);
    state = state.copyWith(sets: n, restLeft: 0, hold: () => null);
  }

  void clearAllSets() => state = state.copyWith(
        sets: [for (var i = 0; i < _ex.length; i++) WorkoutSession.freshSets(i)],
        cur: 0,
        restLeft: 0,
        hold: () => null,
      );

  /// Home "tick": logs every set of exercise [i] at once. Returns the toast.
  (String, String, bool) logExercise(int i) {
    var st = state;
    if (st.isNotStarted) st = WorkoutSession.initial().copyWith(status: WorkoutStatus.live);
    final n = [for (final xs in st.sets) List.of(xs)];
    final on = !st.exerciseDone(i);
    n[i] = [for (final x in n[i]) x.copyWith(done: on, at: () => on ? (x.at ?? st.elapsed) : null)];
    st = st.copyWith(sets: n, lastActivity: st.elapsed);
    final total = _ex.length;
    final done = st.exercisesDone;
    if (on && done == total) {
      state = st.copyWith(status: WorkoutStatus.finished, restLeft: 0, restOpen: false, hold: () => null);
      return ('Workout done!', 'Aman can see it now', true);
    }
    state = st;
    return (on ? '${_ex[i].name} logged' : '${_ex[i].name} not done', '$done of $total exercises done', false);
  }

  // ---------------------------------------------------------------- navigation

  void goTo(int i) => state = state.copyWith(cur: i.clamp(0, _ex.length - 1), restLeft: 0, hold: () => null);

  // ---------------------------------------------------------------- sets

  /// Tick or untick a set. Returns a toast (title, subtitle) when the exercise is complete.
  (String, String)? tickSet(int k) => _tickSet(state.cur, k);

  (String, String)? _tickSet(int ex, int k, {(String, String)? extra}) {
    final s = state;
    final e = _ex[ex];
    final x = s.sets[ex][k];
    final on = !x.done;
    final n = _copySets();
    n[ex][k] = x.copyWith(done: on, at: () => on ? s.elapsed : null);
    final all = n[ex].every((y) => y.done);
    final startRest = on && e.rest > 0 && !all;
    final msg = on && all
        ? ('${e.name} done', ex < _ex.length - 1 ? 'Next: ${_ex[ex + 1].name}' : 'Last one. Finish when you are ready')
        : extra;
    state = s.copyWith(
      sets: n,
      hold: () => null,
      lastActivity: on ? s.elapsed : s.lastActivity,
      restLeft: startRest ? e.rest : 0,
      restMax: e.rest,
      restPaused: false,
      restOpen: startRest,
      restAt: (ex, k),
      cur: on && all && ex < _ex.length - 1 ? ex + 1 : s.cur,
      // timer-driven ticks (hold done) report through an event
      event: extra != null && msg != null ? () => _ev(msg.$1, msg.$2) : null,
    );
    return msg;
  }

  void stepValue(int k, int j, int dir) {
    final s = state;
    final e = _ex[s.cur];
    final n = _copySets();
    final x = n[s.cur][k];
    final lo = e.isWeight && j == 0 ? (x.bw ? -40.0 : 0.0) : 0.0;
    final v = List.of(x.values);
    v[j] = TNum.r1((v[j] + dir * e.step[j]).clamp(lo, 100000));
    n[s.cur][k] = x.copyWith(values: v, touched: true);
    state = s.copyWith(sets: n);
  }

  void toggleBw(int k) {
    final n = _copySets();
    final x = n[state.cur][k];
    final v = List.of(x.values)..[0] = x.bw ? 12 : 0;
    n[state.cur][k] = x.copyWith(bw: !x.bw, values: v, touched: true);
    state = state.copyWith(sets: n);
  }

  /// Load segment: all sets kg or all bodyweight.
  void setAllBw(bool bw) {
    final n = _copySets();
    n[state.cur] = [
      for (final x in n[state.cur])
        if (x.bw == bw) x else x.copyWith(bw: bw, values: List.of(x.values)..[0] = bw ? 0 : 12),
    ];
    state = state.copyWith(sets: n);
  }

  void toggleWarmup(int k) {
    final n = _copySets();
    final x = n[state.cur][k];
    n[state.cur][k] = x.copyWith(warmup: !x.warmup);
    state = state.copyWith(sets: n);
  }

  void deleteSet(int k) {
    final n = _copySets();
    n[state.cur].removeAt(k);
    state = state.copyWith(sets: n);
  }

  void addSet() {
    final n = _copySets();
    final xs = n[state.cur];
    final e = _ex[state.cur];
    xs.add(xs.isNotEmpty
        ? xs.last.copyWith(values: List.of(xs.last.values), done: false, warmup: false, at: () => null)
        : LoggedSet(values: List.of(e.start.first), bw: e.bodyweight));
    state = state.copyWith(sets: n);
  }

  // ---------------------------------------------------------------- hold + rest

  void startHold(int k) => state = state.copyWith(hold: () => (state.cur, k, state.sets[state.cur][k].values[0].round()), restLeft: 0, restOpen: false);
  void stopHold() => state = state.copyWith(hold: () => null);

  void restNow() {
    final e = _ex[state.cur];
    state = state.copyWith(restLeft: e.rest, restMax: e.rest, restPaused: false, restOpen: true, restAt: (state.cur, -1));
  }

  void openRest(bool open) => state = state.copyWith(restOpen: open);
  void toggleRestPause() => state = state.copyWith(restPaused: !state.restPaused);
  void restLess() => state = state.copyWith(restLeft: (state.restLeft - 15).clamp(1, 1 << 30));
  void restMore() {
    final r = state.restLeft + 15;
    state = state.copyWith(restLeft: r, restMax: r > state.restMax ? r : state.restMax);
  }

  void skipRest() => state = state.copyWith(restLeft: 0, restOpen: false, restPaused: false);

  // ---------------------------------------------------------------- done form

  void setEffort(int v) => state = state.copyWith(effort: v);
  void setNote(String? v) => state = state.copyWith(note: () => (v == null || v.trim().isEmpty) ? null : v.trim());
  void send() => state = state.copyWith(sent: true);
}

/// Text of the next set to do, or the next exercise.
String nextUp(WorkoutSession s) {
  final e = WorkoutSession.exercises[s.cur];
  final xs = s.sets[s.cur];
  final k = xs.indexWhere((x) => !x.done);
  if (k >= 0) {
    final x = xs[k];
    final parts = <String>[];
    for (var j = 0; j < e.cols.length; j++) {
      final c = e.cols[j];
      final unit = switch (c) { 'Reps' => '', 'Seconds' => ' s', 'Min' => ' min', 'Km' => ' km', _ => x.bw ? '' : ' kg' };
      parts.add('${formatSetValue(e, x, j)}$unit');
    }
    return 'Set ${k + 1} · ${parts.join(' × ')}';
  }
  return s.cur < WorkoutSession.exercises.length - 1 ? WorkoutSession.exercises[s.cur + 1].name : 'Finish the workout';
}

/// Value of column [j] of a set as the logger shows it.
String formatSetValue(LogExercise e, LoggedSet x, int j) {
  final v = x.values[j];
  if (e.isWeight && j == 0) {
    if (!x.bw) return TNum.short(v);
    return 'BW${v > 0 ? '+${TNum.short(v)}' : v < 0 ? '−${TNum.short(-v)}' : ''}';
  }
  if (e.isCardio && j == 1) return v.toStringAsFixed(1);
  return TNum.short(v);
}

final workoutSessionProvider = NotifierProvider<WorkoutSessionController, WorkoutSession>(WorkoutSessionController.new);
