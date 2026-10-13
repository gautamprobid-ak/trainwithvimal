import '../models/training.dart';

/// Riya's training, food-at-a-glance and progress data (Fat Loss Phase 1,
/// week 6 of 12). Today is Friday 9 Oct 2026.
abstract final class ClientTrainingMock {
  static final today = TDate.day(10, 9);

  /// Monday of this week (5 Oct).
  static final weekStart = TDate.day(10, 5);

  /// Index of today in [week] (Mon = 0).
  static const todayIndex = 4;

  static const programName = 'Fat Loss Phase 1';
  static const weekLabel = 'Week 6 of 12';
  static const coach = 'Aman';
  static const coachFull = 'Aman Verma';
  static const bodyweightKg = 71.2;

  // ------------------------------------------------------------ today's workout

  static const todayTitle = 'Cardio and core';

  static const todayExercises = <LogExercise>[
    LogExercise(
      name: 'Incline treadmill walk',
      block: 'Cardio',
      kind: LogKind.cardio,
      target: '35 min · incline 10% · 5 km/h',
      rest: 0,
      cols: ['Min', 'Km'],
      step: [1, 0.1],
      start: [
        [35, 2.9],
      ],
      prev: ['35 min · 2.8 km'],
      group: 'Cardio',
      equipment: 'Machine',
      level: 'Beginner',
      logs: 'Minutes + km',
      video: 'Incline walk · setup',
      videoLength: '0:38',
      cover: 'Frame at 0:06',
      tiles: [('1', 'set'), ('35 min', 'time'), ('—', 'rest')],
      extra: 'Incline 10% · speed 5 km/h · you can still talk',
      note: 'Zone 2, you should still be able to talk. If the knee hurts on the incline, drop it to 5%.',
      steps: [
        'Start the belt slow, then raise the incline to 10% before you speed up.',
        'Bring the speed up to 5 km/h in small steps.',
        'Walk tall and let go of the rails; swing the arms loose.',
        'Last 2 minutes flat at 4 km/h, then step off slowly.',
      ],
      cues: [
        'Hands off the rails, the legs do the work.',
        'Short, quick steps in the middle of the belt.',
        'Breathe through the nose; if you cannot, slow down a little.',
      ],
      primary: 'Glutes',
      primarySub: 'Push the body up the incline',
      also: [
        MuscleWork('Calves', 'Push off the toes', 'Strong'),
        MuscleWork('Hamstrings', 'Pull the leg back', 'Light'),
        MuscleWork('Quads', 'Straighten the knee', 'Light'),
      ],
    ),
    LogExercise(
      name: 'Kettlebell swing',
      block: 'Conditioning',
      kind: LogKind.weight,
      target: '3 × 15 · RPE 7 · rest 60 s',
      rest: 60,
      cols: ['kg / BW', 'Reps'],
      step: [4, 1],
      start: [
        [12, 15],
        [12, 15],
        [12, 15],
      ],
      prev: ['12 × 15', '12 × 15', '12 × 12'],
      pr: '16 kg',
      group: 'Glutes',
      equipment: 'Kettlebell',
      level: 'Intermediate',
      logs: 'kg × reps',
      video: 'Kettlebell swing · side view',
      videoLength: '0:44',
      cover: 'Frame at 0:10',
      tiles: [('3', 'sets'), ('15', 'reps'), ('60s', 'rest')],
      extra: 'RPE 7 / 10 · tempo not set · 12 kg',
      note: 'Hips drive the bell, not the arms. Stay on 12 kg until all 3 sets of 15 feel clean.',
      steps: [
        'Stand with the bell a foot in front of you, feet a little wider than the hips.',
        'Push the hips back, grab the handle and hike the bell between your legs.',
        'Stand up hard and squeeze the glutes; the bell floats to chest height.',
        'Let it fall and hinge back again as it comes down. After the last rep, park it in front of you.',
      ],
      cues: [
        'Hinge, do not squat: the hips go back, shins stay almost straight.',
        'The arms only hold on; the hips do the work.',
        'Finish tall with glutes and abs tight, do not lean back.',
      ],
      primary: 'Glutes',
      primarySub: 'Hips · drive the bell forward',
      also: [
        MuscleWork('Hamstrings', 'Load the hinge on the way down', 'Strong'),
        MuscleWork('Back', 'Keep the spine straight', 'Light'),
        MuscleWork('Core', 'Keep the body still at the top', 'Light'),
      ],
    ),
    LogExercise(
      name: 'Dead bug',
      block: 'Core',
      kind: LogKind.weight,
      bodyweight: true,
      target: '3 × 10 each side · rest 45 s',
      rest: 45,
      cols: ['kg / BW', 'Reps'],
      step: [2.5, 1],
      start: [
        [0, 10],
        [0, 10],
        [0, 10],
      ],
      prev: ['BW × 10', 'BW × 10', 'BW × 8'],
      group: 'Core',
      equipment: 'Bodyweight',
      level: 'Beginner',
      logs: 'Bodyweight × reps',
      video: 'Dead bug · top view',
      videoLength: '0:35',
      cover: 'Frame at 0:08',
      tiles: [('3', 'sets'), ('10', 'each side'), ('45s', 'rest')],
      extra: 'Tempo 2-0-1 · slow and controlled',
      note: 'Lower back flat on the mat the whole time. If it lifts, do not lower the leg so far.',
      steps: [
        'Lie on your back, arms straight up, knees bent at 90° over the hips.',
        'Pull the ribs down so the lower back touches the mat.',
        'Slowly lower one arm back and the other leg out, just above the floor.',
        'Bring them back and switch sides. That is 1 rep each side.',
      ],
      cues: [
        'Lower back stays on the mat; a hand should not fit under it.',
        'Breathe out as you lower.',
        '2 seconds down, 1 second back.',
      ],
      primary: 'Core',
      primarySub: 'Abs · keep the lower back on the floor',
      also: [
        MuscleWork('Shoulders', 'Hold the arms still', 'Light'),
        MuscleWork('Quads', 'Hold the leg out', 'Light'),
      ],
    ),
    LogExercise(
      name: 'Side plank',
      block: 'Core',
      kind: LogKind.time,
      target: '3 × 30 s each side · rest 45 s',
      rest: 45,
      cols: ['Seconds'],
      step: [5],
      start: [
        [30],
        [30],
        [30],
      ],
      prev: ['30 s', '25 s', '25 s'],
      pr: '40 s',
      group: 'Core',
      equipment: 'Bodyweight',
      level: 'Beginner',
      logs: 'Seconds',
      video: 'Side plank · front view',
      videoLength: '0:28',
      cover: 'Frame at 0:05',
      tiles: [('3', 'sets'), ('30 s', 'each side'), ('45s', 'rest')],
      extra: 'Knees down is fine if the hips drop',
      note: 'Last week sets 2 and 3 were 25 s. Knees down is fine, just hold the full 30 s.',
      steps: [
        'Lie on your side, elbow right under the shoulder, feet stacked.',
        'Push the floor away and lift the hips into one straight line.',
        'Hold with slow breaths, top hand on the hip.',
        'Lower slowly, turn over and hold the same time on the other side.',
      ],
      cues: [
        'Head, hips and feet stay in one line.',
        'Elbow under the shoulder, not in front.',
        'Keep breathing, do not hold your breath.',
      ],
      primary: 'Core',
      primarySub: 'Obliques · hold the hips up',
      also: [
        MuscleWork('Shoulders', 'Hold the body up on the elbow', 'Strong'),
        MuscleWork('Glutes', 'Keep the hips in line', 'Light'),
      ],
    ),
  ];

