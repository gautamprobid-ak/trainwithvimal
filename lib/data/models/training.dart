import 'package:intl/intl.dart';

/// Date labels used across the client training screens.
abstract final class TDate {
  static final _dm = DateFormat('d MMM');
  static final _wdm = DateFormat('EEE, d MMM');
  static final _wd = DateFormat('EEE');
  static final _month = DateFormat('MMMM y');

  /// "9 Oct"
  static String dm(DateTime d) => _dm.format(d);

  /// "Fri, 9 Oct"
  static String wdm(DateTime d) => _wdm.format(d);

  /// "Fri"
  static String wd(DateTime d) => _wd.format(d);

  /// "October 2026"
  static String month(DateTime d) => _month.format(d);

  static DateTime day(int m, int d) => DateTime(2026, m, d);

  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Number helpers: 6,240 · 71.2 kg · −0.4 kg.
abstract final class TNum {
  static final _int = NumberFormat.decimalPattern('en_US');
  static String n(num v) => _int.format(v.round());
  static double r1(double v) => (v * 10).round() / 10;
  static String k1(double v) => r1(v).toStringAsFixed(1);
  static String kg(double v) => '${k1(v)} kg';

  /// Short number: 42.5 → "42.5", 45.0 → "45".
  static String short(double v) {
    final r = r1(v);
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
  }

  /// Amount with unit, the way the design prints it.
  static String amount(double v, String unit) => switch (unit) {
        'kg' => kg(v),
        'kgs' => '${short(v)} kg',
        '%' => '${short(v)}%',
        _ => '${short(v)} $unit',
      };

  /// Signed change: "+1.5 kg", "−4.0 kg", "±0 cm".
  static String change(double v, String unit) {
    final r = r1(v);
    final sign = r > 0 ? '+' : (r < 0 ? '−' : '±');
    return '$sign${amount(r.abs(), unit)}';
  }
}

// ---------------------------------------------------------------- program week

/// One exercise line in the weekly plan ("Bench press", "4 × 6–8 · 42.5 kg").
class PlanExercise {
  const PlanExercise(this.name, this.detail);
  final String name;
  final String detail;
}

/// A training day of the program. Rest days are `null` in the week list.
class PlanDay {
  const PlanDay({required this.title, required this.kind, required this.exercises, this.doneLine = ''});
  final String title;

  /// "Strength" or "Cardio".
  final String kind;
  final List<PlanExercise> exercises;

  /// Summary shown on past days ("Done · 52 min · 6 of 6 exercises").
  final String doneLine;

  bool get isCardio => kind == 'Cardio';
}

// ---------------------------------------------------------------- logger exercises

enum LogKind { cardio, weight, time }

class MuscleWork {
  const MuscleWork(this.name, this.sub, this.level);
  final String name;
  final String sub;

  /// "Strong" or "Light".
  final String level;
}

/// An exercise of today's workout with everything the logger and guide need.
class LogExercise {
  const LogExercise({
    required this.name,
    required this.block,
    required this.kind,
    required this.target,
    required this.rest,
    required this.cols,
    required this.step,
    required this.start,
    required this.prev,
    this.pr = '',
    this.bodyweight = false,
    required this.group,
    required this.equipment,
    required this.level,
    required this.logs,
    required this.video,
    required this.videoLength,
    required this.cover,
    required this.tiles,
    required this.extra,
    required this.note,
    required this.steps,
    required this.cues,
    required this.primary,
    required this.primarySub,
    required this.also,
  });

  final String name;
  final String block;
  final LogKind kind;
  final String target;

  /// Rest after a set, in seconds (0 = no rest timer).
  final int rest;
  final List<String> cols;
  final List<double> step;

  /// Planned values per set (one list of column values per set).
  final List<List<double>> start;
  final List<String> prev;
  final String pr;
  final bool bodyweight;

  // guide
  final String group;
  final String equipment;
  final String level;
  final String logs;
  final String video;
  final String videoLength;
  final String cover;
  final List<(String, String)> tiles;
  final String extra;
  final String note;
  final List<String> steps;
  final List<String> cues;
  final String primary;
  final String primarySub;
  final List<MuscleWork> also;

  bool get isWeight => kind == LogKind.weight;
  bool get isTime => kind == LogKind.time;
  bool get isCardio => kind == LogKind.cardio;
}

/// Exercise block on the Train page ("Cardio", "35 min, easy pace").
class WorkoutBlock {
  const WorkoutBlock(this.name, this.sub);
  final String name;
  final String sub;
}

// ---------------------------------------------------------------- past workouts

class PastExercise {
  const PastExercise(this.name, this.sets, {this.pr = false});
  final String name;
  final List<String> sets;
  final bool pr;
}

class PastWorkout {
  const PastWorkout({required this.date, required this.name, required this.minutes, required this.effort, this.note = '', required this.exercises});
  final DateTime date;
  final String name;
  final int minutes;
  final int effort;
  final String note;
  final List<PastExercise> exercises;

  int get setCount => exercises.fold(0, (a, e) => a + e.sets.length);
  bool get hasPr => exercises.any((e) => e.pr);
}

// ---------------------------------------------------------------- home

class PlanMeal {
  const PlanMeal(this.meal, this.time, this.food, this.kcal, this.protein, this.carbs, this.fat);
  final String meal;
  final String time;
  final String food;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
}

class Supplement {
  const Supplement(this.id, this.name, this.dose);
  final String id;
  final String name;
  final String dose;
}

enum FeedIcon { form, dumbbell, bell, calendar, flag }

/// Notification in the home sheet. [link] is a route or null.
class HomeNotification {
  const HomeNotification(this.icon, this.tint, this.title, this.subtitle, this.when, this.link);
  final FeedIcon icon;
  final String tint;
  final String title;
  final String subtitle;
  final String when;
  final String? link;
}

/// "Coming up" row. [link] is a route; otherwise [toast]/[toastSub] is shown.
class UpcomingItem {
  const UpcomingItem(this.icon, this.tint, this.title, this.subtitle, {this.link, this.toast, this.toastSub});
  final FeedIcon icon;
  final String tint;
  final String title;
  final String subtitle;
  final String? link;
  final String? toast;
  final String? toastSub;
}

// ---------------------------------------------------------------- progress

class WeighIn {
  const WeighIn(this.date, this.kg);
  final DateTime date;
  final double kg;
}

class Measurement {
  const Measurement(this.name, this.unit, this.values);
  final String name;
  final String unit;

  /// One value per measurement date.
  final List<double> values;
}

class LiftProgress {
  const LiftProgress(this.name, this.points, this.best, this.caption);
  final String name;
  final List<(DateTime, double)> points;
  final String best;
  final String caption;
}

class AdherenceWeek {
  const AdherenceWeek(this.start, this.done, this.planned, this.pct);
  final DateTime start;
  final int done;
  final int planned;
  final int pct;
}

/// Photo tint (px-tile t1…t4).
enum PhotoTint { t1, t2, t3, t4 }

class PhotoSet {
  const PhotoSet({required this.date, required this.kg, required this.label, required this.poses, required this.tint});
  final DateTime date;
  final double kg;
  final String label;
  final List<String> poses;
  final PhotoTint tint;

  PhotoSet copyWith({List<String>? poses}) => PhotoSet(date: date, kg: kg, label: label, poses: poses ?? this.poses, tint: tint);
}

/// A planned workout per weekday used to build the history (1 = Monday).
class HistoryWorkout {
  const HistoryWorkout(this.name, this.summary, this.lines);
  final String name;
  final String summary;
  final List<(String, String)> lines;
}
