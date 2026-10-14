import '../../core/widgets/badges.dart';
import '../models/client_profile.dart';

/// Client profile data from the design (ClientProfileMobile / TrainerClientProfileMobile).
/// The design shows Riya Sharma; the same detail is used for every client (header info changes).
abstract final class ClientProfileMock {
  static const tabs = <(String, String, int?)>[
    ('overview', 'Overview', null),
    ('plans', 'Plans', 4),
    ('logs', 'Logs', null),
    ('progress', 'Progress', null),
    ('history', 'History', null),
    ('content', 'Content', 8),
    ('forms', 'Forms', 4),
    ('activity', 'Activity', null),
    ('notes', 'Notes', 4),
  ];

  // ───────────── Header stats ─────────────
  static const stats = <(String, String, String, bool?)>[
    ('Adherence', '86%', '+4% vs last month', true),
    ('Weight', '71.2 kg', '−3.6 kg since start', true),
    ('Workouts', '14 of 16', 'Done in last 30 days', null),
    ('Check-ins', '6 of 7', 'Week 6 waiting for review', null),
  ];

  // ───────────── Overview ─────────────
  static const about = <Kv>[
    ('Age', '29'),
    ('Gender', 'Female'),
    ('Height', '162 cm'),
    ('Start weight', '78.0 kg'),
    ('Now', '71.2 kg'),
    ('Goal weight', '68 kg'),
    ('Diet', 'Vegetarian'),
    ('Trains at', 'Gym · 4 days a week'),
    ('Experience', '6 months – 2 years'),
    ('Daily activity', 'Mostly sitting'),
    ('Wake-up', '6:30 am'),
    ('Injuries', 'Knee pain'),
  ];

  static const weekDays = ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  static const week = <WeekRow>[
    WeekRow('Workout', [DayMark.done, DayMark.rest, DayMark.done, DayMark.miss, DayMark.done, DayMark.rest, DayMark.done]),
    WeekRow('Meals', [DayMark.done, DayMark.part, DayMark.part, DayMark.done, DayMark.done, DayMark.miss, DayMark.done]),
    WeekRow('Check-in', [DayMark.done, DayMark.done, DayMark.done, DayMark.done, DayMark.miss, DayMark.done, DayMark.done]),
    WeekRow('Habits', [DayMark.done, DayMark.done, DayMark.part, DayMark.done, DayMark.done, DayMark.part, DayMark.done]),
  ];

  static const attention = <AttentionItem>[
    AttentionItem('Knee pain on deep squats', 'Flag · use box squats until cleared', BadgeTone.warn),
    AttentionItem('Week 6 check-in to review', 'Sent Sun, 4 Oct · 3 photos', BadgeTone.info, target: 'checkin'),
    AttentionItem('Missed Upper B on Monday', 'First miss in 3 weeks', BadgeTone.bad, target: 'log'),
  ];

  static const coaching = <Kv>[
    ('Program', 'Fat Loss Phase 1 · week 6 of 12'),
    ('Meal plan', '1,650 kcal · high protein'),
    ('Goal', 'Fat loss · 68 kg by Feb 2027'),
    ('Joined', '12 Jan 2026'),
    ('Onboarding', 'Done 12 Jan'),
  ];

  /// Current plans card: (plan tab id, title, sub).
  static const currentPlans = <(String, String, String)>[
    ('workout', 'Fat Loss Phase 1', 'Workout · week 6 of 12 · edited for Riya'),
    ('meal', '1,650 kcal · high protein', 'Meal plan · 5 meals · veg'),
    ('supp', '2 supplements', 'Whey protein, Vitamin D3'),
    ('habit', '3 habits', '8k steps, 3 L water, sleep 7 h'),
  ];

  static const schedule = <ScheduleItem>[
    ScheduleItem('Daily check-in', 'Every morning, 8:00 am', '6 of 7 this week', BadgeTone.ok),
    ScheduleItem('Weekly check-in', 'Every Sunday · next Sun, 11 Oct', 'Week 6 to review', BadgeTone.info),
    ScheduleItem('Measurements', 'Every 2 weeks · next Sat, 17 Oct', 'On time', BadgeTone.ok),
    ScheduleItem('Progress photos', 'Every month · next 1 Nov', 'Last 4 Oct', BadgeTone.neutral),
  ];

  /// 30 days of weigh-ins, 10 Sep → 9 Oct.
  static const weight = <WeightPoint>[
    WeightPoint(0, 74.8),
    WeightPoint(3, 74.6),
    WeightPoint(5, 74.3),
    WeightPoint(8, 74.0),
    WeightPoint(10, 73.4),
    WeightPoint(13, 73.2),
    WeightPoint(15, 72.8),
    WeightPoint(17, 72.9),
    WeightPoint(20, 72.3),
    WeightPoint(22, 72.1),
    WeightPoint(24, 71.6),
    WeightPoint(27, 71.5),
    WeightPoint(29, 71.2),
  ];

  // ───────────── Plans · workout ─────────────
  static const planTabs = <(String, String)>[('workout', 'Workout'), ('meal', 'Meal plan'), ('supp', 'Supplements'), ('habit', 'Habits')];