  static const todayBlocks = [
    WorkoutBlock('Cardio', '35 min, easy pace'),
    WorkoutBlock('Conditioning', '3 sets, rest 60 s'),
    WorkoutBlock('Core', '6 sets, rest 45 s'),
  ];

  // ------------------------------------------------------------ the week

  /// Mon … Sun of week 6. `null` = rest day. Friday is today's workout.
  static const week = <PlanDay?>[
    PlanDay(
      title: 'Upper A',
      kind: 'Strength',
      exercises: [
        PlanExercise('Bench press', '4 × 6–8 · 42.5 kg'),
        PlanExercise('Seated cable row', '3 × 10 · 35 kg'),
        PlanExercise('Incline DB press', '3 × 10 · 12 kg'),
        PlanExercise('Lat pulldown', '3 × 10–12 · 30 kg'),
        PlanExercise('Cable lateral raise', '3 × 15 · 5 kg'),
        PlanExercise('Rope pushdown', '3 × 12 · 20 kg'),
      ],
      doneLine: 'Done · 52 min · 6 of 6 exercises',
    ),
    PlanDay(
      title: 'Lower A',
      kind: 'Strength',
      exercises: [
        PlanExercise('Box squat', '4 × 8 · 30 kg'),
        PlanExercise('Romanian deadlift', '3 × 10 · 35 kg'),
        PlanExercise('Leg press', '3 × 12 · 80 kg'),
        PlanExercise('Walking lunge', '3 × 10 each leg'),
        PlanExercise('Calf raise', '3 × 15'),
      ],
      doneLine: 'Done · 48 min · 5 of 5 exercises',
    ),
    null,
    PlanDay(
      title: 'Upper B',
      kind: 'Strength',
      exercises: [
        PlanExercise('Overhead press', '4 × 8 · 17.5 kg'),
        PlanExercise('Chest-supported row', '3 × 10 · 14 kg'),
        PlanExercise('Push-up', '3 × 10'),
        PlanExercise('Face pull', '3 × 15 · 15 kg'),
        PlanExercise('DB curl', '3 × 12 · 7.5 kg'),
      ],
      doneLine: 'Done · 45 min · 5 of 5 exercises',
    ),
    PlanDay(
      title: todayTitle,
      kind: 'Cardio',
      exercises: [
        PlanExercise('Incline treadmill walk', '35 min · incline 10%'),
        PlanExercise('Kettlebell swing', '3 × 15 · 12 kg'),
        PlanExercise('Dead bug', '3 × 10 each side'),
        PlanExercise('Side plank', '3 × 30 s each side'),
      ],
    ),
    PlanDay(
      title: 'Lower B',
      kind: 'Strength',
      exercises: [
        PlanExercise('Box squat', '4 × 6 · 32.5 kg'),
        PlanExercise('Hip thrust', '3 × 10 · 50 kg'),
        PlanExercise('Leg curl', '3 × 12 · 25 kg'),
        PlanExercise('Step-up', '3 × 10 each leg'),
        PlanExercise('Plank', '3 × 40 s'),
      ],
    ),
    null,
  ];

