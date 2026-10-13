import '../models/programs.dart';

/// Mock data for the BUILD area (programs + exercise library), taken from
/// ProgramsMobile, ProgramBuilderMobile, ExerciseLibraryMobile,
/// ExerciseDetailMobile and Main (design system) pages.
abstract final class ProgramsMock {
  /// Muscle groups used by the library filter and the program builder picker.
  static const muscles = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio'];
  static const equipment = ['Barbell', 'Dumbbell', 'Cable', 'Machine', 'Bodyweight'];
  static const levels = ['Beginner', 'Intermediate'];
  static const sources = ['Built-in', 'Custom'];

  static const _durs = ['0:42', '0:35', '0:51', '0:28'];

  /// Default sets / reps / rest saved on each library exercise, by equipment.
  static const _def = {
    'Barbell': (4, '6–8', 120),
    'Dumbbell': (3, '8–12', 90),
    'Cable': (3, '12–15', 60),
    'Machine': (3, '10–12', 90),
    'Bodyweight': (3, '10–15', 60),
  };

  static const _genericHow = ['Set up as shown in the video.', 'Move through the full range with control.', 'Breathe out on the hard part.'];
  static const _genericCues = ['Keep the core tight.', 'No bouncing at the bottom.'];

  static const _what = {
    'Chest': 'Push the arms forward',
    'Back': 'Pull the shoulder blades back',
    'Shoulders': 'Help lift the arm',
    'Triceps': 'Straighten the arms at the top',
    'Biceps': 'Bend the elbow',
    'Forearms': 'Hold the grip',
    'Core': 'Keep the body still',
    'Glutes': 'Drive the hips forward',
    'Hamstrings': 'Bend the knee',
    'Quads': 'Straighten the knee',
    'Rear delts': 'Pull the arms back',
  };

  static Exercise _ex(int i, String name, String muscle, String works, String equipment, String level) {
    final d = _def[equipment] ?? _def['Cable']!;
    final cardio = muscle == 'Cardio';
    final timed = name == 'Plank' || name == 'Dead Bug';
    final alsoPart = works.contains(' · also ') ? works.split(' · also ').last : '';
    final also = [
      for (final (j, m) in alsoPart.split(', ').where((s) => s.isNotEmpty).indexed) MuscleWork(m, note: _what[m] ?? 'Help keep the position', strong: j == 0),
    ];
    return Exercise(
      id: _slug(name),
      name: name,
      muscle: muscle,
      works: works,
      equipment: equipment,
      level: level,
      hasVideo: i % 3 != 1,
      videoDur: _durs[i % 4],
      tone: i % 4,
      sets: cardio ? 1 : (timed ? 3 : d.$1),
      reps: cardio ? '20 min' : (timed ? '45 s' : d.$2),
      rest: cardio ? 0 : (timed ? 45 : d.$3),
      logType: cardio ? LogType.cardio : (timed ? LogType.time : LogType.weightReps),
      howTo: name == 'Dips'
          ? const ['Grip the bars, arms straight, body upright.', 'Lower until the elbows are at 90°.', 'Press back up to straight arms.']
          : _genericHow,
      cues: name == 'Dips' ? const ['Lean forward a little for more chest.', 'Shoulders down, away from the ears.'] : _genericCues,
      primaryNote: works.split(' · ').first,
      also: also,
    );
  }

