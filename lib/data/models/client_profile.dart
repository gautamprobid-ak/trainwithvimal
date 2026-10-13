import '../../core/widgets/badges.dart';

/// Models for the client profile (admin "Client profile" and trainer "My client").
/// All data comes from the design (Riya Sharma's profile).

typedef Kv = (String, String);

// ───────────────────────── Overview ─────────────────────────

enum DayMark { done, part, miss, rest }

class WeekRow {
  const WeekRow(this.label, this.marks);
  final String label;
  final List<DayMark> marks;
}

class AttentionItem {
  const AttentionItem(this.title, this.sub, this.tone, {this.target});
  final String title;
  final String sub;
  final BadgeTone tone;

  /// Where the row goes: 'checkin' (opens week 6), 'log' (opens the missed workout), null = not tappable.
  final String? target;
}

class ScheduleItem {
  const ScheduleItem(this.title, this.sub, this.badge, this.tone);
  final String title;
  final String sub;
  final String badge;
  final BadgeTone tone;
}

// ───────────────────────── Plans: workout ─────────────────────────

class ProgramEdit {
  const ProgramEdit(this.libraryName, this.name);
  final String libraryName;
  final String name;
}

class WorkoutExercise {
  const WorkoutExercise(
    this.name,
    this.sets,
    this.reps,
    this.rest,
    this.load, {
    this.was,
    this.rpe,
    this.tempo,
    this.superset,
    this.note,
    this.programEdit,
    this.youtube = false,
  });

  final String name;
  final String sets;
  final String reps;
  final String rest;
  final String load;

  /// "Was: Back squat (knee pain)", "Moved from Monday", "Added for Riya" — set when changed for the client.
  final String? was;
  final int? rpe;
  final String? tempo;
  final String? superset;
  final String? note;
  final ProgramEdit? programEdit;
  final bool youtube;

  String get shownName => programEdit?.name ?? name;
  bool get changed => was != null;

  WorkoutExercise copyWith({String? name, String? was, int? rpe, String? tempo, String? superset, bool clearExtras = false}) =>
      WorkoutExercise(
        name ?? this.name,
        sets,
        reps,
        rest,
        load,
        was: was ?? this.was,
        rpe: clearExtras ? rpe : (rpe ?? this.rpe),
        tempo: clearExtras ? tempo : (tempo ?? this.tempo),
        superset: clearExtras ? superset : (superset ?? this.superset),
        note: clearExtras ? null : note,
        programEdit: clearExtras ? null : programEdit,
        youtube: clearExtras ? false : youtube,
      );
}

class WorkoutDay {
  const WorkoutDay(this.day, this.name, this.kind, this.edited, this.exercises, {this.note});
  final String day;
  final String name;
  final String kind;
  final bool edited;
  final List<WorkoutExercise> exercises;
  final String? note;

  bool get isRest => exercises.isEmpty;
  int get totalSets => exercises.fold(0, (a, e) => a + (int.tryParse(e.sets) ?? 0));

  WorkoutDay copyWith({bool? edited, List<WorkoutExercise>? exercises}) =>
      WorkoutDay(day, name, kind, edited ?? this.edited, exercises ?? this.exercises, note: note);
}

class ExerciseGuide {
  const ExerciseGuide({required this.steps, required this.cues, required this.primary, required this.also});
  final List<String> steps;
  final List<String> cues;
  final String primary;
  final List<String> also;
}

class PlanHistoryItem {
  const PlanHistoryItem(this.name, this.dates, this.badge, this.tone);
  final String name;
  final String dates;
  final String badge;
  final BadgeTone tone;
}

// ───────────────────────── Plans: meals ─────────────────────────

/// A food in the read-only day view of the meal plan.
class MealFood {
  const MealFood(this.name, this.qty, this.kcal, this.p, this.c, this.f, [this.swap = '']);
  final String name;
  final String qty;
  final int kcal;
  final int p;
  final int c;
  final int f;
  final String swap;
}

class DayMeal {
  const DayMeal(this.name, this.time, this.foods, {this.changed = false, this.alt = ''});
  final String name;
  final String time;
  final List<MealFood> foods;
  final bool changed;
  final String alt;