  /// Short labels for the Train week strip.
  static const weekShort = ['Upper A', 'Lower A', 'Rest', 'Upper B', 'Cardio', 'Lower B', 'Rest'];

  // ------------------------------------------------------------ past workouts

  static final pastWorkouts = <PastWorkout>[
    PastWorkout(date: TDate.day(10, 8), name: 'Upper B', minutes: 45, effort: 7, note: 'Pull-ups felt better with the lighter band.', exercises: const [
      PastExercise('Overhead press', ['25 kg × 7', '25 kg × 7', '25 kg × 7', '25 kg × 7']),
      PastExercise('Band pull-up', ['Band × 6', 'Band × 6', 'Band × 5']),
      PastExercise('DB row', ['16 kg × 10', '16 kg × 10', '16 kg × 10']),
      PastExercise('Incline DB press', ['14 kg × 10', '14 kg × 10', '14 kg × 10']),
      PastExercise('Biceps curl', ['8 kg × 12', '8 kg × 12', '8 kg × 12']),
      PastExercise('Side plank', ['30 s each', '30 s each', '30 s each']),
    ]),
    PastWorkout(date: TDate.day(10, 6), name: 'Lower A', minutes: 48, effort: 8, note: 'Box squats were hard today.', exercises: const [
      PastExercise('Box squat', ['50 kg × 8', '50 kg × 8', '50 kg × 8', '50 kg × 8']),
      PastExercise('Romanian deadlift', ['50 kg × 8', '50 kg × 8', '50 kg × 8']),
      PastExercise('Walking lunge', ['8 kg × 10 each', '8 kg × 10 each', '8 kg × 10 each']),
      PastExercise('Leg curl', ['25 kg × 12', '25 kg × 12', '25 kg × 12']),
      PastExercise('Standing calf raise', ['40 kg × 15', '40 kg × 15', '40 kg × 15']),
      PastExercise('Dead bug', ['BW × 10', 'BW × 10', 'BW × 10']),
    ]),
    PastWorkout(date: TDate.day(10, 5), name: 'Upper A', minutes: 52, effort: 7, exercises: const [
      PastExercise('Bench press', ['45 kg × 6', '45 kg × 6', '45 kg × 6', '45 kg × 6'], pr: true),
      PastExercise('Seated cable row', ['35 kg × 10', '35 kg × 10', '35 kg × 10']),
      PastExercise('Lat pulldown', ['30 kg × 12', '30 kg × 12', '30 kg × 12']),
      PastExercise('DB shoulder press', ['10 kg × 10', '10 kg × 10', '10 kg × 10']),
      PastExercise('Cable face pull', ['15 kg × 15', '15 kg × 15', '15 kg × 15']),
      PastExercise('Plank', ['40 s', '40 s', '35 s']),
    ]),
    PastWorkout(date: TDate.day(10, 3), name: 'Lower B', minutes: 50, effort: 6, exercises: const [
      PastExercise('Hip thrust', ['57.5 kg × 10', '57.5 kg × 10', '57.5 kg × 10', '57.5 kg × 10']),
      PastExercise('Goblet squat', ['16 kg × 12', '16 kg × 12', '16 kg × 12']),
      PastExercise('Leg press', ['75 kg × 12', '75 kg × 12', '75 kg × 12']),
      PastExercise('Step-up', ['6 kg × 10 each', '6 kg × 10 each', '6 kg × 10 each']),
      PastExercise('Glute bridge', ['BW × 15', 'BW × 15', 'BW × 15']),
    ]),
    PastWorkout(date: TDate.day(10, 2), name: 'Cardio and core', minutes: 44, effort: 6, note: 'Knee was fine at 10% incline.', exercises: const [
      PastExercise('Incline treadmill walk', ['35 min · 2.8 km']),
      PastExercise('Kettlebell swing', ['12 kg × 15', '12 kg × 15', '12 kg × 12']),
      PastExercise('Dead bug', ['BW × 10', 'BW × 10', 'BW × 8']),
      PastExercise('Side plank', ['30 s', '25 s', '25 s']),
    ]),
    PastWorkout(date: TDate.day(9, 29), name: 'Lower A', minutes: 47, effort: 7, exercises: const [
      PastExercise('Box squat', ['47.5 kg × 8', '47.5 kg × 8', '47.5 kg × 8', '47.5 kg × 8']),
      PastExercise('Romanian deadlift', ['47.5 kg × 8', '47.5 kg × 8', '47.5 kg × 8']),
      PastExercise('Walking lunge', ['8 kg × 10 each', '8 kg × 10 each', '8 kg × 10 each']),
      PastExercise('Leg curl', ['25 kg × 12', '25 kg × 12', '25 kg × 12']),
      PastExercise('Standing calf raise', ['40 kg × 15', '40 kg × 15', '40 kg × 15']),
      PastExercise('Dead bug', ['BW × 10', 'BW × 10', 'BW × 10']),
    ]),
    PastWorkout(date: TDate.day(9, 28), name: 'Upper A', minutes: 50, effort: 6, exercises: const [
      PastExercise('Bench press', ['42.5 kg × 6', '42.5 kg × 6', '42.5 kg × 6', '42.5 kg × 6']),
      PastExercise('Seated cable row', ['32.5 kg × 10', '32.5 kg × 10', '32.5 kg × 10']),
      PastExercise('Lat pulldown', ['30 kg × 12', '30 kg × 12', '30 kg × 12']),
      PastExercise('DB shoulder press', ['10 kg × 10', '10 kg × 10', '10 kg × 10']),
      PastExercise('Cable face pull', ['15 kg × 15', '15 kg × 15', '15 kg × 15']),
      PastExercise('Plank', ['40 s', '40 s', '35 s']),
    ]),
    PastWorkout(date: TDate.day(9, 26), name: 'Lower B', minutes: 49, effort: 6, note: 'Short on sleep.', exercises: const [
      PastExercise('Hip thrust', ['55 kg × 10', '55 kg × 10', '55 kg × 10', '55 kg × 10']),
      PastExercise('Goblet squat', ['16 kg × 12', '16 kg × 12', '16 kg × 12']),
      PastExercise('Leg press', ['70 kg × 12', '70 kg × 12', '70 kg × 12']),
      PastExercise('Step-up', ['6 kg × 10 each', '6 kg × 10 each', '6 kg × 10 each']),
      PastExercise('Glute bridge', ['BW × 15', 'BW × 15', 'BW × 15']),
    ]),
    PastWorkout(date: TDate.day(9, 18), name: 'Cardio and core', minutes: 42, effort: 7, note: 'Dropped the incline to 8% for the last 10 min.', exercises: const [
      PastExercise('Incline treadmill walk', ['35 min · 2.7 km']),
      PastExercise('Kettlebell swing', ['12 kg × 12', '12 kg × 12', '12 kg × 12']),
      PastExercise('Dead bug', ['BW × 8', 'BW × 8', 'BW × 8']),
      PastExercise('Side plank', ['25 s', '25 s', '20 s']),
    ]),
  ];

