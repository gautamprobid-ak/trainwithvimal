// Models for the shared "build" library pages: nutrition (meal plans, food
// library, Excel import), habits & supplements, and the content library.

// ---------------------------------------------------------------------------
// Nutrition
// ---------------------------------------------------------------------------

enum Diet { veg, egg, nonVeg, vegan }

extension DietX on Diet {
  /// Long label used in pickers ("Vegetarian").
  String get label => switch (this) {
        Diet.veg => 'Vegetarian',
        Diet.egg => 'Eggetarian',
        Diet.nonVeg => 'Non-veg',
        Diet.vegan => 'Vegan',
      };

  /// Short label used in the food table ("Veg", "Egg").
  String get short => switch (this) {
        Diet.veg => 'Veg',
        Diet.egg => 'Egg',
        Diet.nonVeg => 'Non-veg',
        Diet.vegan => 'Vegan',
      };
}

/// A serving unit of a food: its name and its weight in grams. "g" is grams.
class FoodUnit {
  const FoodUnit(this.name, this.grams);
  final String name;
  final double grams;
  bool get isGrams => name == 'g';
}

/// "Used in" a meal plan: plan name and the meals that use the food.
class PlanUse {
  const PlanUse(this.plan, this.meals);
  final String plan;
  final String meals;
}

/// A food in the team food library. Nutrition is stored per 100 g.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.units,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    required this.group,
    required this.diet,
    this.brand = '',
    this.custom = false,
    this.swaps = const [],
    this.usedIn = const [],
    this.defaultUnit = 0,
    this.defaultQty = 100,
    this.source = 'IFCT',
  });

  final String id;
  final String name;
  final List<FoodUnit> units;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fibre;
  final String group;
  final Diet diet;
  final String brand;

  /// Made by the team (shows in "My foods", can be deleted).
  final bool custom;
  final List<String> swaps;
  final List<PlanUse> usedIn;
  final int defaultUnit;
  final double defaultQty;
  final String source;

  FoodUnit get unit => units[defaultUnit.clamp(0, units.length - 1)];
  double get defaultGrams => unit.grams * defaultQty;

  Food copyWith({
    String? id,
    String? name,
    List<FoodUnit>? units,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fibre,
    String? group,
    Diet? diet,
    bool? custom,
    List<String>? swaps,
    List<PlanUse>? usedIn,
    int? defaultUnit,
    double? defaultQty,
    String? source,
  }) =>
      Food(
        id: id ?? this.id,
        name: name ?? this.name,
        units: units ?? this.units,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fibre: fibre ?? this.fibre,
        group: group ?? this.group,
        diet: diet ?? this.diet,
        brand: brand,
        custom: custom ?? this.custom,
        swaps: swaps ?? this.swaps,
        usedIn: usedIn ?? this.usedIn,
        defaultUnit: defaultUnit ?? this.defaultUnit,
        defaultQty: defaultQty ?? this.defaultQty,
        source: source ?? this.source,
      );
}

/// One row of the "Indian foods.xlsx" sheet in the Excel import.
class ImportRow {
  const ImportRow({
    required this.name,
    required this.category,
    required this.mainCategory,
    required this.unit,
    required this.unitGrams,
    required this.qty,
    required this.per100,
    required this.micros,
    required this.source,
    required this.sheetKcal,
    required this.calcKcal,
    required this.kcalDiffers,
    required this.raw,
    required this.ml,
    required this.existing,
  });

  final String name;
  final String category;
  final String mainCategory;
  final String unit;
  final double unitGrams;
  final double qty;

  /// kcal, protein, carbs, fat, fibre per 100 g.
  final List<double> per100;

  /// Sodium, iron, calcium, potassium (mg).
  final List<double> micros;
  final String source;
  final double sheetKcal;
  final double calcKcal;
  final bool kcalDiffers;
  final bool raw;
  final bool ml;

  /// Name of the library food with the same name ('' if new).
  final String existing;
  bool get isDuplicate => existing.isNotEmpty;
}

/// A client on a meal plan. A non-empty [note] means a custom version.
class PlanClient {
  const PlanClient(this.name, [this.note = '']);
  final String name;
  final String note;
  bool get custom => note.isNotEmpty;
}

/// A swap the client may use instead of a food.
class FoodAlt {
  const FoodAlt(this.name, this.portion, this.match);
  final String name;
  final String portion;
  final int match;
}

