import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';

typedef _M = ClientProfileMock;

/// Prev / next arrows used in detail sheets (dr-pn).
class _PrevNext extends StatelessWidget {
  const _PrevNext({required this.label, required this.onPrev, required this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600))),
          AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous', onPressed: onPrev),
          const SizedBox(width: 6),
          AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next', onPressed: onNext),
        ],
      ),
    );
  }
}

// ───────────────────────── Exercise detail ─────────────────────────

void showExerciseSheet(BuildContext context, ClientProfileController c, String day, int index) {
  final d = c.workoutDays.firstWhere((x) => x.day == day);
  showCpSheet(context, title: d.exercises[index].shownName, subtitle: '${_M.fullDay[day]} · ${d.name}', builder: (_) => _ExerciseDetail(c, d, index));
}

class _ExerciseDetail extends StatefulWidget {
  const _ExerciseDetail(this.c, this.day, this.index);
  final ClientProfileController c;
  final WorkoutDay day;
  final int index;
  @override
  State<_ExerciseDetail> createState() => _ExerciseDetailState();
}

class _ExerciseDetailState extends State<_ExerciseDetail> {
  late int i = widget.index;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final d = widget.day;
    final list = d.exercises;
    final e = list[i];
    final g = _M.guides[e.name] ?? _M.defaultGuide;
    final mate = e.superset == null ? null : list.where((x) => x != e && x.superset == e.superset).firstOrNull;
    final note = e.note ?? (e.changed ? 'Keep the box low and go slow. Stop if the knee hurts.' : 'Control the way down, 2 seconds.');
    void edit() {
      Navigator.of(context).pop();
      c.openPlanEdit(plan: 'workout', day: d.day);
    }

    return SheetBody(
      note: e.changed ? c.r('Changed for Riya · master is the same') : 'Same as the master plan',
      actions: [
        AppButton.outline('Swap exercise', icon: Icons.swap_horiz_rounded, onPressed: edit),
        AppButton('Edit for ${c.first}', icon: Icons.edit_outlined, onPressed: edit),
      ],
      children: [
        _PrevNext(
          label: '${e.shownName} · exercise ${i + 1} of ${list.length}',
          onPrev: () => setState(() => i = (i - 1 + list.length) % list.length),
          onNext: () => setState(() => i = (i + 1) % list.length),
        ),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: MediaBox(
            icon: null,
            radius: 12,
            child: Stack(
              children: [
                const Center(child: CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.play_arrow_rounded, color: AppColors.text))),
                Positioned(right: 8, bottom: 8, child: _Pill(e.youtube ? '3:10' : '0:45')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.ondemand_video_rounded, size: 15, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(e.youtube ? 'YouTube · ${e.shownName} tutorial · 3:10' : 'Content library · ${e.shownName} demo · 0:45', style: AppText.caption),
            ),
          ],
        ),
        const SizedBox(height: 12),
        KpiStrip([
          ('Sets', e.sets),
          ('Reps', e.reps),
          ('Rest', e.rest),
          ('Load', e.load),
          ('RPE', e.rpe?.toString() ?? '–'),
          ('Tempo', e.tempo ?? '–'),
        ]),
        if (e.changed || e.programEdit != null) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (e.changed)
              Row(mainAxisSize: MainAxisSize.min, children: [AppBadge(c.r('Changed for Riya'), tone: BadgeTone.info), InfoTip(e.was!)]),
            if (e.programEdit != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const AppBadge('Edited in Fat Loss Phase 1', tone: BadgeTone.warn),
                InfoTip('Library name: ${e.programEdit!.libraryName}. Changed in the master program, so every client on it gets this version.'),
              ]),
          ]),
        ],
        if (mate != null) ...[
          const SizedBox(height: 10),
          InfoBanner(
            icon: Icons.link_rounded,
            bg: const Color(0xFFEFE9FB),
            fg: const Color(0xFF6D3FC9),
            text: 'Superset ${e.superset} with ${mate.shownName}: one set of each, then rest.',
          ),
        ],
        const SizedBox(height: 10),
        QuoteBox(lead: 'Note for ${c.first}', text: note),
        if (d.note != null) ...[const SizedBox(height: 8), QuoteBox(lead: 'Coach note for this day', text: d.note!)],
        const SubLabel('How to do it'),
        for (var s = 0; s < g.steps.length; s++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NumTag('${s + 1}'),
                const SizedBox(width: 8),
                Expanded(child: Text(g.steps[s], style: AppText.body.copyWith(fontSize: 13.5))),
              ],
            ),
          ),
        const SubLabel('Form cues'),
        for (final cue in g.cues)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.check_rounded, size: 16, color: AppColors.okText),
              const SizedBox(width: 6),
              Expanded(child: Text(cue, style: AppText.body.copyWith(fontSize: 13.5))),
            ]),
          ),
        const SubLabel('Muscles'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MediaBox(width: 64, height: 84, icon: Icons.accessibility_new_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  AppChip(g.primary, color: AppColors.accentSoft, textColor: AppColors.accentText),
                  const SizedBox(height: 8),
                  Text('Also works', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final a in g.also) AppChip(a)]),
                ],
              ),
            ),
          ],
        ),
        SubLabel("${c.first}'s last sessions"),
        QaList([
          ('Tue, 6 Oct', '${e.load} × ${e.reps.split('–').first} · all sets'),
          ('Tue, 29 Sep', '${e.load} × ${e.reps.split('–').first} · all sets'),
          ('Tue, 22 Sep', 'one step lighter · all sets'),
        ]),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xAA000000), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}