  int get kcal => foods.fold(0, (a, f) => a + f.kcal);
  int get protein => foods.fold(0, (a, f) => a + f.p);
  int get carbs => foods.fold(0, (a, f) => a + f.c);
  int get fat => foods.fold(0, (a, f) => a + f.f);
}

class FoodSwap {
  const FoodSwap(this.name, this.portion, this.match);
  final String name;
  final String portion;
  final int match;
}

class FoodUnit {
  const FoodUnit(this.label, this.grams);
  final String label;
  final double grams;
}

/// A food in the meal plan editor. Macros are per one [unit]; amount = [qty] units.
class PlanFood {
  const PlanFood(
    this.name,
    this.unit,
    this.qty, {
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    required this.swaps,
    required this.units,
    required this.per100,
    this.was,
  });

  final String name;
  final String unit;
  final double qty;
  final double kcal;
  final double p;
  final double c;
  final double f;
  final List<FoodSwap> swaps;
  final List<FoodUnit> units;

  /// kcal, protein, carbs, fat per 100 g.
  final List<double> per100;

  /// What it was in the master plan (set when changed for the client).
  final String? was;

  double get unitGrams => units.firstWhere((u) => u.label == unit, orElse: () => const FoodUnit('g', 1)).grams;

  PlanFood copyWith({String? unit, double? qty, double? kcal, double? p, double? c, double? f, List<FoodSwap>? swaps, String? was}) => PlanFood(
        name,
        unit ?? this.unit,
        qty ?? this.qty,
        kcal: kcal ?? this.kcal,
        p: p ?? this.p,
        c: c ?? this.c,
        f: f ?? this.f,
        swaps: swaps ?? this.swaps,
        units: units,
        per100: per100,
        was: was ?? this.was,
      );
}

class PlanMeal {
  const PlanMeal(this.name, this.time, this.target, this.foods);
  final String name;
  final String time;
  final int target;
  final List<PlanFood> foods;

  PlanMeal copyWith({List<PlanFood>? foods}) => PlanMeal(name, time, target, foods ?? this.foods);
}

class LibraryFood {
  const LibraryFood(this.name, this.serving, this.kcal, this.p, this.c, this.f, this.group, this.diet, {this.team = false});
  final String name;
  final String serving;
  final int kcal;
  final int p;
  final int c;
  final int f;
  final String group;
  final String diet;
  final bool team;

  bool get isVeg => diet != 'nonVeg' && diet != 'egg';
}

class LibraryExercise {
  const LibraryExercise(this.name, this.muscle, this.equipment, this.level);
  final String name;
  final String muscle;
  final String equipment;
  final String level;
}

// ───────────────────────── Plans: supplements / habits ─────────────────────────

class SupplementItem {
  const SupplementItem(this.name, this.sub, this.cap, {this.dose = '', this.when = '', this.how = '', this.stock = '', this.changed = false});
  final String name;
  final String sub;
  final String cap;
  final String dose;
  final String when;
  final String how;
  final String stock;
  final bool changed;
}

class HabitItem {
  const HabitItem(this.title, this.sub, this.cap, {this.habit = '', this.target = '', this.often = '', this.starts = '', this.changed = false});
  final String title;
  final String sub;
  final String cap;
  final String habit;
  final String target;
  final String often;
  final String starts;
  final bool changed;
}

// ───────────────────────── Assign plan ─────────────────────────

class PreviewRow {
  const PreviewRow(this.k, this.v, this.m, {this.rest = false});
  final String k;
  final String v;
  final String m;
  final bool rest;
}

class AssignOption {
  const AssignOption({
    required this.id,
    required this.name,
    required this.sub,
    required this.note,
    required this.used,
    required this.kpis,
    required this.meta,
    required this.by,
    required this.rows,
    this.tip = '',
    this.current = false,
    this.diff = const [],
  });
  final String id;
  final String name;
  final String sub;
  final String note;
  final int used;
  final String tip;
  final List<Kv> kpis;
  final String meta;
  final String by;
  final List<PreviewRow> rows;
  final bool current;
  final List<String> diff;
}