  // ------------------------------------------------------------ home

  static const waterGoalMl = 3000;
  static const waterStartMl = 1500;

  /// Same as her meal plan (Food tab).
  static const meals = [
    PlanMeal('Breakfast', '8:00 am', 'Oats, whey protein, banana', 450, 32, 71, 6),
    PlanMeal('Snack', '11:00 am', 'Greek yogurt, almonds', 180, 18, 8, 9),
    PlanMeal('Lunch', '1:30 pm', 'Paneer, brown rice, cucumber salad', 429, 23, 38, 22),
    PlanMeal('Snack', '5:00 pm', 'Sprouts chaat', 180, 11, 28, 3),
    PlanMeal('Dinner', '8:30 pm', 'Tofu, 2 whole wheat roti', 436, 28, 44, 18),
  ];
  static const mealsEatenAtStart = [0, 1, 2];

  /// kcal, protein, carbs, fat targets.
  static const foodTargets = [1650, 120, 170, 52];

  static const stepsStart = 6240;
  static const stepsGoal = 8000;
  static const sleepStartMin = 440;
  static const sleepGoalMin = 420;

  static const supplements = [
    Supplement('whey', 'Whey protein', '1 scoop · morning'),
    Supplement('d3', 'Vitamin D3', '1 tablet · morning'),
    Supplement('mag', 'Magnesium', '1 tablet · night, before bed'),
  ];
  static const supplementsTakenAtStart = ['whey', 'd3'];