/// A food inside a meal option. Macros are per one [unit] ("g" = per gram).
class PlanFood {
  const PlanFood({
    required this.name,
    required this.unit,
    required this.qty,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.alts = const [],
    required this.units,
    required this.per100,
  });

  final String name;
  final String unit;
  final double qty;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final List<FoodAlt> alts;
  final List<FoodUnit> units;

  /// kcal, protein, carbs, fat per 100 g.
  final List<double> per100;

  double get unitGrams => units.firstWhere((u) => u.name == unit, orElse: () => const FoodUnit('g', 1)).grams;
  double get totalKcal => kcal * qty;
  double get totalProtein => protein * qty;
  double get totalCarbs => carbs * qty;
  double get totalFat => fat * qty;

  PlanFood copyWith({String? unit, double? qty, double? kcal, double? protein, double? carbs, double? fat, List<FoodAlt>? alts}) => PlanFood(
        name: name,
        unit: unit ?? this.unit,
        qty: qty ?? this.qty,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        alts: alts ?? this.alts,
        units: units,
        per100: per100,
      );
}

class MealOption {
  const MealOption(this.name, this.foods);
  final String name;
  final List<PlanFood> foods;
  MealOption copyWith({String? name, List<PlanFood>? foods}) => MealOption(name ?? this.name, foods ?? this.foods);
}

class Meal {
  const Meal({required this.id, required this.name, required this.time, required this.target, this.defaultOption = 0, required this.options});
  final String id;
  final String name;
  final String time;
  final int target;
  final int defaultOption;
  final List<MealOption> options;

  Meal copyWith({String? name, String? time, int? target, int? defaultOption, List<MealOption>? options}) => Meal(
        id: id,
        name: name ?? this.name,
        time: time ?? this.time,
        target: target ?? this.target,
        defaultOption: defaultOption ?? this.defaultOption,
        options: options ?? this.options,
      );
}

/// Daily targets of a meal plan.
class PlanTargets {
  const PlanTargets(this.kcal, this.protein, this.carbs, this.fat, [this.fibre = 30, this.water = 3]);
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final int fibre;
  final double water;
}

/// A master meal plan.
class MealPlan {
  const MealPlan({
    required this.id,
    required this.name,
    required this.diet,
    required this.targets,
    required this.mealNames,
    required this.optionCount,
    this.clients = const [],
    this.published = false,
    this.dirty = false,
    this.edited = 'just now',
    this.meals,
    this.perms = const [true, true, true, true],
  });

  final String id;
  final String name;

  /// "Veg", "Eggetarian", "Non-veg" or "Vegan".
  final String diet;
  final PlanTargets targets;
  final List<String> mealNames;
  final int optionCount;
  final List<PlanClient> clients;
  final bool published;

  /// Has changes the clients have not received yet.
  final bool dirty;
  final String edited;

  /// Full meals once the plan was opened in the builder.
  final List<Meal>? meals;
  final List<bool> perms;

  bool get isLive => published && !dirty;

  MealPlan copyWith({
    String? id,
    String? name,
    PlanTargets? targets,
    List<String>? mealNames,
    int? optionCount,
    List<PlanClient>? clients,
    bool? published,
    bool? dirty,
    String? edited,
    List<Meal>? meals,
    List<bool>? perms,
  }) =>
      MealPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        diet: diet,
        targets: targets ?? this.targets,
        mealNames: mealNames ?? this.mealNames,
        optionCount: optionCount ?? this.optionCount,
        clients: clients ?? this.clients,
        published: published ?? this.published,
        dirty: dirty ?? this.dirty,
        edited: edited ?? this.edited,
        meals: meals ?? this.meals,
        perms: perms ?? this.perms,
      );
}

/// A food in the builder's "Add food" picker (per default serving).
class LibraryFood {
  const LibraryFood({
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.group,
    required this.diet,
    this.team = false,
  });
  final String name;
  final String serving;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String group;
  final Diet diet;
  final bool team;
}

// ---------------------------------------------------------------------------
// Habits & supplements
// ---------------------------------------------------------------------------

enum HabitKind { tick, counter }

enum HabitFreq { daily, specificDays, timesPerWeek }

enum HabitIcon { water, steps, sleep, food, timer, sun, habit }

