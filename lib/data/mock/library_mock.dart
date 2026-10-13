import '../models/library.dart';

/// Mock data for the shared build pages (Nutrition & foods, Meal plan builder,
/// Habits & supplements, Content library) — taken from the design scripts.
abstract final class LibraryMock {
  // -------------------------------------------------------------------------
  // Nutrition — meal plans
  // -------------------------------------------------------------------------

  static const plans = <MealPlan>[
    MealPlan(
      id: 'np-cut-egg',
      name: 'Cut · Eggetarian',
      diet: 'Eggetarian',
      targets: PlanTargets(2150, 150, 220, 65, 30, 3),
      mealNames: ['Breakfast', 'Lunch', 'Snack', 'Dinner'],
      optionCount: 10,
      clients: [
        PlanClient('Rohan Kapoor', 'Dinner: brown rice 1 × 100 g instead of 1.5. Banana before training instead of dates.'),
        PlanClient('Riya Sharma'),
        PlanClient('Kabir Mehta'),
      ],
      published: true,
      edited: '8 Oct',
      meals: meals,
    ),
    MealPlan(
      id: 'np-gain-nonveg',
      name: 'Lean gain · Non-veg',
      diet: 'Non-veg',
      targets: PlanTargets(2800, 170, 340, 80),
      mealNames: ['Breakfast', 'Lunch', 'Pre-workout', 'Dinner'],
      optionCount: 6,
      clients: [PlanClient('Dev Patel')],
      published: true,
      edited: '6 Oct',
    ),
    MealPlan(
      id: 'np-fatloss-veg',
      name: 'Fat loss · Veg',
      diet: 'Veg',
      targets: PlanTargets(1700, 110, 180, 55),
      mealNames: ['Breakfast', 'Lunch', 'Snack', 'Dinner'],
      optionCount: 5,
      clients: [PlanClient('Ananya Iyer', 'Jain: no onion or garlic in dal and sabzi.')],
      edited: '2 Oct',
    ),
    MealPlan(
      id: 'np-maint-vegan',
      name: 'Maintenance · Vegan',
      diet: 'Vegan',
      targets: PlanTargets(2200, 110, 290, 65),
      mealNames: ['Breakfast', 'Lunch', 'Snack', 'Dinner'],
      optionCount: 4,
      edited: '29 Sep',
    ),
  ];

  /// Diet filter on the meal plans tab.
  static const planDiets = ['All', 'Veg', 'Eggetarian', 'Non-veg', 'Vegan'];

  /// Clients in the builder's "Assign to clients" list: name, current plan.
  static const assignable = <(String, String)>[
    ('Riya Sharma', 'Cut · Eggetarian'),
    ('Rohan Kapoor', 'Cut · Eggetarian'),
    ('Kabir Mehta', 'Cut · Eggetarian'),
    ('Dev Patel', 'Lean gain · Non-veg'),
    ('Ananya Iyer', 'Fat loss · Veg'),
    ('Ishaan Bose', ''),
    ('Sneha Kulkarni', ''),
    ('Aarav Nair', ''),
  ];

  static const planPermissions = [
    'Client can swap within the approved list',
    'Client can search any food',
    'Client can switch meal options',
    'Allow off-plan meals (flagged to coach)',
  ];

  static const mealTimes = ['6:30 am', '8:00 am', '11:00 am', '1:30 pm', '5:00 pm', '6:30 pm', '8:30 pm', '10:00 pm'];

  // -------------------------------------------------------------------------
  // Nutrition — food library
  // -------------------------------------------------------------------------

  static const foodGroups = ['All', 'Protein', 'Carbs', 'Fats', 'Veg', 'Fruits', 'Dairy', 'Indian dishes'];

  /// Suggested units in the food editor's "Add unit" menu.
  static const unitSuggestions = <FoodUnit>[
    FoodUnit('1 tsp', 5),
    FoodUnit('1 tbsp', 15),
    FoodUnit('1 katori', 150),
    FoodUnit('1 cup', 200),
    FoodUnit('1 glass', 250),
    FoodUnit('1 bowl', 100),
    FoodUnit('1 plate', 200),
    FoodUnit('1 piece', 30),
    FoodUnit('1 slice', 30),
    FoodUnit('1 scoop', 30),
    FoodUnit('1 handful', 30),
  ];

  /// Group of each spreadsheet category (Excel import).
  static const importGroups = {
    'Grains': 'Carbs',
    'Cereals': 'Carbs',
    'Egg': 'Protein',
    'Chicken': 'Protein',
    'Non-Veg': 'Indian dishes',
    'Legumes': 'Protein',
    'Fruits': 'Fruits',
    'Fats': 'Fats',
    'Nuts': 'Fats',
    'Beverages': 'Beverages',
    'Vegetables': 'Veg',
    'Dairy': 'Dairy',
  };

  static const importDiets = {'Vegetarian': Diet.veg, 'Non-Vegetarian': Diet.nonVeg, 'Dairy': Diet.veg};

  /// "What each row needs" in the import: column, help, required.
  static const importNeeds = <(String, String, bool)>[
    ('Food', 'Name clients search for', true),
    ('Portion/Quantity', 'Unit name, like 1 tsp (5 g) or 1 katori', false),
    ('Portion_g', 'Weight of that serving in grams. ml counts as g.', true),
    ('Calories_kcal', 'For that serving', true),
    ('Protein, carbs, fat, fibre, minerals', 'For that serving. Blank is fine.', false),
  ];