  static const coachNote =
      'Great job on Thursday, Riya. Your bench went up again. On Saturday use box squats, not deep squats, until the knee feels fine.';
  static const workoutNote = 'Keep the treadmill at a pace where you can still talk. If the knee hurts on the incline, drop it to 5%.';

  // ------------------------------------------------------------ progress

  static const startKg = 78.0;
  static const goalKg = 68.0;
  static final startDate = TDate.day(1, 12);

  static final weighIns = <WeighIn>[
    for (final (m, d, k) in const [
      (1, 12, 78.0), (2, 9, 77.1), (3, 9, 76.2), (4, 6, 75.0), (5, 4, 74.3), (6, 8, 73.6), (7, 10, 73.0), (8, 3, 73.9), (8, 17, 74.5), (8, 31, 74.6), //
      (9, 6, 74.1), (9, 10, 73.9), (9, 13, 73.6), (9, 16, 73.3), (9, 20, 72.8), (9, 23, 72.6), (9, 27, 72.3), (9, 28, 72.0), (10, 1, 71.9), (10, 4, 71.6),
      (10, 6, 71.5), (10, 9, 71.2),
    ])
      WeighIn(TDate.day(m, d), k),
  ];

  /// Measured every 2 weeks with the photo check-in.
  static final measurementDates = [TDate.day(1, 12), TDate.day(9, 6), TDate.day(9, 20), TDate.day(10, 4)];
  static const measurements = [
    Measurement('Waist', 'cm', [88, 82, 80, 78]),
    Measurement('Hips', 'cm', [104, 100, 99, 98]),
    Measurement('Chest', 'cm', [95, 92, 91, 90]),
    Measurement('Arm', 'cm', [30, 29, 28, 28]),
    Measurement('Body fat', '%', [32, 29, 28, 27]),
  ];