  static const fullDay = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
  };
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const workoutDays = <WorkoutDay>[
    WorkoutDay('Mon', 'Upper A', 'Strength', false, note: 'Warm up with 2 light sets on the bench.', [
      WorkoutExercise('Bench press', '4', '6–8', '2 min', '42.5 kg', rpe: 8, note: 'Two warm-up sets first.'),
      WorkoutExercise('Seated cable row', '3', '10', '90 s', '35 kg'),
      WorkoutExercise('Incline DB press', '3', '10', '90 s', '12 kg', tempo: '3-1-1'),
      WorkoutExercise('Lat pulldown', '3', '10–12', '90 s', '30 kg'),
      WorkoutExercise('Cable lateral raise', '3', '15', '60 s', '5 kg', superset: 'A'),
      WorkoutExercise('Rope pushdown', '3', '12', '60 s', '20 kg', superset: 'A'),
    ]),
    WorkoutDay('Tue', 'Lower A', 'Strength', true, note: 'Brace before every squat rep. Go light on lunges if the knee feels it.', [
      WorkoutExercise('Box squat', '4', '8', '2 min', '50 kg',
          was: 'Was: Back squat (knee pain)', rpe: 7, tempo: '3-1-1', note: 'Keep the box low and go slow. Stop if the knee hurts.'),
      WorkoutExercise('Romanian deadlift', '3', '8–10', '2 min', '50 kg', rpe: 8, tempo: '3-1-1'),
      WorkoutExercise('Walking lunge', '3', '10 each', '90 s', '8 kg', superset: 'A', note: 'Short steps, knee over the toes.'),
      WorkoutExercise('Leg curl', '3', '12', '60 s', '25 kg',
          superset: 'A', youtube: true, programEdit: ProgramEdit('Leg curl', 'Single-leg leg curl')),
      WorkoutExercise('Calf raise', '3', '15', '60 s', '40 kg'),
      WorkoutExercise('Plank', '3', '40 s', '45 s', 'Body', note: 'Squeeze the glutes, breathe normally.'),
    ]),
    WorkoutDay('Wed', 'Rest', 'Rest', false, []),
    WorkoutDay('Thu', 'Upper B', 'Strength', false, note: 'Rest a full 2 minutes between pull-up sets.', [
      WorkoutExercise('Overhead press', '4', '6–8', '2 min', '25 kg', rpe: 8),
      WorkoutExercise('Band pull-up', '3', '6–8', '2 min', 'Band', note: 'Use a lighter band once you get 8.'),
      WorkoutExercise('DB row', '3', '10', '90 s', '16 kg'),
      WorkoutExercise('Push-up', '3', 'Max', '60 s', 'Body', superset: 'A'),
      WorkoutExercise('Hammer curl', '3', '12', '60 s', '8 kg', superset: 'A'),
      WorkoutExercise('Pallof press', '3', '12 each', '45 s', '10 kg'),
    ]),
    WorkoutDay('Fri', 'Cardio and core', 'Cardio', false, note: 'Steady pace, no hand rails.', [
      WorkoutExercise('Incline treadmill walk', '1', '35 min', '—', '10% · 5 km/h', note: 'Zone 2, you should still be able to talk.'),
      WorkoutExercise('Kettlebell swing', '3', '15', '60 s', '12 kg'),
      WorkoutExercise('Dead bug', '3', '10 each', '45 s', 'Body'),
      WorkoutExercise('Side plank', '3', '30 s each', '45 s', 'Body'),
    ]),
    WorkoutDay('Sat', 'Lower B', 'Strength', true, note: 'Squeeze the glutes at the top of every rep.', [
      WorkoutExercise('Hip thrust', '4', '10', '2 min', '60 kg', was: 'Moved from Monday', rpe: 8, tempo: '2-2-1'),
      WorkoutExercise('Goblet squat', '3', '12', '90 s', '16 kg'),
      WorkoutExercise('Step-up', '3', '10 each', '90 s', '8 kg', programEdit: ProgramEdit('Step-up', 'Low step-up')),
      WorkoutExercise('Leg press', '3', '12', '90 s', '80 kg'),
      WorkoutExercise('Dead bug', '3', '10 each', '45 s', 'Body'),
    ]),
    WorkoutDay('Sun', 'Rest', 'Rest', false, []),
  ];

  static const guides = <String, ExerciseGuide>{
    'Box squat': ExerciseGuide(
      steps: [
        'Stand in front of a box at knee height, feet shoulder width apart.',
        'Sit back onto the box with your chest up, pause for one second.',
        'Drive through your heels to stand up, squeeze your glutes at the top.',
      ],
      cues: ['Chest up, sit back onto the box.', 'Knees follow the toes.', 'Push the floor away to stand.'],
      primary: 'Quads',
      also: ['Glutes', 'Core'],
    ),
    'Bench press': ExerciseGuide(
      steps: [
        'Lie flat, eyes under the bar, feet planted.',
        'Lower the bar to your mid chest with elbows at about 45°.',
        'Press up and slightly back until your arms are straight.',
      ],
      cues: ['Brace the core before each rep.', 'Control the way down.'],
      primary: 'Chest',
      also: ['Triceps', 'Front delts'],
    ),
    'Romanian deadlift': ExerciseGuide(steps: _defaultSteps, cues: _defaultCues, primary: 'Hamstrings', also: ['Glutes', 'Lower back']),
    'Walking lunge': ExerciseGuide(steps: _defaultSteps, cues: _defaultCues, primary: 'Quads', also: ['Glutes', 'Adductors']),
    'Leg curl': ExerciseGuide(
      steps: _defaultSteps,
      cues: ['Hips stay down on the pad.', 'Slow on the way back, 3 seconds.'],
      primary: 'Hamstrings',
      also: ['Calves'],
    ),
    'Calf raise': ExerciseGuide(steps: _defaultSteps, cues: _defaultCues, primary: 'Calves', also: []),
    'Plank': ExerciseGuide(steps: _defaultSteps, cues: _defaultCues, primary: 'Core', also: ['Shoulders']),
  };
  static const _defaultSteps = [
    'Set up with a neutral spine and your core braced.',
    'Move slowly through the full range you can control.',
    'Breathe out on the hard part, pause, then return.',
  ];
  static const _defaultCues = ['Brace the core before each rep.', 'Control the way down.'];
  static const defaultGuide = ExerciseGuide(steps: _defaultSteps, cues: _defaultCues, primary: 'Main muscle', also: ['Helpers']);

  static const workoutHistory = <PlanHistoryItem>[
    PlanHistoryItem('Fat Loss Phase 1', '1 Sep – 24 Nov', 'Current', BadgeTone.ok),
    PlanHistoryItem('Beginner Full Body', '12 Jan – 31 Aug', 'Completed', BadgeTone.neutral),
    PlanHistoryItem('Home Starter', '12 Jan – 2 Feb', 'Replaced', BadgeTone.warn),
  ];

  // ───────────── Plans · meals (read-only week view) ─────────────
  static const _baseMeals = <DayMeal>[
    DayMeal('Breakfast', '8:00 am', [
      MealFood('Oats', '60 g', 225, 8, 41, 5, 'Poha 1 plate · 150 g'),
      MealFood('Whey protein', '1 scoop · 32 g', 120, 24, 3, 2, 'Greek yogurt 1.5 × 150 g'),
      MealFood('Banana', '1 medium · 118 g', 105, 1, 27, 0, 'Apple 1 medium'),
    ]),
    DayMeal('Snack', '11:00 am', [
      MealFood('Greek yogurt', '150 g', 110, 15, 6, 3, 'Curd 2 × 1 katori'),
      MealFood('Almonds', '10 × 1 piece · 12 g', 70, 3, 2, 6, 'Peanut butter 1 tbsp'),
    ]),
    DayMeal('Lunch', '1:30 pm', [
      MealFood('Paneer', '100 g', 265, 18, 3, 21, 'Tofu (firm) 180 g · Low-fat paneer 130 g'),
      MealFood('Brown rice (cooked)', '120 g', 134, 4, 29, 1, 'Whole wheat roti 1 medium'),
      MealFood('Cucumber salad', '1 bowl · 100 g', 30, 1, 6, 0),
    ]),
    DayMeal('Snack', '5:00 pm', [
      MealFood('Sprouts chaat', '1 plate · 150 g', 180, 11, 28, 3, 'Roasted chana 1.5 × 30 g'),
    ]),
    DayMeal('Dinner', '8:30 pm', [
      MealFood('Tofu (firm)', '150 g', 216, 23, 5, 14, 'Paneer 80 g'),
      MealFood('Whole wheat roti', '2 × 1 medium · 80 g', 220, 6, 40, 4, 'Brown rice (cooked) 200 g'),
    ]),
  ];

  static List<DayMeal> mealsFor(String day) {
    final m = [..._baseMeals];
    if (day == 'Wed') {
      m[2] = const DayMeal('Lunch', '1:30 pm', changed: true, [
        MealFood('Rajma', '1 katori · 150 g', 210, 13, 35, 2, 'Chana masala 1 katori'),
        MealFood('Brown rice (cooked)', '120 g', 134, 4, 29, 1, 'Whole wheat roti 1 medium'),
        MealFood('Cucumber salad', '1 bowl · 100 g', 30, 1, 6, 0),
      ]);
    }
    if (day == 'Sat') {
      m.insert(
        3,
        const DayMeal('After workout', '12:30 pm', changed: true, [
          MealFood('Whey protein', '1 scoop · 32 g', 120, 24, 3, 2),
          MealFood('Banana', '1 medium · 118 g', 105, 1, 27, 0),
        ]),
      );
    }
    if (day == 'Sun') {
      m[4] = const DayMeal('Dinner', '8:30 pm', [
        MealFood('Eating out', 'about 400 kcal', 400, 20, 40, 15, 'Any dish from the guide "Eating out on a fat loss plan"'),
      ]);
    }
    return m;
  }

  static const mealHow = {
    'Breakfast': 'Cook the oats in water or milk for 4 minutes. Stir in the whey when it cools a little, top with sliced banana.',
    'Lunch': 'Grill or pan-fry the paneer cubes with a pinch of salt and spices. Serve on the rice with the salad.',
    'Snack': 'Ready to eat. Keep it within the amount shown.',
    'Dinner': 'Stir fry the tofu with vegetables in 1 tsp oil. Have it with 2 rotis.',
    'After workout': 'Shake the whey in 300 ml water, eat the banana within 30 minutes of training.',
  };

  static const macros = <Kv>[('1,650', 'kcal a day'), ('120 g', 'Protein'), ('170 g', 'Carbs'), ('52 g', 'Fat')];

  static const mealHistory = <PlanHistoryItem>[
    PlanHistoryItem('1,650 kcal · high protein', '1 Sep – now', 'Current', BadgeTone.ok),
    PlanHistoryItem('1,800 kcal · balanced veg', '12 Jan – 31 Aug', 'Completed', BadgeTone.neutral),
  ];

  // ───────────── Plans · supplements / habits ─────────────
  static const supplements = <SupplementItem>[
    SupplementItem('Whey protein', 'Morning · 1 scoop (30 g) in water · with breakfast', '12 scoops left',
        dose: '1 scoop (30 g)', when: 'Morning', how: 'In water, with breakfast', stock: '12 scoops'),
    SupplementItem('Vitamin D3', 'Morning · 1 tablet · with breakfast', '20 tablets left',
        dose: '1 tablet', when: 'Morning', how: 'With breakfast', stock: '20 tablets'),
    SupplementItem('Magnesium', 'Night · 1 tablet · 30 min before bed', 'Added for Riya',
        dose: '1 tablet', when: 'Night', how: '30 min before bed', stock: '30 tablets', changed: true),
  ];

  static const habits = <HabitItem>[
    HabitItem('Walk 8,000 steps', 'Every day', '5 of 7 this week', habit: 'Walk', target: '8,000 steps', often: 'Every day', starts: '12 Jan'),
    HabitItem('Drink 3 L water', 'Every day', '6 of 7 this week', habit: 'Drink water', target: '3 L', often: 'Every day', starts: '12 Jan'),
    HabitItem('Sleep 7 hours', 'Every night', '4 of 7 this week', habit: 'Sleep', target: '7 hours', often: 'Every night', starts: '12 Jan'),
    HabitItem('No sugar after 7 pm', 'Every day', 'Starts Mon, 12 Oct',
        habit: 'No sugar after 7 pm', target: 'Yes / no', often: 'Every day', starts: 'Mon, 12 Oct', changed: true),
  ];

  // ───────────── Assign plan ─────────────
  static const assignKinds = <String, AssignKind>{
    'workout': AssignKind(
      id: 'workout',
      title: 'Assign a workout plan',
      sub: 'Programs from the library',
      search: 'Search workout plans',
      currentName: 'Fat Loss Phase 1',
      currentEnd: 'Mon, 23 Nov',
      length: '12 weeks · ends 10 Jan',
      rowsTitle: 'Each week',
      filters: [
        ('Level', ['Any', 'Beginner', 'Intermediate', 'Advanced']),
        ('Days a week', ['Any', '3', '4', '5']),
      ],
      options: [
        AssignOption(
          id: 'fl2',
          name: 'Fat Loss Phase 2',
          sub: '12 weeks · 4 days a week · Intermediate',
          note: 'Next step after Phase 1. Heavier lower days.',
          used: 18,
          tip: 'Suggested',
          kpis: [('Days', '4 a week'), ('Length', '12 weeks'), ('Time', '50–60 min'), ('Kit', 'Full gym')],
          meta: '4 days a week · 12 weeks · 50–60 min · full gym',
          by: 'By Vimal · 18 clients on it · updated 2 Sep',
          rows: [
            PreviewRow('Mon', 'Upper A', '6 exercises'),
            PreviewRow('Tue', 'Lower A · heavy', '6 exercises'),
            PreviewRow('Wed', 'Rest', 'Walk 8k', rest: true),
            PreviewRow('Thu', 'Upper B', '6 exercises'),
            PreviewRow('Fri', 'Intervals', '30 min'),
            PreviewRow('Sat', 'Lower B', '5 exercises'),
            PreviewRow('Sun', 'Rest', '', rest: true),
          ],
          diff: [
            'Tuesday gets heavier: Lower A becomes Lower A · heavy',
            'Friday is intervals, not steady cardio',
            'Still 4 days a week, so her routine stays the same',
          ],
        ),
        AssignOption(
          id: 'kf',
          name: 'Knee-friendly Strength',
          sub: '8 weeks · 4 days a week · Beginner',
          note: 'No deep squats, lunges or jumps.',
          used: 9,
          tip: 'Fits her knee',
          kpis: [('Days', '4 a week'), ('Length', '8 weeks'), ('Time', '45 min'), ('Kit', 'Gym')],
          meta: '4 days a week · 8 weeks · 45 min · gym',
          by: 'By Neha Joshi · 9 clients on it · updated 20 Aug',
          rows: [
            PreviewRow('Mon', 'Upper', '6 exercises'),
            PreviewRow('Tue', 'Lower · knee-safe', '5 exercises'),
            PreviewRow('Wed', 'Rest', '', rest: true),
            PreviewRow('Thu', 'Upper', '6 exercises'),
            PreviewRow('Fri', 'Rest', '', rest: true),
            PreviewRow('Sat', 'Lower · glutes', '5 exercises'),
            PreviewRow('Sun', 'Rest', '', rest: true),
          ],
          diff: ['No deep squats, lunges or jumps, good for her right knee', 'Shorter sessions: 45 min instead of 50'],
        ),
        AssignOption(
          id: 'fl1',
          name: 'Fat Loss Phase 1',
          sub: '12 weeks · 4 days a week · Beginner',
          note: 'Riya is on week 6 of this plan.',
          used: 31,
          current: true,
          kpis: [('Days', '4 a week'), ('Length', '12 weeks'), ('Time', '50 min'), ('Kit', 'Full gym')],
          meta: '4 days a week · 12 weeks · 50 min · full gym',
          by: 'Riya is on week 6 of this plan',
          rows: [
            PreviewRow('Mon', 'Upper A', '6 exercises'),
            PreviewRow('Tue', 'Lower A', '6 exercises'),
            PreviewRow('Wed', 'Rest', '', rest: true),
            PreviewRow('Thu', 'Upper B', '6 exercises'),
            PreviewRow('Fri', 'Cardio', '35 min'),
            PreviewRow('Sat', 'Lower B', '5 exercises'),
            PreviewRow('Sun', 'Rest', '', rest: true),
          ],
        ),
        AssignOption(
          id: 'hiit',
          name: 'Home HIIT 30',
          sub: '6 weeks · 5 days a week · Any level',
          note: 'No equipment. For travel weeks.',
          used: 27,
          kpis: [('Days', '5 a week'), ('Length', '6 weeks'), ('Time', '30 min'), ('Kit', 'None')],
          meta: '5 days a week · 6 weeks · 30 min · no equipment',
          by: 'By Vimal · 27 clients on it · updated 1 Jul',
          rows: [
            PreviewRow('Mon', 'Full body', '8 moves'),
            PreviewRow('Tue', 'Core', '6 moves'),
            PreviewRow('Wed', 'Full body', '8 moves'),
            PreviewRow('Thu', 'Rest', '', rest: true),
            PreviewRow('Fri', 'Legs', '7 moves'),
            PreviewRow('Sat', 'Full body', '8 moves'),
            PreviewRow('Sun', 'Rest', '', rest: true),
          ],
          diff: ['No gym needed, all at home', '5 shorter days instead of 4'],
        ),
      ],
    ),
    'meal': AssignKind(
      id: 'meal',
      title: 'Assign a meal plan',
      sub: 'Meal plans from the library',
      search: 'Search meal plans',
      currentName: '1,650 kcal · high protein',
      currentEnd: '',
      length: 'Ongoing',
      rowsTitle: 'Each day',
      filters: [
        ('Diet', ['Any', 'Veg', 'Non-veg', 'Vegan']),
        ('Calories', ['Any', 'Under 1,600', '1,600–1,900', 'Over 1,900']),
      ],
      options: [
        AssignOption(
          id: 'm15',
          name: '1,500 kcal · high protein',
          sub: 'Veg · 4 meals a day',
          note: 'A small step down for the last weeks.',
          used: 22,
          tip: 'Suggested',
          kpis: [('Calories', '1,500 kcal'), ('Protein', '115 g'), ('Meals', '4 a day'), ('Diet', 'Veg')],
          meta: '1,500 kcal · P 115 g · veg · 4 meals',
          by: 'By Sahil Kapoor · 22 clients on it',
          rows: [
            PreviewRow('8:00 am', 'Breakfast', '400 kcal'),
            PreviewRow('1:00 pm', 'Lunch', '450 kcal'),
            PreviewRow('5:00 pm', 'Snack', '200 kcal'),
            PreviewRow('8:30 pm', 'Dinner', '450 kcal'),
          ],
          diff: ['150 kcal less a day', 'One more meal: a 5 pm snack'],
        ),
        AssignOption(
          id: 'm165',
          name: '1,650 kcal · high protein',
          sub: 'Veg · 3 meals a day',
          note: 'Riya is on this plan since 1 Sep.',
          used: 35,
          current: true,
          kpis: [('Calories', '1,650 kcal'), ('Protein', '120 g'), ('Meals', '3 a day'), ('Diet', 'Veg')],
          meta: '1,650 kcal · P 120 g · veg · 3 meals',
          by: 'Riya is on this since 1 Sep',
          rows: [
            PreviewRow('8:00 am', 'Breakfast', '420 kcal'),
            PreviewRow('1:30 pm', 'Lunch', '480 kcal'),
            PreviewRow('8:30 pm', 'Dinner', '360 kcal'),
          ],
        ),
        AssignOption(
          id: 'm18',
          name: '1,800 kcal · maintain',
          sub: 'Veg · 4 meals a day',
          note: 'For after she reaches her goal.',
          used: 14,
          kpis: [('Calories', '1,800 kcal'), ('Protein', '110 g'), ('Meals', '4 a day'), ('Diet', 'Veg')],
          meta: '1,800 kcal · P 110 g · veg · 4 meals',
          by: 'By Sahil Kapoor · 14 clients on it',
          rows: [
            PreviewRow('8:00 am', 'Breakfast', '450 kcal'),
            PreviewRow('1:00 pm', 'Lunch', '550 kcal'),
            PreviewRow('5:00 pm', 'Snack', '250 kcal'),
            PreviewRow('8:30 pm', 'Dinner', '550 kcal'),
          ],
          diff: ['150 kcal more a day', 'For keeping her weight, not losing'],
        ),
      ],
    ),
    'supp': AssignKind(
      id: 'supp',
      title: 'Assign a supplement plan',
      sub: 'Supplement plans from the library',
      search: 'Search supplement plans',
      currentName: 'Fat loss basics',
      currentEnd: '',
      length: 'Ongoing',
      rowsTitle: 'Each day',
      filters: [
        ('Goal', ['Any', 'Fat loss', 'Recovery', 'Health']),
      ],
      options: [
        AssignOption(
          id: 'rec',
          name: 'Recovery stack',
          sub: 'Magnesium, omega 3, creatine',
          note: 'For heavier training blocks.',
          used: 11,
          kpis: [('Items', '3'), ('When', 'Morning, night'), ('Cost', '~₹2,100 a month')],
          meta: '3 items · morning and night',
          by: 'By Vimal · 11 clients on it',
          rows: [
            PreviewRow('Morning', 'Creatine', '5 g'),
            PreviewRow('Morning', 'Omega 3', '2 caps'),
            PreviewRow('Night', 'Magnesium', '1 tablet'),
          ],
          diff: ['Adds creatine and omega 3', 'Drops whey and vitamin D3'],
        ),
        AssignOption(
          id: 'flb',
          name: 'Fat loss basics',
          sub: 'Whey, vitamin D3, magnesium',
          note: 'Riya is on this since 1 Sep.',
          used: 40,
          current: true,
          kpis: [('Items', '3'), ('When', 'Morning, night'), ('Cost', '~₹2,600 a month')],
          meta: '3 items · morning and night',
          by: 'Riya is on this since 1 Sep',
          rows: [
            PreviewRow('Morning', 'Whey protein', '1 scoop'),
            PreviewRow('Morning', 'Vitamin D3', '1 tablet'),
            PreviewRow('Night', 'Magnesium', '1 tablet'),
          ],
        ),
      ],
    ),
    'habit': AssignKind(
      id: 'habit',
      title: 'Assign a habit plan',
      sub: 'Habit plans from the library',
      search: 'Search habit plans',
      currentName: 'Daily basics',
      currentEnd: '',
      length: 'Ongoing',
      rowsTitle: 'Each day',
      filters: [
        ('Length', ['Any', '21 days', 'Ongoing']),
      ],
      options: [
        AssignOption(
          id: 'sl',
          name: 'Sleep reset · 21 days',
          sub: 'Screens off by 10:30 pm, 7.5 h sleep',
          note: 'Her sleep average is 6 h 10 min.',
          used: 16,
          tip: 'Suggested',
          kpis: [('Habits', '3'), ('Length', '21 days'), ('Check', 'Daily')],
          meta: '3 habits · 21 days · checked daily',
          by: 'By Neha Joshi · 16 clients on it',
          rows: [
            PreviewRow('Daily', 'Screens off', 'by 10:30 pm'),
            PreviewRow('Daily', 'Sleep', '7.5 hours'),
            PreviewRow('Daily', 'Morning light', '10 min'),
          ],
          diff: ['3 sleep habits for 21 days', 'Runs next to Daily basics, does not replace it'],
        ),
        AssignOption(
          id: 'db',
          name: 'Daily basics',
          sub: '8k steps, 3 L water, 7 h sleep',
          note: 'Riya is on this since 12 Jan.',
          used: 58,
          current: true,
          kpis: [('Habits', '4'), ('Length', 'Ongoing'), ('Check', 'Daily')],
          meta: '4 habits · ongoing · checked daily',
          by: 'Riya is on this since 12 Jan',
          rows: [
            PreviewRow('Daily', 'Walk', '8,000 steps'),
            PreviewRow('Daily', 'Water', '3 L'),
            PreviewRow('Daily', 'Sleep', '7 hours'),
            PreviewRow('Daily', 'No sugar after 7 pm', 'yes / no'),
          ],
        ),
      ],
    ),
  };

  // ───────────── Logs ─────────────
  static const logTabs = <(String, String)>[
    ('workouts', 'Workouts'),
    ('meals', 'Meals'),
    ('daily', 'Daily check-ins'),
    ('weekly', 'Weekly check-ins'),
    ('habits', 'Habits'),
    ('supps', 'Supplements'),
  ];

  /// Range picker: (key, label, summary).
  static const ranges = <(String, String, String)>[
    ('7', 'Last 7 days', '4 workouts · 31 meals logged · 6 check-ins'),
    ('30', 'Last 30 days', '14 workouts · 138 meals logged · 27 check-ins'),
    ('90', 'Last 90 days', '41 workouts · 402 meals logged · 79 check-ins'),
    ('180', 'Last 6 months', '84 workouts · 790 meals logged · 158 check-ins'),
    ('0', 'Since start', '112 workouts · 1,120 meals logged · 241 check-ins'),
    ('p1', 'Plan: Fat Loss Phase 1', '1 Sep – today · 22 workouts · 196 meals logged · 37 check-ins'),
    ('p0', 'Plan: Beginner Full Body', '12 Jan – 31 Aug · 86 workouts · 924 meals logged · 204 check-ins'),
    ('c', 'Custom dates…', 'Pick a start and end date'),
  ];

  static const workoutLog = <WorkoutLogRow>[
    WorkoutLogRow('Thu, 8 Oct', 'Upper A', '18 / 18', '4,820 kg', '52 min', 'done'),
    WorkoutLogRow('Tue, 6 Oct', 'Lower A', '16 / 20', '6,140 kg', '58 min', 'part'),
    WorkoutLogRow('Mon, 5 Oct', 'Upper B', '—', '—', '—', 'miss'),
    WorkoutLogRow('Sun, 4 Oct', 'Cardio · incline walk', '—', '—', '35 min', 'done'),
    WorkoutLogRow('Fri, 2 Oct', 'Lower B', '20 / 20', '6,480 kg', '61 min', 'done'),
    WorkoutLogRow('Wed, 30 Sep', 'Upper A', '18 / 18', '4,700 kg', '50 min', 'done'),
  ];

  static const mealLog = <MealLogRow>[
    MealLogRow('Thu, 8 Oct', '1,610', .97, '118 g', '182 g', '52 g', '5 / 5', 'ok'),
    MealLogRow('Wed, 7 Oct', '1,980', 1, '102 g', '214 g', '80 g', '5 / 5', 'over'),
    MealLogRow('Tue, 6 Oct', '1,430', .87, '107 g', '154 g', '49 g', '4 / 5', 'part'),
    MealLogRow('Mon, 5 Oct', '1,700', 1, '122 g', '170 g', '55 g', '5 / 5', 'ok'),
    MealLogRow('Sun, 4 Oct', '1,630', .98, '115 g', '165 g', '50 g', '5 / 5', 'ok'),
  ];

  static const dailyLog = <DailyCheckinRow>[
    DailyCheckinRow('Thu, 8 Oct', '7.5 h', 'Good', 'Good', 'Normal', '9,240', 'Felt strong today'),
    DailyCheckinRow('Wed, 7 Oct', '6 h', 'Low', 'Okay', 'High', '5,110', 'Late office, ate out'),
    DailyCheckinRow('Tue, 6 Oct', '—', '—', '—', '—', '—', 'Not sent'),
    DailyCheckinRow('Mon, 5 Oct', '7 h', 'Good', 'Good', 'Normal', '8,020', '—'),
    DailyCheckinRow('Sun, 4 Oct', '8 h', 'Great', 'Great', 'Low', '11,300', '—'),
  ];

  static const weeklyLog = <WeeklyCheckinRow>[
    WeeklyCheckinRow('Week 6', 'Sun, 4 Oct', '71.6 kg', 'Sent Sun, 4 Oct · 71.6 kg · 3 photos · "Knee better, energy good"', 'To review', BadgeTone.info),
    WeeklyCheckinRow('Week 5', 'Sun, 27 Sep', '72.3 kg', 'Sent Sun, 27 Sep · 72.3 kg · reply by Aman Verma', 'Reviewed', BadgeTone.ok),
    WeeklyCheckinRow('Week 4', 'Sun, 20 Sep', '—', 'Not sent', 'Missed', BadgeTone.bad),
    WeeklyCheckinRow('Week 3', 'Sun, 13 Sep', '73.4 kg', 'Sent Sun, 13 Sep · 73.4 kg · reply by Aman Verma', 'Reviewed', BadgeTone.ok),
  ];

  static const habitNames = ['Walk 8,000 steps', 'Drink 3 L water', 'Sleep 7 hours'];
  static const habitDetail = <Kv>[('Walk 8,000 steps', '9,240 steps'), ('Drink 3 L water', '3.2 L'), ('Sleep 7 hours', '7 h 30 min')];
  static const habitLog = <TickLogRow>[
    TickLogRow('Thu, 8 Oct', [true, true, true]),
    TickLogRow('Wed, 7 Oct', [false, true, false]),
    TickLogRow('Tue, 6 Oct', [true, true, false]),
    TickLogRow('Mon, 5 Oct', [true, true, true]),
  ];

  static const suppNames = ['Whey protein', 'Vitamin D3', 'Magnesium'];
  static const suppDetail = <Kv>[('Whey protein', '1 scoop · morning'), ('Vitamin D3', '1 tablet · morning'), ('Magnesium', '1 tablet · night')];
  static const suppLog = <TickLogRow>[
    TickLogRow('Thu, 8 Oct', [true, true, true]),
    TickLogRow('Wed, 7 Oct', [true, true, false]),
    TickLogRow('Tue, 6 Oct', [true, false, false]),
    TickLogRow('Mon, 5 Oct', [true, true, true]),
  ];

  static const weeklyAnswers = <Kv>[
    ('How was your week?', '4 / 5'),
    ('Did you follow the meal plan?', 'Mostly, ate out once'),
    ('How does your right knee feel?', '3 / 5, better on box squats'),
    ('Anything your coach should know?', 'Office travel next week, Tue to Thu'),
  ];

  static const _bf = [
    LoggedFood('Rolled oats', '50 g', 190, 7, 32, 3),
    LoggedFood('Whey protein', '1 scoop', 120, 24, 3, 2),
    LoggedFood('Banana', '1 medium', 110, 1, 27, 0),
  ];
  static const _sn1 = [LoggedFood('Greek yogurt', '150 g', 150, 15, 6, 7), LoggedFood('Almonds', '10 pieces', 70, 3, 2, 6)];
  static const _lu = [
    LoggedFood('Paneer', '100 g', 265, 18, 4, 20),
    LoggedFood('Brown rice', '120 g cooked', 135, 3, 28, 1),
    LoggedFood('Salad', '1 bowl', 80, 9, 10, 1),
  ];
  static const _sn2 = [LoggedFood('Sprouts chaat', '1 bowl', 180, 11, 28, 3)];
  static const _di = [LoggedFood('Tofu stir fry', '150 g', 130, 21, 6, 7), LoggedFood('Roti', '2 pieces', 180, 6, 36, 2)];

  /// One day of logged meals for the meal log drawer. [status] is the row's 'ok' | 'over' | 'part'.
  static List<LoggedMeal> loggedMeals(String status) {
    final m = <LoggedMeal>[
      const LoggedMeal('Breakfast', '8:10 am', _bf, 'On plan', BadgeTone.ok, photo: true),
      const LoggedMeal('Snack', '11:20 am', _sn1, 'On plan', BadgeTone.ok, photo: true),
      const LoggedMeal('Lunch', '1:45 pm', _lu, 'On plan', BadgeTone.ok, photo: true),
      const LoggedMeal('Snack', '5:30 pm', _sn2, 'On plan', BadgeTone.ok),
      const LoggedMeal('Dinner', '8:40 pm', _di, 'On plan', BadgeTone.ok, photo: true),
    ];
    if (status == 'over') {
      m[3] = const LoggedMeal('Snack', '5:10 pm', [LoggedFood('Samosa', '1 piece', 260, 4, 30, 14)], 'Swapped', BadgeTone.warn,
          photo: true, was: 'Sprouts chaat, 180 kcal · P 11 g');
      m[4] = const LoggedMeal('Dinner', '9:30 pm', [LoggedFood('Pizza, veg', '3 slices', 600, 18, 72, 26)], 'Off plan', BadgeTone.bad,
          photo: true, was: 'Tofu stir fry and 2 rotis, 310 kcal · P 27 g. Office party.');
    }
    if (status == 'part') {
      m[3] = const LoggedMeal('Snack', '', [], 'Missed', BadgeTone.bad);
    }
    return m;
  }

  static const mealTargets = [1650, 120, 180, 52];

  // ───────────── Compare plans ─────────────
  static const comparePlanA = ('Beginner Full Body', 'Workout + 1,800 kcal veg · 12 Jan – 31 Aug · 33 weeks');
  static const comparePlanB = ('Fat Loss Phase 1', 'Workout + 1,650 kcal high protein · 1 Sep – now · 6 weeks');
  static const compareAspects = <(String, String)>[
    ('all', 'All'),
    ('workouts', 'Workouts'),
    ('meals', 'Meals'),
    ('checkins', 'Check-ins'),
    ('habits', 'Habits'),
    ('supps', 'Supplements'),
    ('body', 'Body'),
  ];
  static const compare = <CompareSection>[
    CompareSection('workouts', 'Workouts', '9 of 12', [
      CompareTable('Number', [
        CompareRow('Workouts planned a week', '3', '4', change: '+1', tone: BadgeTone.neutral),
        CompareRow('Workouts done a week', '2.6', '3.6', change: '+1.0', tone: BadgeTone.ok),
        CompareRow('Completed', '72%', '88%', barA: 0.72, barB: 0.88, change: '+16%', tone: BadgeTone.ok),
        CompareRow('Sets done', '81%', '93%', barA: 0.81, barB: 0.93, change: '+12%', tone: BadgeTone.ok),
        CompareRow('Avg volume per workout', '3,900 kg', '5,400 kg', change: '+38%', tone: BadgeTone.ok),
        CompareRow('Avg session', '46 min', '54 min', change: '+8 min', tone: BadgeTone.neutral),
        CompareRow('Missed workouts', '18', '2', change: '−16', tone: BadgeTone.ok),
        CompareRow('Most missed day', 'Friday', 'Monday', change: '', tone: BadgeTone.neutral),
      ]),
      CompareTable('Best set', [
        CompareRow('Bench press', '35 kg × 8', '45 kg × 6', change: '+10 kg', tone: BadgeTone.ok),
        CompareRow('Back squat', '50 kg × 8', '60 kg × 6', change: '+10 kg', tone: BadgeTone.ok),
        CompareRow('Romanian deadlift', '45 kg × 10', '55 kg × 8', change: '+10 kg', tone: BadgeTone.ok),
        CompareRow('Lat pulldown', '30 kg × 10', '35 kg × 10', change: '+5 kg', tone: BadgeTone.ok),
      ]),
    ]),
    CompareSection('meals', 'Meals', '10 of 13', [
      CompareTable('Number', [
        CompareRow('Calorie target', '1,800 kcal', '1,650 kcal', change: '−150', tone: BadgeTone.neutral),
        CompareRow('Avg calories eaten', '1,920 kcal', '1,690 kcal', change: '−230', tone: BadgeTone.ok),
        CompareRow('Avg protein', '78 g', '112 g', barA: 0.65, barB: 0.93, change: '+34 g', tone: BadgeTone.ok),
        CompareRow('Avg carbs', '240 g', '172 g', change: '−68 g', tone: BadgeTone.neutral),
        CompareRow('Avg fat', '62 g', '53 g', change: '−9 g', tone: BadgeTone.neutral),
        CompareRow('Days on plan', '61%', '78%', barA: 0.61, barB: 0.78, change: '+17%', tone: BadgeTone.ok),
        CompareRow('Days over target', '34%', '14%', barA: 0.34, barB: 0.14, change: '−20%', tone: BadgeTone.ok),
        CompareRow('Meals logged a day', '4.1 of 5', '4.8 of 5', barA: 0.82, barB: 0.96, change: '+0.7', tone: BadgeTone.ok),
      ]),
      CompareTable('Logged per meal', [
        CompareRow('Breakfast', '94%', '99%', barA: 0.94, barB: 0.99, change: '+5%', tone: BadgeTone.ok),
        CompareRow('Morning snack', '71%', '92%', barA: 0.71, barB: 0.92, change: '+21%', tone: BadgeTone.ok),
        CompareRow('Lunch', '88%', '97%', barA: 0.88, barB: 0.97, change: '+9%', tone: BadgeTone.ok),
        CompareRow('Evening snack', '66%', '90%', barA: 0.66, barB: 0.9, change: '+24%', tone: BadgeTone.ok),
        CompareRow('Dinner', '90%', '96%', barA: 0.9, barB: 0.96, change: '+6%', tone: BadgeTone.ok),
      ]),
    ]),
    CompareSection('checkins', 'Check-ins', '6 of 6', [
      CompareTable('Number', [
        CompareRow('Daily check-ins sent', '70%', '90%', barA: 0.7, barB: 0.9, change: '+20%', tone: BadgeTone.ok),
        CompareRow('Weekly check-ins on time', '25 of 33', '5 of 6', barA: 0.76, barB: 0.83, change: '76% → 83%', tone: BadgeTone.ok),
        CompareRow('Avg sleep', '6.4 h', '7.1 h', change: '+0.7 h', tone: BadgeTone.ok),
        CompareRow('Energy good or great', '48%', '71%', barA: 0.48, barB: 0.71, change: '+23%', tone: BadgeTone.ok),
        CompareRow('Mood good or great', '55%', '74%', barA: 0.55, barB: 0.74, change: '+19%', tone: BadgeTone.ok),
        CompareRow('High hunger days', '22%', '18%', barA: 0.22, barB: 0.18, change: '−4%', tone: BadgeTone.ok),
      ]),
    ]),
    CompareSection('habits', 'Habits', '6 of 6', [
      CompareTable('Number', [
        CompareRow('Walk 8,000 steps', '41%', '71%', barA: 0.41, barB: 0.71, change: '+30%', tone: BadgeTone.ok),
        CompareRow('Drink 3 L water', '52%', '86%', barA: 0.52, barB: 0.86, change: '+34%', tone: BadgeTone.ok),
        CompareRow('Sleep 7 hours', '38%', '57%', barA: 0.38, barB: 0.57, change: '+19%', tone: BadgeTone.ok),
        CompareRow('All habits done', '55%', '76%', barA: 0.55, barB: 0.76, change: '+21%', tone: BadgeTone.ok),
        CompareRow('Avg steps', '6,200', '8,400', change: '+2,200', tone: BadgeTone.ok),
        CompareRow('Avg water', '2.3 L', '2.9 L', change: '+0.6 L', tone: BadgeTone.ok),
      ]),
    ]),
    CompareSection('supps', 'Supplements', '4 of 5', [
      CompareTable('Number', [
        CompareRow('Whey protein', '64%', '93%', barA: 0.64, barB: 0.93, change: '+29%', tone: BadgeTone.ok),
        CompareRow('Vitamin D3', '58%', '86%', barA: 0.58, barB: 0.86, change: '+28%', tone: BadgeTone.ok),
        CompareRow('Magnesium', 'Not in plan', '71%', barA: 0.0, barB: 0.71, change: 'New', tone: BadgeTone.neutral),
        CompareRow('All taken', '61%', '84%', barA: 0.61, barB: 0.84, change: '+23%', tone: BadgeTone.ok),
        CompareRow('Ran out of stock', '2 times', '0 times', change: '−2', tone: BadgeTone.ok),
      ]),
    ]),
    CompareSection('body', 'Body', '4 of 4', [
      CompareTable('Number', [
        CompareRow('Weight change', '−2.4 kg', '−4.4 kg', change: '−2.0 kg', tone: BadgeTone.ok),
        CompareRow('Per week', '−0.07 kg', '−0.73 kg', change: 'faster', tone: BadgeTone.ok),
        CompareRow('Waist', '−4 cm', '−6 cm', change: '−2 cm', tone: BadgeTone.ok),
        CompareRow('Body fat', '−2%', '−3%', change: '−1%', tone: BadgeTone.ok),
      ]),
    ]),
  ];

  // ───────────── Progress ─────────────
  static const progressStats = <ProgressStat>[
    ProgressStat('Weight', '−6.8 kg', '71.2 kg', 'from 78.0 kg · 12 Jan'),
    ProgressStat('Waist', '−10 cm', '78 cm', 'from 88 cm'),
    ProgressStat('Body fat', '−5%', '27%', 'from 32%'),
    ProgressStat('Bench press', '+15 kg', '45 kg', 'best set 45 kg × 6'),
  ];

  static const measurements = <Measurement>[
    Measurement('4 Oct', '71.6 kg', '78 cm', '98 cm', '90 cm', '28 cm', '27%'),
    Measurement('20 Sep', '72.8 kg', '80 cm', '99 cm', '91 cm', '28 cm', '28%'),
    Measurement('6 Sep', '74.1 kg', '82 cm', '100 cm', '92 cm', '29 cm', '29%'),
    Measurement('12 Jan · start', '78.0 kg', '88 cm', '104 cm', '95 cm', '30 cm', '32%'),
  ];
  static const measurementChange = Measurement('Change', '−6.4 kg', '−10 cm', '−6 cm', '−5 cm', '−2 cm', '−5%');

  /// Start vs latest photos: (date, caption, tone).
  static const startVsLatest = <(String, String, int)>[
    ('12 Jan', '78.0 kg · front', 0),
    ('4 Oct', '71.6 kg · front', 1),
    ('12 Jan', 'side', 2),
    ('4 Oct', 'side', 3),
  ];

  static const personalBests = <PersonalBest>[
    PersonalBest('Bench press', '30 kg × 8', '45 kg × 6', '+15 kg'),
    PersonalBest('Back squat', '40 kg × 8', '60 kg × 6', '+20 kg'),
    PersonalBest('Romanian deadlift', '40 kg × 10', '55 kg × 8', '+15 kg'),
    PersonalBest('Lat pulldown', '25 kg × 10', '35 kg × 10', '+10 kg'),
  ];

  static const photoDates = <PhotoDate>[
    PhotoDate('12 Jan', '78.0 kg', 0, 'Start photos'),
    PhotoDate('6 Sep', '74.1 kg', 2, 'Week 2 check-in'),
    PhotoDate('20 Sep', '72.8 kg', 1, 'Week 4 check-in'),
    PhotoDate('27 Sep', '72.3 kg', 3, 'Week 5 check-in'),
    PhotoDate('4 Oct', '71.6 kg', 1, 'Week 6 check-in'),
  ];

  // ───────────── Content ─────────────
  static const content = <ClientContent>[
    ClientContent(
      title: 'Box squat: how to',
      type: 'Video',
      by: 'Aman Verma',
      why: 'Assigned to Riya',
      whyTone: BadgeTone.warn,
      seen: 'Opened 2 d ago',
      seenBadge: false,
      len: '3:05',
      until: 'Until Fat Loss Phase 1 ends',
      added: '28 Sep',
      kpis: [('Opened', '2 days ago'), ('Watched', '2:40 of 3:05'), ('Times', '3')],
      text: 'Sit back onto the box, keep your chest up, and stand up through your heels. Start with a box at knee height.',
      assigned: true,
    ),
    ClientContent(
      title: 'Eating out on a fat loss plan',
      type: 'PDF',
      by: 'Vimal',
      why: 'Assigned to Riya',
      whyTone: BadgeTone.warn,
      seen: 'Not opened',
      seenBadge: true,
      len: '6 pages',
      until: 'Always',
      added: '1 Oct',
      kpis: [('Opened', 'Not yet'), ('Read', '0%'), ('Reminder', 'Sent 5 Oct')],
      text: 'Pick grilled over fried, ask for dressing on the side, and start with a protein. Here are 12 orders that fit your plan…',
      assigned: true,
    ),
    ClientContent(
      title: 'Upper A walkthrough',
      type: 'Video',
      by: 'Vimal',
      why: 'From Fat Loss Phase 1',
      whyTone: BadgeTone.info,
      seen: 'Opened 5 d ago',
      seenBadge: false,
      len: '6:20',
      until: 'Until 23 Nov (plan ends)',
      added: '1 Sep',
      kpis: [('Opened', '5 days ago'), ('Watched', 'Full'), ('Times', '6')],
      text: 'All six moves of Upper A, with the sets, reps and rest for each.',
      assigned: false,
    ),
    ClientContent(
      title: 'How to warm up for leg day',
      type: 'Article',
      by: 'Vimal',
      why: 'From Fat Loss Phase 1',
      whyTone: BadgeTone.info,
      seen: 'Opened 3 w ago',
      seenBadge: false,
      len: '4 min read',
      until: 'Until 23 Nov (plan ends)',
      added: '1 Sep',
      kpis: [('Opened', '3 weeks ago'), ('Read', '100%'), ('Times', '1')],
      text: 'Five minutes of easy cardio, then hip openers, glute bridges and bodyweight squats.',
      assigned: false,
    ),
    ClientContent(
      title: 'Macro cheat sheet',
      type: 'PDF',
      by: 'Aman Verma',
      why: 'Assigned to Riya',
      whyTone: BadgeTone.warn,
      seen: 'Opened 1 w ago',
      seenBadge: false,
      len: '2 pages',
      until: 'Always',
      added: '10 Aug',
      kpis: [('Opened', '1 week ago'), ('Read', '100%'), ('Times', '4')],
      text: 'Protein: 1.6 to 2 g per kg of body weight. One palm of paneer, chicken, fish or tofu is about 25 g.',
      assigned: true,
    ),
    ClientContent(
      title: '10 veg snacks under 200 kcal',
      type: 'Image',
      by: 'Sahil Kapoor',
      why: 'From meal plan 1,650 kcal',
      whyTone: BadgeTone.info,
      seen: 'Not opened',
      seenBadge: true,
      len: 'JPG',
      until: 'While on the meal plan',
      added: '1 Sep',
      kpis: [('Opened', 'Not yet'), ('Read', '0%'), ('Reminder', 'None')],
      text: 'Roasted chana, sprouts chaat, Greek yogurt with berries, and seven more.',
      assigned: false,
    ),
    ClientContent(
      title: 'Welcome to Train With Vimal',
      type: 'Article',
      by: 'Vimal',
      why: 'Everyone',
      whyTone: BadgeTone.neutral,
      seen: 'Opened 12 Jan',
      seenBadge: false,
      len: '2 min read',
      until: 'Always',
      added: '12 Jan',
      kpis: [('Opened', '12 Jan'), ('Read', '100%'), ('Times', '1')],
      text: 'How the app works, how to log, and how to reach your coach.',
      assigned: false,
    ),
    ClientContent(
      title: 'How check-ins work',
      type: 'PDF',
      by: 'Vimal',
      why: 'Everyone',
      whyTone: BadgeTone.neutral,
      seen: 'Opened 12 Jan',
      seenBadge: false,
      len: '3 pages',
      until: 'Always',
      added: '12 Jan',
      kpis: [('Opened', '12 Jan'), ('Read', '100%'), ('Times', '2')],
      text: 'Daily check-ins take 30 seconds. Weekly check-ins go to your coach every Sunday.',
      assigned: false,
    ),
  ];

  static const contentPicks = <ContentPick>[
    ContentPick('Knee-safe leg day warm-up', 'Video', '8 min', true, 'Good before her Tuesday leg day'),
    ContentPick('Box squat: how to', 'Video', '3 min', true, 'Her plan already has this', has: true),
    ContentPick('Eating out on a fat loss plan', 'PDF', '6 pages', false, 'Assigned on 1 Oct', has: true),
    ContentPick('Sleep better in 7 days', 'Guide', '6 min read', false, 'Her sleep average is 6 h 10 min'),
    ContentPick('Hip thrust: form check', 'Video', '4 min', true, 'For Saturday, Lower B'),
  ];

  // ───────────── Forms ─────────────
  static const forms = <ClientForm>[
    ClientForm(
      id: 'onb',
      name: 'Onboarding questionnaire',
      sub: 'Filled 12 Jan · 5 parts',
      badge: 'Done',
      tone: BadgeTone.ok,
      cap: 'Filled by Riya on 12 Jan 2026 · edits change her profile too',
      answers: [
        QaSection('Goal', [('Main goal', 'Lose fat'), ('By when', 'Before my wedding, February 2027'), ('Training experience', '6 months – 2 years')]),
        QaSection('Body and lifestyle', [
          ('Age', '29'),
          ('Height', '162 cm'),
          ('Weight', '78.0 kg'),
          ('Where do you train?', 'Gym'),
          ('Days a week', '4'),
          ('Food preference', 'Vegetarian'),
        ]),
        QaSection('Health', [
          ('Injuries or pain', 'Right knee hurts on deep squats'),
          ('Doctor clearance to exercise', 'Yes'),
          ('Daily activity', 'Mostly sitting (desk job)'),
          ('Wake-up time', '6:30 am'),
        ]),
        QaSection('Food', [('Meals a day', '5'), ('Foods to avoid', 'Eggs, mushrooms'), ('Allergies', 'None')]),
        QaSection('Photos', [('Starting photos', '2 photos · front and side')]),
      ],
    ),
    ClientForm(
      id: 'parq',
      name: 'Health and consent waiver',
      sub: 'Signed 12 Jan',
      badge: 'Signed',
      tone: BadgeTone.ok,
      cap: 'Signed by Riya on 12 Jan 2026, 7:42 pm',
      answers: [
        QaSection('Answers', [
          ('Has a doctor ever said you have a heart condition?', 'No'),
          ('Do you feel chest pain during exercise?', 'No'),
          ('Do you have a bone or joint problem that exercise could make worse?', 'Yes · right knee'),
          ('I agree to the terms and the privacy policy', 'Yes · signed "Riya Sharma"'),
        ]),
      ],
    ),
    ClientForm(
      id: 'fb',
      name: 'Monthly feedback',
      sub: 'Sent 1 Oct · same as master',
      badge: 'Waiting',
      tone: BadgeTone.warn,
      cap: 'From master "Monthly feedback" · no changes · sent Thu, 1 Oct, not answered yet',
      editCap: 'From master "Monthly feedback" · no changes yet',
      schedule: ['Every month', '1st, 10:00 am', 'Push + email'],
      questions: [
        FormQuestion('How happy are you with your coaching?', 'Scale 1–5', required: true),
        FormQuestion('What should we do better?', 'Text'),
        FormQuestion('Would you recommend us to a friend?', 'Yes / no', required: true),
      ],
    ),
    ClientForm(
      id: 'wk',
      name: 'Weekly check-in',
      sub: 'Every Sunday · edited for Riya',
      badge: 'Recurring',
      tone: BadgeTone.neutral,
      edited: true,
      cap: 'From master "Weekly check-in" · every Sunday, 6:00 pm · 1 question added, 1 changed · answers are in Logs',
      editCap: 'From master "Weekly check-in" · 2 changes',
      schedule: ['Every Sunday', '6:00 pm', 'Push + WhatsApp'],
      questions: [
        FormQuestion('Body weight (kg)', 'Number', required: true),
        FormQuestion('How was your week?', 'Scale 1–5', required: true),
        FormQuestion('Did you follow the meal plan?', 'Yes / no', required: true),
        FormQuestion('How does your right knee feel? (1–5)', 'Scale 1–5', required: true, changed: true, note: 'Added for Riya'),
        FormQuestion('Progress photos this week?', 'Yes / no', changed: true, note: 'Was: required'),
        FormQuestion('Anything your coach should know?', 'Text'),
      ],
    ),
  ];

  static const sendForms = <SendFormOption>[
    SendFormOption('wk', 'Weekly check-in', 'Weight, energy, meals, photos', '6 questions', 'Sending'),
    SendFormOption('fb', 'Monthly feedback', 'How happy she is with coaching', '3 questions', 'Sent 1 Oct'),
    SendFormOption('ms', 'Body measurements', 'Waist, hips, chest, arms, thighs', '6 questions'),
    SendFormOption('ss', 'Sleep and stress check', 'Sleep hours, stress, mood', '5 questions'),
    SendFormOption('dh', 'Diet history', 'What she ate before joining', '9 questions'),
  ];

  // ───────────── History ─────────────
  static const historySummary = <(String, String, String, bool)>[
    ('With Train With Vimal', '9 months', 'Joined Mon, 12 Jan 2026', false),
    ('Weight', '78.0 → 71.2 kg', '−6.8 kg · 3.2 kg to goal', true),
    ('Workouts done', '112 of 126', '89% · best streak 34 days', false),
    ('Check-ins sent', '36 of 39', '92% · 3 missed', false),
  ];

  static const timelineMonths = <(String, double)>[
    ('Jan', 0),
    ('Feb', .0731),
    ('Mar', .1392),
    ('Apr', .2123),
    ('May', .283),
    ('Jun', .3561),
    ('Jul', .4269),
    ('Aug', .50),
    ('Sep', .5731),
    ('Oct', .6439),
    ('Nov', .717),
    ('Dec', .7877),
    ('Jan ’27', .8608),
    ('Feb', .934),
  ];
  static const timelineToday = .6627;
  static const timelineRows = <(String, List<TimelineBar>)>[
    ('Trainer', [TimelineBar('Aman Verma', .0259, .9741, 'cur', 'Aman Verma · since 12 Jan')]),
    ('Workout', [
      TimelineBar('Home Starter', .0259, .0519, 'old', 'Home Starter · 12 Jan – 2 Feb · replaced'),
      TimelineBar('Beginner Full Body', .0778, .4953, 'done', 'Beginner Full Body · 3 Feb – 31 Aug · completed'),
      TimelineBar('Fat Loss Phase 1', .5731, .1981, 'cur', 'Fat Loss Phase 1 · 1 Sep – 23 Nov · week 6 of 12'),
      TimelineBar('Phase 2', .7712, .1981, 'next', 'Fat Loss Phase 2 · from 24 Nov · up next'),
    ]),
    ('Meal plan', [
      TimelineBar('1,800 kcal · balanced veg', .0259, .5472, 'done', '1,800 kcal · balanced veg · 12 Jan – 31 Aug'),
      TimelineBar('1,650 kcal · high protein', .5731, .4269, 'cur', '1,650 kcal · high protein · since 1 Sep'),
    ]),
    ('Supplements', [TimelineBar('Fat loss basics', .5731, .4269, 'cur', 'Fat loss basics · since 1 Sep')]),
    ('Habits', [TimelineBar('Daily basics', .0259, .9741, 'cur', 'Daily basics · since 12 Jan')]),
  ];

  static const historyFilters = <(String, String)>[
    ('all', 'All'),
    ('plans', 'Plans and trainer'),
    ('miles', 'Milestones and goals'),
    ('checks', 'Check-ins and forms'),
    ('health', 'Health'),
    ('acct', 'Account'),
  ];
  static const historyKind = {
    'plan': 'plans',
    'check': 'checks',
    'form': 'checks',
    'mile': 'miles',
    'goal': 'miles',
    'health': 'health',
    'trainer': 'plans',
    'acct': 'acct',
  };

  static const history = <HistoryMonth>[
    HistoryMonth('October 2026', '8 workouts · 1 check-in · −0.4 kg so far', [
      HistoryEvent('plan', 'Fat Loss Phase 2 set as Up next', 'Starts Tue, 24 Nov after Phase 1 ends. 12 weeks, 4 days a week.', 'Thu, 8 Oct', 'Vimal',
          'Up next', BadgeTone.info),
      HistoryEvent('check', 'Week 6 check-in reviewed', '71.6 kg, knee 3/5 and better on box squats. Aman replied with a deload note.', 'Sun, 4 Oct',
          'Aman Verma'),
      HistoryEvent('plan', 'Lunch swapped in her meal plan', 'Moong dal became paneer at lunch, +7 g protein.', 'Sat, 3 Oct', 'Sahil Kapoor'),
    ]),
    HistoryMonth('September 2026', '16 of 17 workouts · 4 check-ins · −1.6 kg', [
      HistoryEvent('mile', 'Lost 6 kg since joining', '78.0 kg to 72.0 kg in 8 months.', 'Mon, 28 Sep', 'Auto', 'Milestone', BadgeTone.ok),
      HistoryEvent('plan', 'Started Fat Loss Phase 1', 'Replaced Beginner Full Body. Her copy has box squats instead of back squats.', 'Tue, 1 Sep',
          'Aman Verma', 'Workout', BadgeTone.neutral),
      HistoryEvent('plan', 'Moved to 1,650 kcal · high protein', 'Down from 1,800 kcal. Protein target 120 g.', 'Tue, 1 Sep', 'Sahil Kapoor',
          'Meal plan', BadgeTone.neutral),
      HistoryEvent('plan', 'Fat loss basics supplements added', 'Whey, vitamin D3, magnesium.', 'Tue, 1 Sep', 'Aman Verma', 'Supplements',
          BadgeTone.neutral),
    ]),
    HistoryMonth('August 2026', '15 of 16 workouts · 4 check-ins · −0.9 kg', [
      HistoryEvent('plan', 'Finished Beginner Full Body', '30 weeks · 92% of workouts done.', 'Mon, 31 Aug', 'Auto', 'Completed', BadgeTone.ok),
      HistoryEvent('form', 'Monthly feedback answered', 'Happy with coaching 5/5. Wants more variety in lunch.', 'Sat, 1 Aug', 'Riya Sharma'),
    ]),
    HistoryMonth('July 2026', '14 of 16 workouts · 3 of 4 check-ins · −0.7 kg', [
      HistoryEvent('goal', 'Goal weight changed', '70 kg became 68 kg. Target date moved from Dec 2026 to Feb 2027.', 'Wed, 15 Jul', 'Aman Verma',
          'Goal', BadgeTone.warn),
      HistoryEvent('mile', 'Lost 5 kg since joining', '78.0 kg to 73.0 kg.', 'Fri, 10 Jul', 'Auto', 'Milestone', BadgeTone.ok),
      HistoryEvent('check', 'Missed a check-in', 'Week 26. She was travelling for a wedding.', 'Sun, 5 Jul', 'Auto', 'Missed', BadgeTone.bad),
    ]),
    HistoryMonth('March 2026', '15 of 16 workouts · 4 check-ins · −1.1 kg', [
      HistoryEvent('health', 'Right knee pain reported', 'Pain on deep squats. Box squats and no jumps from now on.', 'Sat, 14 Mar', 'Riya Sharma',
          'Health', BadgeTone.warn),
      HistoryEvent('mile', '34 day workout streak', 'Her best streak so far.', 'Sun, 15 Mar', 'Auto', 'Milestone', BadgeTone.ok),
    ]),
    HistoryMonth('February 2026', '14 of 15 workouts · 4 check-ins · −1.3 kg', [
      HistoryEvent('plan', 'Moved to the gym: Beginner Full Body', 'Replaced Home Starter after she joined a gym.', 'Tue, 3 Feb', 'Aman Verma',
          'Workout', BadgeTone.neutral),
    ]),
    HistoryMonth('January 2026', 'Joined · 6 workouts · 2 check-ins', [
      HistoryEvent('acct', 'Onboarding form filled', 'Goal: lose fat. 78.0 kg, 162 cm, vegetarian, trains 4 days a week.', 'Mon, 12 Jan', 'Riya Sharma'),
      HistoryEvent('trainer', 'Aman Verma assigned as trainer', 'Picked for fat loss and women’s strength.', 'Mon, 12 Jan', 'Vimal', 'Trainer',
          BadgeTone.neutral),
      HistoryEvent('acct', 'Joined Train With Vimal', 'Signed up from an Instagram ad.', 'Mon, 12 Jan', 'Riya Sharma', 'Joined', BadgeTone.info),
    ]),
  ];

  static const journey = <Kv>[
    ('Joined', 'Mon, 12 Jan 2026'),
    ('Came from', 'Instagram ad'),
    ('Goal', 'Lose fat · since joining'),
    ('Goal weight', '68 kg · was 70 kg until Jul'),
    ('Target date', 'Feb 2027 · was Dec 2026'),
    ('Trainer', 'Aman Verma · only trainer so far'),
  ];

  /// (tone: warn | ok | neutral, title, detail)
  static const healthOverTime = <(String, String, String)>[
    ('warn', 'Right knee pain on deep squats', 'Since 14 Mar · box squats instead · better in Sep'),
    ('ok', 'Lower back stiffness', 'Feb – Apr · cleared after mobility work'),
    ('neutral', 'Food', 'Vegetarian, no eggs · whey added in Sep'),
  ];

  // ───────────── Activity ─────────────
  static const activityKinds = ['All', 'Workout', 'Meal', 'Check-in', 'Body', 'Plan', 'Content'];
  static const activityRanges = <(String, int)>[
    ('Today', 0),
    ('Last 7 days', 7),
    ('Last 30 days', 30),
    ('Last 3 months', 90),
    ('All time', 99999),
  ];
  static const activity = <ActivityDay>[
    ActivityDay('Today', 0, [
      ActivityItem('food', 'Meal', 'Riya', ' logged lunch', '1:20 pm', note: 'Paneer bowl, 480 kcal'),
      ActivityItem('clip', 'Check-in', 'Riya', ' sent the daily check-in', '8:04 am', note: 'Sleep 7.5 h, energy good'),
      ActivityItem('edit', 'Plan', 'Aman Verma', ' swapped an exercise in Lower A', '7:30 am', old: 'Back squat', nw: 'Box squat'),
    ]),
    ActivityDay('Yesterday', 1, [
      ActivityItem('dumb', 'Workout', 'Riya', ' finished Upper A', '7:12 pm', note: '18 of 18 sets, 52 min'),
      ActivityItem('edit', 'Plan', 'Sahil Kapoor', ' changed lunch in the meal plan', '4:20 pm', old: 'Dal rice', nw: 'Paneer bowl'),
      ActivityItem('edit', 'Plan', 'Vimal', ' set the next program', '11:02 am', note: 'Fat Loss Phase 2, from 25 Nov'),
      ActivityItem('play', 'Content', 'Riya', ' watched a video', '9:40 am', note: 'Box squat: how to'),
    ]),
    ActivityDay('Sun, 4 Oct', 4, [
      ActivityItem('clip', 'Check-in', 'Riya', ' sent the week 6 check-in', '6:15 pm', note: '71.6 kg, 3 photos'),
      ActivityItem('scale', 'Body', 'Riya', ' logged body weight', '7:02 am', old: '72.3 kg', nw: '71.6 kg'),
    ]),
    ActivityDay('Thu, 1 Oct', 7, [
      ActivityItem('dumb', 'Workout', 'Riya', ' skipped Lower B', '8:00 pm', note: 'Reason: knee felt sore'),
      ActivityItem('clip', 'Check-in', 'Aman Verma', ' replied to her daily check-in', '10:15 am', note: '“Rest the knee today, walk 30 min.”'),
    ]),
    ActivityDay('Sun, 27 Sep', 11, [
      ActivityItem('clip', 'Check-in', 'Riya', ' sent the week 5 check-in', '7:40 pm', note: '72.3 kg, 3 photos'),
      ActivityItem('food', 'Meal', 'Riya', ' swapped a food at dinner', '8:30 pm', old: 'Rice 150 g', nw: 'Quinoa 120 g'),
    ]),
    ActivityDay('Mon, 14 Sep', 24, [
      ActivityItem('edit', 'Plan', 'Aman Verma', ' moved her to week 4', '9:00 am', note: 'Fat Loss Phase 1'),
      ActivityItem('scale', 'Body', 'Riya', ' added measurements', '7:10 am', note: 'Waist 84 cm, hips 101 cm'),
    ]),
    ActivityDay('Mon, 31 Aug', 38, [
      ActivityItem('play', 'Content', 'Vimal', ' shared a guide with her', '5:30 pm', note: 'Eating out on a fat loss plan'),
    ]),
  ];

  // ───────────── Notes ─────────────
  static const notes = <ProfileNote>[
    ProfileNote('Knee pain on deep squats. Use box squats until cleared.', 'Vimal', '12 Sep', flag: true),
    ProfileNote('Asked to move leg day to Saturday because of office travel. Swapped with Upper B.', 'Aman Verma', '2 days ago'),
    ProfileNote('Prefers veg meals. Paneer and tofu are fine, no eggs.', 'Sahil Kapoor', '3 weeks ago'),
    ProfileNote('Onboarding call done. Goal is 68 kg before her wedding in February.', 'Vimal', '12 Jan'),
  ];

  // ───────────── Change trainer ─────────────
  static const trainerOptions = <TrainerOption>[
    TrainerOption('av', 'Aman Verma', 'AV', 1, 'Strength, fat loss · 4.8 rating', 24, 30, current: true),
    TrainerOption('sk', 'Sahil Kapoor', 'SK', 0, 'Fat loss, nutrition · 4.9 rating', 18, 30),
    TrainerOption('nj', 'Neha Joshi', 'NJ', 4, "Women's strength, rehab · 4.9 rating", 21, 30, best: true),
    TrainerOption('km', 'Karan Mehta', 'KM', 2, 'Muscle gain · 4.6 rating', 30, 30),
  ];

  // ───────────── Plan editor libraries ─────────────
  static const foodGroups = ['All', 'Protein', 'Carbs', 'Fats', 'Veg', 'Fruits', 'Dairy', 'Indian dishes', 'My foods'];

  static const editorMeals = <PlanMeal>[
    PlanMeal('Breakfast', '8:00 am', 440, [
      PlanFood('Oats', 'g', 60.0, kcal: 3.75, p: 0.125, c: 0.675, f: 0.075, swaps: [FoodSwap('Poha', '1 plate · 150 g', 82)], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 8.0), FoodUnit('1 cup', 80.0)], per100: [375.0, 12.5, 67.5, 7.5]),
      PlanFood('Whey protein', '1 scoop', 1.0, kcal: 120.0, p: 24.0, c: 3.008, f: 1.984, swaps: [FoodSwap('Greek yogurt', '1.5 × 150 g', 74)], units: [FoodUnit('g', 1.0), FoodUnit('1 scoop', 32.0)], per100: [375.0, 75.0, 9.4, 6.2]),
      PlanFood('Banana', '1 medium', 1.0, kcal: 105.02, p: 0.944, c: 27.022, f: 0.0, swaps: [FoodSwap('Apple', '1 medium', 91)], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 118.0), FoodUnit('1 small', 90.0)], per100: [89.0, 0.8, 22.9, 0.0]),
    ]),
    PlanMeal('Snack', '11:00 am', 180, [
      PlanFood('Greek yogurt', 'g', 150.0, kcal: 0.733, p: 0.1, c: 0.04, f: 0.02, swaps: [FoodSwap('Curd (dahi)', '2 × 1 katori', 70)], units: [FoodUnit('g', 1.0), FoodUnit('1 cup', 200.0), FoodUnit('1 tbsp', 15.0)], per100: [73.3, 10.0, 4.0, 2.0]),
      PlanFood('Almonds', '1 piece', 10.0, kcal: 6.9996, p: 0.3, c: 0.2004, f: 0.6, swaps: [FoodSwap('Peanut butter', '1 tbsp', 88)], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 1.2), FoodUnit('1 handful', 25.0)], per100: [583.3, 25.0, 16.7, 50.0]),
    ]),
    PlanMeal('Lunch', '1:30 pm', 420, [
      PlanFood('Paneer', 'g', 100.0, kcal: 2.65, p: 0.18, c: 0.03, f: 0.21, swaps: [FoodSwap('Tofu (firm)', '180 g', 93), FoodSwap('Low-fat paneer', '130 g', 90)], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [265.0, 18.0, 3.0, 21.0], was: 'Moong dal (cooked), 1 katori · 150 g'),
      PlanFood('Brown rice (cooked)', 'g', 120.0, kcal: 1.12, p: 0.03, c: 0.24, f: 0.01, swaps: [FoodSwap('Whole wheat roti', '1 medium', 88)], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [112.0, 3.0, 24.0, 1.0]),
      PlanFood('Cucumber salad', '1 bowl', 1.0, kcal: 30.0, p: 1.0, c: 6.0, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 100.0)], per100: [30.0, 1.0, 6.0, 0.0]),
    ]),
    PlanMeal('Snack', '5:00 pm', 180, [
      PlanFood('Sprouts chaat', '1 plate', 1.0, kcal: 180.0, p: 10.95, c: 28.05, f: 3.0, swaps: [FoodSwap('Roasted chana', '1.5 × 30 g', 84)], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], per100: [120.0, 7.3, 18.7, 2.0]),
    ]),
    PlanMeal('Dinner', '8:30 pm', 430, [
      PlanFood('Tofu (firm)', 'g', 150.0, kcal: 1.44, p: 0.15, c: 0.03, f: 0.09, swaps: [FoodSwap('Paneer', '80 g', 93)], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [144.0, 15.0, 3.0, 9.0]),
      PlanFood('Whole wheat roti', '1 medium', 2.0, kcal: 110.0, p: 3.0, c: 20.0, f: 2.0, swaps: [FoodSwap('Brown rice (cooked)', '200 g', 88)], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
    ]),
  ];

  static const foodLibrary = <LibraryFood>[
    LibraryFood('Meera\'s protein shake', '1 glass · 350 g', 310, 32, 30, 7, 'My foods', 'veg', team: true),
    LibraryFood('Coach\'s paneer bhurji', '1 plate · 180 g', 290, 22, 8, 19, 'My foods', 'veg', team: true),
    LibraryFood('Paneer', '100 g', 265, 18, 3, 21, 'Dairy', 'veg', team: false),
    LibraryFood('Low-fat paneer', '100 g', 200, 20, 4, 12, 'Protein', 'veg', team: false),
    LibraryFood('Chicken breast (cooked)', '100 g', 165, 31, 0, 4, 'Protein', 'nonVeg', team: false),
    LibraryFood('Egg (whole)', '1 large · 50 g', 72, 6, 0, 5, 'Protein', 'egg', team: false),
    LibraryFood('Egg whites', '4 × 1 egg white · 132 g', 68, 14, 1, 0, 'Protein', 'egg', team: false),
    LibraryFood('Whey protein', '1 scoop · 32 g', 120, 24, 3, 2, 'Protein', 'veg', team: false),
    LibraryFood('Soya chunks', '30 g', 104, 16, 10, 0, 'Protein', 'vegan', team: false),
    LibraryFood('Tofu (firm)', '100 g', 144, 15, 3, 9, 'Protein', 'vegan', team: false),
    LibraryFood('Fish curry (rohu)', '1 katori · 150 g', 220, 22, 5, 12, 'Indian dishes', 'nonVeg', team: false),
    LibraryFood('Moong dal (cooked)', '1 katori · 150 g', 160, 11, 27, 1, 'Indian dishes', 'vegan', team: false),
    LibraryFood('Rajma', '1 katori · 150 g', 210, 13, 35, 2, 'Indian dishes', 'vegan', team: false),
    LibraryFood('Chana masala', '1 katori · 150 g', 240, 11, 32, 8, 'Indian dishes', 'vegan', team: false),
    LibraryFood('Poha', '1 plate · 150 g', 250, 5, 45, 6, 'Indian dishes', 'vegan', team: false),
    LibraryFood('Idli + sambar', '2 × 1 idli with sambar · 220 g', 190, 7, 36, 2, 'Indian dishes', 'veg', team: false),
    LibraryFood('Masala dosa', '1 medium · 160 g', 330, 7, 45, 13, 'Indian dishes', 'veg', team: false),
    LibraryFood('Besan chilla', '2 × 1 piece · 140 g', 240, 12, 28, 8, 'Indian dishes', 'veg', team: false),
    LibraryFood('Sprouts chaat', '1 plate · 150 g', 180, 11, 28, 3, 'Indian dishes', 'vegan', team: false),
    LibraryFood('Paneer tikka', '6 × 1 piece · 180 g', 360, 24, 10, 25, 'Indian dishes', 'veg', team: false),
    LibraryFood('Dal tadka', '1 katori · 150 g', 180, 8, 20, 8, 'Indian dishes', 'veg', team: false),
    LibraryFood('Whole wheat roti', '1 medium · 40 g', 110, 3, 20, 2, 'Carbs', 'vegan', team: false),
    LibraryFood('Brown rice (cooked)', '100 g', 112, 3, 24, 1, 'Carbs', 'vegan', team: false),
    LibraryFood('White rice (cooked)', '100 g', 130, 3, 28, 0, 'Carbs', 'vegan', team: false),
    LibraryFood('Oats', '40 g', 150, 5, 27, 3, 'Carbs', 'vegan', team: false),
    LibraryFood('Sweet potato (boiled)', '150 g', 130, 2, 30, 0, 'Carbs', 'vegan', team: false),
    LibraryFood('Multigrain toast', '2 × 1 slice · 60 g', 160, 6, 28, 2, 'Carbs', 'veg', team: false),
    LibraryFood('Curd (dahi)', '1 katori · 150 g', 90, 5, 7, 5, 'Dairy', 'veg', team: false),
    LibraryFood('Greek yogurt', '150 g', 110, 15, 6, 3, 'Dairy', 'veg', team: false),
    LibraryFood('Milk (toned)', '1 glass · 250 g', 145, 8, 12, 7, 'Dairy', 'veg', team: false),
    LibraryFood('Buttermilk (chaas)', '1 glass · 200 g', 60, 3, 5, 3, 'Dairy', 'veg', team: false),
    LibraryFood('Almonds', '10 × 1 piece · 12 g', 70, 3, 2, 6, 'Fats', 'vegan', team: false),
    LibraryFood('Peanut butter', '1 tbsp · 16 g', 95, 4, 3, 8, 'Fats', 'vegan', team: false),
    LibraryFood('Ghee', '1 tsp · 5 g', 45, 0, 0, 5, 'Fats', 'veg', team: false),
    LibraryFood('Roasted chana', '30 g', 110, 6, 18, 2, 'Protein', 'vegan', team: false),
    LibraryFood('Banana', '1 medium · 118 g', 105, 1, 27, 0, 'Fruits', 'vegan', team: false),
    LibraryFood('Apple', '1 medium · 150 g', 95, 0, 25, 0, 'Fruits', 'vegan', team: false),
    LibraryFood('Papaya', '1 bowl · 150 g', 60, 1, 15, 0, 'Fruits', 'vegan', team: false),
    LibraryFood('Mixed veg sabzi', '1 katori · 150 g', 110, 3, 12, 6, 'Veg', 'vegan', team: false),
    LibraryFood('Palak sabzi', '1 katori · 150 g', 90, 4, 8, 5, 'Veg', 'vegan', team: false),
    LibraryFood('Cucumber salad', '1 bowl · 100 g', 30, 1, 6, 0, 'Veg', 'vegan', team: false),
  ];

  static const foodCatalog = <String, PlanFood>{
    'Meera\'s protein shake': PlanFood('Meera\'s protein shake', '1 glass', 1.0, kcal: 310.1, p: 31.85, c: 30.1, f: 7.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 350.0)], per100: [88.6, 9.1, 8.6, 2.0]),
    'Coach\'s paneer bhurji': PlanFood('Coach\'s paneer bhurji', '1 plate', 1.0, kcal: 289.98, p: 21.96, c: 7.92, f: 19.08, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 180.0), FoodUnit('1 katori', 120.0)], per100: [161.1, 12.2, 4.4, 10.6]),
    'Paneer': PlanFood('Paneer', 'g', 100.0, kcal: 2.65, p: 0.18, c: 0.03, f: 0.21, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [265.0, 18.0, 3.0, 21.0]),
    'Low-fat paneer': PlanFood('Low-fat paneer', 'g', 100.0, kcal: 2.0, p: 0.2, c: 0.04, f: 0.12, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [200.0, 20.0, 4.0, 12.0]),
    'Chicken breast (cooked)': PlanFood('Chicken breast (cooked)', 'g', 100.0, kcal: 1.65, p: 0.31, c: 0.0, f: 0.04, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 120.0)], per100: [165.0, 31.0, 0.0, 4.0]),
    'Egg (whole)': PlanFood('Egg (whole)', '1 large', 1.0, kcal: 72.0, p: 6.0, c: 0.0, f: 5.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 large', 50.0)], per100: [144.0, 12.0, 0.0, 10.0]),
    'Egg whites': PlanFood('Egg whites', '1 egg white', 4.0, kcal: 16.995, p: 3.498, c: 0.264, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 egg white', 33.0)], per100: [51.5, 10.6, 0.8, 0.0]),
    'Whey protein': PlanFood('Whey protein', '1 scoop', 1.0, kcal: 120.0, p: 24.0, c: 3.008, f: 1.984, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 scoop', 32.0)], per100: [375.0, 75.0, 9.4, 6.2]),
    'Soya chunks': PlanFood('Soya chunks', 'g', 30.0, kcal: 3.467, p: 0.533, c: 0.333, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori dry', 30.0)], per100: [346.7, 53.3, 33.3, 0.0]),
    'Tofu (firm)': PlanFood('Tofu (firm)', 'g', 100.0, kcal: 1.44, p: 0.15, c: 0.03, f: 0.09, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [144.0, 15.0, 3.0, 9.0]),
    'Fish curry (rohu)': PlanFood('Fish curry (rohu)', '1 katori', 1.0, kcal: 220.05, p: 22.05, c: 4.95, f: 12.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [146.7, 14.7, 3.3, 8.0]),
    'Moong dal (cooked)': PlanFood('Moong dal (cooked)', '1 katori', 1.0, kcal: 160.05, p: 10.95, c: 27.0, f: 1.05, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [106.7, 7.3, 18.0, 0.7]),
    'Rajma': PlanFood('Rajma', '1 katori', 1.0, kcal: 210.0, p: 13.05, c: 34.95, f: 1.95, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [140.0, 8.7, 23.3, 1.3]),
    'Chana masala': PlanFood('Chana masala', '1 katori', 1.0, kcal: 240.0, p: 10.95, c: 31.95, f: 7.95, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [160.0, 7.3, 21.3, 5.3]),
    'Poha': PlanFood('Poha', '1 plate', 1.0, kcal: 250.05, p: 4.95, c: 45.0, f: 6.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], per100: [166.7, 3.3, 30.0, 4.0]),
    'Idli + sambar': PlanFood('Idli + sambar', '1 idli with sambar', 2.0, kcal: 95.04, p: 3.52, c: 18.04, f: 0.99, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 idli with sambar', 110.0)], per100: [86.4, 3.2, 16.4, 0.9]),
    'Masala dosa': PlanFood('Masala dosa', '1 medium', 1.0, kcal: 329.92, p: 7.04, c: 44.96, f: 12.96, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 160.0)], per100: [206.2, 4.4, 28.1, 8.1]),
    'Besan chilla': PlanFood('Besan chilla', '1 piece', 2.0, kcal: 119.98, p: 6.02, c: 14.0, f: 3.99, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 70.0)], per100: [171.4, 8.6, 20.0, 5.7]),
    'Sprouts chaat': PlanFood('Sprouts chaat', '1 plate', 1.0, kcal: 180.0, p: 10.95, c: 28.05, f: 3.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], per100: [120.0, 7.3, 18.7, 2.0]),
    'Paneer tikka': PlanFood('Paneer tikka', '1 piece', 6.0, kcal: 60.0, p: 3.99, c: 1.68, f: 4.17, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 30.0)], per100: [200.0, 13.3, 5.6, 13.9]),
    'Dal tadka': PlanFood('Dal tadka', '1 katori', 1.0, kcal: 180.0, p: 7.95, c: 19.95, f: 7.95, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [120.0, 5.3, 13.3, 5.3]),
    'Whole wheat roti': PlanFood('Whole wheat roti', '1 medium', 1.0, kcal: 110.0, p: 3.0, c: 20.0, f: 2.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
    'Brown rice (cooked)': PlanFood('Brown rice (cooked)', 'g', 100.0, kcal: 1.12, p: 0.03, c: 0.24, f: 0.01, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [112.0, 3.0, 24.0, 1.0]),
    'White rice (cooked)': PlanFood('White rice (cooked)', 'g', 100.0, kcal: 1.3, p: 0.03, c: 0.28, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [130.0, 3.0, 28.0, 0.0]),
    'Oats': PlanFood('Oats', 'g', 40.0, kcal: 3.75, p: 0.125, c: 0.675, f: 0.075, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 8.0), FoodUnit('1 cup', 80.0)], per100: [375.0, 12.5, 67.5, 7.5]),
    'Sweet potato (boiled)': PlanFood('Sweet potato (boiled)', 'g', 150.0, kcal: 0.867, p: 0.013, c: 0.2, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], per100: [86.7, 1.3, 20.0, 0.0]),
    'Multigrain toast': PlanFood('Multigrain toast', '1 slice', 2.0, kcal: 80.01, p: 3.0, c: 14.01, f: 0.99, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 slice', 30.0)], per100: [266.7, 10.0, 46.7, 3.3]),
    'Curd (dahi)': PlanFood('Curd (dahi)', '1 katori', 1.0, kcal: 90.0, p: 4.95, c: 7.05, f: 4.95, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [60.0, 3.3, 4.7, 3.3]),
    'Greek yogurt': PlanFood('Greek yogurt', 'g', 150.0, kcal: 0.733, p: 0.1, c: 0.04, f: 0.02, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cup', 200.0), FoodUnit('1 tbsp', 15.0)], per100: [73.3, 10.0, 4.0, 2.0]),
    'Milk (toned)': PlanFood('Milk (toned)', '1 glass', 1.0, kcal: 145.0, p: 8.0, c: 12.0, f: 7.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 250.0), FoodUnit('1 cup', 150.0)], per100: [58.0, 3.2, 4.8, 2.8]),
    'Buttermilk (chaas)': PlanFood('Buttermilk (chaas)', '1 glass', 1.0, kcal: 60.0, p: 3.0, c: 5.0, f: 3.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 200.0)], per100: [30.0, 1.5, 2.5, 1.5]),
    'Almonds': PlanFood('Almonds', '1 piece', 10.0, kcal: 6.9996, p: 0.3, c: 0.2004, f: 0.6, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 1.2), FoodUnit('1 handful', 25.0)], per100: [583.3, 25.0, 16.7, 50.0]),
    'Peanut butter': PlanFood('Peanut butter', '1 tbsp', 1.0, kcal: 95.008, p: 4.0, c: 3.008, f: 8.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 16.0), FoodUnit('1 tsp', 5.0)], per100: [593.8, 25.0, 18.8, 50.0]),
    'Ghee': PlanFood('Ghee', '1 tsp', 1.0, kcal: 45.0, p: 0.0, c: 0.0, f: 5.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tsp', 5.0), FoodUnit('1 tbsp', 15.0)], per100: [900.0, 0.0, 0.0, 100.0]),
    'Roasted chana': PlanFood('Roasted chana', 'g', 30.0, kcal: 3.667, p: 0.2, c: 0.6, f: 0.067, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 handful', 30.0), FoodUnit('1 katori', 60.0)], per100: [366.7, 20.0, 60.0, 6.7]),
    'Banana': PlanFood('Banana', '1 medium', 1.0, kcal: 105.02, p: 0.944, c: 27.022, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 118.0), FoodUnit('1 small', 90.0)], per100: [89.0, 0.8, 22.9, 0.0]),
    'Apple': PlanFood('Apple', '1 medium', 1.0, kcal: 94.95, p: 0.0, c: 25.05, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], per100: [63.3, 0.0, 16.7, 0.0]),
    'Papaya': PlanFood('Papaya', '1 bowl', 1.0, kcal: 60.0, p: 1.05, c: 15.0, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 150.0), FoodUnit('1 slice', 100.0)], per100: [40.0, 0.7, 10.0, 0.0]),
    'Mixed veg sabzi': PlanFood('Mixed veg sabzi', '1 katori', 1.0, kcal: 109.95, p: 3.0, c: 12.0, f: 6.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [73.3, 2.0, 8.0, 4.0]),
    'Palak sabzi': PlanFood('Palak sabzi', '1 katori', 1.0, kcal: 90.0, p: 4.05, c: 7.95, f: 4.95, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [60.0, 2.7, 5.3, 3.3]),
    'Cucumber salad': PlanFood('Cucumber salad', '1 bowl', 1.0, kcal: 30.0, p: 1.0, c: 6.0, f: 0.0, swaps: [], units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 100.0)], per100: [30.0, 1.0, 6.0, 0.0]),
  };

  static const exerciseLibrary = <LibraryExercise>[
    LibraryExercise('Barbell Bench Press', 'Chest', 'Barbell', 'Intermediate'),
    LibraryExercise('Incline Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate'),
    LibraryExercise('Cable Fly', 'Chest', 'Cable', 'Beginner'),
    LibraryExercise('Push-up', 'Chest', 'Bodyweight', 'Beginner'),
    LibraryExercise('Dips', 'Chest', 'Bodyweight', 'Intermediate'),
    LibraryExercise('Pull-up', 'Back', 'Bodyweight', 'Intermediate'),
    LibraryExercise('Barbell Row', 'Back', 'Barbell', 'Intermediate'),
    LibraryExercise('Seated Cable Row', 'Back', 'Cable', 'Beginner'),
    LibraryExercise('Lat Pulldown', 'Back', 'Machine', 'Beginner'),
    LibraryExercise('One-arm Dumbbell Row', 'Back', 'Dumbbell', 'Beginner'),
    LibraryExercise('Back Squat', 'Legs', 'Barbell', 'Intermediate'),
    LibraryExercise('Goblet Squat', 'Legs', 'Dumbbell', 'Beginner'),
    LibraryExercise('Romanian Deadlift', 'Hamstrings', 'Barbell', 'Intermediate'),
    LibraryExercise('Walking Lunge', 'Legs', 'Dumbbell', 'Beginner'),
    LibraryExercise('Bulgarian Split Squat', 'Legs', 'Dumbbell', 'Intermediate'),
    LibraryExercise('Leg Press', 'Legs', 'Machine', 'Beginner'),
    LibraryExercise('Hip Thrust', 'Glutes', 'Barbell', 'Intermediate'),
    LibraryExercise('Overhead Press', 'Shoulders', 'Barbell', 'Intermediate'),
    LibraryExercise('Seated DB Shoulder Press', 'Shoulders', 'Dumbbell', 'Beginner'),
    LibraryExercise('Arnold Press', 'Shoulders', 'Dumbbell', 'Intermediate'),
    LibraryExercise('Cable Lateral Raise', 'Shoulders', 'Cable', 'Beginner'),
    LibraryExercise('Face Pull', 'Rear delts', 'Cable', 'Beginner'),
    LibraryExercise('EZ Bar Curl', 'Arms', 'Barbell', 'Beginner'),
    LibraryExercise('Hammer Curl', 'Arms', 'Dumbbell', 'Beginner'),
    LibraryExercise('Tricep Rope Pushdown', 'Arms', 'Cable', 'Beginner'),
    LibraryExercise('Plank', 'Core', 'Bodyweight', 'Beginner'),
    LibraryExercise('Pallof Press', 'Core', 'Cable', 'Beginner'),
    LibraryExercise('Incline Treadmill Walk', 'Cardio', 'Machine', 'Beginner'),
    LibraryExercise('Box squat', 'Legs', 'Barbell', 'Beginner'),
    LibraryExercise('Goblet squat', 'Legs', 'Dumbbell', 'Beginner'),
    LibraryExercise('Hip thrust', 'Glutes', 'Barbell', 'Beginner'),
    LibraryExercise('Step-up', 'Legs', 'Dumbbell', 'Beginner'),
    LibraryExercise('Leg press', 'Legs', 'Machine', 'Beginner'),
    LibraryExercise('Dead bug', 'Core', 'Bodyweight', 'Beginner'),
    LibraryExercise('Calf raise', 'Legs', 'Machine', 'Beginner'),
    LibraryExercise('Glute bridge', 'Glutes', 'Bodyweight', 'Beginner'),
  ];
}