// ───────────────────────── Meal detail ─────────────────────────

void showMealSheet(BuildContext context, ClientProfileController c, String day, int index) {
  showCpSheet(context, title: 'Meal', subtitle: '${_M.fullDay[day]} · 1,650 kcal · high protein', builder: (_) => _MealDetail(c, day, index));
}

class _MealDetail extends StatefulWidget {
  const _MealDetail(this.c, this.day, this.index);
  final ClientProfileController c;
  final String day;
  final int index;
  @override
  State<_MealDetail> createState() => _MealDetailState();
}

class _MealDetailState extends State<_MealDetail> {
  late int i = widget.index;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final meals = _M.mealsFor(widget.day);
    final m = meals[i];
    return SheetBody(
      note: m.changed ? c.r('Changed for Riya · master is the same') : 'Same as the master plan',
      actions: [
        AppButton.outline('Close', onPressed: () => Navigator.of(context).pop()),
        AppButton('Edit for ${c.first}', icon: Icons.edit_outlined, onPressed: () {
          Navigator.of(context).pop();
          c.openPlanEdit(plan: 'meal');
        }),
      ],
      children: [
        _PrevNext(
          label: '${m.name} · ${m.time}',
          onPrev: () => setState(() => i = (i - 1 + meals.length) % meals.length),
          onNext: () => setState(() => i = (i + 1) % meals.length),
        ),
        KpiStrip([('Calories', '${m.kcal} kcal'), ('Protein', '${m.protein} g'), ('Foods', '${m.foods.length}'), ('Time', m.time)], columns: 2),
        SubLabel(
          'Foods',
          trailing: m.changed
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  AppBadge(c.r('Changed for Riya'), tone: BadgeTone.info),
                  InfoTip(m.name == 'Lunch' ? 'Paneer instead of moong dal. Rajma on Wednesdays.' : 'Added for training days.'),
                ])
              : null,
        ),
        for (final f in m.foods) _FoodLine(f.name, f.qty, f.kcal, '${f.p} g', '${f.c} g', '${f.f} g', swap: f.swap),
        _FoodLine('Meal total', '', m.kcal, '${m.protein} g', '${m.carbs} g', '${m.fat} g', total: true),
        const SizedBox(height: 10),
        QuoteBox(lead: 'How to make it', text: m.alt.isNotEmpty ? m.alt : (_M.mealHow[m.name] ?? '')),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FoodLine extends StatelessWidget {
  const _FoodLine(this.name, this.qty, this.kcal, this.p, this.c, this.f, {this.swap = '', this.total = false});
  final String name;
  final String qty;
  final int kcal;
  final String p;
  final String c;
  final String f;
  final String swap;
  final bool total;

  @override
  Widget build(BuildContext context) {
    Widget macro(Color col, String l, String v) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text.rich(TextSpan(style: AppText.caption, children: [
            TextSpan(text: '$l '),
            TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
          ])),
        ]);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: total ? AppColors.sub : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(name, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
            if (qty.isNotEmpty) Text(qty, style: AppText.caption),
            const SizedBox(width: 8),
            Text('$kcal kcal', style: AppText.bodyBold.copyWith(fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Wrap(spacing: 12, children: [
            macro(AppColors.protein, 'Protein', p),
            macro(AppColors.carbs, 'Carbs', c),
            macro(AppColors.fat, 'Fat', f),
          ]),
          if (swap.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(child: Text('Can swap for $swap', style: AppText.caption)),
            ]),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Log detail ─────────────────────────

const _logTitles = {
  'workouts': 'Workout log',
  'meals': 'Meal log',
  'daily': 'Daily check-in',
  'weekly': 'Weekly check-in',
  'habits': 'Habit log',
  'supps': 'Supplement log',
};

int _logCount(String kind) => switch (kind) {
      'workouts' => _M.workoutLog.length,
      'meals' => _M.mealLog.length,
      'daily' => _M.dailyLog.length,
      'weekly' => _M.weeklyLog.length,
      'habits' => _M.habitLog.length,
      _ => _M.suppLog.length,
    };

void showLogSheet(BuildContext context, ClientProfileController c, String kind, int index) {
  showCpSheet(context, title: _logTitles[kind]!, subtitle: c.name, builder: (_) => _LogDetail(c, kind, index.clamp(0, _logCount(kind) - 1)));
}

class _LogDetail extends StatefulWidget {
  const _LogDetail(this.c, this.kind, this.index);
  final ClientProfileController c;
  final String kind;
  final int index;
  @override
  State<_LogDetail> createState() => _LogDetailState();
}

class _LogDetailState extends State<_LogDetail> {
  late int i = widget.index;
  bool reviewed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final n = _logCount(widget.kind);
    final (title, body, foot) = switch (widget.kind) {
      'workouts' => _workout(),
      'meals' => _meals(),
      'daily' => _daily(),
      'weekly' => _weekly(),
      _ => _ticks(),
    };
    return SheetBody(
      note: foot,
      actions: [
        AppButton.outline('Close', onPressed: () => Navigator.of(context).pop()),
        if (widget.kind == 'weekly')
          AppButton(reviewed ? 'Reviewed' : 'Mark reviewed', icon: Icons.check_rounded, onPressed: reviewed
              ? null
              : () {
                  setState(() => reviewed = true);
                  Navigator.of(context).pop();
                  showToast(context, '${_M.weeklyLog[i].week} marked reviewed', subtitle: '${c.first} sees your reply in the app', kind: ToastKind.ok);
                }),
      ],
      children: [
        _PrevNext(label: title, onPrev: () => setState(() => i = (i - 1 + n) % n), onNext: () => setState(() => i = (i + 1) % n)),
        ...body,
        const SizedBox(height: 12),
      ],
    );
  }

  (String, List<Widget>, String) _workout() {
    final c = widget.c;
    final r = _M.workoutLog[i];
    final w = _M.workoutDays.where((d) => d.name == r.workout).firstOrNull ?? _M.workoutDays[4];
    final miss = r.status == 'miss';
    final part = r.status == 'part';
    final kpis = miss
        ? const [('Status', 'Missed'), ('Reason', 'Not given'), ('Reminder', 'Sent 7:00 pm'), ('Streak', 'Broken')]
        : part
            ? const [('Sets', '16 / 20'), ('Volume', '6,140 kg'), ('Time', '58 min'), ('Effort', '8 / 10')]
            : const [('Sets', '18 / 18'), ('Volume', '4,820 kg'), ('Time', '52 min'), ('Effort', '7 / 10')];
    final body = <Widget>[
      KpiStrip(kpis, columns: 2),
      const SizedBox(height: 10),
      if (!miss)
        for (var x = 0; x < w.exercises.length; x++) _setRow(w.exercises[x], x, part),
      if (!miss) ...[
        const SizedBox(height: 6),
        QuoteBox(lead: "${c.first}'s note", text: 'Knee felt okay on the box squat. Skipped the last 2 sets of lunges, legs were done.'),
        const SizedBox(height: 10),
        Row(children: [
          const MediaBox(tone: 1, width: 64, height: 64, icon: Icons.play_circle_outline_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Box squat, set 3', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              Text('Form check video · sent 7:42 pm', style: AppText.caption),
            ]),
          ),
          AppButton.outline('Watch', small: true, onPressed: () => showToast(context, 'Playing form check video', subtitle: '0:24', kind: ToastKind.info)),
        ]),
      ],
      ReplyBox(hint: 'Comment on this workout…', firstName: c.first),
    ];
    return ('${r.date} · ${w.name}', body, miss ? 'Not logged' : 'Logged in the Android app · 7:40 pm');
  }

