import 'package:intl/intl.dart';

/// Calories + macros (kcal, protein g, carbs g, fat g).
class Macros {
  const Macros(this.kcal, this.protein, this.carbs, this.fat);
  static const zero = Macros(0, 0, 0, 0);

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  Macros operator +(Macros o) => Macros(kcal + o.kcal, protein + o.protein, carbs + o.carbs, fat + o.fat);
  Macros operator *(double q) => Macros(kcal * q, protein * q, carbs * q, fat * q);

  /// 0 = kcal, 1 = protein, 2 = carbs, 3 = fat.
  double operator [](int i) => switch (i) { 0 => kcal, 1 => protein, 2 => carbs, _ => fat };

  /// "1,650 kcal · 120 g P · 170 g C · 52 g F"
  String get line => '${nf(kcal)} kcal · ${protein.round()} g P · ${carbs.round()} g C · ${fat.round()} g F';
}

/// A serving unit and its weight in grams ("1 katori" = 150 g).
class ServingUnit {
  const ServingUnit(this.name, this.grams);
  final String name;
  final double grams;
}

/// A food: default amount ([qty] × [unit]) and macros per one [unit].
class Food {
  const Food({
    required this.name,
    required this.unit,
    required this.qty,
    required this.per,
    this.step = 1,
    this.units = const [ServingUnit('g', 1)],
    this.alts = const [],
    this.match,
    this.group,
    this.serving,
    this.mine = false,
  });

  final String name;
  final String unit;
  final double qty;
  final Macros per;
  final double step;
  final List<ServingUnit> units;

  /// Swaps approved by the coach (meal plan only).
  final List<Food> alts;

  /// Match % against the planned food (swap options only).
  final int? match;
  final String? group;
  final String? serving;

  /// Created by the client (My foods).
  final bool mine;

  Macros macrosFor(double q) => per * q;
  Macros get defaultMacros => per * qty;
  bool get canSwap => alts.isNotEmpty;

  double gramsPerUnit(String u) => u == 'g' ? 1 : units.firstWhere((x) => x.name == u, orElse: () => const ServingUnit('', 1)).grams;
  double gramsFor(double q) => q * gramsPerUnit(unit);

  /// Same food measured in another unit (macros follow the grams).
  Food inUnit(String u) {
    if (u == unit) return this;
    final factor = gramsPerUnit(u) / gramsPerUnit(unit);
    return Food(name: name, unit: u, qty: qty, per: per * factor, step: step, units: units, alts: alts, match: match, group: group, serving: serving, mine: mine);
  }
}

/// One meal of the plan.
class PlanMeal {
  const PlanMeal(this.name, this.time, this.foods);
  final String name;
  final String time;
  final List<Food> foods;
}

/// A food-log entry outside the plan meals (search, quick add, copied).
class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.macros,
    required this.mealIndex,
    required this.atMinute,
    this.offPlan = false,
    this.reason,
    this.seed = false,
  });

  final String id;
  final String name;
  final String amount;
  final Macros macros;
  final int mealIndex;
  final int atMinute;
  final bool offPlan;
  final String? reason;

  /// Entry that was already in the log before this session (not "added now").
  final bool seed;
}

// ---------------------------------------------------------------- habits

class HabitDef {
  const HabitDef({
    required this.id,
    required this.short,
    required this.name,
    required this.goal,
    required this.target,
    required this.how,
    required this.baseStreak,
    required this.best,
    required this.week,
  });
  final String id;
  final String short;
  final String name;
  final int goal;
  final String target;
  final String how;
  final int baseStreak;
  final int best;
  final String week;
}

class Supplement {
  const Supplement({required this.name, required this.dose, required this.night, required this.how, required this.stock, required this.unit, this.note});
  final String name;
  final String dose;
  final bool night;
  final String how;
  final int stock;
  final String unit;
  final String? note;
}

// ---------------------------------------------------------------- check-ins

