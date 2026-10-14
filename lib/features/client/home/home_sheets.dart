import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/training_widgets.dart';
import 'home_cards.dart';

const _wdLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Row used in the home lists (ch-n): icon, title, subtitle, trailing.
class _ListRow extends StatelessWidget {
  const _ListRow({required this.icon, required this.tint, required this.title, required this.subtitle, this.trailing, this.isNew = false, this.first = false, this.onTap});
  final IconData icon;
  final String tint;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isNew;
  final bool first;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: first ? null : const Border(top: BorderSide(color: AppColors.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TintIcon(icon, tint: tintOf(tint), size: 32),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                if (isNew) ...[
                  const SizedBox(width: 6),
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                ],
              ]),
              Text(subtitle, style: AppText.caption),
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
      ),
    );
  }
}

/// All exercises of a day.
Future<void> showWorkoutPreview(BuildContext context, PlanDay p, int day) {
  return showAppSheet<void>(
    context,
    title: p.title,
    subtitle: '${_wdLong[day]} · ${p.exercises.length} exercises',
    builder: (_) => Column(children: [
      for (var i = 0; i < p.exercises.length; i++)
        _ListRow(icon: Icons.fitness_center_rounded, tint: 'blue', title: p.exercises[i].name, subtitle: p.exercises[i].detail, first: i == 0),
    ]),
  );
}

/// Notifications. Returns true when "Mark all as read" was tapped.
Future<bool?> showNotificationsSheet(BuildContext context, {required bool read}) {
  const list = ClientHomeMock.notifications;
  return showAppSheet<bool>(
    context,
    title: 'Notifications',
    subtitle: read ? 'All read' : '2 new',
    builder: (ctx) => Column(children: [
      for (var i = 0; i < list.length; i++)
        _ListRow(
          icon: feedIcon(list[i].icon),
          tint: list[i].tint,
          title: list[i].title,
          subtitle: list[i].subtitle,
          isNew: !read && i < 2,
          first: i == 0,
          trailing: Text(list[i].when, style: AppText.caption.copyWith(fontSize: 11.5)),
          onTap: list[i].link == null
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  context.go(list[i].link!);
                },
        ),
    ]),
    actions: (ctx) => [AppButton.outline('Mark all as read', icon: Icons.done_all_rounded, onPressed: () => Navigator.of(ctx).pop(true))],
  );
}

/// "Log food": plan meals for today with "Ate it".
Future<void> showLogFoodSheet(BuildContext context, {required List<int> Function() eaten, required ValueChanged<int> onEat}) {
  const meals = ClientTrainingMock.meals;
  return showLiveSheet<void>(
    context,
    builder: (ctx, setSheet) {
      final e = eaten();
      return SheetContent(
        title: 'Log food',
        subtitle: 'What did you eat?',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchField(
              hint: 'Search foods, e.g. dal, roti, paneer',
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            Text('FROM YOUR PLAN TODAY', style: AppText.overline.copyWith(fontSize: 12, letterSpacing: .5)),
            const SizedBox(height: 4),
            for (var i = 0; i < meals.length; i++)
              _ListRow(
                icon: Icons.restaurant_rounded,
                tint: e.contains(i) ? 'green' : 'gray',
                title: meals[i].food,
                subtitle: '${meals[i].meal}, ${meals[i].time} · ${meals[i].kcal} kcal',
                first: i == 0,
                trailing: e.contains(i)
                    ? const OkLabel('Logged', icon: false)
                    : AppButton.outline('Ate it', small: true, onPressed: () {
                        onEat(i);
                        setSheet(() {});
                      }),
              ),
          ],
        ),
      );
    },
  );
}

/// Big value with − / + (ch-big).
class _BigStepper extends StatelessWidget {
  const _BigStepper({required this.value, required this.caption, required this.onMinus, required this.onPlus});
  final String value;
  final String caption;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, String tip, VoidCallback f) => Tooltip(
          message: tip,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
            child: InkWell(customBorder: const CircleBorder(), onTap: f, child: SizedBox(width: 46, height: 46, child: Icon(i, color: AppColors.text2))),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        btn(Icons.remove_rounded, 'Less', onMinus),
        Expanded(
          child: Column(children: [
            Text(value, style: AppText.bigNumber.copyWith(fontSize: 34)),
            Text(caption, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
        ),
        btn(Icons.add_rounded, 'More', onPlus),
      ]),
    );
  }
}

/// Quick pick buttons (ch-qs).
class QuickPicks extends StatelessWidget {
  const QuickPicks({super.key, required this.items, this.selected});
  final List<(String, VoidCallback)> items;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (t, f) in items)
          SizedBox(
            height: 38,
            child: Material(
              color: t == selected ? AppColors.text : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: t == selected ? AppColors.text : AppColors.line)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: f,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Text(t, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: t == selected ? Colors.white : AppColors.text)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Add steps". Returns the new count.
Future<int?> showStepsSheet(BuildContext context, int steps) {
  var v = steps;
  return showLiveSheet<int>(
    context,
    builder: (ctx, setSheet) => SheetContent(
      title: 'Add steps',
      subtitle: 'Goal 8,000 steps a day',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigStepper(
            value: TNum.n(v),
            caption: 'steps today',
            onMinus: () => setSheet(() => v = (v - 500).clamp(0, 1 << 30)),
            onPlus: () => setSheet(() => v += 500),
          ),
          QuickPicks(items: [for (final q in [1000, 2000, 5000, 10000]) ('+${TNum.n(q)}', () => setSheet(() => v += q))]),
          const SizedBox(height: 12),
          ProgressBar(v / 8000, color: const Color(0xFF22C55E), height: 8),
          const SizedBox(height: 8),
          Text(v >= 8000 ? 'Goal reached' : '${TNum.n(8000 - v)} steps to go', style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [AppButton('Save steps', icon: Icons.check_rounded, onPressed: () => Navigator.of(ctx).pop(v))],
    ),
  );
}

/// "How long did you sleep?". Returns minutes.
Future<int?> showSleepSheet(BuildContext context, int minutes) {
  var v = minutes;
  return showLiveSheet<int>(
    context,
    builder: (ctx, setSheet) => SheetContent(
      title: 'How long did you sleep?',
      subtitle: 'Last night · goal 7 hours',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigStepper(
            value: fmtHm(v),
            caption: v >= 420 ? 'Goal met' : '${fmtHm(420 - v)} short of 7 h',
            onMinus: () => setSheet(() => v = (v - 15).clamp(0, 900)),
            onPlus: () => setSheet(() => v = (v + 15).clamp(0, 900)),
          ),
          QuickPicks(
            selected: v % 60 == 0 ? '${v ~/ 60} h' : null,
            items: [for (final h in [5, 6, 7, 8, 9, 10]) ('$h h', () => setSheet(() => v = h * 60))],
          ),
        ],
      ),
      actions: [AppButton('Save sleep', icon: Icons.check_rounded, onPressed: () => Navigator.of(ctx).pop(v))],
    ),
  );
}