  Widget _setRow(WorkoutExercise e, int x, bool part) {
    final k = int.tryParse(e.sets) ?? 1;
    final partial = part && x == 2;
    final reps = e.reps.split('–').first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumTag('${x + 1}', tone: partial ? BadgeTone.warn : BadgeTone.ok),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 6, children: [
                  Text(e.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  if (part && x == 0) const AppBadge('Form video', tone: BadgeTone.info),
                ]),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: [
                  for (var s = 0; s < k; s++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: partial && s >= k - 2 ? AppColors.badBg : AppColors.okBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('${e.load == 'Body' ? '' : '${e.load} × '}$reps',
                          style: AppText.caption.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w700, color: partial && s >= k - 2 ? AppColors.badText : AppColors.okText)),
                    ),
                ]),
              ],
            ),
          ),
          Text('${partial ? k - 2 : k} / $k sets', style: AppText.caption),
        ],
      ),
    );
  }

  (String, List<Widget>, String) _meals() {
    final c = widget.c;
    final r = _M.mealLog[i];
    final meals = _M.loggedMeals(r.status);
    final t = [0, 0, 0, 0];
    for (final m in meals) {
      for (final f in m.foods) {
        t[0] += f.kcal;
        t[1] += f.p;
        t[2] += f.c;
        t[3] += f.f;
      }
    }
    const names = ['Calories', 'Protein', 'Carbs', 'Fat'];
    const colors = [AppColors.accent, AppColors.protein, AppColors.carbs, AppColors.fat];
    final logged = meals.where((m) => m.logged).length;
    final pics = meals.where((m) => m.logged && m.photo).length;
    final off = meals.where((m) => m.badge != 'On plan').length;
    final body = <Widget>[
      LayoutBuilder(builder: (context, box) {
        final w = (box.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (var j = 0; j < 4; j++) SizedBox(width: w, child: _macroBox(names[j], j == 0 ? '' : ' g', t[j], _M.mealTargets[j], colors[j])),
        ]);
      }),
      HintLine('$logged of 5 meals logged · $pics with a photo · $off off plan'),
      for (final m in meals) _loggedMeal(m),
      ReplyBox(hint: 'Comment on her meals for this day…', firstName: c.first),
    ];
    return ('${r.date} · meals', body, 'Photos are added by ${c.first} when she logs a meal');
  }

  Widget _macroBox(String k, String u, int v, int tgt, Color col) {
    final d = v - tgt;
    final over = d > tgt * .05;
    String fmt(int n) => n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
    final note = d == 0 ? 'On target' : (d > 0 ? '${fmt(d)}$u over' : '${fmt(-d)}$u left');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
          Text.rich(TextSpan(children: [
            TextSpan(text: '${fmt(v)}$u', style: AppText.bodyBold.copyWith(fontSize: 15)),
            TextSpan(text: ' / ${fmt(tgt)}$u', style: AppText.caption),
          ])),
          const SizedBox(height: 4),
          ProgressBar(v / tgt, color: over ? AppColors.warn : col, height: 5),
          const SizedBox(height: 3),
          Text(note, style: AppText.caption.copyWith(fontSize: 11, color: over ? AppColors.warnText : AppColors.muted)),
        ],
      ),
    );
  }

  Widget _loggedMeal(LoggedMeal m) {
    final k = m.foods.fold(0, (a, f) => a + f.kcal);
    final p = m.foods.fold(0, (a, f) => a + f.p);
    final cc = m.foods.fold(0, (a, f) => a + f.c);
    final ff = m.foods.fold(0, (a, f) => a + f.f);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.logged && m.photo)
                GestureDetector(
                  onTap: () => showPhotoViewer(context, widget.c),
                  child: const MediaBox(tone: 1, width: 44, height: 44, icon: Icons.restaurant_rounded, radius: 8),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(8)),
                  child: Text('No photo', textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 9.5)),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(m.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      if (m.time.isNotEmpty) Text(m.time, style: AppText.caption),
                      AppBadge(m.badge, tone: m.tone),
                    ]),
                    const SizedBox(height: 3),
                    if (m.logged)
                      Text('$k kcal · Protein $p g · Carbs $cc g · Fat $ff g', style: AppText.caption.copyWith(color: AppColors.text2))
                    else
                      Text('Not logged. ${widget.c.first} got a reminder at 6:00 pm.', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          if (m.logged) ...[
            const SizedBox(height: 6),
            for (final f in m.foods)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(children: [
                  Expanded(child: Text(f.name, style: AppText.bodyBold.copyWith(fontSize: 12.5))),
                  Text('${f.qty} · ${f.kcal} kcal · P ${f.p} g', style: AppText.caption),
                ]),
              ),
          ],
          if (m.was.isNotEmpty) ...[
            const SizedBox(height: 6),
            InfoBanner(icon: Icons.info_outline_rounded, bg: AppColors.warnBg, fg: AppColors.warnText, text: 'Plan had ${m.was}'),
          ],
        ],
      ),
    );
  }

  (String, List<Widget>, String) _daily() {
    final r = _M.dailyLog[i];
    final none = !r.sent;
    return (
      '${r.date} · daily check-in',
      [
        KpiStrip([('Sleep', r.sleep), ('Energy', r.energy), ('Mood', r.mood), ('Steps', r.steps)], columns: 2),
        const SizedBox(height: 6),
        QaList([
          ('Hunger', r.hunger),
          ('Water', none ? '—' : '2.5 L'),
          ('Morning weight', none ? '—' : '71.4 kg'),
          ('Note', r.note),
        ]),
        ReplyBox(hint: 'Reply to her check-in…', firstName: widget.c.first),
      ],
      none ? 'Not sent · reminder went at 9:00 pm' : 'Sent at 8:05 am',
    );
  }

  (String, List<Widget>, String) _weekly() {
    final r = _M.weeklyLog[i];
    return (
      '${r.week} check-in · ${r.date}',
      [
        KpiStrip([('Weight', r.weight), ('Change', '−0.7 kg'), ('Workouts', '4 / 4'), ('Meals on plan', '86%')], columns: 2),
        const SizedBox(height: 6),
        const QaList(_M.weeklyAnswers),
        const SubLabel('Progress photos'),
        Row(children: [
          for (final (t, a) in const [(0, 'Front'), (2, 'Side'), (3, 'Back')]) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => showPhotoViewer(context, widget.c, angle: a),
                child: Column(children: [
                  AspectRatio(aspectRatio: 3 / 4, child: MediaBox(tone: t, icon: Icons.person_outline_rounded)),
                  const SizedBox(height: 4),
                  Text(a, style: AppText.caption),
                ]),
              ),
            ),
            if (a != 'Back') const SizedBox(width: 8),
          ],
        ]),
        ReplyBox(hint: 'Write your review for ${r.week.toLowerCase()}…', firstName: widget.c.first),
      ],
      'Sent ${r.date}, 6:15 pm',
    );
  }

  (String, List<Widget>, String) _ticks() {
    final habits = widget.kind == 'habits';
    final r = habits ? _M.habitLog[i] : _M.suppLog[i];
    final names = habits ? _M.habitDetail : _M.suppDetail;
    return (
      '${r.date} · ${habits ? 'habits' : 'supplements'}',
      [
        for (var j = 0; j < names.length; j++)
          CpRow(
            leading: _Tick(r.ticks[j]),
            title: names[j].$1,
            sub: names[j].$2,
            trailing: Text(r.ticks[j] ? (j == 2 ? '10:40 pm' : '9:15 am') : 'Not ticked', style: AppText.caption),
          ),
      ],
      'Ticked by ${widget.c.first} in the app',
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick(this.ok);
  final bool ok;
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: ok ? AppColors.okBg : AppColors.badBg, borderRadius: BorderRadius.circular(7)),
        child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, size: 15, color: ok ? AppColors.okText : AppColors.badText),
      );
}