class WeeklyCheckin {
  const WeeklyCheckin({
    required this.title,
    required this.date,
    required this.summary,
    required this.pill,
    this.waiting = false,
    this.missed = false,
    this.reviewed = false,
    this.reply,
    this.replyWhen,
    this.kpis = const [],
    this.answers = const [],
    this.photoDate = '',
    this.mine = false,
  });
  final String title;
  final String date;
  final String summary;
  final String pill;
  final bool waiting;
  final bool missed;
  final bool reviewed;
  final String? reply;
  final String? replyWhen;
  final List<(String, String)> kpis;
  final List<(String, String)> answers;
  final String photoDate;
  final bool mine;
}

class DailyCheckin {
  const DailyCheckin({required this.title, required this.summary, this.at, this.missed = false, this.reply, this.replyWhen, this.answers, this.today = false});
  final String title;
  final String summary;
  final String? at;
  final bool missed;
  final String? reply;
  final String? replyWhen;

  /// sleep, energy, mood, hunger, soreness, steps, water, weight, note
  final List<String>? answers;
  final bool today;
}

// ---------------------------------------------------------------- library

enum LibraryKind {
  video('Video'),
  pdf('PDF'),
  image('Image'),
  article('Article');

  const LibraryKind(this.label);
  final String label;
}

class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.length,
    required this.source,
    required this.tone,
    required this.by,
    required this.note,
    required this.description,
    this.duration = 0,
    this.chapters = const [],
    this.file,
    this.pages = const [],
    this.body = const [],
  });
  final String id;
  final String title;
  final LibraryKind kind;
  final String length;
  final String source;

  /// 1 blue · 2 green · 3 amber · 4 purple
  final int tone;
  final String by;
  final String note;
  final String description;
  final int duration;
  final List<(int, String)> chapters;
  final String? file;
  final List<(String, String)> pages;
  final List<String> body;
}

// ---------------------------------------------------------------- more

class ClientNotification {
  const ClientNotification(this.id, this.icon, this.tone, this.title, this.body, this.when, this.actionLabel, this.route);
  final String id;
  final String icon;
  final String tone;
  final String title;
  final String body;
  final String when;
  final String actionLabel;
  final String route;
}

class ActivityItem {
  const ActivityItem({
    required this.day,
    required this.time,
    required this.kind,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.rows,
    this.actionLabel,
    this.route,
  });
  final int day;
  final String time;
  final String kind;
  final String icon;
  final String tone;
  final String title;
  final String subtitle;
  final List<(String, String)> rows;
  final String? actionLabel;
  final String? route;
}

class ReminderSetting {
  const ReminderSetting(this.key, this.icon, this.tone, this.name, this.subtitle);
  final String key;
  final String icon;
  final String tone;
  final String name;
  final String subtitle;
}

// ---------------------------------------------------------------- formatting

final _nf = NumberFormat('#,##,##0', 'en_IN');

/// Rounded number with Indian grouping: 1,650 · 11,300.
String nf(num v) => _nf.format(v.round());

const _plural = {
  'piece': 'pieces',
  'scoop': 'scoops',
  'plate': 'plates',
  'bowl': 'bowls',
  'slice': 'slices',
  'glass': 'glasses',
  'egg white': 'egg whites',
  'cube': 'cubes',
};

/// Amount text: "60 g" · "1 scoop" · "10 pieces" · "2 medium".
String amountOf(String unit, double q) {
  if (unit == 'g') return '${q.round()} g';
  final w = unit.replaceFirst(RegExp(r'^1 '), '');
  final qs = q == q.roundToDouble() ? q.toInt().toString() : ((q * 10).round() / 10).toString();
  return '$qs ${q == 1 ? w : (_plural[w] ?? w)}';
}

/// Minute of the day → "5:40 pm".
String clock(int minute) {
  final h = (minute ~/ 60) % 24, m = minute % 60;
  return '${(h + 11) % 12 + 1}:${m.toString().padLeft(2, '0')} ${h < 12 ? 'am' : 'pm'}';
}

/// Millilitres → "1.5 L" / "3 L" / "1.25 L".
String litres(int ml) {
  final digits = ml % 1000 == 0 ? 0 : (ml % 500 == 0 ? 1 : 2);
  return '${(ml / 1000).toStringAsFixed(digits)} L';
}

/// Minutes → "7 h 20 min".
String hoursMin(int m) => '${m ~/ 60} h${m % 60 != 0 ? ' ${m % 60} min' : ''}';
