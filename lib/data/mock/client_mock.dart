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

  // ================================================================ water

  static const waterGoalMl = 3000;
  static const waterToday0 = 1500;
}
