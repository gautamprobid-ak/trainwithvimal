import '../models/client_app.dart';

/// Mock data for the client app (Riya Sharma), taken from the design scripts:
/// ClientFood / ClientFoodLog / ClientNutrition / ClientHabits / ClientCheckin /
/// ClientLibrary / ClientMore / ClientAbout.
abstract final class ClientMock {
  // ================================================================ food

  /// Daily targets: 1,650 kcal · 120 g protein · 170 g carbs · 52 g fat.
  static const targets = Macros(1650, 120, 170, 52);

  /// "Now" in the demo: Fri 9 Oct, 5:40 pm.
  static const nowMinute = 17 * 60 + 40;

  /// Week strip Mon 5 – Sun 11 Oct; today is Fri (index 4).
  static const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const todayIndex = 4;

  /// Logged totals on the past days of this week (from her food log).
  static const pastDays = [
    Macros(1610, 118, 172, 49),
    Macros(1702, 124, 181, 55),
    Macros(1580, 109, 175, 47),
    Macros(1655, 121, 169, 53),
  ];

  /// Meals eaten so far today (meal index → minute of the day).
  static const eatenAt0 = {0: 490, 1: 665, 2: 820};

  /// Extra food-log entries today.
  static const extras0 = [
    FoodEntry(id: 'tea', name: 'Green tea, no sugar', amount: '1 cup', macros: Macros.zero, mealIndex: 0, atMinute: 500, seed: true),
  ];

  /// Yesterday's extra foods (Copy yesterday).
  static const yesterday = [
    FoodEntry(id: 'chai', name: 'Masala chai', amount: '1 cup', macros: Macros(90, 3, 12, 3), mealIndex: 3, atMinute: 990),
    FoodEntry(id: 'makh', name: 'Roasted makhana', amount: '30 g', macros: Macros(105, 3, 23, 0), mealIndex: 3, atMinute: 1035),
  ];

  /// "Made for you" sheet on the meal plan.
  static const madeForYou = [
    ('Breakfast', 'Whey protein added in Sep for more protein'),
    ('Lunch', 'Brown rice 120 g, down from 150 g'),
    ('Dinner', 'Tofu instead of paneer, so paneer is once a day'),
    ('Diet', 'Vegetarian, no eggs'),
  ];

  static const recentFoods = ['Oats', 'Whey protein', 'Greek yogurt', 'Paneer', 'Brown rice (cooked)', 'Sprouts chaat', 'Tofu (firm)', 'Whole wheat roti'];
  static const searchTries = ['paneer', 'dal', 'roti', 'rajma'];
  static const offPlanReasons = ['Ate out', 'Party', 'Travelling'];

  static const myFoods0 = [
    Food(
      name: 'Mom’s besan chilla',
      unit: '1 piece',
      qty: 2,
      per: Macros(130, 6, 14, 5),
      units: [ServingUnit('g', 1), ServingUnit('1 piece', 70)],
      serving: '2 pieces',
      mine: true,
    ),
  ];

  /// Custom food sheet demo values.
  static const customFoodName = 'Mom’s veg upma';
  static const customFoodServing = '1 katori';
  static const customFood0 = [210, 6, 32, 7];

