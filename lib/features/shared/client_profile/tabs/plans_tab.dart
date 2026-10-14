import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import '../sheets/detail_sheets.dart';
import '../sheets/profile_sheets.dart';
import 'plan_editors.dart';

typedef _M = ClientProfileMock;

/// Plans tab: sub tabs Workout / Meal plan / Supplements / Habits, each with a read view
/// and an "Edit for Riya" editor (or "Duplicate and edit").
class PlansTab extends StatelessWidget {
  const PlansTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    if (c.planEdit) return PlanEditor(kind: c.planTab);
    return Spaced(
      children: [
        Row(
          children: [
            Expanded(child: CpSubTabs(items: _M.planTabs, value: c.planTab, onChanged: c.setPlanTab)),
          ],
        ),
        AppButton.outline('Assign new plan', icon: Icons.add_rounded, small: true, onPressed: () => showAssignPlanSheet(context, c, c.planTab)),
        ...switch (c.planTab) {
          'meal' => const [_MealView()],
          'supp' => const [_SuppView()],
          'habit' => const [_HabitView()],
          _ => const [_WorkoutView()],
        },
      ],
    );
  }
}

/// Title row of a current plan card with badges and the actions (Edit for Riya + ⋯ menu).
class _PlanHead extends StatelessWidget {
  const _PlanHead({required this.title, required this.cap, required this.kind, this.edited = true});
  final String title;
  final String cap;
  final String kind;
  final bool edited;

  static const _what = {'workout': 'master program', 'meal': 'master meal plan', 'supp': 'master supplement plan', 'habit': 'master habit plan'};

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: AppText.cardTitle),
              const AppBadge.status('Current', tone: BadgeTone.ok),
              if (edited) AppBadge(c.r('Edited for Riya'), tone: BadgeTone.info),
              InfoTip('Changes here apply only to ${c.first}. The ${_what[kind]} in the library stays the same.'),
            ],
          ),
          const SizedBox(height: 3),
          Text(c.r(cap), style: AppText.caption),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton.outline('Edit for ${c.first}', icon: Icons.edit_outlined, small: true, onPressed: () => c.openPlanEdit(plan: kind)),
              ),
              const SizedBox(width: 8),
              AppIconButton(Icons.more_horiz_rounded, small: true, tooltip: 'More actions', onPressed: () => _menu(context, c)),
            ],
          ),
        ],
      ),
    );
  }

  void _menu(BuildContext context, ClientProfileController c) {
    showActionSheet(context, title: title, actions: [
      SheetAction('Duplicate and edit', Icons.copy_rounded, () => c.openPlanEdit(plan: kind, duplicate: true)),
      SheetAction('Replace with another plan', Icons.swap_horiz_rounded, () => showAssignPlanSheet(context, c, kind)),
      SheetAction('Reset to master', Icons.restart_alt_rounded, () async {
        final ok = await showConfirmDialog(context,
            title: 'Reset to master?',
            message: 'Changes made for ${c.first} are removed. She gets the master plan from tomorrow.',
            confirmLabel: 'Reset',
            icon: Icons.restart_alt_rounded);
        if (ok && context.mounted) {
          if (kind == 'workout') c.restoreWorkout([..._M.workoutDays]);
          if (kind == 'meal') c.setMeals([..._M.editorMeals]);
          showToast(context, 'Reset to master', subtitle: title, kind: ToastKind.ok);
        }
      }),
      SheetAction('Open master plan', Icons.open_in_new_rounded, () => showToast(context, 'Opening the master plan', subtitle: title, kind: ToastKind.info)),
      SheetAction('End this plan', Icons.stop_circle_outlined, destructive: true, () async {
        final ok = await showConfirmDialog(context,
            title: 'End $title?',
            message: 'It moves to Plan history today. ${c.first} stops seeing it in her app.',
            confirmLabel: 'End plan',
            destructive: true,
            icon: Icons.stop_circle_outlined);
        if (ok && context.mounted) showToast(context, 'Plan ended', subtitle: '$title moved to Plan history', kind: ToastKind.del);
      }),
    ]);
  }
}

/// Day picker strip (pd-days): day, short label, blue dot when changed.
class DayStrip extends StatelessWidget {
  const DayStrip({super.key, required this.days, required this.value, required this.onPick});
  final List<(String, String, bool, bool)> days; // day, label, edited, rest
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (d, n, ed, rest) in days)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => onPick(d),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 74,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: d == value ? AppColors.accentSoft : (rest ? const Color(0xFFFAFAF8) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: d == value ? AppColors.accent : AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(d, style: AppText.bodyBold.copyWith(fontSize: 13, color: d == value ? AppColors.accentText : AppColors.text)),
                        const Spacer(),
                        if (ed) Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                      ]),
                      Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "A1"/"1" style tags for a day's exercises (supersets share a letter).
