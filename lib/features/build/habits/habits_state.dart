import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

/// Habit templates (Habits & supplements → Habits).
class HabitsController extends Notifier<List<Habit>> {
  @override
  List<Habit> build() => LibraryMock.habits;

  void add(Habit h) => state = [...state, h];
  void update(String id, Habit Function(Habit) fn) => state = [for (final h in state) h.id == id ? fn(h) : h];
  void remove(String id) => state = state.where((h) => h.id != id).toList();
  void restore(List<Habit> list) => state = list;
}

final habitsProvider = NotifierProvider<HabitsController, List<Habit>>(HabitsController.new);

/// Supplement plans (Habits & supplements → Supplements).
class SupplementsController extends Notifier<List<SupplementPlan>> {
  @override
  List<SupplementPlan> build() => LibraryMock.supplementPlans;

  void add(SupplementPlan p) => state = [...state, p];
  void update(String id, SupplementPlan Function(SupplementPlan) fn) => state = [for (final p in state) p.id == id ? fn(p) : p];
  void remove(String id) => state = state.where((p) => p.id != id).toList();
  void restore(List<SupplementPlan> list) => state = list;
}

final supplementsProvider = NotifierProvider<SupplementsController, List<SupplementPlan>>(SupplementsController.new);

// ---------------------------------------------------------------------------
// Labels and looks
// ---------------------------------------------------------------------------

const weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const weekNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtCount(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
}

String freqLabel(Habit h) => switch (h.freq) {
      HabitFreq.daily => 'Daily',
      HabitFreq.specificDays => h.days.map((d) => weekNames[d]).join(', '),
      HabitFreq.timesPerWeek => '${h.timesPerWeek} times a week',
    };

String kindLabel(Habit h) => h.kind == HabitKind.tick ? 'Tick' : 'Counter · ${fmtCount(h.target)} ${h.unit}';

String daysLabel(List<int> d) => d.length == 7 ? 'Every day' : d.map((x) => weekNames[x]).join(', ');

IconData habitIcon(HabitIcon i) => switch (i) {
      HabitIcon.water => Icons.water_drop_outlined,
      HabitIcon.steps => Icons.directions_walk_rounded,
      HabitIcon.sleep => Icons.bedtime_outlined,
      HabitIcon.food => Icons.restaurant_rounded,
      HabitIcon.timer => Icons.timer_outlined,
      HabitIcon.sun => Icons.wb_sunny_outlined,
      HabitIcon.habit => Icons.track_changes_rounded,
    };

/// hb-ic tones t1…t4: (background, foreground).
const _tones = [
  (Color(0xFFE0EAFF), Color(0xFF1E40AF)),
  (Color(0xFFE8F6EE), Color(0xFF11663D)),
  (Color(0xFFFFF1E6), Color(0xFF9A3A10)),
  (Color(0xFFF1EAFE), Color(0xFF5B21B6)),
];

int habitTone(HabitIcon i) => switch (i) {
      HabitIcon.water || HabitIcon.timer => 0,
      HabitIcon.steps || HabitIcon.habit => 1,
      HabitIcon.food || HabitIcon.sun => 2,
      HabitIcon.sleep => 3,
    };

/// Rounded tinted icon square (hb-ic).
class HabitIconBox extends StatelessWidget {
  const HabitIconBox(this.icon, {super.key, this.tone = 0, this.size = 34});
  final IconData icon;
  final int tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tones[tone.clamp(0, 3)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .26)),
      child: Icon(icon, size: size * .52, color: fg),
    );
  }
}