  static const foods = <Food>[
    Food(id: 'f0', name: "Meera's protein shake", units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 350.0)], kcal: 88.6, protein: 9.1, carbs: 8.6, fat: 2.0, fibre: 0.0, group: 'My foods', diet: Diet.veg, brand: '', custom: true, swaps: ['Whey protein', 'Greek yogurt'], usedIn: [], defaultUnit: 1, defaultQty: 1.0, source: 'Your team'),
    Food(id: 'f1', name: "Coach's paneer bhurji", units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 180.0), FoodUnit('1 katori', 120.0)], kcal: 161.1, protein: 12.2, carbs: 4.4, fat: 10.6, fibre: 0.0, group: 'My foods', diet: Diet.veg, brand: '', custom: true, swaps: ['Tofu (firm)', 'Low-fat paneer'], usedIn: [], defaultUnit: 1, defaultQty: 1.0, source: 'Your team'),
    Food(id: 'f2', name: 'Paneer', units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], kcal: 265.0, protein: 18.0, carbs: 3.0, fat: 21.0, fibre: 0.0, group: 'Dairy', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch')], defaultUnit: 0, defaultQty: 100.0, source: 'IFCT'),
    Food(id: 'f3', name: 'Low-fat paneer', units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], kcal: 200.0, protein: 20.0, carbs: 4.0, fat: 12.0, fibre: 0.0, group: 'Protein', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Fat loss · Veg', 'Lunch')], defaultUnit: 0, defaultQty: 100.0, source: 'IFCT'),
    Food(id: 'f4', name: 'Chicken breast (cooked)', units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 120.0)], kcal: 165.0, protein: 31.0, carbs: 0.0, fat: 4.0, fibre: 0.0, group: 'Protein', diet: Diet.nonVeg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch'), PlanUse('Lean gain · Non-veg', 'Lunch, Dinner')], defaultUnit: 0, defaultQty: 100.0, source: 'IFCT'),
    Food(id: 'f5', name: 'Egg (whole)', units: [FoodUnit('g', 1.0), FoodUnit('1 large', 50.0)], kcal: 144.0, protein: 12.0, carbs: 0.0, fat: 10.0, fibre: 0.0, group: 'Protein', diet: Diet.egg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast, Dinner'), PlanUse('Lean gain · Non-veg', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f6', name: 'Egg whites', units: [FoodUnit('g', 1.0), FoodUnit('1 egg white', 33.0)], kcal: 51.5, protein: 10.6, carbs: 0.8, fat: 0.0, fibre: 0.0, group: 'Protein', diet: Diet.egg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast, Dinner'), PlanUse('Lean gain · Non-veg', 'Breakfast')], defaultUnit: 1, defaultQty: 4.0, source: 'IFCT'),
    Food(id: 'f7', name: 'Whey protein', units: [FoodUnit('g', 1.0), FoodUnit('1 scoop', 32.0)], kcal: 375.0, protein: 75.0, carbs: 9.4, fat: 6.2, fibre: 0.0, group: 'Protein', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast, Snack'), PlanUse('Lean gain · Non-veg', 'Pre-workout')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f8', name: 'Soya chunks', units: [FoodUnit('g', 1.0), FoodUnit('1 katori dry', 30.0)], kcal: 346.7, protein: 53.3, carbs: 33.3, fat: 0.0, fibre: 0.0, group: 'Protein', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [], defaultUnit: 0, defaultQty: 30.0, source: 'IFCT'),
    Food(id: 'f9', name: 'Tofu (firm)', units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], kcal: 144.0, protein: 15.0, carbs: 3.0, fat: 9.0, fibre: 0.0, group: 'Protein', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner'), PlanUse('Maintenance · Vegan', 'Dinner')], defaultUnit: 0, defaultQty: 100.0, source: 'IFCT'),
    Food(id: 'f10', name: 'Fish curry (rohu)', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], kcal: 146.7, protein: 14.7, carbs: 3.3, fat: 8.0, fibre: 0.0, group: 'Indian dishes', diet: Diet.nonVeg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Lean gain · Non-veg', 'Dinner')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f11', name: 'Moong dal (cooked)', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], kcal: 106.7, protein: 7.3, carbs: 18.0, fat: 0.7, fibre: 0.0, group: 'Indian dishes', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch, Dinner'), PlanUse('Fat loss · Veg', 'Lunch')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f12', name: 'Rajma', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], kcal: 140.0, protein: 8.7, carbs: 23.3, fat: 1.3, fibre: 0.0, group: 'Indian dishes', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Fat loss · Veg', 'Dinner')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f13', name: 'Chana masala', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], kcal: 160.0, protein: 7.3, carbs: 21.3, fat: 5.3, fibre: 0.0, group: 'Indian dishes', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Maintenance · Vegan', 'Lunch')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f14', name: 'Poha', units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], kcal: 166.7, protein: 3.3, carbs: 30.0, fat: 4.0, fibre: 0.0, group: 'Indian dishes', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Fat loss · Veg', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f15', name: 'Idli + sambar', units: [FoodUnit('g', 1.0), FoodUnit('1 idli with sambar', 110.0)], kcal: 86.4, protein: 3.2, carbs: 16.4, fat: 0.9, fibre: 0.0, group: 'Indian dishes', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [], defaultUnit: 1, defaultQty: 2.0, source: 'IFCT'),
    Food(id: 'f16', name: 'Masala dosa', units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 160.0)], kcal: 206.2, protein: 4.4, carbs: 28.1, fat: 8.1, fibre: 0.0, group: 'Indian dishes', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Lean gain · Non-veg', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f17', name: 'Besan chilla', units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 70.0)], kcal: 171.4, protein: 8.6, carbs: 20.0, fat: 5.7, fibre: 0.0, group: 'Indian dishes', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Fat loss · Veg', 'Breakfast')], defaultUnit: 1, defaultQty: 2.0, source: 'IFCT'),
    Food(id: 'f18', name: 'Sprouts chaat', units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], kcal: 120.0, protein: 7.3, carbs: 18.7, fat: 2.0, fibre: 0.0, group: 'Indian dishes', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Snack'), PlanUse('Maintenance · Vegan', 'Snack')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f19', name: 'Paneer tikka', units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 30.0)], kcal: 200.0, protein: 13.3, carbs: 5.6, fat: 13.9, fibre: 0.0, group: 'Indian dishes', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner')], defaultUnit: 1, defaultQty: 6.0, source: 'IFCT'),
    Food(id: 'f20', name: 'Dal tadka', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], kcal: 120.0, protein: 5.3, carbs: 13.3, fat: 5.3, fibre: 0.0, group: 'Indian dishes', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner'), PlanUse('Lean gain · Non-veg', 'Lunch')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f21', name: 'Whole wheat roti', units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], kcal: 275.0, protein: 7.5, carbs: 50.0, fat: 5.0, fibre: 0.0, group: 'Carbs', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch, Dinner'), PlanUse('Lean gain · Non-veg', 'Dinner'), PlanUse('Fat loss · Veg', 'Lunch'), PlanUse('Maintenance · Vegan', 'Dinner')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f22', name: 'Brown rice (cooked)', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], kcal: 112.0, protein: 3.0, carbs: 24.0, fat: 1.0, fibre: 0.0, group: 'Carbs', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch, Dinner'), PlanUse('Fat loss · Veg', 'Dinner'), PlanUse('Maintenance · Vegan', 'Lunch')], defaultUnit: 0, defaultQty: 100.0, source: 'IFCT'),
    Food(id: 'f23', name: 'White rice (cooked)', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], kcal: 130.0, protein: 3.0, carbs: 28.0, fat: 0.0, fibre: 0.0, group: 'Carbs', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner'), PlanUse('Lean gain · Non-veg', 'Lunch, Dinner')], defaultUnit: 0, defaultQty: 100.0, source: 'IFCT'),
    Food(id: 'f24', name: 'Oats', units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 8.0), FoodUnit('1 cup', 80.0)], kcal: 375.0, protein: 12.5, carbs: 67.5, fat: 7.5, fibre: 0.0, group: 'Carbs', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast'), PlanUse('Maintenance · Vegan', 'Breakfast')], defaultUnit: 0, defaultQty: 40.0, source: 'IFCT'),
    Food(id: 'f25', name: 'Sweet potato (boiled)', units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], kcal: 86.7, protein: 1.3, carbs: 20.0, fat: 0.0, fibre: 0.0, group: 'Carbs', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [], defaultUnit: 0, defaultQty: 150.0, source: 'IFCT'),
    Food(id: 'f26', name: 'Multigrain toast', units: [FoodUnit('g', 1.0), FoodUnit('1 slice', 30.0)], kcal: 266.7, protein: 10.0, carbs: 46.7, fat: 3.3, fibre: 0.0, group: 'Carbs', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast'), PlanUse('Lean gain · Non-veg', 'Breakfast')], defaultUnit: 1, defaultQty: 2.0, source: 'IFCT'),
    Food(id: 'f27', name: 'Curd (dahi)', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], kcal: 60.0, protein: 3.3, carbs: 4.7, fat: 3.3, fibre: 0.0, group: 'Dairy', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch, Dinner'), PlanUse('Lean gain · Non-veg', 'Dinner'), PlanUse('Fat loss · Veg', 'Breakfast, Dinner')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f28', name: 'Greek yogurt', units: [FoodUnit('g', 1.0), FoodUnit('1 cup', 200.0), FoodUnit('1 tbsp', 15.0)], kcal: 73.3, protein: 10.0, carbs: 4.0, fat: 2.0, fibre: 0.0, group: 'Dairy', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Snack'), PlanUse('Fat loss · Veg', 'Snack')], defaultUnit: 0, defaultQty: 150.0, source: 'IFCT'),
    Food(id: 'f29', name: 'Milk (toned)', units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 250.0), FoodUnit('1 cup', 150.0)], kcal: 58.0, protein: 3.2, carbs: 4.8, fat: 2.8, fibre: 0.0, group: 'Dairy', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast, Snack'), PlanUse('Lean gain · Non-veg', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f30', name: 'Buttermilk (chaas)', units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 200.0)], kcal: 30.0, protein: 1.5, carbs: 2.5, fat: 1.5, fibre: 0.0, group: 'Dairy', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Snack'), PlanUse('Fat loss · Veg', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f31', name: 'Almonds', units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 1.2), FoodUnit('1 handful', 25.0)], kcal: 583.3, protein: 25.0, carbs: 16.7, fat: 50.0, fibre: 0.0, group: 'Fats', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Fat loss · Veg', 'Breakfast'), PlanUse('Maintenance · Vegan', 'Snack')], defaultUnit: 1, defaultQty: 10.0, source: 'IFCT'),
    Food(id: 'f32', name: 'Peanut butter', units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 16.0), FoodUnit('1 tsp', 5.0)], kcal: 593.8, protein: 25.0, carbs: 18.8, fat: 50.0, fibre: 0.0, group: 'Fats', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast'), PlanUse('Lean gain · Non-veg', 'Pre-workout'), PlanUse('Maintenance · Vegan', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f33', name: 'Ghee', units: [FoodUnit('g', 1.0), FoodUnit('1 tsp', 5.0), FoodUnit('1 tbsp', 15.0)], kcal: 900.0, protein: 0.0, carbs: 0.0, fat: 100.0, fibre: 0.0, group: 'Fats', diet: Diet.veg, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f34', name: 'Roasted chana', units: [FoodUnit('g', 1.0), FoodUnit('1 handful', 30.0), FoodUnit('1 katori', 60.0)], kcal: 366.7, protein: 20.0, carbs: 60.0, fat: 6.7, fibre: 0.0, group: 'Protein', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Snack'), PlanUse('Fat loss · Veg', 'Snack')], defaultUnit: 0, defaultQty: 30.0, source: 'IFCT'),
    Food(id: 'f35', name: 'Banana', units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 118.0), FoodUnit('1 small', 90.0)], kcal: 89.0, protein: 0.8, carbs: 22.9, fat: 0.0, fibre: 0.0, group: 'Fruits', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast'), PlanUse('Lean gain · Non-veg', 'Breakfast, Pre-workout'), PlanUse('Maintenance · Vegan', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f36', name: 'Apple', units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], kcal: 63.3, protein: 0.0, carbs: 16.7, fat: 0.0, fibre: 0.0, group: 'Fruits', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f37', name: 'Papaya', units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 150.0), FoodUnit('1 slice', 100.0)], kcal: 40.0, protein: 0.7, carbs: 10.0, fat: 0.0, fibre: 0.0, group: 'Fruits', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Fat loss · Veg', 'Breakfast')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f38', name: 'Mixed veg sabzi', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], kcal: 73.3, protein: 2.0, carbs: 8.0, fat: 4.0, fibre: 0.0, group: 'Veg', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Lunch, Dinner'), PlanUse('Lean gain · Non-veg', 'Dinner'), PlanUse('Maintenance · Vegan', 'Lunch')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f39', name: 'Palak sabzi', units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], kcal: 60.0, protein: 2.7, carbs: 5.3, fat: 3.3, fibre: 0.0, group: 'Veg', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner'), PlanUse('Lean gain · Non-veg', 'Dinner'), PlanUse('Fat loss · Veg', 'Dinner'), PlanUse('Maintenance · Vegan', 'Dinner')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
    Food(id: 'f40', name: 'Cucumber salad', units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 100.0)], kcal: 30.0, protein: 1.0, carbs: 6.0, fat: 0.0, fibre: 0.0, group: 'Veg', diet: Diet.vegan, brand: '', custom: false, swaps: [], usedIn: [PlanUse('Cut · Eggetarian', 'Dinner'), PlanUse('Lean gain · Non-veg', 'Lunch'), PlanUse('Fat loss · Veg', 'Lunch'), PlanUse('Maintenance · Vegan', 'Lunch')], defaultUnit: 1, defaultQty: 1.0, source: 'IFCT'),
  ];

  static const importRows = <ImportRow>[
    ImportRow(name: 'Rice, Basmati (raw)', category: 'Grains', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [367.5, 7.8, 80.7, 2.5, 2.9], micros: [5.1, 1.05, 21.0, 92.8], source: 'IFCT/USDA', sheetKcal: 367.5, calcKcal: 376.3, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Egg (whole, raw)', category: 'Egg', mainCategory: 'Non-Vegetarian', unit: '1 egg', unitGrams: 50.0, qty: 1.0, per100: [144.0, 12.6, 0.7, 10.6, 0.0], micros: [142.0, 1.76, 56.0, 126.0], source: 'IFCT/USDA', sheetKcal: 72.0, calcKcal: 74.3, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Oats (raw)', category: 'Grains', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [379.0, 13.2, 67.7, 6.5, 10.1], micros: [6.0, 4.25, 54.0, 362.0], source: 'IFCT/USDA', sheetKcal: 379.0, calcKcal: 382.1, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Rice, White (raw)', category: 'Grains', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [361.0, 7.0, 80.4, 0.6, 1.3], micros: [5.0, 0.8, 10.0, 95.0], source: 'IFCT/USDA', sheetKcal: 361.0, calcKcal: 355.0, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: "Roti (cooked, medium size (7'))", category: 'Grains', mainCategory: 'Vegetarian', unit: '1 medium', unitGrams: 40.0, qty: 1.0, per100: [275.0, 7.5, 46.2, 5.0, 5.0], micros: [12.5, 1.5, 25.0, 125.0], source: 'IFCT', sheetKcal: 110.0, calcKcal: 104.0, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Multigrain Roti (Cooked size 7")', category: 'Grains', mainCategory: 'Vegetarian', unit: '1 roti', unitGrams: 40.0, qty: 1.0, per100: [275.0, 8.8, 45.0, 3.8, 7.5], micros: [15.0, 2.5, 37.5, 225.0], source: 'IFCT/Estimated', sheetKcal: 110.0, calcKcal: 99.5, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Muesli', category: 'Cereals', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 30.0, per100: [400.0, 10.0, 66.7, 11.7, 8.3], micros: [150.0, 3.33, 66.7, 333.3], source: 'USDA', sheetKcal: 120.0, calcKcal: 123.5, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Chicken Breast (raw)', category: 'Chicken', mainCategory: 'Non-Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [165.0, 31.0, 0.0, 3.6, 0.0], micros: [74.0, 1.0, 15.0, 256.0], source: 'USDA', sheetKcal: 165.0, calcKcal: 156.4, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Soya Chunks (raw)', category: 'Legumes', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [345.0, 52.0, 33.0, 0.5, 13.0], micros: [10.0, 20.0, 350.0, 1100.0], source: 'IFCT', sheetKcal: 345.0, calcKcal: 344.5, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Banana (medium)', category: 'Fruits', mainCategory: 'Vegetarian', unit: '1 medium', unitGrams: 118.0, qty: 1.0, per100: [89.0, 1.1, 22.9, 0.3, 2.5], micros: [0.8, 0.25, 5.1, 357.6], source: 'USDA', sheetKcal: 105.0, calcKcal: 115.9, kcalDiffers: true, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Apple (medium)', category: 'Fruits', mainCategory: 'Vegetarian', unit: '1 piece', unitGrams: 150.0, qty: 1.0, per100: [53.3, 0.2, 13.3, 0.1, 2.0], micros: [0.7, 0.07, 6.7, 130.0], source: 'USDA', sheetKcal: 80.0, calcKcal: 83.0, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Papaya (raw)', category: 'Fruits', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [43.0, 0.5, 11.0, 0.3, 1.8], micros: [8.0, 0.3, 20.0, 182.0], source: 'IFCT', sheetKcal: 43.0, calcKcal: 48.7, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Seasonal Mix Fruits', category: 'Fruits', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 150.0, per100: [73.3, 0.7, 16.7, 0.3, 2.0], micros: [3.3, 0.33, 13.3, 166.7], source: 'Estimated', sheetKcal: 110.0, calcKcal: 108.5, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Ghee', category: 'Fats', mainCategory: 'Vegetarian', unit: '1 tsp', unitGrams: 5.0, qty: 1.0, per100: [900.0, 0.0, 0.0, 100.0, 0.0], micros: [0.0, 0.0, 20.0, 0.0], source: 'IFCT', sheetKcal: 45.0, calcKcal: 45.0, kcalDiffers: false, raw: false, ml: false, existing: 'Ghee'),
    ImportRow(name: 'Tea with Milk & Sugar', category: 'Beverages', mainCategory: 'Vegetarian', unit: '1 cup', unitGrams: 150.0, qty: 1.0, per100: [50.0, 1.3, 6.7, 2.0, 0.0], micros: [20.0, 0.13, 53.3, 66.7], source: 'IFCT', sheetKcal: 75.0, calcKcal: 75.0, kcalDiffers: false, raw: false, ml: true, existing: ''),
    ImportRow(name: 'Dal (cooked)', category: 'Legumes', mainCategory: 'Vegetarian', unit: '1 cup', unitGrams: 150.0, qty: 1.0, per100: [120.0, 6.0, 15.3, 2.3, 4.7], micros: [233.3, 1.33, 26.7, 233.3], source: 'IFCT', sheetKcal: 180.0, calcKcal: 159.5, kcalDiffers: true, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Sabji (mixed veg, cooked)', category: 'Vegetables', mainCategory: 'Vegetarian', unit: '1 cup', unitGrams: 150.0, qty: 1.0, per100: [86.7, 2.0, 8.0, 4.0, 2.3], micros: [200.0, 1.0, 40.0, 266.7], source: 'IFCT', sheetKcal: 130.0, calcKcal: 114.0, kcalDiffers: true, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Curd (plain)', category: 'Dairy', mainCategory: 'Dairy', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [60.0, 3.5, 4.0, 3.0, 0.0], micros: [50.0, 0.1, 120.0, 150.0], source: 'IFCT', sheetKcal: 60.0, calcKcal: 57.0, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Buttermilk (plain)', category: 'Dairy', mainCategory: 'Dairy', unit: '1 glass', unitGrams: 200.0, qty: 1.0, per100: [25.0, 1.0, 4.0, 0.5, 0.0], micros: [40.0, 0.05, 50.0, 90.0], source: 'IFCT', sheetKcal: 50.0, calcKcal: 49.0, kcalDiffers: false, raw: false, ml: true, existing: ''),
    ImportRow(name: 'Egg White', category: 'Egg', mainCategory: 'Non-Vegetarian', unit: '1 egg white', unitGrams: 33.0, qty: 1.0, per100: [51.5, 10.9, 0.6, 0.2, 0.0], micros: [166.7, 0.0, 6.1, 163.6], source: 'USDA', sheetKcal: 17.0, calcKcal: 15.6, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Salad (mixed, raw)', category: 'Vegetables', mainCategory: 'Vegetarian', unit: '1 bowl', unitGrams: 100.0, qty: 1.0, per100: [35.0, 1.0, 6.0, 0.2, 2.5], micros: [10.0, 0.4, 30.0, 250.0], source: 'IFCT', sheetKcal: 35.0, calcKcal: 29.8, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Almond (soaked)', category: 'Nuts', mainCategory: 'Vegetarian', unit: '1 piece', unitGrams: 1.2, qty: 1.0, per100: [583.3, 20.8, 4.2, 50.0, 8.3], micros: [0.0, 1.67, 166.7, 666.7], source: 'USDA', sheetKcal: 7.0, calcKcal: 6.6, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Bread (white slice)', category: 'Grains', mainCategory: 'Vegetarian', unit: '1 slice', unitGrams: 25.0, qty: 1.0, per100: [260.0, 10.4, 48.0, 3.2, 2.0], micros: [520.0, 1.2, 160.0, 144.0], source: 'USDA', sheetKcal: 65.0, calcKcal: 65.6, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Paneer (Indian Cottage Cheese)', category: 'Dairy', mainCategory: 'Dairy', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [265.0, 18.3, 1.2, 20.8, 0.0], micros: [25.0, 0.2, 208.0, 93.0], source: 'IFCT', sheetKcal: 265.0, calcKcal: 265.2, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Spinach (Palak, raw)', category: 'Vegetables', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [23.0, 2.9, 3.6, 0.4, 2.2], micros: [79.0, 2.7, 99.0, 558.0], source: 'USDA', sheetKcal: 23.0, calcKcal: 29.6, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Moong Dal (raw)', category: 'Legumes', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [347.0, 24.0, 63.0, 1.0, 16.0], micros: [15.0, 4.0, 132.0, 1000.0], source: 'IFCT', sheetKcal: 347.0, calcKcal: 357.0, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Idli (steamed)', category: 'Grains', mainCategory: 'Vegetarian', unit: '1 medium', unitGrams: 50.0, qty: 1.0, per100: [140.0, 4.0, 30.0, 1.0, 2.0], micros: [100.0, 0.8, 20.0, 60.0], source: 'IFCT', sheetKcal: 70.0, calcKcal: 72.5, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Dosa (plain)', category: 'Grains', mainCategory: 'Vegetarian', unit: '1 medium', unitGrams: 70.0, qty: 1.0, per100: [200.0, 4.3, 35.7, 4.3, 2.1], micros: [100.0, 0.86, 21.4, 85.7], source: 'IFCT', sheetKcal: 140.0, calcKcal: 139.0, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Potato (Aloo, raw)', category: 'Vegetables', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [77.0, 2.0, 17.0, 0.1, 2.2], micros: [6.0, 0.8, 12.0, 429.0], source: 'USDA', sheetKcal: 77.0, calcKcal: 76.9, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Besan (Gram Flour)', category: 'Legumes', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [387.0, 22.0, 58.0, 5.0, 10.0], micros: [60.0, 4.8, 49.0, 846.0], source: 'IFCT', sheetKcal: 387.0, calcKcal: 365.0, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Mango (raw)', category: 'Fruits', mainCategory: 'Vegetarian', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [60.0, 0.8, 15.0, 0.4, 1.6], micros: [1.0, 0.2, 11.0, 168.0], source: 'USDA', sheetKcal: 60.0, calcKcal: 66.8, kcalDiffers: false, raw: true, ml: false, existing: ''),
    ImportRow(name: 'Chapati (whole wheat)', category: 'Grains', mainCategory: 'Vegetarian', unit: '1 medium', unitGrams: 40.0, qty: 1.0, per100: [300.0, 10.0, 62.5, 3.8, 7.5], micros: [5.0, 3.75, 37.5, 200.0], source: 'IFCT', sheetKcal: 120.0, calcKcal: 129.5, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Chicken Curry', category: 'Non-Veg', mainCategory: 'Non-Vegetarian', unit: '1 serving', unitGrams: 150.0, qty: 1.0, per100: [166.7, 16.7, 5.3, 8.0, 1.3], micros: [233.3, 1.67, 20.0, 200.0], source: 'Estimated', sheetKcal: 250.0, calcKcal: 240.0, kcalDiffers: false, raw: false, ml: false, existing: ''),
    ImportRow(name: 'Yogurt/Curd (Dahi)', category: 'Dairy', mainCategory: 'Dairy', unit: 'g', unitGrams: 1.0, qty: 100.0, per100: [61.0, 3.5, 4.7, 3.3, 0.0], micros: [46.0, 0.1, 110.0, 150.0], source: 'USDA', sheetKcal: 61.0, calcKcal: 62.5, kcalDiffers: false, raw: false, ml: false, existing: ''),
  ];

  static const meals = <Meal>[
    Meal(id: 'meal-12', name: 'Breakfast', time: '8:00 am', target: 520, defaultOption: 0, options: [
      MealOption('Veg', [
        PlanFood(name: 'Oats', unit: 'g', qty: 60.0, kcal: 3.75, protein: 0.125, carbs: 0.675, fat: 0.075, alts: [FoodAlt('Poha', '1 plate · 150 g', 82)], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 8.0), FoodUnit('1 cup', 80.0)], per100: [375.0, 12.5, 67.5, 7.5]),
        PlanFood(name: 'Whey protein', unit: '1 scoop', qty: 1.0, kcal: 120.0, protein: 24.0, carbs: 3.008, fat: 1.984, alts: [FoodAlt('Greek yogurt', '150 g', 84), FoodAlt('Egg whites', '2 × 4 large', 87)], units: [FoodUnit('g', 1.0), FoodUnit('1 scoop', 32.0)], per100: [375.0, 75.0, 9.4, 6.2]),
        PlanFood(name: 'Banana', unit: '1 medium', qty: 1.0, kcal: 105.02, protein: 0.944, carbs: 27.022, fat: 0.0, alts: [FoodAlt('Apple', '1 medium', 64)], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 118.0), FoodUnit('1 small', 90.0)], per100: [89.0, 0.8, 22.9, 0.0]),
        PlanFood(name: 'Peanut butter', unit: '1 tbsp', qty: 1.0, kcal: 95.008, protein: 4.0, carbs: 3.008, fat: 8.0, alts: [FoodAlt('Almonds', '1.5 × 10 pieces', 86)], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 16.0), FoodUnit('1 tsp', 5.0)], per100: [593.8, 25.0, 18.8, 50.0]),
      ]),
      MealOption('Eggs', [
        PlanFood(name: 'Egg whites', unit: '1 egg white', qty: 4.0, kcal: 16.995, protein: 3.498, carbs: 0.264, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 egg white', 33.0)], per100: [51.5, 10.6, 0.8, 0.0]),
        PlanFood(name: 'Egg (whole)', unit: '1 large', qty: 1.0, kcal: 72.0, protein: 6.0, carbs: 0.0, fat: 5.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 large', 50.0)], per100: [144.0, 12.0, 0.0, 10.0]),
        PlanFood(name: 'Multigrain toast', unit: '1 slice', qty: 2.0, kcal: 80.01, protein: 3.0, carbs: 14.01, fat: 0.99, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 slice', 30.0)], per100: [266.7, 10.0, 46.7, 3.3]),
        PlanFood(name: 'Apple', unit: '1 medium', qty: 1.0, kcal: 94.95, protein: 0.0, carbs: 25.05, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], per100: [63.3, 0.0, 16.7, 0.0]),
        PlanFood(name: 'Milk (toned)', unit: '1 glass', qty: 1.0, kcal: 145.0, protein: 8.0, carbs: 12.0, fat: 7.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 250.0), FoodUnit('1 cup', 150.0)], per100: [58.0, 3.2, 4.8, 2.8]),
      ]),
    ]),
    Meal(id: 'meal-22', name: 'Lunch', time: '1:30 pm', target: 640, defaultOption: 0, options: [
      MealOption('Veg', [
        PlanFood(name: 'Paneer', unit: 'g', qty: 100.0, kcal: 2.65, protein: 0.18, carbs: 0.03, fat: 0.21, alts: [FoodAlt('Tofu (firm)', '2 × 100 g', 75), FoodAlt('Low-fat paneer', '1.5 × 100 g', 72), FoodAlt('Soya chunks', '2.5 × 30 g dry', 69)], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [265.0, 18.0, 3.0, 21.0]),
        PlanFood(name: 'Whole wheat roti', unit: '1 medium', qty: 2.0, kcal: 110.0, protein: 3.0, carbs: 20.0, fat: 2.0, alts: [FoodAlt('Brown rice (cooked)', '2 × 100 g', 99)], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
        PlanFood(name: 'Moong dal (cooked)', unit: '1 katori', qty: 1.0, kcal: 160.05, protein: 10.95, carbs: 27.0, fat: 1.05, alts: [FoodAlt('Rajma', '1 katori', 76)], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [106.7, 7.3, 18.0, 0.7]),
      ]),
      MealOption('Non-veg', [
        PlanFood(name: 'Chicken breast (cooked)', unit: 'g', qty: 150.0, kcal: 1.65, protein: 0.31, carbs: 0.0, fat: 0.04, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 120.0)], per100: [165.0, 31.0, 0.0, 4.0]),
        PlanFood(name: 'Brown rice (cooked)', unit: 'g', qty: 150.0, kcal: 1.12, protein: 0.03, carbs: 0.24, fat: 0.01, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [112.0, 3.0, 24.0, 1.0]),
        PlanFood(name: 'Mixed veg sabzi', unit: '1 katori', qty: 1.0, kcal: 109.95, protein: 3.0, carbs: 12.0, fat: 6.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [73.3, 2.0, 8.0, 4.0]),
        PlanFood(name: 'Curd (dahi)', unit: '1 katori', qty: 1.0, kcal: 90.0, protein: 4.95, carbs: 7.05, fat: 4.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [60.0, 3.3, 4.7, 3.3]),
      ]),
    ]),
    Meal(id: 'meal-32', name: 'Snack', time: '5:00 pm', target: 260, defaultOption: 0, options: [
      MealOption('Quick', [
        PlanFood(name: 'Greek yogurt', unit: 'g', qty: 225.0, kcal: 0.733, protein: 0.1, carbs: 0.04, fat: 0.02, alts: [FoodAlt('Curd (dahi)', '2 × 1 katori · 150 g', 78)], units: [FoodUnit('g', 1.0), FoodUnit('1 cup', 200.0), FoodUnit('1 tbsp', 15.0)], per100: [73.3, 10.0, 4.0, 2.0]),
        PlanFood(name: 'Roasted chana', unit: 'g', qty: 30.0, kcal: 3.667, protein: 0.2, carbs: 0.6, fat: 0.067, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 handful', 30.0), FoodUnit('1 katori', 60.0)], per100: [366.7, 20.0, 60.0, 6.7]),
      ]),
      MealOption('Shake', [
        PlanFood(name: 'Whey protein', unit: '1 scoop', qty: 1.0, kcal: 120.0, protein: 24.0, carbs: 3.008, fat: 1.984, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 scoop', 32.0)], per100: [375.0, 75.0, 9.4, 6.2]),
        PlanFood(name: 'Milk (toned)', unit: '1 glass', qty: 1.0, kcal: 145.0, protein: 8.0, carbs: 12.0, fat: 7.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 250.0), FoodUnit('1 cup', 150.0)], per100: [58.0, 3.2, 4.8, 2.8]),
      ]),
      MealOption('Eating out', [
        PlanFood(name: 'Sprouts chaat', unit: '1 plate', qty: 1.0, kcal: 180.0, protein: 10.95, carbs: 28.05, fat: 3.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], per100: [120.0, 7.3, 18.7, 2.0]),
        PlanFood(name: 'Buttermilk (chaas)', unit: '1 glass', qty: 1.0, kcal: 60.0, protein: 3.0, carbs: 5.0, fat: 3.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 200.0)], per100: [30.0, 1.5, 2.5, 1.5]),
      ]),
    ]),
    Meal(id: 'meal-52', name: 'Dinner', time: '8:30 pm', target: 730, defaultOption: 0, options: [
      MealOption('Eggetarian', [
        PlanFood(name: 'Egg whites', unit: '1 egg white', qty: 6.0, kcal: 16.995, protein: 3.498, carbs: 0.264, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 egg white', 33.0)], per100: [51.5, 10.6, 0.8, 0.0]),
        PlanFood(name: 'Egg (whole)', unit: '1 large', qty: 1.0, kcal: 72.0, protein: 6.0, carbs: 0.0, fat: 5.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 large', 50.0)], per100: [144.0, 12.0, 0.0, 10.0]),
        PlanFood(name: 'Brown rice (cooked)', unit: 'g', qty: 150.0, kcal: 1.12, protein: 0.03, carbs: 0.24, fat: 0.01, alts: [FoodAlt('White rice (cooked)', '1.5 × 100 g', 90)], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [112.0, 3.0, 24.0, 1.0]),
        PlanFood(name: 'Mixed veg sabzi', unit: '1 katori', qty: 1.0, kcal: 109.95, protein: 3.0, carbs: 12.0, fat: 6.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [73.3, 2.0, 8.0, 4.0]),
        PlanFood(name: 'Moong dal (cooked)', unit: '1 katori', qty: 1.0, kcal: 160.05, protein: 10.95, carbs: 27.0, fat: 1.05, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [106.7, 7.3, 18.0, 0.7]),
        PlanFood(name: 'Whole wheat roti', unit: '1 medium', qty: 1.0, kcal: 110.0, protein: 3.0, carbs: 20.0, fat: 2.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
        PlanFood(name: 'Ghee', unit: '1 tsp', qty: 1.0, kcal: 45.0, protein: 0.0, carbs: 0.0, fat: 5.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tsp', 5.0), FoodUnit('1 tbsp', 15.0)], per100: [900.0, 0.0, 0.0, 100.0]),
      ]),
      MealOption('Veg', [
        PlanFood(name: 'Tofu (firm)', unit: 'g', qty: 150.0, kcal: 1.44, protein: 0.15, carbs: 0.03, fat: 0.09, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [144.0, 15.0, 3.0, 9.0]),
        PlanFood(name: 'Whole wheat roti', unit: '1 medium', qty: 2.0, kcal: 110.0, protein: 3.0, carbs: 20.0, fat: 2.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
        PlanFood(name: 'Palak sabzi', unit: '1 katori', qty: 1.0, kcal: 90.0, protein: 4.05, carbs: 7.95, fat: 4.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [60.0, 2.7, 5.3, 3.3]),
        PlanFood(name: 'Curd (dahi)', unit: '1 katori', qty: 1.0, kcal: 90.0, protein: 4.95, carbs: 7.05, fat: 4.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [60.0, 3.3, 4.7, 3.3]),
        PlanFood(name: 'White rice (cooked)', unit: 'g', qty: 100.0, kcal: 1.3, protein: 0.03, carbs: 0.28, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [130.0, 3.0, 28.0, 0.0]),
      ]),
      MealOption('Eating out', [
        PlanFood(name: 'Paneer tikka', unit: '1 piece', qty: 6.0, kcal: 60.0, protein: 3.99, carbs: 1.68, fat: 4.17, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 30.0)], per100: [200.0, 13.3, 5.6, 13.9]),
        PlanFood(name: 'Whole wheat roti', unit: '1 medium', qty: 1.0, kcal: 110.0, protein: 3.0, carbs: 20.0, fat: 2.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
        PlanFood(name: 'Dal tadka', unit: '1 katori', qty: 1.0, kcal: 180.0, protein: 7.95, carbs: 19.95, fat: 7.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [120.0, 5.3, 13.3, 5.3]),
        PlanFood(name: 'Cucumber salad', unit: '1 bowl', qty: 1.0, kcal: 30.0, protein: 1.0, carbs: 6.0, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 100.0)], per100: [30.0, 1.0, 6.0, 0.0]),
      ]),
    ]),
  ];

  static const pickerFoods = <LibraryFood>[
    LibraryFood(name: "Meera's protein shake", serving: '1 glass · 350 g', kcal: 310, protein: 32, carbs: 30, fat: 7, group: 'My foods', diet: Diet.veg, team: true),
    LibraryFood(name: "Coach's paneer bhurji", serving: '1 plate · 180 g', kcal: 290, protein: 22, carbs: 8, fat: 19, group: 'My foods', diet: Diet.veg, team: true),
    LibraryFood(name: 'Paneer', serving: '100 g', kcal: 265, protein: 18, carbs: 3, fat: 21, group: 'Dairy', diet: Diet.veg, team: false),
    LibraryFood(name: 'Low-fat paneer', serving: '100 g', kcal: 200, protein: 20, carbs: 4, fat: 12, group: 'Protein', diet: Diet.veg, team: false),
    LibraryFood(name: 'Chicken breast (cooked)', serving: '100 g', kcal: 165, protein: 31, carbs: 0, fat: 4, group: 'Protein', diet: Diet.nonVeg, team: false),
    LibraryFood(name: 'Egg (whole)', serving: '1 large · 50 g', kcal: 72, protein: 6, carbs: 0, fat: 5, group: 'Protein', diet: Diet.egg, team: false),
    LibraryFood(name: 'Egg whites', serving: '4 × 1 egg white · 132 g', kcal: 68, protein: 14, carbs: 1, fat: 0, group: 'Protein', diet: Diet.egg, team: false),
    LibraryFood(name: 'Whey protein', serving: '1 scoop · 32 g', kcal: 120, protein: 24, carbs: 3, fat: 2, group: 'Protein', diet: Diet.veg, team: false),
    LibraryFood(name: 'Soya chunks', serving: '30 g', kcal: 104, protein: 16, carbs: 10, fat: 0, group: 'Protein', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Tofu (firm)', serving: '100 g', kcal: 144, protein: 15, carbs: 3, fat: 9, group: 'Protein', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Fish curry (rohu)', serving: '1 katori · 150 g', kcal: 220, protein: 22, carbs: 5, fat: 12, group: 'Indian dishes', diet: Diet.nonVeg, team: false),
    LibraryFood(name: 'Moong dal (cooked)', serving: '1 katori · 150 g', kcal: 160, protein: 11, carbs: 27, fat: 1, group: 'Indian dishes', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Rajma', serving: '1 katori · 150 g', kcal: 210, protein: 13, carbs: 35, fat: 2, group: 'Indian dishes', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Chana masala', serving: '1 katori · 150 g', kcal: 240, protein: 11, carbs: 32, fat: 8, group: 'Indian dishes', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Poha', serving: '1 plate · 150 g', kcal: 250, protein: 5, carbs: 45, fat: 6, group: 'Indian dishes', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Idli + sambar', serving: '2 × 1 idli with sambar · 220 g', kcal: 190, protein: 7, carbs: 36, fat: 2, group: 'Indian dishes', diet: Diet.veg, team: false),
    LibraryFood(name: 'Masala dosa', serving: '1 medium · 160 g', kcal: 330, protein: 7, carbs: 45, fat: 13, group: 'Indian dishes', diet: Diet.veg, team: false),
    LibraryFood(name: 'Besan chilla', serving: '2 × 1 piece · 140 g', kcal: 240, protein: 12, carbs: 28, fat: 8, group: 'Indian dishes', diet: Diet.veg, team: false),
    LibraryFood(name: 'Sprouts chaat', serving: '1 plate · 150 g', kcal: 180, protein: 11, carbs: 28, fat: 3, group: 'Indian dishes', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Paneer tikka', serving: '6 × 1 piece · 180 g', kcal: 360, protein: 24, carbs: 10, fat: 25, group: 'Indian dishes', diet: Diet.veg, team: false),
    LibraryFood(name: 'Dal tadka', serving: '1 katori · 150 g', kcal: 180, protein: 8, carbs: 20, fat: 8, group: 'Indian dishes', diet: Diet.veg, team: false),
    LibraryFood(name: 'Whole wheat roti', serving: '1 medium · 40 g', kcal: 110, protein: 3, carbs: 20, fat: 2, group: 'Carbs', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Brown rice (cooked)', serving: '100 g', kcal: 112, protein: 3, carbs: 24, fat: 1, group: 'Carbs', diet: Diet.vegan, team: false),
    LibraryFood(name: 'White rice (cooked)', serving: '100 g', kcal: 130, protein: 3, carbs: 28, fat: 0, group: 'Carbs', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Oats', serving: '40 g', kcal: 150, protein: 5, carbs: 27, fat: 3, group: 'Carbs', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Sweet potato (boiled)', serving: '150 g', kcal: 130, protein: 2, carbs: 30, fat: 0, group: 'Carbs', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Multigrain toast', serving: '2 × 1 slice · 60 g', kcal: 160, protein: 6, carbs: 28, fat: 2, group: 'Carbs', diet: Diet.veg, team: false),
    LibraryFood(name: 'Curd (dahi)', serving: '1 katori · 150 g', kcal: 90, protein: 5, carbs: 7, fat: 5, group: 'Dairy', diet: Diet.veg, team: false),
    LibraryFood(name: 'Greek yogurt', serving: '150 g', kcal: 110, protein: 15, carbs: 6, fat: 3, group: 'Dairy', diet: Diet.veg, team: false),
    LibraryFood(name: 'Milk (toned)', serving: '1 glass · 250 g', kcal: 145, protein: 8, carbs: 12, fat: 7, group: 'Dairy', diet: Diet.veg, team: false),
    LibraryFood(name: 'Buttermilk (chaas)', serving: '1 glass · 200 g', kcal: 60, protein: 3, carbs: 5, fat: 3, group: 'Dairy', diet: Diet.veg, team: false),
    LibraryFood(name: 'Almonds', serving: '10 × 1 piece · 12 g', kcal: 70, protein: 3, carbs: 2, fat: 6, group: 'Fats', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Peanut butter', serving: '1 tbsp · 16 g', kcal: 95, protein: 4, carbs: 3, fat: 8, group: 'Fats', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Ghee', serving: '1 tsp · 5 g', kcal: 45, protein: 0, carbs: 0, fat: 5, group: 'Fats', diet: Diet.veg, team: false),
    LibraryFood(name: 'Roasted chana', serving: '30 g', kcal: 110, protein: 6, carbs: 18, fat: 2, group: 'Protein', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Banana', serving: '1 medium · 118 g', kcal: 105, protein: 1, carbs: 27, fat: 0, group: 'Fruits', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Apple', serving: '1 medium · 150 g', kcal: 95, protein: 0, carbs: 25, fat: 0, group: 'Fruits', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Papaya', serving: '1 bowl · 150 g', kcal: 60, protein: 1, carbs: 15, fat: 0, group: 'Fruits', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Mixed veg sabzi', serving: '1 katori · 150 g', kcal: 110, protein: 3, carbs: 12, fat: 6, group: 'Veg', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Palak sabzi', serving: '1 katori · 150 g', kcal: 90, protein: 4, carbs: 8, fat: 5, group: 'Veg', diet: Diet.vegan, team: false),
    LibraryFood(name: 'Cucumber salad', serving: '1 bowl · 100 g', kcal: 30, protein: 1, carbs: 6, fat: 0, group: 'Veg', diet: Diet.vegan, team: false),
  ];

  static const pickerTemplates = <String, PlanFood>{
    "Meera's protein shake": PlanFood(name: "Meera's protein shake", unit: '1 glass', qty: 1.0, kcal: 310.1, protein: 31.85, carbs: 30.1, fat: 7.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 350.0)], per100: [88.6, 9.1, 8.6, 2.0]),
    "Coach's paneer bhurji": PlanFood(name: "Coach's paneer bhurji", unit: '1 plate', qty: 1.0, kcal: 289.98, protein: 21.96, carbs: 7.92, fat: 19.08, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 180.0), FoodUnit('1 katori', 120.0)], per100: [161.1, 12.2, 4.4, 10.6]),
    'Paneer': PlanFood(name: 'Paneer', unit: 'g', qty: 100.0, kcal: 2.65, protein: 0.18, carbs: 0.03, fat: 0.21, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [265.0, 18.0, 3.0, 21.0]),
    'Low-fat paneer': PlanFood(name: 'Low-fat paneer', unit: 'g', qty: 100.0, kcal: 2.0, protein: 0.2, carbs: 0.04, fat: 0.12, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [200.0, 20.0, 4.0, 12.0]),
    'Chicken breast (cooked)': PlanFood(name: 'Chicken breast (cooked)', unit: 'g', qty: 100.0, kcal: 1.65, protein: 0.31, carbs: 0.0, fat: 0.04, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 120.0)], per100: [165.0, 31.0, 0.0, 4.0]),
    'Egg (whole)': PlanFood(name: 'Egg (whole)', unit: '1 large', qty: 1.0, kcal: 72.0, protein: 6.0, carbs: 0.0, fat: 5.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 large', 50.0)], per100: [144.0, 12.0, 0.0, 10.0]),
    'Egg whites': PlanFood(name: 'Egg whites', unit: '1 egg white', qty: 4.0, kcal: 16.995, protein: 3.498, carbs: 0.264, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 egg white', 33.0)], per100: [51.5, 10.6, 0.8, 0.0]),
    'Whey protein': PlanFood(name: 'Whey protein', unit: '1 scoop', qty: 1.0, kcal: 120.0, protein: 24.0, carbs: 3.008, fat: 1.984, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 scoop', 32.0)], per100: [375.0, 75.0, 9.4, 6.2]),
    'Soya chunks': PlanFood(name: 'Soya chunks', unit: 'g', qty: 30.0, kcal: 3.467, protein: 0.533, carbs: 0.333, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori dry', 30.0)], per100: [346.7, 53.3, 33.3, 0.0]),
    'Tofu (firm)': PlanFood(name: 'Tofu (firm)', unit: 'g', qty: 100.0, kcal: 1.44, protein: 0.15, carbs: 0.03, fat: 0.09, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cube', 25.0)], per100: [144.0, 15.0, 3.0, 9.0]),
    'Fish curry (rohu)': PlanFood(name: 'Fish curry (rohu)', unit: '1 katori', qty: 1.0, kcal: 220.05, protein: 22.05, carbs: 4.95, fat: 12.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [146.7, 14.7, 3.3, 8.0]),
    'Moong dal (cooked)': PlanFood(name: 'Moong dal (cooked)', unit: '1 katori', qty: 1.0, kcal: 160.05, protein: 10.95, carbs: 27.0, fat: 1.05, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [106.7, 7.3, 18.0, 0.7]),
    'Rajma': PlanFood(name: 'Rajma', unit: '1 katori', qty: 1.0, kcal: 210.0, protein: 13.05, carbs: 34.95, fat: 1.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [140.0, 8.7, 23.3, 1.3]),
    'Chana masala': PlanFood(name: 'Chana masala', unit: '1 katori', qty: 1.0, kcal: 240.0, protein: 10.95, carbs: 31.95, fat: 7.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [160.0, 7.3, 21.3, 5.3]),
    'Poha': PlanFood(name: 'Poha', unit: '1 plate', qty: 1.0, kcal: 250.05, protein: 4.95, carbs: 45.0, fat: 6.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], per100: [166.7, 3.3, 30.0, 4.0]),
    'Idli + sambar': PlanFood(name: 'Idli + sambar', unit: '1 idli with sambar', qty: 2.0, kcal: 95.04, protein: 3.52, carbs: 18.04, fat: 0.99, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 idli with sambar', 110.0)], per100: [86.4, 3.2, 16.4, 0.9]),
    'Masala dosa': PlanFood(name: 'Masala dosa', unit: '1 medium', qty: 1.0, kcal: 329.92, protein: 7.04, carbs: 44.96, fat: 12.96, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 160.0)], per100: [206.2, 4.4, 28.1, 8.1]),
    'Besan chilla': PlanFood(name: 'Besan chilla', unit: '1 piece', qty: 2.0, kcal: 119.98, protein: 6.02, carbs: 14.0, fat: 3.99, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 70.0)], per100: [171.4, 8.6, 20.0, 5.7]),
    'Sprouts chaat': PlanFood(name: 'Sprouts chaat', unit: '1 plate', qty: 1.0, kcal: 180.0, protein: 10.95, carbs: 28.05, fat: 3.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 plate', 150.0), FoodUnit('1 katori', 100.0)], per100: [120.0, 7.3, 18.7, 2.0]),
    'Paneer tikka': PlanFood(name: 'Paneer tikka', unit: '1 piece', qty: 6.0, kcal: 60.0, protein: 3.99, carbs: 1.68, fat: 4.17, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 30.0)], per100: [200.0, 13.3, 5.6, 13.9]),
    'Dal tadka': PlanFood(name: 'Dal tadka', unit: '1 katori', qty: 1.0, kcal: 180.0, protein: 7.95, carbs: 19.95, fat: 7.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [120.0, 5.3, 13.3, 5.3]),
    'Whole wheat roti': PlanFood(name: 'Whole wheat roti', unit: '1 medium', qty: 1.0, kcal: 110.0, protein: 3.0, carbs: 20.0, fat: 2.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 40.0), FoodUnit('1 small', 30.0)], per100: [275.0, 7.5, 50.0, 5.0]),
    'Brown rice (cooked)': PlanFood(name: 'Brown rice (cooked)', unit: 'g', qty: 100.0, kcal: 1.12, protein: 0.03, carbs: 0.24, fat: 0.01, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [112.0, 3.0, 24.0, 1.0]),
    'White rice (cooked)': PlanFood(name: 'White rice (cooked)', unit: 'g', qty: 100.0, kcal: 1.3, protein: 0.03, carbs: 0.28, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [130.0, 3.0, 28.0, 0.0]),
    'Oats': PlanFood(name: 'Oats', unit: 'g', qty: 40.0, kcal: 3.75, protein: 0.125, carbs: 0.675, fat: 0.075, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 8.0), FoodUnit('1 cup', 80.0)], per100: [375.0, 12.5, 67.5, 7.5]),
    'Sweet potato (boiled)': PlanFood(name: 'Sweet potato (boiled)', unit: 'g', qty: 150.0, kcal: 0.867, protein: 0.013, carbs: 0.2, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], per100: [86.7, 1.3, 20.0, 0.0]),
    'Multigrain toast': PlanFood(name: 'Multigrain toast', unit: '1 slice', qty: 2.0, kcal: 80.01, protein: 3.0, carbs: 14.01, fat: 0.99, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 slice', 30.0)], per100: [266.7, 10.0, 46.7, 3.3]),
    'Curd (dahi)': PlanFood(name: 'Curd (dahi)', unit: '1 katori', qty: 1.0, kcal: 90.0, protein: 4.95, carbs: 7.05, fat: 4.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0), FoodUnit('1 tbsp', 15.0)], per100: [60.0, 3.3, 4.7, 3.3]),
    'Greek yogurt': PlanFood(name: 'Greek yogurt', unit: 'g', qty: 150.0, kcal: 0.733, protein: 0.1, carbs: 0.04, fat: 0.02, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 cup', 200.0), FoodUnit('1 tbsp', 15.0)], per100: [73.3, 10.0, 4.0, 2.0]),
    'Milk (toned)': PlanFood(name: 'Milk (toned)', unit: '1 glass', qty: 1.0, kcal: 145.0, protein: 8.0, carbs: 12.0, fat: 7.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 250.0), FoodUnit('1 cup', 150.0)], per100: [58.0, 3.2, 4.8, 2.8]),
    'Buttermilk (chaas)': PlanFood(name: 'Buttermilk (chaas)', unit: '1 glass', qty: 1.0, kcal: 60.0, protein: 3.0, carbs: 5.0, fat: 3.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 glass', 200.0)], per100: [30.0, 1.5, 2.5, 1.5]),
    'Almonds': PlanFood(name: 'Almonds', unit: '1 piece', qty: 10.0, kcal: 6.9996, protein: 0.3, carbs: 0.2004, fat: 0.6, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 piece', 1.2), FoodUnit('1 handful', 25.0)], per100: [583.3, 25.0, 16.7, 50.0]),
    'Peanut butter': PlanFood(name: 'Peanut butter', unit: '1 tbsp', qty: 1.0, kcal: 95.008, protein: 4.0, carbs: 3.008, fat: 8.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tbsp', 16.0), FoodUnit('1 tsp', 5.0)], per100: [593.8, 25.0, 18.8, 50.0]),
    'Ghee': PlanFood(name: 'Ghee', unit: '1 tsp', qty: 1.0, kcal: 45.0, protein: 0.0, carbs: 0.0, fat: 5.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 tsp', 5.0), FoodUnit('1 tbsp', 15.0)], per100: [900.0, 0.0, 0.0, 100.0]),
    'Roasted chana': PlanFood(name: 'Roasted chana', unit: 'g', qty: 30.0, kcal: 3.667, protein: 0.2, carbs: 0.6, fat: 0.067, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 handful', 30.0), FoodUnit('1 katori', 60.0)], per100: [366.7, 20.0, 60.0, 6.7]),
    'Banana': PlanFood(name: 'Banana', unit: '1 medium', qty: 1.0, kcal: 105.02, protein: 0.944, carbs: 27.022, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 118.0), FoodUnit('1 small', 90.0)], per100: [89.0, 0.8, 22.9, 0.0]),
    'Apple': PlanFood(name: 'Apple', unit: '1 medium', qty: 1.0, kcal: 94.95, protein: 0.0, carbs: 25.05, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 medium', 150.0)], per100: [63.3, 0.0, 16.7, 0.0]),
    'Papaya': PlanFood(name: 'Papaya', unit: '1 bowl', qty: 1.0, kcal: 60.0, protein: 1.05, carbs: 15.0, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 150.0), FoodUnit('1 slice', 100.0)], per100: [40.0, 0.7, 10.0, 0.0]),
    'Mixed veg sabzi': PlanFood(name: 'Mixed veg sabzi', unit: '1 katori', qty: 1.0, kcal: 109.95, protein: 3.0, carbs: 12.0, fat: 6.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [73.3, 2.0, 8.0, 4.0]),
    'Palak sabzi': PlanFood(name: 'Palak sabzi', unit: '1 katori', qty: 1.0, kcal: 90.0, protein: 4.05, carbs: 7.95, fat: 4.95, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 katori', 150.0)], per100: [60.0, 2.7, 5.3, 3.3]),
    'Cucumber salad': PlanFood(name: 'Cucumber salad', unit: '1 bowl', qty: 1.0, kcal: 30.0, protein: 1.0, carbs: 6.0, fat: 0.0, alts: [], units: [FoodUnit('g', 1.0), FoodUnit('1 bowl', 100.0)], per100: [30.0, 1.0, 6.0, 0.0]),
  };

  // -------------------------------------------------------------------------
  // Habits & supplements
  // -------------------------------------------------------------------------

  static const habits = <Habit>[
    Habit(id: 'hb-water', name: 'Drink 3 L water', kind: HabitKind.counter, target: 12, unit: 'glasses', freq: HabitFreq.daily, days: [0, 2, 4], timesPerWeek: 3, why: 'Staying hydrated keeps energy up and hunger in check.', icon: HabitIcon.water, clients: ['Riya Sharma', 'Rohan Kapoor', 'Kabir Mehta']),
    Habit(id: 'hb-steps', name: '8,000 steps', kind: HabitKind.counter, target: 8000, unit: 'steps', freq: HabitFreq.daily, days: [0, 2, 4], timesPerWeek: 3, why: 'Daily movement does more for fat loss than most people expect.', icon: HabitIcon.steps, clients: ['Riya Sharma', 'Ananya Iyer']),
    Habit(id: 'hb-sleep', name: 'Sleep by 11 pm', kind: HabitKind.tick, target: 1, unit: '', freq: HabitFreq.daily, days: [0, 2, 4], timesPerWeek: 3, why: 'Recovery and cravings both depend on sleep.', icon: HabitIcon.sleep, clients: ['Rohan Kapoor']),
    Habit(id: 'hb-protein', name: 'Hit protein target', kind: HabitKind.counter, target: 150, unit: 'g', freq: HabitFreq.daily, days: [0, 2, 4], timesPerWeek: 3, why: 'Protein protects muscle while you lose fat.', icon: HabitIcon.food, clients: ['Rohan Kapoor', 'Dev Patel']),
    Habit(id: 'hb-mobility', name: '10 min mobility', kind: HabitKind.counter, target: 10, unit: 'min', freq: HabitFreq.specificDays, days: [0, 2, 4], timesPerWeek: 3, why: 'Less stiffness, fewer injuries.', icon: HabitIcon.timer, clients: ['Kabir Mehta']),
    Habit(id: 'hb-sun', name: 'Morning sunlight', kind: HabitKind.tick, target: 1, unit: '', freq: HabitFreq.daily, days: [0, 2, 4], timesPerWeek: 3, why: 'Ten minutes before 10 am sets your sleep cycle.', icon: HabitIcon.sun, clients: []),
    Habit(id: 'hb-sugar', name: 'No sugary drinks', kind: HabitKind.tick, target: 1, unit: '', freq: HabitFreq.daily, days: [0, 2, 4], timesPerWeek: 3, why: 'The easiest calories to cut.', icon: HabitIcon.food, clients: ['Riya Sharma', 'Ananya Iyer']),
    Habit(id: 'hb-strength', name: 'Strength session', kind: HabitKind.tick, target: 1, unit: '', freq: HabitFreq.timesPerWeek, days: [0, 2, 4], timesPerWeek: 3, why: 'Three sessions a week is enough to keep progressing.', icon: HabitIcon.habit, clients: ['Dev Patel']),
  ];

  static const supplementPlans = <SupplementPlan>[
    SupplementPlan(id: 'sp-muscle', name: 'Muscle gain basics', note: 'Take creatine every day, rest days too. Whey only when food protein falls short.', items: [
      SupplementItem('Multivitamin', '1 tablet', 'Breakfast', true, [0, 1, 2, 3, 4, 5, 6]),
      SupplementItem('Omega-3', '2 softgels', 'Breakfast', true, [0, 1, 2, 3, 4, 5, 6]),
      SupplementItem('Whey protein', '1 scoop · 30 g', 'Post-workout', false, [0, 1, 3, 4]),
      SupplementItem('Creatine monohydrate', '5 g', 'Any time', false, [0, 1, 2, 3, 4, 5, 6]),
      SupplementItem('Magnesium glycinate', '200 mg', 'Before bed', false, [0, 1, 2, 3, 4, 5, 6]),
    ], clients: ['Rohan Kapoor', 'Dev Patel']),
    SupplementPlan(id: 'sp-fatloss', name: 'Fat loss support', note: 'Psyllium with a full glass of water.', items: [
      SupplementItem('Multivitamin', '1 tablet', 'Breakfast', true, [0, 1, 2, 3, 4, 5, 6]),
      SupplementItem('Vitamin D3', '2,000 IU', 'Breakfast', true, [0, 1, 2, 3, 4, 5, 6]),
      SupplementItem('Fibre (psyllium)', '1 tsp', 'Before bed', false, [0, 1, 2, 3, 4, 5, 6]),
    ], clients: ['Riya Sharma']),
    SupplementPlan(id: 'sp-veg', name: 'Vegetarian essentials', note: '', items: [
      SupplementItem('B12', '500 mcg', 'Breakfast', true, [0, 1, 2, 3, 4, 5, 6]),
      SupplementItem('Iron', '18 mg', 'Any time', false, [0, 2, 4]),
      SupplementItem('Vitamin D3', '2,000 IU', 'Breakfast', true, [0, 1, 2, 3, 4, 5, 6]),
    ], clients: []),
  ];

  /// Quick add chips in a supplement plan.
  static const supplementLibrary = ['Vitamin D3', 'Electrolytes', 'Caffeine', 'Iron', 'B12', 'Fibre (psyllium)', 'Probiotic', 'Ashwagandha'];

  static const supplementTimings = ['Breakfast', 'Pre-workout', 'Post-workout', 'Any time', 'Before bed'];

  /// Clients in the habits / content "Assign to clients" lists.
  static const assignClients = ['Riya Sharma', 'Rohan Kapoor', 'Neha Jain', 'Kabir Mehta', 'Ananya Iyer', 'Dev Patel', 'Sana Khan', 'Ishaan Mehta'];

  // -------------------------------------------------------------------------
  // Content library
  // -------------------------------------------------------------------------

  static const contentCategories = ['Exercise videos', 'Form tutorials', 'Onboarding', 'Nutrition guides', 'Mindset & sleep'];

  static const contentItems = <ContentItem>[
    ContentItem(id: 'c1', title: 'Bench press · setup', kind: ContentKind.video, category: 'Exercise videos', by: 'Aman Verma', updated: '14 Sep', length: '0:42', everyone: false, clients: [], uses: [ContentUse('Exercise', 'Bench press', ContentLink.exercise), ContentUse('Program', 'Fat Loss Phase 1 · Push day', ContentLink.program)], opened: 52, finished: 44, body: '', tone: 1),
    ContentItem(id: 'c2', title: 'Landmine press · side view', kind: ContentKind.video, category: 'Exercise videos', by: 'Aman Verma', updated: '2 Oct', length: '0:38', everyone: false, clients: [], uses: [ContentUse('Exercise', 'Landmine press', ContentLink.exercise)], opened: 8, finished: 7, body: '', tone: 1),
    ContentItem(id: 'c3', title: 'Landmine press · front view', kind: ContentKind.video, category: 'Exercise videos', by: 'Aman Verma', updated: '2 Oct', length: '0:41', everyone: false, clients: [], uses: [ContentUse('Exercise', 'Landmine press', ContentLink.exercise)], opened: 5, finished: 5, body: '', tone: 2),
    ContentItem(id: 'c4', title: 'Half-kneeling press · coaching', kind: ContentKind.video, category: 'Exercise videos', by: 'Pooja Nair', updated: '28 Sep', length: '1:12', everyone: false, clients: [], uses: [], opened: 0, finished: 0, body: '', tone: 3),
    ContentItem(id: 'c5', title: 'Shoulder warm-up', kind: ContentKind.video, category: 'Exercise videos', by: 'Sahil Khan', updated: '21 Sep', length: '2:05', everyone: false, clients: [], uses: [ContentUse('Program', 'Hypertrophy · Push / Pull / Legs', ContentLink.program)], opened: 31, finished: 22, body: '', tone: 4),
    ContentItem(id: 'c6', title: 'Push-up progressions', kind: ContentKind.video, category: 'Exercise videos', by: 'Aman Verma', updated: '9 Sep', length: '1:48', everyone: false, clients: [], uses: [ContentUse('Exercise', 'Push-up', ContentLink.exercise)], opened: 19, finished: 15, body: '', tone: 2),
    ContentItem(id: 'c7', title: 'Box squat: how to', kind: ContentKind.video, category: 'Form tutorials', by: 'Aman Verma', updated: '28 Sep', length: '3:05', everyone: false, clients: ['Riya Sharma'], uses: [ContentUse('Client', 'Riya Sharma · until Fat Loss Phase 1 ends', ContentLink.client)], opened: 3, finished: 2, body: '', tone: 3),
    ContentItem(id: 'c8', title: 'Squat form: 5 common mistakes', kind: ContentKind.video, category: 'Form tutorials', by: 'Aman Verma', updated: '28 Sep', length: '4:10', everyone: true, clients: [], uses: [], opened: 64, finished: 40, body: '', tone: 1),
    ContentItem(id: 'c9', title: 'Upper A walkthrough', kind: ContentKind.video, category: 'Form tutorials', by: 'Vimal', updated: '1 Sep', length: '6:20', everyone: false, clients: [], uses: [ContentUse('Program', 'Fat Loss Phase 1 · Upper A', ContentLink.program)], opened: 41, finished: 30, body: '', tone: 4),
    ContentItem(id: 'c10', title: 'Deadlift setup', kind: ContentKind.video, category: 'Form tutorials', by: 'Aman Verma', updated: '5 Sep', length: '2:30', everyone: false, clients: ['Rohan Kapoor', 'Kabir Mehta'], uses: [], opened: 9, finished: 6, body: '', tone: 2),
    ContentItem(id: 'c11', title: 'Knee-safe leg day warm-up', kind: ContentKind.video, category: 'Form tutorials', by: 'Pooja Nair', updated: '20 Sep', length: '8:00', everyone: false, clients: [], uses: [], opened: 0, finished: 0, body: '', tone: 3),
    ContentItem(id: 'c12', title: 'Hip thrust: form check', kind: ContentKind.video, category: 'Form tutorials', by: 'Aman Verma', updated: '18 Sep', length: '4:00', everyone: false, clients: [], uses: [], opened: 0, finished: 0, body: '', tone: 1),
    ContentItem(id: 'c13', title: 'Travel workout (no gym)', kind: ContentKind.video, category: 'Form tutorials', by: 'Sahil Khan', updated: '22 Aug', length: '12:40', everyone: true, clients: [], uses: [], opened: 37, finished: 18, body: '', tone: 4),
    ContentItem(id: 'c14', title: 'Welcome to the program', kind: ContentKind.video, category: 'Onboarding', by: 'Pooja Nair', updated: '20 Sep', length: '2:15', everyone: false, clients: ['Neha Jain'], uses: [], opened: 1, finished: 1, body: '', tone: 2),
    ContentItem(id: 'c15', title: 'Welcome to Train With Vimal', kind: ContentKind.article, category: 'Onboarding', by: 'Vimal', updated: '12 Jan', length: '2 min read', everyone: true, clients: [], uses: [ContentUse('Automation', 'Client onboarding · on approval', ContentLink.automation)], opened: 88, finished: 80, body: 'How the app works, how to log, and how to reach your coach.', tone: 1),
    ContentItem(id: 'c16', title: 'How check-ins work', kind: ContentKind.pdf, category: 'Onboarding', by: 'Vimal', updated: '12 Jan', length: '3 pages', everyone: true, clients: [], uses: [ContentUse('Form', 'Weekly check-in', ContentLink.form)], opened: 72, finished: 61, body: 'Daily check-ins take 30 seconds. Weekly check-ins go to your coach every Sunday.', tone: 2),
    ContentItem(id: 'c17', title: 'Macro cheat sheet', kind: ContentKind.pdf, category: 'Onboarding', by: 'Aman Verma', updated: '10 Aug', length: '2 pages', everyone: false, clients: ['Riya Sharma', 'Ananya Iyer'], uses: [], opened: 6, finished: 4, body: 'Protein: 1.6 to 2 g per kg of body weight. One palm of paneer, chicken, fish or tofu is about 25 g.', tone: 3),
    ContentItem(id: 'c18', title: 'Eating out on a fat loss plan', kind: ContentKind.pdf, category: 'Nutrition guides', by: 'Vimal', updated: '1 Oct', length: '6 pages', everyone: false, clients: ['Riya Sharma'], uses: [ContentUse('Client', 'Riya Sharma · always', ContentLink.client)], opened: 0, finished: 0, body: 'Pick grilled over fried, ask for dressing on the side, and start with a protein. Here are 12 orders that fit your plan.', tone: 3),
    ContentItem(id: 'c19', title: 'Eating out · Indian restaurants', kind: ContentKind.pdf, category: 'Nutrition guides', by: 'Aman Verma', updated: '15 Sep', length: '8 pages', everyone: false, clients: ['Riya Sharma', 'Rohan Kapoor', 'Ananya Iyer'], uses: [ContentUse('Meal plan', 'Cut · Eggetarian · Eating out options', ContentLink.mealPlan)], opened: 14, finished: 9, body: 'Start with the protein. Tandoori chicken, paneer tikka, fish tikka or dal are the safest picks.', tone: 1),
    ContentItem(id: 'c20', title: '10 veg snacks under 200 kcal', kind: ContentKind.image, category: 'Nutrition guides', by: 'Sahil Kapoor', updated: '1 Sep', length: 'JPG', everyone: false, clients: [], uses: [ContentUse('Meal plan', 'Fat loss · Veg', ContentLink.mealPlan)], opened: 22, finished: 12, body: 'Roasted chana, sprouts chaat, Greek yogurt with berries, and seven more.', tone: 2),
    ContentItem(id: 'c28', title: 'Portion guide · use your hand', kind: ContentKind.image, category: 'Nutrition guides', by: 'Vimal', updated: '3 Oct', length: 'PNG', everyone: true, clients: [], uses: [ContentUse('Meal plan', 'Cut · Eggetarian', ContentLink.mealPlan)], opened: 58, finished: 58, body: 'Palm = protein, fist = carbs, cupped hand = fruit, thumb = fats.', tone: 1),
    ContentItem(id: 'c29', title: 'Gym timings and rules', kind: ContentKind.image, category: 'Onboarding', by: 'Pooja Nair', updated: '20 Sep', length: 'JPG', everyone: true, clients: [], uses: [ContentUse('Automation', 'Client onboarding · on approval', ContentLink.automation)], opened: 66, finished: 66, body: 'Open 6 am to 10 pm. Carry a towel. Re-rack your weights.', tone: 4),
    ContentItem(id: 'c25', title: 'How to warm up for leg day', kind: ContentKind.article, category: 'Mindset & sleep', by: 'Vimal', updated: '1 Sep', length: '4 min read', everyone: false, clients: [], uses: [ContentUse('Program', 'Fat Loss Phase 1 · Lower A', ContentLink.program)], opened: 26, finished: 21, body: 'Five minutes of easy cardio, then hip openers, glute bridges and bodyweight squats.', tone: 2),
    ContentItem(id: 'c26', title: 'Sleep hygiene basics', kind: ContentKind.article, category: 'Mindset & sleep', by: 'Aman Verma', updated: '30 Aug', length: '5 min read', everyone: true, clients: [], uses: [ContentUse('Habit', 'Sleep by 11 pm', ContentLink.habit)], opened: 49, finished: 35, body: 'Keep the same wake-up time every day, weekends included. It matters more than the time you go to bed.', tone: 4),
    ContentItem(id: 'c27', title: 'Sleep better in 7 days', kind: ContentKind.pdf, category: 'Mindset & sleep', by: 'Pooja Nair', updated: '24 Sep', length: '7 pages', everyone: false, clients: [], uses: [], opened: 0, finished: 0, body: 'One small change a night for a week: light, caffeine, screens, room, wind-down, wake time, review.', tone: 3),
  ];}