List<(String, bool)> exerciseTags(List<WorkoutExercise> ex) {
  var k = 0;
  final seen = <String, int>{};
  return [
    for (final e in ex)
      if (e.superset == null) ('${++k}', false) else ('${e.superset}${seen[e.superset!] = (seen[e.superset!] ?? 0) + 1}', true),
  ];
}

String exerciseMeta(WorkoutExercise e) => [
      if (e.rpe != null) 'RPE ${e.rpe}',
      if (e.tempo != null) 'tempo ${e.tempo}',
      if (e.rest != '—') 'rest ${e.rest}',
      e.load,
    ].join(' · ');

class _WorkoutView extends StatelessWidget {
  const _WorkoutView();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final day = c.workoutDays.firstWhere((d) => d.day == c.viewDay);
    final tags = exerciseTags(day.exercises);
    return Spaced(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PlanHead(
                title: 'Fat Loss Phase 1',
                kind: 'workout',
                cap: 'From master "Fat Loss Phase 1" · 1 Sep – 24 Nov · week 6 of 12 · 4 workouts a week',
              ),
              DayStrip(
                days: [for (final d in c.workoutDays) (d.day, d.name, d.edited, d.isRest)],
                value: c.viewDay,
                onPick: c.setViewDay,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_M.fullDay[day.day]} · ${day.name}', style: AppText.bodyBold),
                      Text(
                        day.isRest
                            ? 'Rest day'
                            : '${day.exercises.length} exercises · ${day.totalSets} sets · ~${day.exercises.length > 1 ? 55 : 35} min · tap an exercise to see it',
                        style: AppText.caption,
                      ),
                    ]),
                  ),
                  if (day.edited) AppBadge(c.r('Edited for Riya'), tone: BadgeTone.info),
                ]),
              ),
              if (day.note != null)
                Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: QuoteBox(lead: 'Coach note for this day', text: day.note!)),
              if (day.isRest)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text('Rest day. ${c.first} only sees her step goal: walk 8,000 steps.', style: AppText.secondary),
                )
              else
                CpRows([
                  for (var i = 0; i < day.exercises.length; i++) _ExerciseRow(day.exercises[i], tags[i], () => showExerciseSheet(context, c, day.day, i)),
                ]),
            ],
          ),
        ),
        CpCard(
          title: 'Up next',
          child: CpRows([
            CpRow(
              icon: Icons.upcoming_outlined,
              tone: BadgeTone.info,
              title: 'Fat Loss Phase 2',
              sub: 'Starts Wed, 25 Nov · 8 weeks · set by ${c.trainer}',
              trailing: AppButton.outline('Change', small: true, onPressed: () => showAssignPlanSheet(context, c, 'workout')),
            ),
          ]),
        ),
        const _History(_M.workoutHistory),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(this.e, this.tag, this.onTap);
  final WorkoutExercise e;
  final (String, bool) tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumTag(tag.$1, superset: tag.$2),
            const SizedBox(width: 8),
            const MediaBox(width: 40, height: 40, icon: Icons.play_arrow_rounded, radius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(e.shownName, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    if (e.changed) AppBadge(c.r('Changed for Riya'), tone: BadgeTone.info),
                    if (e.programEdit != null) const AppBadge('Edited in program', tone: BadgeTone.warn),
                  ]),
                  const SizedBox(height: 2),
                  Text.rich(TextSpan(style: AppText.caption, children: [
                    TextSpan(text: '${e.sets} × ${e.reps}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text2)),
                    TextSpan(text: ' · ${exerciseMeta(e)}'),
                  ])),
                  if (e.note != null) ...[
                    const SizedBox(height: 3),
                    Text(e.note!, style: AppText.caption.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History(this.items);
  final List<PlanHistoryItem> items;
  @override
  Widget build(BuildContext context) {
    return CpCard(
      title: 'Plan history',
      count: items.length,
      child: CpRows([
        for (final h in items) CpRow(title: h.name, bold: true, sub: h.dates, trailing: AppBadge.status(h.badge, tone: h.tone)),
      ]),
    );
  }
}

class _NextEmpty extends StatelessWidget {
  const _NextEmpty(this.text, this.kind);
  final String text;
  final String kind;
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'Up next',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(children: [
          Expanded(child: Text(text, style: AppText.secondary)),
          const SizedBox(width: 8),
          AppButton.outline('Choose next plan', icon: Icons.add_rounded, small: true, onPressed: () => showAssignPlanSheet(context, c, kind)),
        ]),
      ),
    );
  }
}

