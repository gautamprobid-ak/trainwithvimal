/// Models for the BUILD area: exercise library and master programs.
library;

/// How the client logs an exercise (New exercise > Client logs).
enum LogType { weightReps, time, cardio }

extension LogTypeX on LogType {
  String get label => switch (this) {
        LogType.weightReps => 'kg × reps',
        LogType.time => 'Seconds',
        LogType.cardio => 'Minutes · km',
      };
}

/// A muscle the exercise also works ("Also works" list on the Muscles tab).
class MuscleWork {
  const MuscleWork(this.name, {this.note = '', this.strong = false});
  final String name;
  final String note;
  final bool strong;
}

/// One exercise in the library.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.works,
    required this.equipment,
    required this.level,
    this.custom = false,
    this.hasVideo = true,
    this.videoDur = '0:42',
    this.videoTitle,
    this.tone = 0,
    required this.sets,
    required this.reps,
    required this.rest,
    this.rpe = 0,
    this.tempo = '',
    this.logType = LogType.weightReps,
    this.howTo = const [],
    this.cues = const [],
    this.primaryNote = '',
    this.also = const [],
  });

  final String id;
  final String name;

  /// Muscle group used by the library filter (Chest, Back, Legs ...).
  final String muscle;

  /// "Chest · also Triceps, Shoulders".
  final String works;
  final String equipment;
  final String level;

  /// Made by the team (Source: Custom) instead of built-in.
  final bool custom;
  final bool hasVideo;
  final String videoDur;
  final String? videoTitle;

  /// Thumbnail gradient (media t1 … t4) → 0 … 3.
  final int tone;

  // Default sets and reps, filled in when added to a program.
  final int sets;
  final String reps;

  /// Seconds.
  final int rest;
  final int rpe;
  final String tempo;
  final LogType logType;

  final List<String> howTo;
  final List<String> cues;
  final String primaryNote;
  final List<MuscleWork> also;

  String get source => custom ? 'Custom' : 'Built-in';
}

/// Per-program copy of a library exercise ("Edit for this program").
class ExerciseOverride {
  const ExerciseOverride({required this.name, required this.video, required this.steps, required this.cues});

  /// Name in this program.
  final String name;

  /// 'lib' · 'cl' (another content library video) · 'yt' (YouTube link).
  final String video;
  final List<String> steps;
  final List<String> cues;

  ExerciseOverride copyWith({String? name, String? video, List<String>? steps, List<String>? cues}) => ExerciseOverride(
        name: name ?? this.name,
        video: video ?? this.video,
        steps: steps ?? this.steps,
        cues: cues ?? this.cues,
      );
}

/// An exercise placed on a program day, with its prescription.
class ProgramExercise {
  const ProgramExercise(
    this.name,
    this.sets,
    this.reps,
    this.rest, {
    this.rpe = 0,
    this.tempo = '',
    this.group = '',
    this.note = '',
    this.custom,
  });

  /// Library exercise name.
  final String name;
  final int sets;
  final String reps;

  /// Seconds.
  final int rest;
  final int rpe;
  final String tempo;

  /// Superset letter ('' = not in a superset).
  final String group;
  final String note;
  final ExerciseOverride? custom;

  String get shownName => custom?.name ?? name;

  ProgramExercise copyWith({
    int? sets,
    String? reps,
    int? rest,
    int? rpe,
    String? tempo,
    String? group,
    String? note,
    ExerciseOverride? custom,
    bool clearCustom = false,
  }) =>
      ProgramExercise(
        name,
        sets ?? this.sets,
        reps ?? this.reps,
        rest ?? this.rest,
        rpe: rpe ?? this.rpe,
        tempo: tempo ?? this.tempo,
        group: group ?? this.group,
        note: note ?? this.note,
        custom: clearCustom ? null : (custom ?? this.custom),
      );
}

/// One day of the program week (workout or rest day).
class ProgramDay {
  const ProgramDay({required this.id, required this.title, this.rest = false, this.note = '', this.exercises = const []});
  final String id;
  final String title;
  final bool rest;
  final String note;
  final List<ProgramExercise> exercises;

  ProgramDay copyWith({String? title, bool? rest, String? note, List<ProgramExercise>? exercises}) => ProgramDay(
        id: id,
        title: title ?? this.title,
        rest: rest ?? this.rest,
        note: note ?? this.note,
        exercises: exercises ?? this.exercises,
      );
}

/// A client that can follow a program (assign modal / assigned clients).
class ProgramClient {
  const ProgramClient(this.name, this.goal, this.trainer, this.initials, this.colorIndex, {this.custom = false});
  final String name;
  final String goal;
  final String trainer;
  final String initials;

  /// av.c1 … c6 → 0 … 5.
  final int colorIndex;

  /// Has a custom version of the program made only for them.
  final bool custom;
}

/// A master program.
class Program {
  const Program({
    required this.id,
    required this.name,
    required this.goal,
    required this.weeks,
    required this.days,
    required this.clients,
    required this.edited,
    this.archived = false,
    this.tone = 1,
    this.shortName,
  });

  final String id;
  final String name;
  final String goal;
  final int weeks;

  /// Mon … Sun (up to 7).
  final List<ProgramDay> days;

  /// Names of the clients following it.
  final List<String> clients;
  final String edited;
  final bool archived;

  /// Icon tone t1 … t4.
  final int tone;

  /// Short name used in "On Hypertrophy PPL".
  final String? shortName;

  /// Training (true) / rest (false) for each weekday, Monday first.
  List<bool> get pattern => [for (var i = 0; i < 7; i++) i < days.length && !days[i].rest];

  int get daysPerWeek => pattern.where((x) => x).length;

  Program copyWith({
    String? id,
    String? name,
    String? goal,
    int? weeks,
    List<ProgramDay>? days,
    List<String>? clients,
    String? edited,
    bool? archived,
  }) =>
      Program(
        id: id ?? this.id,
        name: name ?? this.name,
        goal: goal ?? this.goal,
        weeks: weeks ?? this.weeks,
        days: days ?? this.days,
        clients: clients ?? this.clients,
        edited: edited ?? this.edited,
        archived: archived ?? this.archived,
        tone: tone,
        shortName: id != null || name != null ? null : shortName,
      );
}