  static List<(DateTime, double)> _pts(List<(int, int, double)> l) => [for (final (m, d, v) in l) (TDate.day(m, d), v)];

  static final lifts = <LiftProgress>[
    LiftProgress('Bench press', _pts(const [(1, 19, 30), (3, 2, 32.5), (5, 4, 35), (7, 6, 37.5), (8, 31, 40), (9, 14, 42.5), (10, 5, 45)]), '45 kg × 6',
        'Two warm-up sets first. Next step is 47.5 kg once all sets hit 8 reps.'),
    LiftProgress('Hip thrust', _pts(const [(1, 24, 40), (3, 7, 45), (5, 9, 50), (7, 11, 52.5), (9, 5, 55), (10, 3, 60)]), '60 kg × 10',
        'Squeeze the glutes at the top of every rep.'),
    LiftProgress('Romanian deadlift', _pts(const [(1, 20, 30), (3, 3, 35), (5, 5, 40), (7, 7, 42.5), (9, 1, 47.5), (10, 6, 50)]), '50 kg × 8',
        'Slow on the way down, 3 seconds.'),
    LiftProgress('Box squat', _pts(const [(8, 25, 40), (9, 8, 45), (9, 22, 47.5), (10, 6, 50)]), '50 kg × 8',
        'Swapped in for back squat while the knee settles. Keep the box low.'),
  ];

  static final adherence = <AdherenceWeek>[
    AdherenceWeek(TDate.day(8, 31), 5, 5, 92),
    AdherenceWeek(TDate.day(9, 7), 5, 5, 90),
    AdherenceWeek(TDate.day(9, 14), 4, 5, 82),
    AdherenceWeek(TDate.day(9, 21), 4, 5, 85),
    AdherenceWeek(TDate.day(9, 28), 4, 5, 80),
    AdherenceWeek(TDate.day(10, 5), 3, 5, 86),
  ];

  static final photoSets = <PhotoSet>[
    PhotoSet(date: TDate.day(1, 12), kg: 78.0, label: 'Start photos', poses: const ['Front', 'Side', 'Back'], tint: PhotoTint.t1),
    PhotoSet(date: TDate.day(9, 6), kg: 74.1, label: 'Week 2 check-in', poses: const ['Front', 'Side'], tint: PhotoTint.t3),
    PhotoSet(date: TDate.day(9, 20), kg: 72.8, label: 'Week 4 check-in', poses: const ['Front', 'Side', 'Back'], tint: PhotoTint.t2),
    PhotoSet(date: TDate.day(9, 27), kg: 72.3, label: 'Week 5 check-in', poses: const ['Front', 'Side', 'Back'], tint: PhotoTint.t4),
    PhotoSet(date: TDate.day(10, 4), kg: 71.6, label: 'Week 6 check-in', poses: const ['Front', 'Side', 'Back'], tint: PhotoTint.t2),
  ];

  static const poses = ['Front', 'Side', 'Back'];