class _MealView extends StatelessWidget {
  const _MealView();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final meals = _M.mealsFor(c.mealDay);
    final kcal = meals.fold(0, (a, m) => a + m.kcal);
    final prot = meals.fold(0, (a, m) => a + m.protein);
    final changed = c.mealDay == 'Wed' || c.mealDay == 'Sat';
    String fmt(int n) => n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
    return Spaced(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PlanHead(
                title: '1,650 kcal · high protein',
                kind: 'meal',
                cap: 'From master "Veg fat loss 1,600" · since 1 Sep · lunch: paneer instead of moong dal',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  for (final (v, l) in _M.macros)
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v, style: AppText.bodyBold.copyWith(fontSize: 16)),
                        Text(l, style: AppText.caption.copyWith(fontSize: 11.5)),
                      ]),
                    ),
                ]),
              ),
              DayStrip(
                days: [
                  for (final d in _M.days) (d, '${fmt(_M.mealsFor(d).fold(0, (a, m) => a + m.kcal))} kcal', d == 'Wed' || d == 'Sat', false),
                ],
                value: c.mealDay,
                onPick: c.setMealDay,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_M.fullDay[c.mealDay]} · ${meals.length} meals', style: AppText.bodyBold),
                      Text('${fmt(kcal)} kcal · P $prot g · tap a meal to see the foods', style: AppText.caption),
                    ]),
                  ),
                  if (changed) AppBadge(c.r('Edited for Riya'), tone: BadgeTone.info),
                ]),
              ),
              CpRows([
                for (var i = 0; i < meals.length; i++)
                  CpRow(
                    leading: SizedBox(width: 58, child: Text(meals[i].time, style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
                    title: meals[i].name,
                    titleWidget: Wrap(spacing: 6, children: [
                      Text(meals[i].name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      if (meals[i].changed) const AppBadge('Changed', tone: BadgeTone.info),
                    ]),
                    sub: meals[i].foods.map((f) => f.name).join(', '),
                    trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${meals[i].kcal} kcal', style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                      Text('P ${meals[i].protein} g', style: AppText.caption.copyWith(color: AppColors.protein, fontWeight: FontWeight.w700)),
                    ]),
                    chevron: true,
                    onTap: () => showMealSheet(context, c, c.mealDay, i),
                  ),
              ]),
            ],
          ),
        ),
        const _NextEmpty('No next meal plan yet. The current one keeps going.', 'meal'),
        const _History(_M.mealHistory),
      ],
    );
  }
}

class _SuppView extends StatelessWidget {
  const _SuppView();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return Spaced(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PlanHead(
                title: 'Fat loss basics',
                kind: 'supp',
                cap: 'From master "Fat loss basics" · since 1 Sep · Magnesium added for sleep',
              ),
              CpRows([
                for (final s in _M.supplements)
                  CpRow(icon: Icons.medication_outlined, title: s.name, sub: s.sub, trailing: Text(c.r(s.cap), style: AppText.caption)),
              ]),
            ],
          ),
        ),
        const _NextEmpty('No next supplement plan.', 'supp'),
        const _History([PlanHistoryItem('Fat loss basics', '1 Sep – now', 'Current', BadgeTone.ok)]),
      ],
    );
  }
}

class _HabitView extends StatelessWidget {
  const _HabitView();
  static const _icons = [Icons.directions_walk_rounded, Icons.water_drop_outlined, Icons.bedtime_outlined, Icons.no_food_outlined];
  @override
  Widget build(BuildContext context) {
    return Spaced(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PlanHead(
                title: 'Daily basics',
                kind: 'habit',
                edited: false,
                cap: 'From master "Daily basics" · since 12 Jan · 1 habit starts next week',
              ),
              CpRows([
                for (var i = 0; i < _M.habits.length; i++)
                  CpRow(icon: _icons[i], title: _M.habits[i].title, sub: _M.habits[i].sub, trailing: Text(_M.habits[i].cap, style: AppText.caption)),
              ]),
            ],
          ),
        ),
        const _NextEmpty('No next habit plan.', 'habit'),
        const _History([PlanHistoryItem('Daily basics', '12 Jan – now', 'Current', BadgeTone.ok)]),
      ],
    );
  }
}