  static const plan = <PlanMeal>[
    PlanMeal('Breakfast', '8:00 am', [
      Food(name: 'Oats', unit: 'g', qty: 60.0, per: Macros(3.75, 0.125, 0.675, 0.075), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 tbsp', 8.0), ServingUnit('1 cup', 80.0)], alts: [
        Food(name: 'Poha', unit: '1 plate', qty: 1.0, per: Macros(250.05, 4.95, 45.0, 6.0), units: [ServingUnit('g', 1.0), ServingUnit('1 plate', 150.0), ServingUnit('1 katori', 100.0)], match: 82),
      ]),
      Food(name: 'Whey protein', unit: '1 scoop', qty: 1.0, per: Macros(120.0, 24.0, 3.008, 1.984), units: [ServingUnit('g', 1.0), ServingUnit('1 scoop', 32.0)], alts: [
        Food(name: 'Greek yogurt', unit: 'g', qty: 225.0, per: Macros(0.733, 0.1, 0.04, 0.02), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cup', 200.0), ServingUnit('1 tbsp', 15.0)], match: 74),
      ]),
      Food(name: 'Banana', unit: '1 medium', qty: 1.0, per: Macros(105.02, 0.944, 27.022, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 118.0), ServingUnit('1 small', 90.0)], alts: [
        Food(name: 'Apple', unit: '1 medium', qty: 1.0, per: Macros(94.95, 0.0, 25.05, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 150.0)], match: 91),
      ]),
    ]),
    PlanMeal('Snack', '11:00 am', [
      Food(name: 'Greek yogurt', unit: 'g', qty: 150.0, per: Macros(0.733, 0.1, 0.04, 0.02), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cup', 200.0), ServingUnit('1 tbsp', 15.0)], alts: [
        Food(name: 'Curd (dahi)', unit: '1 katori', qty: 2.0, per: Macros(90.0, 4.95, 7.05, 4.95), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], match: 70),
      ]),
      Food(name: 'Almonds', unit: '1 piece', qty: 10.0, per: Macros(6.9996, 0.3, 0.2004, 0.6), units: [ServingUnit('g', 1.0), ServingUnit('1 piece', 1.2), ServingUnit('1 handful', 25.0)], alts: [
        Food(name: 'Peanut butter', unit: '1 tbsp', qty: 1.0, per: Macros(95.008, 4.0, 3.008, 8.0), units: [ServingUnit('g', 1.0), ServingUnit('1 tbsp', 16.0), ServingUnit('1 tsp', 5.0)], match: 88),
      ]),
    ]),
    PlanMeal('Lunch', '1:30 pm', [
      Food(name: 'Paneer', unit: 'g', qty: 100.0, per: Macros(2.65, 0.18, 0.03, 0.21), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], alts: [
        Food(name: 'Tofu (firm)', unit: 'g', qty: 180.0, per: Macros(1.44, 0.15, 0.03, 0.09), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], match: 93),
        Food(name: 'Low-fat paneer', unit: 'g', qty: 130.0, per: Macros(2.0, 0.2, 0.04, 0.12), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], match: 90),
      ]),
      Food(name: 'Brown rice (cooked)', unit: 'g', qty: 120.0, per: Macros(1.12, 0.03, 0.24, 0.01), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], alts: [
        Food(name: 'Whole wheat roti', unit: '1 medium', qty: 1.0, per: Macros(110.0, 3.0, 20.0, 2.0), step: 0.5, units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 40.0), ServingUnit('1 small', 30.0)], match: 88),
      ]),
      Food(name: 'Cucumber salad', unit: '1 bowl', qty: 1.0, per: Macros(30.0, 1.0, 6.0, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 bowl', 100.0)]),
    ]),
    PlanMeal('Snack', '5:00 pm', [
      Food(name: 'Sprouts chaat', unit: '1 plate', qty: 1.0, per: Macros(180.0, 10.95, 28.05, 3.0), units: [ServingUnit('g', 1.0), ServingUnit('1 plate', 150.0), ServingUnit('1 katori', 100.0)], alts: [
        Food(name: 'Roasted chana', unit: 'g', qty: 45.0, per: Macros(3.667, 0.2, 0.6, 0.067), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 handful', 30.0), ServingUnit('1 katori', 60.0)], match: 84),
      ]),
    ]),
    PlanMeal('Dinner', '8:30 pm', [
      Food(name: 'Tofu (firm)', unit: 'g', qty: 150.0, per: Macros(1.44, 0.15, 0.03, 0.09), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], alts: [
        Food(name: 'Paneer', unit: 'g', qty: 80.0, per: Macros(2.65, 0.18, 0.03, 0.21), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], match: 93),
      ]),
      Food(name: 'Whole wheat roti', unit: '1 medium', qty: 2.0, per: Macros(110.0, 3.0, 20.0, 2.0), step: 0.5, units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 40.0), ServingUnit('1 small', 30.0)], alts: [
        Food(name: 'Brown rice (cooked)', unit: 'g', qty: 200.0, per: Macros(1.12, 0.03, 0.24, 0.01), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], match: 88),
      ]),
    ]),
  ];

  static const catalog = <Food>[
    Food(name: 'Paneer', unit: 'g', qty: 100.0, per: Macros(2.65, 0.18, 0.03, 0.21), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], group: 'Dairy', serving: '100 g'),
    Food(name: 'Low-fat paneer', unit: 'g', qty: 100.0, per: Macros(2.0, 0.2, 0.04, 0.12), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], group: 'Protein', serving: '100 g'),
    Food(name: 'Chicken breast (cooked)', unit: 'g', qty: 100.0, per: Macros(1.65, 0.31, 0.0, 0.04), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 piece', 120.0)], group: 'Protein', serving: '100 g'),
    Food(name: 'Egg (whole)', unit: '1 large', qty: 1.0, per: Macros(72.0, 6.0, 0.0, 5.0), units: [ServingUnit('g', 1.0), ServingUnit('1 large', 50.0)], group: 'Protein', serving: '1 large · 50 g'),
    Food(name: 'Egg whites', unit: '1 egg white', qty: 4.0, per: Macros(16.995, 3.498, 0.264, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 egg white', 33.0)], group: 'Protein', serving: '4 × 1 egg white · 132 g'),
    Food(name: 'Whey protein', unit: '1 scoop', qty: 1.0, per: Macros(120.0, 24.0, 3.008, 1.984), units: [ServingUnit('g', 1.0), ServingUnit('1 scoop', 32.0)], group: 'Protein', serving: '1 scoop · 32 g'),
    Food(name: 'Soya chunks', unit: 'g', qty: 30.0, per: Macros(3.467, 0.533, 0.333, 0.0), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 katori dry', 30.0)], group: 'Protein', serving: '30 g'),
    Food(name: 'Tofu (firm)', unit: 'g', qty: 100.0, per: Macros(1.44, 0.15, 0.03, 0.09), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cube', 25.0)], group: 'Protein', serving: '100 g'),
    Food(name: 'Fish curry (rohu)', unit: '1 katori', qty: 1.0, per: Macros(220.05, 22.05, 4.95, 12.0), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0)], group: 'Indian dishes', serving: '1 katori · 150 g'),
    Food(name: 'Moong dal (cooked)', unit: '1 katori', qty: 1.0, per: Macros(160.05, 10.95, 27.0, 1.05), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], group: 'Indian dishes', serving: '1 katori · 150 g'),
    Food(name: 'Rajma', unit: '1 katori', qty: 1.0, per: Macros(210.0, 13.05, 34.95, 1.95), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0)], group: 'Indian dishes', serving: '1 katori · 150 g'),
    Food(name: 'Chana masala', unit: '1 katori', qty: 1.0, per: Macros(240.0, 10.95, 31.95, 7.95), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0)], group: 'Indian dishes', serving: '1 katori · 150 g'),
    Food(name: 'Poha', unit: '1 plate', qty: 1.0, per: Macros(250.05, 4.95, 45.0, 6.0), units: [ServingUnit('g', 1.0), ServingUnit('1 plate', 150.0), ServingUnit('1 katori', 100.0)], group: 'Indian dishes', serving: '1 plate · 150 g'),
    Food(name: 'Idli + sambar', unit: '1 idli with sambar', qty: 2.0, per: Macros(95.04, 3.52, 18.04, 0.99), units: [ServingUnit('g', 1.0), ServingUnit('1 idli with sambar', 110.0)], group: 'Indian dishes', serving: '2 × 1 idli with sambar · 220 g'),
    Food(name: 'Masala dosa', unit: '1 medium', qty: 1.0, per: Macros(329.92, 7.04, 44.96, 12.96), units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 160.0)], group: 'Indian dishes', serving: '1 medium · 160 g'),
    Food(name: 'Besan chilla', unit: '1 piece', qty: 2.0, per: Macros(119.98, 6.02, 14.0, 3.99), units: [ServingUnit('g', 1.0), ServingUnit('1 piece', 70.0)], group: 'Indian dishes', serving: '2 × 1 piece · 140 g'),
    Food(name: 'Sprouts chaat', unit: '1 plate', qty: 1.0, per: Macros(180.0, 10.95, 28.05, 3.0), units: [ServingUnit('g', 1.0), ServingUnit('1 plate', 150.0), ServingUnit('1 katori', 100.0)], group: 'Indian dishes', serving: '1 plate · 150 g'),
    Food(name: 'Paneer tikka', unit: '1 piece', qty: 6.0, per: Macros(60.0, 3.99, 1.68, 4.17), units: [ServingUnit('g', 1.0), ServingUnit('1 piece', 30.0)], group: 'Indian dishes', serving: '6 × 1 piece · 180 g'),
    Food(name: 'Dal tadka', unit: '1 katori', qty: 1.0, per: Macros(180.0, 7.95, 19.95, 7.95), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0)], group: 'Indian dishes', serving: '1 katori · 150 g'),
    Food(name: 'Whole wheat roti', unit: '1 medium', qty: 1.0, per: Macros(110.0, 3.0, 20.0, 2.0), step: 0.5, units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 40.0), ServingUnit('1 small', 30.0)], group: 'Carbs', serving: '1 medium · 40 g'),
    Food(name: 'Brown rice (cooked)', unit: 'g', qty: 100.0, per: Macros(1.12, 0.03, 0.24, 0.01), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], group: 'Carbs', serving: '100 g'),
    Food(name: 'White rice (cooked)', unit: 'g', qty: 100.0, per: Macros(1.3, 0.03, 0.28, 0.0), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], group: 'Carbs', serving: '100 g'),
    Food(name: 'Oats', unit: 'g', qty: 40.0, per: Macros(3.75, 0.125, 0.675, 0.075), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 tbsp', 8.0), ServingUnit('1 cup', 80.0)], group: 'Carbs', serving: '40 g'),
    Food(name: 'Sweet potato (boiled)', unit: 'g', qty: 150.0, per: Macros(0.867, 0.013, 0.2, 0.0), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 150.0)], group: 'Carbs', serving: '150 g'),
    Food(name: 'Multigrain toast', unit: '1 slice', qty: 2.0, per: Macros(80.01, 3.0, 14.01, 0.99), units: [ServingUnit('g', 1.0), ServingUnit('1 slice', 30.0)], group: 'Carbs', serving: '2 × 1 slice · 60 g'),
    Food(name: 'Curd (dahi)', unit: '1 katori', qty: 1.0, per: Macros(90.0, 4.95, 7.05, 4.95), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0), ServingUnit('1 tbsp', 15.0)], group: 'Dairy', serving: '1 katori · 150 g'),
    Food(name: 'Greek yogurt', unit: 'g', qty: 150.0, per: Macros(0.733, 0.1, 0.04, 0.02), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 cup', 200.0), ServingUnit('1 tbsp', 15.0)], group: 'Dairy', serving: '150 g'),
    Food(name: 'Milk (toned)', unit: '1 glass', qty: 1.0, per: Macros(145.0, 8.0, 12.0, 7.0), units: [ServingUnit('g', 1.0), ServingUnit('1 glass', 250.0), ServingUnit('1 cup', 150.0)], group: 'Dairy', serving: '1 glass · 250 g'),
    Food(name: 'Buttermilk (chaas)', unit: '1 glass', qty: 1.0, per: Macros(60.0, 3.0, 5.0, 3.0), units: [ServingUnit('g', 1.0), ServingUnit('1 glass', 200.0)], group: 'Dairy', serving: '1 glass · 200 g'),
    Food(name: 'Almonds', unit: '1 piece', qty: 10.0, per: Macros(6.9996, 0.3, 0.2004, 0.6), units: [ServingUnit('g', 1.0), ServingUnit('1 piece', 1.2), ServingUnit('1 handful', 25.0)], group: 'Fats', serving: '10 × 1 piece · 12 g'),
    Food(name: 'Peanut butter', unit: '1 tbsp', qty: 1.0, per: Macros(95.008, 4.0, 3.008, 8.0), units: [ServingUnit('g', 1.0), ServingUnit('1 tbsp', 16.0), ServingUnit('1 tsp', 5.0)], group: 'Fats', serving: '1 tbsp · 16 g'),
    Food(name: 'Ghee', unit: '1 tsp', qty: 1.0, per: Macros(45.0, 0.0, 0.0, 5.0), units: [ServingUnit('g', 1.0), ServingUnit('1 tsp', 5.0), ServingUnit('1 tbsp', 15.0)], group: 'Fats', serving: '1 tsp · 5 g'),
    Food(name: 'Roasted chana', unit: 'g', qty: 30.0, per: Macros(3.667, 0.2, 0.6, 0.067), step: 10.0, units: [ServingUnit('g', 1.0), ServingUnit('1 handful', 30.0), ServingUnit('1 katori', 60.0)], group: 'Protein', serving: '30 g'),
    Food(name: 'Banana', unit: '1 medium', qty: 1.0, per: Macros(105.02, 0.944, 27.022, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 118.0), ServingUnit('1 small', 90.0)], group: 'Fruits', serving: '1 medium · 118 g'),
    Food(name: 'Apple', unit: '1 medium', qty: 1.0, per: Macros(94.95, 0.0, 25.05, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 medium', 150.0)], group: 'Fruits', serving: '1 medium · 150 g'),
    Food(name: 'Papaya', unit: '1 bowl', qty: 1.0, per: Macros(60.0, 1.05, 15.0, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 bowl', 150.0), ServingUnit('1 slice', 100.0)], group: 'Fruits', serving: '1 bowl · 150 g'),
    Food(name: 'Mixed veg sabzi', unit: '1 katori', qty: 1.0, per: Macros(109.95, 3.0, 12.0, 6.0), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0)], group: 'Veg', serving: '1 katori · 150 g'),
    Food(name: 'Palak sabzi', unit: '1 katori', qty: 1.0, per: Macros(90.0, 4.05, 7.95, 4.95), units: [ServingUnit('g', 1.0), ServingUnit('1 katori', 150.0)], group: 'Veg', serving: '1 katori · 150 g'),
    Food(name: 'Cucumber salad', unit: '1 bowl', qty: 1.0, per: Macros(30.0, 1.0, 6.0, 0.0), units: [ServingUnit('g', 1.0), ServingUnit('1 bowl', 100.0)], group: 'Veg', serving: '1 bowl · 100 g'),
  ];

  // ================================================================ habits

  /// Days 0 = Sat 3 Oct … 6 = Fri 9 Oct (today) … 8 = Sun 11 Oct.
  static const habitDayNames = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const habitDates = [3, 4, 5, 6, 7, 8, 9, 10, 11];
  static const habitToday = 6;

  static const steps0 = <int?>[8400, 11300, 8020, 8600, 5110, 9240, 6240, null, null];
  static const water0 = <int?>[3000, 3000, 3200, 3000, 3000, 3200, 1500, null, null];
  static const sleep0 = <int?>[390, 480, 420, 390, 360, 450, 440, null, null];

  static const habits = [
    HabitDef(id: 'steps', short: 'Steps', name: 'Walk 8,000 steps', goal: 8000, target: '8,000 steps a day', how: 'Every day', baseStreak: 0, best: 19, week: '8,000 a day'),
    HabitDef(id: 'water', short: 'Water', name: 'Drink 3 L water', goal: 3000, target: '3 L a day (12 glasses)', how: 'Every day', baseStreak: 3, best: 24, week: '3 L a day'),
    HabitDef(id: 'sleep', short: 'Sleep', name: 'Sleep 7 hours', goal: 420, target: '7 hours a night', how: 'Every night', baseStreak: 0, best: 9, week: '7 h a night'),
  ];

  static const supplements = [
    Supplement(name: 'Whey protein', dose: '1 scoop (30 g) in water', night: false, how: 'In water, with breakfast', stock: 12, unit: 'scoops'),
    Supplement(name: 'Vitamin D3', dose: '1 tablet with breakfast', night: false, how: 'With breakfast', stock: 20, unit: 'tablets'),
    Supplement(name: 'Magnesium', dose: '1 tablet, 30 min before bed', night: true, how: '30 min before bed', stock: 30, unit: 'tablets', note: 'Added by Aman for sleep'),
  ];

  /// Supplements taken per day (rows = days 0…8, columns = supplements).
  static const taken0 = [
    [true, true, true], [true, true, true], [true, true, true], [true, false, false], [true, true, false],
    [true, true, true], [true, true, false], [false, false, false], [false, false, false],
  ];
  static const supplementTimes = ['8:10 am', '10:40 pm'];

  // ================================================================ check-ins

  static const faces = ['Very low', 'Low', 'Okay', 'Good', 'Great'];
  static const hunger = ['Very low', 'Low', 'Normal', 'High', 'Very high'];
  static const soreness = ['Very sore', 'Sore', 'Some', 'Light', 'None'];
  static const sleepOptions = ['5 h', '6 h', '6.5 h', '7 h', '7.5 h', '8 h', '9 h'];
  static const dailyNoteChips = ['Felt strong today', 'Knee a bit sore', 'Slept late', 'Busy day at work'];
  static const weeklyNoteChips = ['Office travel next week, Tue to Thu', 'Knee felt better on box squats', 'Can I get more dinner ideas?', 'Nothing this week'];
  static const weekScale = ['Very hard', 'Hard', 'Okay', 'Good', 'Great'];
  static const kneeScale = ['Very sore', 'Sore', 'Some pain', 'Mild', 'No pain'];
  static const mealPlanOptions = ['Yes, all week', 'Mostly, ate out once or twice', 'No, it was a hard week'];
  static const weeklyQuestionChips = ['Weight', 'Your week', 'Meal plan', 'Knee', '3 photos', 'Notes'];

  static const weeklyCheckins = [
    WeeklyCheckin(
      title: 'Week 6',
      date: 'Sun, 4 Oct, 6:15 pm',
      summary: 'Sun, 4 Oct · 71.6 kg · 3 photos',
      pill: 'Sent',
      waiting: true,
      kpis: [('71.6 kg', 'Weight'), ('−0.7 kg', 'Change'), ('4 / 4', 'Workouts'), ('86%', 'Meals on plan')],
      answers: [
        ('Body weight', '71.6 kg'),
        ('How was your week?', '4 / 5 · Good'),
        ('Did you follow the meal plan?', 'Mostly, ate out once'),
        ('How does your right knee feel?', '3 / 5, better on box squats'),
        ('Progress photos', '3 photos'),
        ('Anything your coach should know?', 'Office travel next week, Tue to Thu'),
      ],
      photoDate: '4 Oct',
    ),
    WeeklyCheckin(
      title: 'Week 5',
      date: 'Sun, 27 Sep, 7:40 pm',
      summary: 'Sun, 27 Sep · 72.3 kg · 3 photos',
      pill: 'Replied',
      reply: 'Great progress on the waist. Keep the steps up.',
      replyWhen: 'Fri, 9 Oct',
      kpis: [('72.3 kg', 'Weight'), ('−1.1 kg', 'In 2 weeks'), ('4 / 4', 'Workouts'), ('80%', 'Meals on plan')],
      answers: [
        ('Body weight', '72.3 kg'),
        ('How was your week?', '4 / 5 · Good'),
        ('Did you follow the meal plan?', 'Yes, all week'),
        ('How does your right knee feel?', '2 / 5, sore after lunges'),
        ('Progress photos', '3 photos'),
        ('Anything your coach should know?', 'Can I swap lunges for something easier on the knee?'),
      ],
      photoDate: '27 Sep',
    ),
    WeeklyCheckin(title: 'Week 4', date: 'Sun, 20 Sep', summary: 'Sun, 20 Sep · not sent', pill: 'Missed', missed: true),
    WeeklyCheckin(
      title: 'Week 3',
      date: 'Sun, 13 Sep, 7:05 pm',
      summary: 'Sun, 13 Sep · 73.4 kg · 3 photos',
      pill: 'Reviewed',
      reviewed: true,
      kpis: [('73.4 kg', 'Weight'), ('−0.7 kg', 'Change'), ('3 / 4', 'Workouts'), ('78%', 'Meals on plan')],
      answers: [
        ('Body weight', '73.4 kg'),
        ('How was your week?', '3 / 5 · Okay'),
        ('Did you follow the meal plan?', 'Mostly, ate out once or twice'),
        ('How does your right knee feel?', '3 / 5, some pain'),
        ('Progress photos', '3 photos'),
        ('Anything your coach should know?', '—'),
      ],
      photoDate: '13 Sep',
    ),
  ];

  static const dailyCheckins = [
    DailyCheckin(title: 'Thu, 8 Oct', summary: '7.5 h sleep · energy Good · “Felt strong today”', at: '8:05 am',
        answers: ['7.5 h', 'Good', 'Good', 'Normal', 'Light', '9,240', '3.2 L', '71.5 kg', 'Felt strong today']),
    DailyCheckin(title: 'Wed, 7 Oct', summary: '6 h sleep · energy Low · “Late office, ate out”', at: '8:20 am',
        answers: ['6 h', 'Low', 'Okay', 'High', 'Some', '5,110', '3 L', '71.7 kg', 'Late office, ate out']),
    DailyCheckin(title: 'Tue, 6 Oct', summary: 'Not sent · reminder went at 9:00 pm', missed: true),
    DailyCheckin(title: 'Mon, 5 Oct', summary: '7 h sleep · energy Good', at: '7:55 am',
        answers: ['7 h', 'Good', 'Good', 'Normal', 'Light', '8,020', '3.2 L', '71.8 kg', '—']),
    DailyCheckin(title: 'Sun, 4 Oct', summary: '8 h sleep · energy Great', at: '8:30 am',
        answers: ['8 h', 'Great', 'Great', 'Low', 'None', '11,300', '3 L', '71.6 kg', '—']),
    DailyCheckin(title: 'Thu, 1 Oct', summary: '6.5 h sleep · energy Okay · “Right knee sore”', at: '7:50 am',
        reply: 'Rest the knee today, walk 30 min.', replyWhen: 'Thu, 1 Oct, 10:15 am',
        answers: ['6.5 h', 'Okay', 'Okay', 'Normal', 'Sore', '7,100', '2.8 L', '72.0 kg', 'Right knee sore']),
  ];

  // ================================================================ library

  static const library = [
    LibraryItem(
      id: 'box',
      title: 'Box squat: how to',
      kind: LibraryKind.video,
      length: '3:05',
      duration: 185,
      source: 'Assigned by Aman · 28 Sep',
      tone: 3,
      by: 'Aman Verma',
      note: 'Use box squats on Saturday until the knee feels fine. Sit back to the box, pause for a second, then drive up.',
      description: 'How to set the box height, sit back with control and stand up without bouncing. Good for squatting with a sore knee.',
      chapters: [(0, 'Setting the box height'), (48, 'Sitting back'), (115, 'Driving up'), (150, 'Common mistakes')],
    ),
    LibraryItem(
      id: 'eat',
      title: 'Eating out on a fat loss plan',
      kind: LibraryKind.pdf,
      length: '6 pages',
      source: 'Assigned by Aman · 1 Oct',
      tone: 1,
      by: 'Vimal',
      file: 'eating-out-on-a-fat-loss-plan.pdf',
      note: 'Read this before Saturday’s family dinner. Page 4 has orders that fit your plan.',
      description: 'Pick grilled over fried, ask for dressing on the side, and start with a protein. Here are 12 orders that fit your plan.',
      pages: [
        ('Eating out is fine', 'One meal out does not undo a week. Plan it, enjoy it, log it.'),
        ('Rules of thumb', 'Protein first, grilled over fried, sauces on the side.'),
        ('Reading an Indian menu', 'Tandoori, tikka and dal are safe picks. Watch for makhani and malai.'),
        ('12 orders that fit your plan', 'Paneer tikka, dal tadka with 1 roti, grilled fish with salad and more.'),
        ('Drinks and desserts', 'Chaas or fresh lime soda without sugar. Share one dessert.'),
        ('Back to plan', 'Log it honestly and go back to your plan at the next meal.'),
      ],
    ),
    LibraryItem(
      id: 'upa',
      title: 'Upper A walkthrough',
      kind: LibraryKind.video,
      length: '6:20',
      duration: 380,
      source: 'From Fat Loss Phase 1',
      tone: 4,
      by: 'Vimal',
      note: '',
      description: 'Every exercise of Upper A, with the setup and the one cue that matters most for each.',
      chapters: [(0, 'Warm-up sets'), (100, 'Bench press'), (210, 'Rows and pulldowns'), (310, 'Arms finisher')],
    ),
    LibraryItem(
      id: 'leg',
      title: 'How to warm up for leg day',
      kind: LibraryKind.article,
      length: '4 min read',
      source: 'From Fat Loss Phase 1',
      tone: 2,
      by: 'Vimal',
      note: '',
      description: 'Ten minutes that make your squats feel better and keep the knees happy.',
      body: [
        'Start with 5 minutes of easy cardio: bike, incline walk or skipping. You want to be warm, not tired.',
        'Open the hips: 10 leg swings each way, 8 hip circles and 30 seconds in a deep squat hold.',
        'Wake up the glutes with 2 sets of 15 glute bridges and 10 banded side steps each way.',
        'Finish with 2 light sets of your first exercise before the working weight.',
      ],
    ),
    LibraryItem(
      id: 'macro',
      title: 'Macro cheat sheet',
      kind: LibraryKind.pdf,
      length: '2 pages',
      source: 'Assigned by Aman · 10 Aug',
      tone: 3,
      by: 'Aman Verma',
      file: 'macro-cheat-sheet.pdf',
      note: 'Keep this handy for grocery runs. Your targets: 120 g protein, 170 g carbs, 52 g fat.',
      description: 'Protein: 1.6 to 2 g per kg of body weight. One palm of paneer, chicken, fish or tofu is about 25 g.',
      pages: [
        ('Your daily targets', '1,650 kcal · 120 g protein · 170 g carbs · 52 g fat.'),
        ('Protein in common foods', 'Paneer 100 g: 18 g · Tofu 100 g: 15 g · Greek yogurt 150 g: 15 g.'),
      ],
    ),
    LibraryItem(
      id: 'snacks',
      title: '10 veg snacks under 200 kcal',
      kind: LibraryKind.image,
      length: 'PNG',
      source: 'From your meal plan',
      tone: 2,
      by: 'Sahil Kapoor',
      note: 'Pick from this list for your 5 pm snack when you are bored of sprouts.',
      description: 'Quick vegetarian snacks with their calories. All of them fit your evening snack.',
    ),
    LibraryItem(
      id: 'welcome',
      title: 'Welcome to Train With Vimal',
      kind: LibraryKind.article,
      length: '2 min read',
      source: 'For all clients · 12 Jan',
      tone: 1,
      by: 'Vimal',
      note: '',
      description: 'How the app works, how to log, and how to reach your coach.',
      body: [
        'Your coach builds your training and meal plan. You will find both in the app every day.',
        'Log your workouts and food as you go. It takes a few seconds and helps your coach adjust your plan.',
        'Every Sunday you send a weekly check-in with photos. Your coach replies within a day.',
      ],
    ),
    LibraryItem(
      id: 'checkins',
      title: 'How check-ins work',
      kind: LibraryKind.pdf,
      length: '3 pages',
      source: 'For all clients · 12 Jan',
      tone: 4,
      by: 'Vimal',
      file: 'how-check-ins-work.pdf',
      note: '',
      description: 'Daily check-ins take 30 seconds. Weekly check-ins go to your coach every Sunday.',
      pages: [
        ('Daily check-in', 'Sleep, energy, hunger and steps. 30 seconds a day.'),
        ('Weekly check-in', 'Weight, waist, how the week went. Sent every Sunday.'),
        ('Progress photos', 'Front, side and back, same light and same time of day.'),
      ],
    ),
  ];

  static const libraryRead0 = ['box', 'upa', 'leg', 'macro', 'welcome', 'checkins'];
  static const libraryDone0 = ['leg', 'welcome', 'checkins'];
  static const librarySaved0 = ['macro'];
  static const libraryTries = ['squat', 'eating out', 'protein', 'check-in'];

  static const vegSnacks = [
    ('Roasted chana · 45 g', '165 kcal'),
    ('Sprouts chaat · 1 plate', '180 kcal'),
    ('Makhana · 30 g', '105 kcal'),
    ('Greek yogurt · 150 g', '110 kcal'),
    ('Apple + 10 almonds', '165 kcal'),
    ('Moong chilla · 1', '150 kcal'),
    ('Paneer tikka · 60 g', '170 kcal'),
    ('Chaas + chana · 20 g', '140 kcal'),
    ('Fruit chaat · 1 bowl', '120 kcal'),
    ('Corn chaat · 1 bowl', '150 kcal'),
  ];

  // ================================================================ more

  static const coachRows = [
    ('Next session', 'Today, 6:30 pm · Gym floor · 60 min'),
    ('Training days', 'Mon, Tue, Thu, Fri, Sat'),
    ('Weekly check-in', 'Every Sunday, 6:00 pm'),
    ('Next check-in', 'Sun, 11 Oct · week 7'),
    ('Check-in reply', 'Aman replies by Monday evening'),
    ('Program', 'Fat Loss Phase 1 · week 6 of 12'),
    ('Meal plan', '1,650 kcal · vegetarian'),
    ('Plan ends', 'Mon, 23 Nov'),
  ];

  /// Profile fields with the quick suggestions of the Edit profile sheet.
  static const profileFields = [
    ('name', 'Full name', ['Riya Sharma', 'Riya S. Sharma']),
    ('email', 'Email', ['riya.sharma@email.com', 'riya.s@gmail.com']),
    ('phone', 'Mobile', ['98201 11234', '98190 55621']),
    ('city', 'City', ['Mumbai', 'Thane', 'Navi Mumbai']),
    ('dob', 'Date of birth', ['14 Mar 1997']),
  ];
  static const profile0 = {'name': 'Riya Sharma', 'email': 'riya.sharma@email.com', 'phone': '98201 11234', 'city': 'Mumbai', 'dob': '14 Mar 1997'};

  static const notifications = [
    ClientNotification('n1', 'form', 'amber', 'Aman replied to your check-in',
        'Week 6: “Knee looks better. Keep box squats on Saturday and push steps to 9,000.”', '2 h ago', 'Open check-ins', '/c/more/checkins'),
    ClientNotification('n2', 'cal', 'blue', 'Session today at 6:30 pm', 'With Aman on the gym floor · 60 min · Cardio and core', 'Today, 8:00 am', 'Open training', '/c/train'),
    ClientNotification('n3', 'star', 'green', 'New personal best', 'Bench press 45 kg × 6 on Upper A', 'Mon, 5 Oct', 'See progress', '/c/progress'),
    ClientNotification('n4', 'dumb', 'blue', 'Plan updated', 'Aman changed Lower B for your knee: box squats instead of deep squats.', 'Tue, 6 Oct', 'Open training', '/c/train'),
    ClientNotification('n5', 'water', 'blue', 'Water reminder', 'You were 1.5 L behind for the day at 4:00 pm.', 'Wed, 7 Oct', 'Open habits', '/c/more/habits'),
    ClientNotification('n6', 'form', 'amber', 'Check-in reminder', 'Your week 6 check-in is due today at 6:00 pm.', 'Sun, 4 Oct', 'Open check-ins', '/c/more/checkins'),
    ClientNotification('n7', 'food', 'green', 'Meal plan updated', 'Tofu instead of paneer at dinner, so paneer is once a day.', 'Mon, 28 Sep', 'Open meal plan', '/c/food'),
  ];
  static const notificationsRead0 = ['n4', 'n5', 'n6', 'n7'];

  static const reminderSettings = [
    ReminderSetting('workout', 'dumb', 'blue', 'Workout reminders', '1 hour before your session or planned workout'),
    ReminderSetting('meals', 'food', 'green', 'Meal reminders', 'At each meal time in your plan'),
    ReminderSetting('water', 'water', 'blue', 'Water reminders', 'Every 2 hours when you are behind'),
    ReminderSetting('supps', 'pill', 'purple', 'Supplement reminders', 'Whey and D3 in the morning, magnesium at night'),
    ReminderSetting('habits', 'steps', 'green', 'Habit reminders', 'Steps and sleep nudges in the evening'),
    ReminderSetting('checkin', 'form', 'amber', 'Check-in reminders', 'Sunday 6:00 pm, again on Monday if not sent'),
    ReminderSetting('coach', 'user', 'gray', 'Coach updates', 'Aman replies or changes your plan'),
    ReminderSetting('progress', 'star', 'amber', 'Progress and personal bests', 'New bests, streaks and milestones'),
  ];
  static const reminders0 = {'workout': true, 'meals': true, 'water': true, 'supps': true, 'habits': false, 'checkin': true, 'coach': true, 'progress': true};

  static const faq = [
    ('How do I change my workout or meal plan?', 'Your plan is set by Aman. Tell him what you want changed in your weekly check-in, or talk to him at your next session.'),
    ('Why did I not get a reminder?', 'Check Notification settings and quiet hours. Notifications must also be allowed for the app in your phone settings.'),
    ('How do I switch kg to lb?', 'Open Units & preferences on the More page. Aman still sees your numbers in the units he uses.'),
    ('What happens when my program ends?', 'Fat Loss Phase 1 ends on Mon, 23 Nov. Aman sets your next plan before that and it shows up in Train.'),
  ];
  static const reportCategories = ['Something is broken', 'Wrong numbers', 'An idea'];

  static const activityDays = ['Today · Fri, 9 Oct', 'Yesterday · Thu, 8 Oct', 'Wed, 7 Oct', 'Tue, 6 Oct', 'Mon, 5 Oct', 'Sun, 4 Oct'];
  static const activityFilters = ['All', 'Training', 'Food', 'Check-ins', 'Habits', 'Account'];
  static const activity = [
    ActivityItem(day: 0, time: '1:40 pm', kind: 'Food', icon: 'food', tone: 'green', title: 'Logged lunch', subtitle: 'Paneer, brown rice, cucumber salad',
        rows: [('Meals today', '3 of 5 logged'), ('Lunch', 'Paneer 100 g · brown rice 120 g · salad'), ('Calories so far', 'About 1,000 kcal')], actionLabel: 'Open meal plan', route: '/c/food'),
    ActivityItem(day: 0, time: '9:05 am', kind: 'Habits', icon: 'pill', tone: 'purple', title: 'Took whey protein and vitamin D3', subtitle: '2 of 3 supplements today',
        rows: [('Whey protein', '1 scoop · morning'), ('Vitamin D3', '1 tablet · morning'), ('Still to take', 'Magnesium at night')], actionLabel: 'Open habits', route: '/c/more/habits'),
    ActivityItem(day: 0, time: '7:30 am', kind: 'Check-ins', icon: 'scale', tone: 'amber', title: 'Logged weight', subtitle: '71.2 kg · 0.4 kg down since Sunday',
        rows: [('Weight', '71.2 kg'), ('Change', '0.4 kg down since Sun, 4 Oct'), ('Since start', '6.8 kg down')], actionLabel: 'See progress', route: '/c/progress'),
    ActivityItem(day: 1, time: '9:30 pm', kind: 'Habits', icon: 'steps', tone: 'green', title: 'Walked 8,450 steps', subtitle: 'Step goal met',
        rows: [('Steps', '8,450 of 8,000'), ('Streak', '4 days in a row')], actionLabel: 'Open habits', route: '/c/more/habits'),
    ActivityItem(day: 1, time: '7:20 pm', kind: 'Training', icon: 'dumb', tone: 'blue', title: 'Completed Upper B', subtitle: '45 min · 5 of 5 exercises',
        rows: [('Duration', '45 min'), ('Exercises', '5 of 5'), ('Top set', 'Overhead press 17.5 kg × 8')], actionLabel: 'Open training', route: '/c/train'),
    ActivityItem(day: 2, time: '10:30 pm', kind: 'Habits', icon: 'moon', tone: 'purple', title: 'Logged sleep', subtitle: '7 h 20 min · goal met',
        rows: [('Sleep', '7 h 20 min'), ('Goal', '7 hours')], actionLabel: 'Open habits', route: '/c/more/habits'),
    ActivityItem(day: 2, time: '1:15 pm', kind: 'Food', icon: 'food', tone: 'green', title: 'Swapped brown rice for whole wheat roti', subtitle: 'Lunch · today only',
        rows: [('From', 'Brown rice 120 g'), ('To', 'Whole wheat roti × 2'), ('Calories', 'About the same')], actionLabel: 'Open meal plan', route: '/c/food'),
    ActivityItem(day: 3, time: '7:05 pm', kind: 'Training', icon: 'dumb', tone: 'blue', title: 'Completed Lower A', subtitle: '48 min · 5 of 5 exercises',
        rows: [('Duration', '48 min'), ('Exercises', '5 of 5'), ('Top set', 'Box squat 30 kg × 8')], actionLabel: 'Open training', route: '/c/train'),
    ActivityItem(day: 4, time: '7:15 pm', kind: 'Training', icon: 'star', tone: 'amber', title: 'Completed Upper A · 1 personal best', subtitle: '52 min · bench press 45 kg × 6',
        rows: [('Duration', '52 min'), ('Exercises', '6 of 6'), ('Personal best', 'Bench press 45 kg × 6')], actionLabel: 'See progress', route: '/c/progress'),
    ActivityItem(day: 5, time: '6:12 pm', kind: 'Check-ins', icon: 'form', tone: 'amber', title: 'Sent week 6 check-in', subtitle: '71.6 kg · 3 photos',
        rows: [('Weight', '71.6 kg'), ('Your note', '“Knee better, energy good”'), ('Reply', 'Aman replied on Fri, 9 Oct')], actionLabel: 'Open check-ins', route: '/c/more/checkins'),
  ];

  // ================================================================ water

  static const waterGoalMl = 3000;
  static const waterToday0 = 1500;
}
