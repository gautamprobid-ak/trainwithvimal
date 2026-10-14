import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/training_widgets.dart';
import '../workout/workout_session.dart';
import 'home_cards.dart';
import 'home_sheets.dart';
import 'home_workout_card.dart';

/// Design: ClientHome.dc.html — week strip, workout of the picked day (shared
/// with Train and the logger), water, food, habits, supplements, coach note,
/// coming up, notifications.
class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  int _day = ClientTrainingMock.todayIndex;
  int _ml = ClientTrainingMock.waterStartMl;
  List<int> _eaten = List.of(ClientTrainingMock.mealsEatenAtStart);
  int _steps = ClientTrainingMock.stepsStart;
  int _sleepM = ClientTrainingMock.sleepStartMin;
  List<String> _taken = List.of(ClientTrainingMock.supplementsTakenAtStart);
  bool _read = false;

  // ------------------------------------------------------------ actions

  void _setWater(int d) {
    const goal = ClientTrainingMock.waterGoalMl;
    final ml = _ml;
    if (d < 0 && ml == 0) {
      showToast(context, 'Nothing to remove', subtitle: 'No water logged yet');
      return;
    }
    final now = ml + d, left = goal - now, g = (left / 250).ceil();
    setState(() => _ml = now);
    if (d > 0 && ml < goal && now >= goal) {
      showToast(context, 'Water goal complete!', subtitle: '${fmtLitres(now)} today', kind: ToastKind.star);
    } else if (d > 0 && now > 5000) {
      showToast(context, '${fmtLitres(now)} today, that is plenty',
          subtitle: 'Slow down: too much water at once is not good for you', kind: ToastKind.warn);
    } else if (left > 0) {
      showToast(context, d > 0 ? '${fmtLitres(left)} to go' : 'Removed 250 ml · ${fmtLitres(now)} logged',
          subtitle: '$g ${g == 1 ? 'glass' : 'glasses'} more', kind: d > 0 ? ToastKind.water : ToastKind.info);
    } else {
      showToast(context, '${fmtLitres(now)} today', subtitle: 'Goal complete', kind: ToastKind.water);
    }
  }

  void _eat(int i) {
    final prev = _eaten;
    final m = ClientTrainingMock.meals[i];
    setState(() => _eaten = [..._eaten, i]);
    showToast(context, '${m.meal} logged', subtitle: '${m.food} · ${m.kcal} kcal', kind: ToastKind.ok, onUndo: () => setState(() => _eaten = prev));
  }

  void _take(Supplement s) {
    final prev = _taken;
    setState(() => _taken = [..._taken, s.id]);
    showToast(context, '${s.name} taken', subtitle: s.dose, kind: ToastKind.ok, onUndo: () => setState(() => _taken = prev));
  }

  Future<void> _addSteps() async {
    final v = await showStepsSheet(context, _steps);
    if (v == null || !mounted) return;
    final prev = _steps;
    setState(() => _steps = v);
    if (v >= 8000 && prev < 8000) {
      showToast(context, 'Step goal reached!', subtitle: '${TNum.n(v)} steps today', kind: ToastKind.star);
    } else {
      showToast(context, 'Steps saved', subtitle: '${TNum.n(v)} of 8,000 today', kind: ToastKind.ok, onUndo: () => setState(() => _steps = prev));
    }
  }

  Future<void> _changeSleep() async {
    final v = await showSleepSheet(context, _sleepM);
    if (v == null || !mounted) return;
    final prev = _sleepM;
    setState(() => _sleepM = v);
    final met = v >= ClientTrainingMock.sleepGoalMin;
    showToast(context, 'Sleep saved',
        subtitle: '${fmtHm(v)}${met ? ' · goal met' : ' · aim for 7 h tonight'}',
        kind: met ? ToastKind.ok : ToastKind.info,
        onUndo: () => setState(() => _sleepM = prev));
  }

  Future<void> _openNotifications() async {
    final readAll = await showNotificationsSheet(context, read: _read);
    if (readAll == true && mounted) {
      setState(() => _read = true);
      showToast(context, 'All notifications read', kind: ToastKind.ok);
    }
  }

  void _openUpcoming(UpcomingItem u) {
    if (u.link != null) {
      context.go(u.link!);
    } else {
      showToast(context, u.toast!, subtitle: u.toastSub);
    }
  }

  List<HabitItem> get _habits => [
        HabitItem(Icons.directions_walk_rounded, 'green', 'Walk 8,000 steps', '${TNum.n(_steps)} of 8,000 steps', _steps / 8000, 'Add steps', _addSteps),
        HabitItem(Icons.water_drop_outlined, 'warm', 'Drink 3 L water', '${fmtLitres(_ml)} of 3 L · from the water card', _ml / 3000, '+250 ml', () => _setWater(250)),
        HabitItem(Icons.bedtime_outlined, 'purple', 'Sleep 7 hours', 'Last night ${fmtHm(_sleepM)}', _sleepM / 420, 'Change', _changeSleep),
      ];

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      children: [
        _HomeTop(dot: !_read, onBell: _openNotifications),
        WeekStrip(selected: _day, onPick: (i) => setState(() => _day = i)),
        HomeWorkoutCard(day: _day),
        WaterCard(ml: _ml, onPlus: () => _setWater(250), onMinus: () => _setWater(-250)),
        FoodCard(
          eaten: _eaten,
          onOpen: () => context.go(Routes.cFood),
          onLog: () => showLogFoodSheet(context, eaten: () => _eaten, onEat: _eat),
          onEat: _eat,
        ),
        HabitsCard(items: _habits, onSeeAll: () => context.push(Routes.cHabits)),
        SupplementsCard(taken: _taken, onTake: _take, onSeeAll: () => context.push(Routes.cHabits)),
        const CoachNoteCard(title: ClientTrainingMock.coachFull, subtitle: 'Your trainer · 2 h ago', text: ClientTrainingMock.coachNote),
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 6),
          child: Text('Coming up', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
        ),
        UpcomingCard(onTap: _openUpcoming),
      ],
    );
  }
}