/// Green tick / red cross used in tables.
class TickMark extends StatelessWidget {
  const TickMark(this.ok, {super.key});
  final bool ok;
  @override
  Widget build(BuildContext context) => _Tick(ok);
}

// ───────────────────────── Photos ─────────────────────────

void showAllPhotosSheet(BuildContext context, ClientProfileController c) {
  showCpSheet(context, title: 'All photos', subtitle: '${c.name} · 5 dates · 14 photos', builder: (_) => _AllPhotos(c));
}

class _AllPhotos extends StatefulWidget {
  const _AllPhotos(this.c);
  final ClientProfileController c;
  @override
  State<_AllPhotos> createState() => _AllPhotosState();
}

class _AllPhotosState extends State<_AllPhotos> {
  String angle = 'Front';

  @override
  Widget build(BuildContext context) {
    final dates = _M.photoDates.reversed.toList();
    return SheetBody(
      note: 'From weekly check-ins and the start photos',
      actions: [
        AppButton.outline('Close', onPressed: () => Navigator.of(context).pop()),
        AppButton('Compare two dates', icon: Icons.compare_rounded, onPressed: () => showPhotoViewer(context, widget.c, compare: true)),
      ],
      children: [
        Row(children: [
          Expanded(
            child: SegmentedTabs<String>(
              items: const [('Front', 'Front'), ('Side', 'Side'), ('Back', 'Back')],
              value: angle,
              onChanged: (v) => setState(() => angle = v),
            ),
          ),
          const SizedBox(width: 10),
          Text('5 dates · 14 photos', style: AppText.caption),
        ]),
        for (final d in dates) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(children: [
              Text(d.date, style: AppText.bodyBold),
              const SizedBox(width: 8),
              Text('${d.weight} · ${d.source}', style: AppText.caption),
            ]),
          ),
          Row(children: [
            for (final (j, a) in (d.date == '12 Jan' ? const ['Front', 'Side'] : const ['Front', 'Side', 'Back']).indexed) ...[
              if (j > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => showPhotoViewer(context, widget.c, date: _M.photoDates.indexOf(d), angle: a),
                  child: Column(children: [
                    AspectRatio(aspectRatio: 3 / 4, child: MediaBox(tone: const [0, 2, 3][j], icon: Icons.person_outline_rounded)),
                    const SizedBox(height: 4),
                    Text(a, style: AppText.caption),
                  ]),
                ),
              ),
            ],
            if (d.date == '12 Jan') ...[const SizedBox(width: 8), const Expanded(child: SizedBox())],
          ]),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Full-screen photo viewer (pv-back / phv) with angle tabs, compare and a date strip.
void showPhotoViewer(BuildContext context, ClientProfileController c, {int date = 4, String angle = 'Front', bool compare = false}) {
  showDialog(
    context: context,
    useRootNavigator: true,
    barrierColor: const Color(0xE6101010),
    builder: (_) => _PhotoViewer(date: date, angle: angle, compare: compare),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.date, required this.angle, required this.compare});
  final int date;
  final String angle;
  final bool compare;
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int d = widget.date;
  late String angle = widget.angle;
  late bool cmp = widget.compare;

  @override
  Widget build(BuildContext context) {
    final cur = _M.photoDates[d];
    final white = AppText.bodyBold.copyWith(color: Colors.white);
    final tones = {'Front': 0, 'Side': 2, 'Back': 3};
    Widget img(PhotoDate p) => AspectRatio(
          aspectRatio: 3 / 4,
          child: MediaBox(
            tone: (p.tone + tones[angle]!) % 4,
            icon: Icons.person_outline_rounded,
            radius: 12,
            child: Positioned(left: 8, bottom: 8, child: _Pill('${p.date} · ${p.weight}')),
          ),
        );
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Progress photos', style: white),
                    Text('${cur.date} · ${cur.weight} · from ${cur.source.toLowerCase()}',
                        style: AppText.caption.copyWith(color: Colors.white70)),
                  ]),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: Colors.white)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: SegmentedTabs<String>(
                    items: const [('Front', 'Front'), ('Side', 'Side'), ('Back', 'Back')],
                    value: angle,
                    onChanged: (v) => setState(() => angle = v),
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(cmp ? 'Compare' : 'Compare',
                    small: true,
                    icon: Icons.compare_rounded,
                    variant: cmp ? AppButtonVariant.primary : AppButtonVariant.outline,
                    onPressed: () => setState(() => cmp = !cmp)),
              ]),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: cmp
                      ? Row(children: [
                          Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            img(_M.photoDates[0]),
                            const SizedBox(height: 6),
                            Text('Start · 12 Jan', style: white.copyWith(fontSize: 12.5)),
                          ])),
                          const SizedBox(width: 8),
                          Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            img(cur),
                            const SizedBox(height: 6),
                            Text(cur.date, style: white.copyWith(fontSize: 12.5)),
                          ])),
                        ])
                      : Row(children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: Colors.white24),
                            onPressed: () => setState(() => d = (d + 4) % 5),
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: img(cur)),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: Colors.white24),
                            onPressed: () => setState(() => d = (d + 1) % 5),
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ),
                        ]),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 74,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var j = 0; j < _M.photoDates.length; j++)
                      GestureDetector(
                        onTap: () => setState(() => d = j),
                        child: Container(
                          width: 52,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(children: [
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: j == d ? Colors.white : Colors.transparent, width: 2),
                              ),
                              child: MediaBox(tone: _M.photoDates[j].tone, icon: null, radius: 7),
                            ),
                            const SizedBox(height: 3),
                            Text(_M.photoDates[j].date, style: AppText.caption.copyWith(color: Colors.white70, fontSize: 10.5)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Content preview ─────────────────────────

void showContentSheet(BuildContext context, ClientProfileController c, ClientContent x) {
  showCpSheet(
    context,
    title: 'Content preview',
    subtitle: 'Exactly what ${c.first} sees in her app',
    builder: (ctx) => SheetBody(
      lead: Align(
        alignment: Alignment.centerLeft,
        child: CpTextButton('${x.assigned ? 'Remove' : 'Hide'} for ${c.first}', danger: true, icon: Icons.delete_outline_rounded, size: 13, onTap: () {
          Navigator.of(ctx).pop();
          c.hideContent(x.title);
          showToast(context, '${x.assigned ? 'Removed' : 'Hidden'} for ${c.first}', subtitle: x.title, kind: ToastKind.del, onUndo: () => c.showContent(x.title));
        }),
      ),
      actions: [
        AppButton.outline('Open in library', icon: Icons.open_in_new_rounded, onPressed: () {
          Navigator.of(ctx).pop();
          showToast(context, 'Opening ${x.title} in the library', kind: ToastKind.info);
        }),
        AppButton('Remind her', icon: Icons.notifications_active_outlined, onPressed: () {
          Navigator.of(ctx).pop();
          showToast(context, 'Reminder sent to ${c.first}', subtitle: x.title, kind: ToastKind.ok);
        }),
      ],
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: MediaBox(
            icon: x.type == 'Video' ? null : Icons.description_outlined,
            radius: 12,
            child: Stack(children: [
              if (x.type == 'Video')
                const Center(child: CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.play_arrow_rounded, color: AppColors.text))),
              Positioned(right: 8, bottom: 8, child: _Pill(x.len)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(x.title, style: AppText.cardTitle),
        Text('${x.type} · by ${x.by}', style: AppText.caption),
        const SizedBox(height: 10),
        KpiStrip(x.kpis),
        const SizedBox(height: 6),
        QaList([('Why she sees it', c.r(x.why)), ('Shown until', x.until), ('Added', x.added)]),
        SubLabel('What ${c.first} reads'),
        Text(x.text, style: AppText.body),
        const SizedBox(height: 12),
      ],
    ),
  );
}