  static String _slug(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  static const _benchPress = Exercise(
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    muscle: 'Chest',
    works: 'Chest · also Triceps, Shoulders',
    equipment: 'Barbell',
    level: 'Intermediate',
    hasVideo: true,
    videoDur: '0:42',
    videoTitle: 'Bench press · setup',
    tone: 0,
    sets: 4,
    reps: '6–8',
    rest: 120,
    rpe: 8,
    tempo: '3-1-1',
    howTo: [
      'Lie with your eyes under the bar, feet flat, shoulder blades pulled back and down.',
      'Grip slightly wider than shoulder width and unrack with straight arms.',
      'Lower the bar to the mid chest in about two seconds, elbows at roughly 45°.',
      'Press up and slightly back until the arms are straight.',
    ],
    cues: [
      'Squeeze the bar and keep the wrists stacked over the elbows.',
      'Keep the hips on the bench; drive through the feet.',
      'Touch the chest, do not bounce.',
    ],
    primaryNote: 'Pectorals',
    also: [
      MuscleWork('Triceps', note: 'Straighten the arms at the top', strong: true),
      MuscleWork('Front shoulders', note: 'Help press the bar up'),
    ],
  );

  /// The library: 28 built-in exercises.
  static final List<Exercise> exercises = [
    _benchPress,
    for (final (i, e) in const [
      ('Incline Dumbbell Press', 'Chest', 'Chest · also Shoulders, Triceps', 'Dumbbell', 'Intermediate'),
      ('Cable Fly', 'Chest', 'Chest', 'Cable', 'Beginner'),
      ('Push-up', 'Chest', 'Chest · also Triceps, Core', 'Bodyweight', 'Beginner'),
      ('Dips', 'Chest', 'Chest · also Triceps', 'Bodyweight', 'Intermediate'),
      ('Pull-up', 'Back', 'Back · also Biceps', 'Bodyweight', 'Intermediate'),
      ('Barbell Row', 'Back', 'Back · also Biceps, Rear delts', 'Barbell', 'Intermediate'),
      ('Seated Cable Row', 'Back', 'Back · also Biceps', 'Cable', 'Beginner'),
      ('Lat Pulldown', 'Back', 'Back · also Biceps', 'Machine', 'Beginner'),
      ('One-arm Dumbbell Row', 'Back', 'Back · also Biceps', 'Dumbbell', 'Beginner'),
      ('Back Squat', 'Legs', 'Quads · also Glutes, Core', 'Barbell', 'Intermediate'),
      ('Goblet Squat', 'Legs', 'Quads · also Glutes', 'Dumbbell', 'Beginner'),
      ('Romanian Deadlift', 'Legs', 'Hamstrings · also Glutes, Back', 'Barbell', 'Intermediate'),
      ('Walking Lunge', 'Legs', 'Quads · also Glutes', 'Dumbbell', 'Beginner'),
      ('Leg Press', 'Legs', 'Quads · also Glutes', 'Machine', 'Beginner'),
      ('Overhead Press', 'Shoulders', 'Shoulders · also Triceps', 'Barbell', 'Intermediate'),
      ('Arnold Press', 'Shoulders', 'Shoulders · also Triceps', 'Dumbbell', 'Intermediate'),
      ('Cable Lateral Raise', 'Shoulders', 'Shoulders', 'Cable', 'Beginner'),
      ('EZ Bar Curl', 'Arms', 'Biceps', 'Barbell', 'Beginner'),
      ('Hammer Curl', 'Arms', 'Biceps · also Forearms', 'Dumbbell', 'Beginner'),
      ('Tricep Rope Pushdown', 'Arms', 'Triceps', 'Cable', 'Beginner'),
      ('Plank', 'Core', 'Core', 'Bodyweight', 'Beginner'),
      ('Pallof Press', 'Core', 'Core', 'Cable', 'Beginner'),
      ('Incline Treadmill Walk', 'Cardio', 'Cardio', 'Machine', 'Beginner'),
      ('Face Pull', 'Shoulders', 'Rear delts · also Back', 'Cable', 'Beginner'),
      ('Hip Thrust', 'Legs', 'Glutes · also Hamstrings', 'Barbell', 'Intermediate'),
      ('Seated DB Shoulder Press', 'Shoulders', 'Shoulders · also Triceps', 'Dumbbell', 'Beginner'),
      ('Dead Bug', 'Core', 'Core', 'Bodyweight', 'Beginner'),
    ].indexed)
      _ex(i + 1, e.$1, e.$2, e.$3, e.$4, e.$5),
  ];

  /// Clients that can follow a program (assign modal). Initials and colours from the design.
  static const clients = [
    ProgramClient('Riya Sharma', 'Fat loss', 'Aman Verma', 'RS', 0, custom: true),
    ProgramClient('Kabir Mehta', 'Fat loss', 'Aman Verma', 'KM', 1),
    ProgramClient('Ishita Bose', 'Fat loss', 'Aman Verma', 'IB', 2),
    ProgramClient('Dev Malhotra', 'Recomp', 'Aman Verma', 'DM', 3),
    ProgramClient('Rohan Kapoor', 'Muscle gain', 'Aman Verma', 'RK', 4),
    ProgramClient('Sana Khan', 'General fitness', 'Neha Joshi', 'SK', 5),
    ProgramClient('Vikram Rao', 'Muscle gain', 'Sahil Kapoor', 'VR', 0),
    ProgramClient('Aisha Sheikh', 'Fat loss', 'Meera Shah', 'AS', 1),
    ProgramClient('Arjun Nair', 'Strength', 'Karan Mehta', 'AN', 2),
    ProgramClient('Pooja Nair', 'Fat loss', 'Vimal', 'PN', 3),
    ProgramClient('Karan Bedi', 'Muscle gain', 'Karan Mehta', 'KB', 4),
  ];

  // ---- Program days -------------------------------------------------------

  static const _fatLossDays = [
    ProgramDay(id: 'd1', title: 'Upper A', note: 'Warm up with 2 light sets on the bench.', exercises: [
      ProgramExercise('Barbell Bench Press', 4, '6–8', 120, rpe: 8),
      ProgramExercise('One-arm Dumbbell Row', 3, '10/side', 90),
      ProgramExercise('Overhead Press', 3, '8', 90, rpe: 8),
      ProgramExercise('Lat Pulldown', 3, '10–12', 75),
      ProgramExercise('EZ Bar Curl', 2, '12', 60, group: 'A'),
      ProgramExercise('Tricep Rope Pushdown', 2, '12', 60, group: 'A'),
    ]),
    ProgramDay(
        id: 'd2',
        title: 'Push Day',
        note: 'Slow on the way down, two-second pause at the bottom. Face pulls are there for shoulder health.',
        exercises: [
          ProgramExercise('Incline Dumbbell Press', 4, '8–10', 90, rpe: 8, tempo: '3-1-1'),
          ProgramExercise('Seated DB Shoulder Press', 3, '8–10', 90, rpe: 8),
          ProgramExercise('Dips', 3, '8–12', 90,
              note: 'Feet on the floor makes it easier.',
              custom: ExerciseOverride(
                name: 'Bench Dips',
                video: 'yt',
                steps: ['Hands on the bench edge, fingers forward.', 'Lower until the elbows are at 90°.', 'Push back up without locking the elbows.'],
                cues: ['Keep the back close to the bench.', 'Shoulders down, away from the ears.'],
              )),
          ProgramExercise('Cable Lateral Raise', 3, '12–15', 45, rpe: 9, group: 'A'),
          ProgramExercise('Face Pull', 3, '15', 45, group: 'A'),
          ProgramExercise('Push-up', 1, 'AMRAP', 0),
        ]),
    ProgramDay(id: 'd3', title: 'Rest', rest: true, note: 'Steps 8k · mobility'),
    ProgramDay(id: 'd4', title: 'Pull Day', exercises: [
      ProgramExercise('Pull-up', 4, '6–8', 120, rpe: 8, note: 'Use the band if you get fewer than 6.'),
      ProgramExercise('Barbell Row', 3, '8', 90),
      ProgramExercise('Seated Cable Row', 3, '10–12', 75),
      ProgramExercise('Face Pull', 3, '15', 45, group: 'A'),
      ProgramExercise('Hammer Curl', 3, '12', 60, group: 'A'),
    ]),
    ProgramDay(id: 'd5', title: 'Legs', note: 'Brace before every squat rep.', exercises: [
      ProgramExercise('Back Squat', 4, '6–8', 150, rpe: 8, tempo: '3-1-1'),
      ProgramExercise('Romanian Deadlift', 3, '8–10', 120),
      ProgramExercise('Walking Lunge', 3, '10/leg', 90),
      ProgramExercise('Leg Press', 3, '12', 90),
      ProgramExercise('Plank', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd6', title: 'Cardio', exercises: [
      ProgramExercise('Incline Treadmill Walk', 1, '30 min', 0, note: 'Zone 2 — you should be able to hold a conversation.'),
    ]),
    ProgramDay(id: 'd7', title: 'Rest', rest: true, note: 'Check-in day'),
  ];

  static const _pplDays = [
    ProgramDay(id: 'd1', title: 'Push A', exercises: [
      ProgramExercise('Barbell Bench Press', 4, '6–8', 120, rpe: 8, tempo: '3-1-1'),
      ProgramExercise('Incline Dumbbell Press', 3, '8–12', 90),
      ProgramExercise('Overhead Press', 3, '8', 90),
      ProgramExercise('Cable Lateral Raise', 3, '12–15', 60, group: 'A'),
      ProgramExercise('Tricep Rope Pushdown', 3, '12–15', 60, group: 'A'),
    ]),
    ProgramDay(id: 'd2', title: 'Pull A', exercises: [
      ProgramExercise('Pull-up', 4, '6–8', 120),
      ProgramExercise('Barbell Row', 4, '6–8', 120),
      ProgramExercise('Face Pull', 3, '15', 60),
      ProgramExercise('EZ Bar Curl', 3, '10', 60),
    ]),
    ProgramDay(id: 'd3', title: 'Legs A', exercises: [
      ProgramExercise('Back Squat', 4, '6–8', 150),
      ProgramExercise('Romanian Deadlift', 3, '8–10', 120),
      ProgramExercise('Leg Press', 3, '10–12', 90),
      ProgramExercise('Walking Lunge', 3, '10/leg', 90),
    ]),
    ProgramDay(id: 'd4', title: 'Rest', rest: true, note: 'Steps 8k · mobility'),
    ProgramDay(id: 'd5', title: 'Upper', exercises: [
      ProgramExercise('Incline Dumbbell Press', 4, '8–10', 90),
      ProgramExercise('Lat Pulldown', 3, '10–12', 90),
      ProgramExercise('Seated DB Shoulder Press', 3, '8–12', 90),
      ProgramExercise('Hammer Curl', 3, '12', 60),
    ]),
    ProgramDay(id: 'd6', title: 'Lower', exercises: [
      ProgramExercise('Hip Thrust', 4, '8–10', 120),
      ProgramExercise('Goblet Squat', 3, '10–12', 90),
      ProgramExercise('Leg Press', 3, '12', 90),
      ProgramExercise('Plank', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd7', title: 'Rest', rest: true, note: 'Check-in day'),
  ];

  static const _fullBodyDays = [
    ProgramDay(id: 'd1', title: 'Full Body A', exercises: [
      ProgramExercise('Goblet Squat', 3, '8–12', 90),
      ProgramExercise('Push-up', 3, '10–15', 60),
      ProgramExercise('Seated Cable Row', 3, '12–15', 60),
      ProgramExercise('Plank', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd2', title: 'Rest', rest: true, note: 'Steps 8k'),
    ProgramDay(id: 'd3', title: 'Full Body B', exercises: [
      ProgramExercise('Leg Press', 3, '10–12', 90),
      ProgramExercise('Lat Pulldown', 3, '10–12', 90),
      ProgramExercise('Seated DB Shoulder Press', 3, '8–12', 90),
      ProgramExercise('Dead Bug', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd4', title: 'Rest', rest: true, note: 'Steps 8k'),
    ProgramDay(id: 'd5', title: 'Full Body C', exercises: [
      ProgramExercise('Walking Lunge', 3, '10/leg', 90),
      ProgramExercise('Incline Dumbbell Press', 3, '8–12', 90),
      ProgramExercise('One-arm Dumbbell Row', 3, '10/side', 90),
      ProgramExercise('Incline Treadmill Walk', 1, '20 min', 0),
    ]),
    ProgramDay(id: 'd6', title: 'Rest', rest: true),
    ProgramDay(id: 'd7', title: 'Rest', rest: true, note: 'Check-in day'),
  ];

  static const _yogaDays = [
    ProgramDay(id: 'd1', title: 'Flow + Strength', exercises: [
      ProgramExercise('Goblet Squat', 3, '10–12', 60),
      ProgramExercise('Push-up', 3, '8–10', 60),
      ProgramExercise('Plank', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd2', title: 'Rest', rest: true, note: 'Yoga flow · 20 min'),
    ProgramDay(id: 'd3', title: 'Core + Hips', exercises: [
      ProgramExercise('Hip Thrust', 3, '12', 60),
      ProgramExercise('Pallof Press', 3, '12/side', 45),
      ProgramExercise('Dead Bug', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd4', title: 'Rest', rest: true),
    ProgramDay(id: 'd5', title: 'Rest', rest: true, note: 'Steps 8k · mobility'),
    ProgramDay(id: 'd6', title: 'Full Body', exercises: [
      ProgramExercise('Walking Lunge', 3, '10/leg', 60),
      ProgramExercise('Seated Cable Row', 3, '12', 60),
      ProgramExercise('Face Pull', 3, '15', 45),
    ]),
    ProgramDay(id: 'd7', title: 'Rest', rest: true, note: 'Check-in day'),
  ];

  static const _strengthDays = [
    ProgramDay(id: 'd1', title: 'Squat Day', exercises: [
      ProgramExercise('Back Squat', 5, '5', 180, rpe: 8),
      ProgramExercise('Romanian Deadlift', 3, '6–8', 120),
      ProgramExercise('Plank', 3, '45 s', 45),
    ]),
    ProgramDay(id: 'd2', title: 'Press Day', exercises: [
      ProgramExercise('Overhead Press', 5, '5', 150, rpe: 8),
      ProgramExercise('Pull-up', 4, '6–8', 120),
      ProgramExercise('Dips', 3, '8–10', 90),
    ]),
    ProgramDay(id: 'd3', title: 'Rest', rest: true, note: 'Steps 8k · mobility'),
    ProgramDay(id: 'd4', title: 'Hinge Day', exercises: [
      ProgramExercise('Hip Thrust', 4, '6–8', 120),
      ProgramExercise('Barbell Row', 4, '6–8', 120),
      ProgramExercise('Walking Lunge', 3, '8/leg', 90),
    ]),
    ProgramDay(id: 'd5', title: 'Bench Day', exercises: [
      ProgramExercise('Barbell Bench Press', 5, '5', 180, rpe: 8),
      ProgramExercise('One-arm Dumbbell Row', 3, '8/side', 90),
      ProgramExercise('EZ Bar Curl', 3, '10', 60),
    ]),
    ProgramDay(id: 'd6', title: 'Rest', rest: true),
    ProgramDay(id: 'd7', title: 'Rest', rest: true, note: 'Check-in day'),
  ];

  static const _shoulderDays = [
    ProgramDay(id: 'd1', title: 'Upper A', exercises: [
      ProgramExercise('Push-up', 3, '8–12', 60),
      ProgramExercise('Seated Cable Row', 3, '12', 60),
      ProgramExercise('Face Pull', 3, '15', 45),
    ]),
    ProgramDay(id: 'd2', title: 'Rest', rest: true),
    ProgramDay(id: 'd3', title: 'Upper B', exercises: [
      ProgramExercise('Lat Pulldown', 3, '10–12', 90),
      ProgramExercise('Cable Fly', 3, '12–15', 60),
      ProgramExercise('Pallof Press', 3, '12/side', 45),
    ]),
    ProgramDay(id: 'd4', title: 'Rest', rest: true),
    ProgramDay(id: 'd5', title: 'Upper C', exercises: [
      ProgramExercise('Cable Lateral Raise', 3, '12–15', 45),
      ProgramExercise('One-arm Dumbbell Row', 3, '10/side', 90),
      ProgramExercise('Hammer Curl', 3, '12', 60),
    ]),
    ProgramDay(id: 'd6', title: 'Rest', rest: true),
    ProgramDay(id: 'd7', title: 'Rest', rest: true, note: 'Check-in day'),
  ];

  static const programs = [
    Program(
      id: 'p1',
      name: 'Fat Loss Phase 1',
      goal: 'Fat loss · gym',
      weeks: 12,
      days: _fatLossDays,
      clients: ['Riya Sharma', 'Kabir Mehta', 'Ishita Bose', 'Dev Malhotra'],
      edited: '2 Oct',
      tone: 1,
    ),
    Program(
      id: 'p2',
      name: 'Hypertrophy · Push / Pull / Legs',
      shortName: 'Hypertrophy PPL',
      goal: 'Muscle gain · 5 days',
      weeks: 8,
      days: _pplDays,
      clients: ['Rohan Kapoor', 'Vikram Rao', 'Arjun Nair', 'Karan Bedi'],
      edited: '28 Sep',
      tone: 2,
    ),
    Program(
      id: 'p3',
      name: 'Beginner Full Body',
      goal: 'General fitness · 3 days',
      weeks: 4,
      days: _fullBodyDays,
      clients: ['Sana Khan'],
      edited: '24 Sep',
      tone: 3,
    ),
    Program(
      id: 'p4',
      name: 'Yoga Strength',
      goal: 'Mobility and strength · 3 days',
      weeks: 6,
      days: _yogaDays,
      clients: ['Aisha Sheikh', 'Pooja Nair'],
      edited: '21 Sep',
      tone: 4,
    ),
    Program(id: 'p5', name: 'Strength Base', goal: 'Strength · 4 days', weeks: 10, days: _strengthDays, clients: [], edited: '18 Sep', tone: 1),
    Program(
      id: 'p6',
      name: 'Shoulder-safe Upper Body',
      goal: 'Rehab friendly · 3 days',
      weeks: 6,
      days: _shoulderDays,
      clients: [],
      edited: '3 Aug',
      archived: true,
      tone: 3,
    ),
  ];
}