class AssignKind {
  const AssignKind({
    required this.id,
    required this.title,
    required this.sub,
    required this.search,
    required this.currentName,
    required this.currentEnd,
    required this.length,
    required this.rowsTitle,
    required this.filters,
    required this.options,
  });
  final String id;
  final String title;
  final String sub;
  final String search;
  final String currentName;
  final String currentEnd;
  final String length;
  final String rowsTitle;
  final List<(String, List<String>)> filters;
  final List<AssignOption> options;
}

// ───────────────────────── Logs ─────────────────────────

class WorkoutLogRow {
  const WorkoutLogRow(this.date, this.workout, this.sets, this.volume, this.time, this.status);
  final String date;
  final String workout;
  final String sets;
  final String volume;
  final String time;

  /// 'done' | 'part' | 'miss'
  final String status;
}

class MealLogRow {
  const MealLogRow(this.date, this.kcal, this.pct, this.protein, this.carbs, this.fat, this.meals, this.status);
  final String date;
  final String kcal;
  final double pct;
  final String protein;
  final String carbs;
  final String fat;
  final String meals;

  /// 'ok' | 'over' | 'part'
  final String status;
}

class DailyCheckinRow {
  const DailyCheckinRow(this.date, this.sleep, this.energy, this.mood, this.hunger, this.steps, this.note);
  final String date;
  final String sleep;
  final String energy;
  final String mood;
  final String hunger;
  final String steps;
  final String note;
  bool get sent => sleep != '—';
}

class WeeklyCheckinRow {
  const WeeklyCheckinRow(this.week, this.date, this.weight, this.sub, this.badge, this.tone);
  final String week;
  final String date;
  final String weight;
  final String sub;
  final String badge;
  final BadgeTone tone;
}

class TickLogRow {
  const TickLogRow(this.date, this.ticks);
  final String date;
  final List<bool> ticks;
  int get done => ticks.where((t) => t).length;
}

class LoggedFood {
  const LoggedFood(this.name, this.qty, this.kcal, this.p, this.c, this.f);
  final String name;
  final String qty;
  final int kcal;
  final int p;
  final int c;
  final int f;
}

class LoggedMeal {
  const LoggedMeal(this.name, this.time, this.foods, this.badge, this.tone, {this.photo = false, this.was = ''});
  final String name;
  final String time;
  final List<LoggedFood> foods;
  final String badge;
  final BadgeTone tone;
  final bool photo;
  final String was;
  bool get logged => foods.isNotEmpty;
}

// ───────────────────────── Compare plans ─────────────────────────

class CompareRow {
  const CompareRow(this.label, this.a, this.b, {this.barA, this.barB, required this.change, required this.tone});
  final String label;
  final String a;
  final String b;
  final double? barA;
  final double? barB;
  final String change;
  final BadgeTone tone;
}

class CompareTable {
  const CompareTable(this.head, this.rows);
  final String head;
  final List<CompareRow> rows;
}

class CompareSection {
  const CompareSection(this.id, this.title, this.better, this.tables);
  final String id;
  final String title;
  final String better;
  final List<CompareTable> tables;
}

// ───────────────────────── Progress ─────────────────────────

class ProgressStat {
  const ProgressStat(this.label, this.delta, this.value, this.sub);
  final String label;
  final String delta;
  final String value;
  final String sub;
}

class Measurement {
  const Measurement(this.date, this.weight, this.waist, this.hips, this.chest, this.arm, this.bodyFat);
  final String date;
  final String weight;
  final String waist;
  final String hips;
  final String chest;
  final String arm;
  final String bodyFat;
}

class PersonalBest {
  const PersonalBest(this.exercise, this.start, this.best, this.change);
  final String exercise;
  final String start;
  final String best;
  final String change;
}

class PhotoDate {
  const PhotoDate(this.date, this.weight, this.tone, this.source);
  final String date;
  final String weight;
  final int tone;
  final String source;
}

class WeightPoint {
  const WeightPoint(this.day, this.kg);

  /// Days since 10 Sep.
  final int day;
  final double kg;
}

// ───────────────────────── Content ─────────────────────────