  /// Planned workout per weekday (DateTime.weekday: 1 = Mon) for the history.
  static const historyPlan = <int, HistoryWorkout>{
    1: HistoryWorkout('Upper A', '52 min · 6 of 6 exercises', [('Bench press', '4 × 6 · 45 kg'), ('Seated cable row', '3 × 10 · 35 kg'), ('Lat pulldown', '3 × 12 · 30 kg')]),
    2: HistoryWorkout('Lower A', '48 min · 6 of 6 exercises', [('Box squat', '4 × 8 · 50 kg'), ('Romanian deadlift', '3 × 8 · 50 kg'), ('Walking lunge', '3 × 10 each · 8 kg')]),
    4: HistoryWorkout('Upper B', '45 min · 6 of 6 exercises', [('Overhead press', '4 × 7 · 25 kg'), ('Band pull-up', '3 × 6'), ('DB row', '3 × 10 · 16 kg')]),
    5: HistoryWorkout('Cardio and core', '44 min · 4 of 4 exercises',
        [('Incline treadmill walk', '35 min · 10% · 5 km/h'), ('Kettlebell swing', '3 × 15 · 12 kg'), ('Side plank', '3 × 30 s each')]),
    6: HistoryWorkout('Lower B', '50 min · 5 of 5 exercises', [('Hip thrust', '4 × 10 · 60 kg'), ('Goblet squat', '3 × 12 · 16 kg'), ('Leg press', '3 × 12 · 80 kg')]),
  };

  static final missedWorkouts = <DateTime, String>{
    TDate.day(9, 17): 'Work ran late',
    TDate.day(9, 25): 'Travelling',
    TDate.day(10, 1): 'Felt unwell',
    TDate.day(8, 13): 'Family function',
    TDate.day(7, 23): 'Work ran late',
  };

  static const historyMeals = [
    ('Breakfast', '8:00 am', 'Oats, Whey protein, Banana'),
    ('Snack', '11:00 am', 'Greek yogurt, Almonds'),
    ('Lunch', '1:30 pm', 'Paneer, Brown rice (cooked), Cucumber salad'),
    ('Snack', '5:00 pm', 'Sprouts chaat'),
    ('Dinner', '8:30 pm', 'Tofu (firm), Whole wheat roti'),
  ];

  static const coachReplies = [
    'Great week, Riya. Keep calories the same and aim for 8k steps.',
    'Nice work on the bench. Box squats again on Saturday.',
    'Sleep was short this week. Try lights out by 11 pm.',
    'Waist is down again. Keep the protein up at lunch.',
    'Good recovery week. We go a bit heavier from Monday.',
  ];

  /// Program week 0 starts on 23 Aug (week numbers of the Sunday check-ins).
  static final checkinWeekZero = TDate.day(8, 23);
}

/// Home feed data (notifications and "Coming up"). Links are client routes.
abstract final class ClientHomeMock {
  static const notifications = [
    HomeNotification(FeedIcon.form, 'amber', 'Aman replied to your check-in', 'Week 5: “Great progress on the waist. Keep the steps up.”', '2 h', '/c/more/checkins'),
    HomeNotification(FeedIcon.dumbbell, 'blue', 'New personal best', 'Bench press 45 kg × 6', 'Mon', '/c/progress'),
    HomeNotification(FeedIcon.bell, 'green', 'Plan updated', 'Aman changed Lower B for your knee', 'Tue', '/c/train'),
    HomeNotification(FeedIcon.bell, 'gray', 'Water reminder', 'You are 1.5 L behind for the day', 'Wed', null),
  ];

  static const upcoming = [
    UpcomingItem(FeedIcon.calendar, 'blue', 'Session with Aman', 'Today, 6:30 pm · Gym floor · 60 min',
        toast: 'Session with Aman', toastSub: 'Today 6:30 pm at the gym floor. Aman can move it if you need.'),
    UpcomingItem(FeedIcon.form, 'amber', 'Weekly check-in', 'Sun, 11 Oct · 6 questions and 3 photos', link: '/c/more/checkins'),
    UpcomingItem(FeedIcon.flag, 'gray', 'Fat Loss Phase 1 ends', 'Mon, 23 Nov · Aman will set your next plan',
        toast: 'Your plan ends on 23 Nov', toastSub: 'Aman is already planning the next phase'),
  ];
}