extension HabitIconX on HabitIcon {
  String get label => switch (this) {
        HabitIcon.water => 'Water',
        HabitIcon.steps => 'Steps',
        HabitIcon.sleep => 'Sleep',
        HabitIcon.food => 'Food',
        HabitIcon.timer => 'Timer',
        HabitIcon.sun => 'Sun',
        HabitIcon.habit => 'Habit',
      };
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.kind,
    required this.target,
    required this.unit,
    required this.freq,
    this.days = const [0, 2, 4],
    this.timesPerWeek = 3,
    required this.why,
    required this.icon,
    this.clients = const [],
  });

  final String id;
  final String name;
  final HabitKind kind;
  final int target;
  final String unit;
  final HabitFreq freq;

  /// 0 = Monday … 6 = Sunday.
  final List<int> days;
  final int timesPerWeek;
  final String why;
  final HabitIcon icon;
  final List<String> clients;

  Habit copyWith({
    String? id,
    String? name,
    HabitKind? kind,
    int? target,
    String? unit,
    HabitFreq? freq,
    List<int>? days,
    int? timesPerWeek,
    String? why,
    HabitIcon? icon,
    List<String>? clients,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        target: target ?? this.target,
        unit: unit ?? this.unit,
        freq: freq ?? this.freq,
        days: days ?? this.days,
        timesPerWeek: timesPerWeek ?? this.timesPerWeek,
        why: why ?? this.why,
        icon: icon ?? this.icon,
        clients: clients ?? this.clients,
      );
}

class SupplementItem {
  const SupplementItem(this.name, this.dose, this.timing, this.withFood, this.days);
  final String name;
  final String dose;
  final String timing;
  final bool withFood;
  final List<int> days;

  SupplementItem copyWith({String? name, String? dose, String? timing, bool? withFood, List<int>? days}) =>
      SupplementItem(name ?? this.name, dose ?? this.dose, timing ?? this.timing, withFood ?? this.withFood, days ?? this.days);
}

class SupplementPlan {
  const SupplementPlan({required this.id, required this.name, this.note = '', this.items = const [], this.clients = const []});
  final String id;
  final String name;
  final String note;
  final List<SupplementItem> items;
  final List<String> clients;

  SupplementPlan copyWith({String? id, String? name, String? note, List<SupplementItem>? items, List<String>? clients}) => SupplementPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        note: note ?? this.note,
        items: items ?? this.items,
        clients: clients ?? this.clients,
      );
}

// ---------------------------------------------------------------------------
// Content library
// ---------------------------------------------------------------------------

enum ContentKind { video, article, pdf, image }

extension ContentKindX on ContentKind {
  String get label => switch (this) {
        ContentKind.video => 'Video',
        ContentKind.article => 'Article',
        ContentKind.pdf => 'PDF',
        ContentKind.image => 'Image',
      };
}

/// Where a piece of content links to when it is "used in" something.
enum ContentLink { exercise, program, client, mealPlan, automation, form, habit }

class ContentUse {
  const ContentUse(this.what, this.name, this.link);

  /// "Exercise", "Program", "Client", "Meal plan" ...
  final String what;
  final String name;
  final ContentLink link;
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.category,
    required this.by,
    required this.updated,
    required this.length,
    this.everyone = false,
    this.clients = const [],
    this.uses = const [],
    this.opened = 0,
    this.finished = 0,
    this.body = '',
    this.tone = 1,
  });

  final String id;
  final String title;
  final ContentKind kind;
  final String category;
  final String by;
  final String updated;

  /// "0:42", "2 min read", "3 pages", "JPG".
  final String length;
  final bool everyone;
  final List<String> clients;
  final List<ContentUse> uses;
  final int opened;
  final int finished;
  final String body;

  /// Thumbnail gradient 1–4 (media t1…t4).
  final int tone;

  ContentItem copyWith({ContentKind? kind, String? category, String? updated, bool? everyone, List<String>? clients, String? title, String? body}) =>
      ContentItem(
        id: id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        category: category ?? this.category,
        by: by,
        updated: updated ?? this.updated,
        length: length,
        everyone: everyone ?? this.everyone,
        clients: clients ?? this.clients,
        uses: uses,
        opened: opened,
        finished: finished,
        body: body ?? this.body,
        tone: tone,
      );
}