class ClientContent {
  const ClientContent({
    required this.title,
    required this.type,
    required this.by,
    required this.why,
    required this.whyTone,
    required this.seen,
    required this.seenBadge,
    required this.len,
    required this.until,
    required this.added,
    required this.kpis,
    required this.text,
    required this.assigned,
  });
  final String title;
  final String type;
  final String by;
  final String why;
  final BadgeTone whyTone;
  final String seen;
  final bool seenBadge;
  final String len;
  final String until;
  final String added;
  final List<Kv> kpis;
  final String text;

  /// Assigned straight to the client ("Remove for X") vs from a plan / everyone ("Hide for X").
  final bool assigned;

  /// 'assigned' | 'plans' | 'everyone'
  String get group => assigned ? 'assigned' : (why == 'Everyone' ? 'everyone' : 'plans');
}

class ContentPick {
  const ContentPick(this.name, this.kind, this.len, this.video, this.note, {this.has = false});
  final String name;
  final String kind;
  final String len;
  final bool video;
  final String note;
  final bool has;
}

// ───────────────────────── Forms ─────────────────────────

class FormQuestion {
  const FormQuestion(this.text, this.type, {this.required = false, this.changed = false, this.note});
  final String text;
  final String type;
  final bool required;
  final bool changed;
  final String? note;
}

class QaSection {
  const QaSection(this.title, this.items);
  final String title;
  final List<Kv> items;
}

class ClientForm {
  const ClientForm({
    required this.id,
    required this.name,
    required this.sub,
    required this.badge,
    required this.tone,
    this.answers = const [],
    this.questions = const [],
    this.cap = '',
    this.editCap = '',
    this.schedule = const [],
    this.edited = false,
  });
  final String id;
  final String name;
  final String sub;
  final String badge;
  final BadgeTone tone;

  /// Filled forms show their answers.
  final List<QaSection> answers;

  /// Recurring / waiting forms show their questions and can be edited.
  final List<FormQuestion> questions;
  final String cap;
  final String editCap;
  final List<String> schedule;
  final bool edited;

  bool get editable => questions.isNotEmpty;
}

class SendFormOption {
  const SendFormOption(this.id, this.name, this.sub, this.questions, [this.has = '']);
  final String id;
  final String name;
  final String sub;
  final String questions;
  final String has;
}

// ───────────────────────── History / Activity / Notes ─────────────────────────

class HistoryEvent {
  const HistoryEvent(this.kind, this.title, this.detail, this.when, this.who, [this.badge = '', this.tone = BadgeTone.neutral]);

  /// plan | check | form | mile | goal | health | trainer | acct
  final String kind;
  final String title;
  final String detail;
  final String when;
  final String who;
  final String badge;
  final BadgeTone tone;
}

class HistoryMonth {
  const HistoryMonth(this.month, this.summary, this.items);
  final String month;
  final String summary;
  final List<HistoryEvent> items;
}

class TimelineBar {
  const TimelineBar(this.label, this.start, this.width, this.state, this.tip);
  final String label;

  /// Left offset and width as a fraction of the year track (0–1).
  final double start;
  final double width;

  /// cur | done | old | next
  final String state;
  final String tip;
}

class ActivityItem {
  const ActivityItem(this.icon, this.kind, this.who, this.post, this.when, {this.note = '', this.old = '', this.nw = ''});

  /// food | clip | edit | dumb | play | scale
  final String icon;
  final String kind;
  final String who;
  final String post;
  final String when;
  final String note;
  final String old;
  final String nw;

  String get source => who == 'Riya' ? 'Riya · Android app' : who == 'Vimal' ? 'Admin · Web' : 'Trainer · Web';
}

class ActivityDay {
  const ActivityDay(this.label, this.daysAgo, this.items);
  final String label;
  final int daysAgo;
  final List<ActivityItem> items;
}

class ProfileNote {
  const ProfileNote(this.text, this.by, this.when, {this.flag = false});
  final String text;
  final String by;
  final String when;
  final bool flag;
}

class TrainerOption {
  const TrainerOption(this.id, this.name, this.initials, this.colorIndex, this.sub, this.clients, this.max, {this.current = false, this.best = false});
  final String id;
  final String name;
  final String initials;
  final int colorIndex;
  final String sub;
  final int clients;
  final int max;
  final bool current;
  final bool best;
  bool get full => clients >= max;
}
