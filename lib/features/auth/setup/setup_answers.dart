import 'package:train_with_vimal/data/mock/auth_mock.dart';

/// A toast the setup flow wants to show (title, subtitle, warn?).
typedef SetupProblem = (String, String);

/// The client's onboarding answers. Defaults are what Riya typed in her real form.
class SetupAnswers {
  int goal = -1;
  int level = 1;
  List<double> body = [for (final f in AuthMock.body) f.initial];
  int place = 0;
  List<int> days = [...AuthMock.defaultDays];
  int length = 1;
  int wake = 1;
  List<String> injuries = [];
  String note = '';
  List<String> conditions = [];
  int activity = 0;
  bool doctor = false;
  int diet = -1;
  int meals = 5;
  List<String> avoid = [...AuthMock.defaultAvoid];
  bool homeFood = true;

  // ---- derived ----

  List<String> get realInjuries => injuries.where((x) => x != 'None').toList();

  List<String> get noteOptions =>
      [for (final x in realInjuries) ...?AuthMock.injuryNotes[x]].take(3).toList();

  String get activeNote {
    final opts = noteOptions;
    return note.isNotEmpty && opts.contains(note) ? note : (opts.isEmpty ? '' : opts.first);
  }

  bool get heart => conditions.contains('Heart condition');

  List<int> get sortedDays => [...days]..sort();

  String get daysLine => sortedDays.map((d) => AuthMock.weekdays[d]).join(', ');

  /// Multi-select where "None" clears the others.
  static List<String> toggleMulti(List<String> list, String n) {
    if (n == 'None') return list.contains('None') ? [] : ['None'];
    if (list.contains(n)) return list.where((x) => x != n).toList();
    return [...list.where((x) => x != 'None'), n];
  }

  static String f1(double x) => ((x * 10).round() / 10).toStringAsFixed(1);

  String bodyValue(int k) {
    final f = AuthMock.body[k];
    final v = body[k];
    return f.unit == 'kg' ? '${f1(v)} kg' : '${v.round()} ${f.unit}';
  }

  String get bodyLine {
    final diff = ((body[2] - body[3]) * 10).round() / 10;
    if (diff > 0) return 'Goal: lose ${f1(diff)} kg. A safe pace is about 0.5 kg a week, so roughly ${(diff / .5).ceil()} weeks.';
    if (diff < 0) return 'Goal: gain ${f1(-diff)} kg. Aman plans a small surplus.';
    return 'Goal: keep your weight and change your shape.';
  }

  /// What is missing on a step before Continue works, or null.
  SetupProblem? problem(int step) => switch (step) {
        0 when goal < 0 => ('Pick your main goal', 'Aman builds your plan around it'),
        2 when days.length < 2 => ('Pick at least 2 days', 'Tap the days you can train'),
        3 when injuries.isEmpty => ('Tell us about injuries', 'Pick None if nothing hurts'),
        3 when conditions.isEmpty => ('Tell us about health conditions', 'Pick None if you have none'),
        3 when heart && !doctor => ('Doctor’s OK needed', 'Tick the box once your doctor clears you'),
        4 when diet < 0 => ('Pick your food preference', 'Your meal plan only uses foods you eat'),
        _ => null,
      };

  /// Profile summary rows on the "all set" screen.
  List<(String, String)> get summary {
    final lv = AuthMock.levels[level].title;
    final real = realInjuries;
    final cond = conditions.where((x) => x != 'None').toList();
    return [
      ('Goal', '${goal >= 0 ? AuthMock.goals[goal].name : '—'} · $lv'),
      ('About you', '${body[0].round()} yrs · ${body[1].round()} cm · ${f1(body[2])} → ${f1(body[3])} kg'),
      ('Training', '${days.length} days · $daysLine · ${AuthMock.lengths[length]} · ${AuthMock.placeNames[place]}'),
      (
        'Health',
        '${real.isNotEmpty ? '${real.join(', ')} · ' : 'No injuries · '}'
            '${cond.isNotEmpty ? '${cond.join(', ')} · ' : ''}${AuthMock.activity[activity].title}'
      ),
      (
        'Food',
        '${diet >= 0 ? AuthMock.diets[diet].name : '—'} · $meals meals'
            '${avoid.isNotEmpty ? ' · avoids ${avoid.join(', ').toLowerCase()}' : ''}'
      ),
    ];
  }
}