class _HomeTop extends StatelessWidget {
  const _HomeTop({required this.dot, required this.onBell});
  final bool dot;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fri, 9 Oct · ${ClientTrainingMock.weekLabel}', style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Hey Riya', style: AppText.pageTitle.copyWith(fontSize: 28)),
          ]),
        ),
        AppIconButton(Icons.notifications_none_rounded, dot: dot, tooltip: 'Notifications', onPressed: onBell),
        const SizedBox(width: 8),
        const Avatar('RS', size: 38, color: AvatarColor.indigo),
      ]),
    );
  }
}

/// Mon–Sun strip (ch-week): tap a day to see its workout.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key, required this.selected, required this.onPick});
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fin = ref.watch(workoutSessionProvider.select((s) => s.isFinished));
    const wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: const [BoxShadow(color: Color(0x14171717), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Row(children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Day(
              wd: wd[i],
              n: ClientTrainingMock.weekStart.day + i,
              on: i == selected,
              today: i == ClientTrainingMock.todayIndex,
              rest: ClientTrainingMock.week[i] == null,
              done: (i < ClientTrainingMock.todayIndex && ClientTrainingMock.week[i] != null) || (i == ClientTrainingMock.todayIndex && fin),
              onTap: () => onPick(i),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.wd, required this.n, required this.on, required this.today, required this.rest, required this.done, required this.onTap});
  final String wd;
  final int n;
  final bool on;
  final bool today;
  final bool rest;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = on ? Colors.white : AppColors.text;
    return Material(
      color: on ? AppColors.text : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 7, 0, 6),
          child: Column(children: [
            Text(wd, style: AppText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: on ? const Color(0xFFC9C9C9) : AppColors.text2)),
            const SizedBox(height: 3),
            Text('$n', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 3),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFF22C55E) : (today ? AppColors.accentSoft : (rest ? null : const Color(0xFFE8E8E4))),
                border: done
                    ? null
                    : today
                        ? Border.all(color: AppColors.accent, width: 2)
                        : rest
                            ? Border.all(color: const Color(0xFFCFCFC9), width: 1.5)
                            : null,
              ),
              child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
          ]),
        ),
      ),
    );
  }
}
