import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';

import '../widgets/auth_widgets.dart';
import 'setup_answers.dart';

/// Change callback: runs [fn] on the answers inside the parent's setState.
typedef Edit = void Function(void Function(SetupAnswers a) fn);

/// The five setup steps (ClientWelcome "onb" view, step 4 = ClientHealth design).
List<Widget> setupStepBody(int step, SetupAnswers a, Edit edit) => switch (step) {
      0 => _goalStep(a, edit),
      1 => _bodyStep(a, edit),
      2 => _daysStep(a, edit),
      3 => _healthStep(a, edit),
      _ => _foodStep(a, edit),
    };

// ---------------- 1 · Goal ----------------

List<Widget> _goalStep(SetupAnswers a, Edit edit) => [
      const QuestionHead('What’s your main goal?', subtitle: 'Aman builds your training and meals around it.'),
      _GoalGrid(selected: a.goal, onPick: (i) => edit((a) => a.goal = i)),
      if (a.goal >= 0) Hint(AuthMock.goals[a.goal].hint, icon: Icons.lightbulb_outline_rounded),
      const QuestionHead('Training experience'),
      SegChoice(items: AuthMock.levels, index: a.level, onChanged: (i) => edit((a) => a.level = i)),
    ];

class _GoalGrid extends StatelessWidget {
  const _GoalGrid({required this.selected, required this.onPick});
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final goals = AuthMock.goals;
    return Column(
      children: [
        for (var r = 0; r < goals.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _GoalCard(goals[r], on: selected == r, onTap: () => onPick(r))),
                const SizedBox(width: 8),
                Expanded(child: _GoalCard(goals[r + 1], on: selected == r + 1, onTap: () => onPick(r + 1))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard(this.g, {required this.on, required this.onTap});
  final GoalOption g;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectCard(
      on: on,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: on ? AppColors.accent : AppColors.sub, borderRadius: BorderRadius.circular(9)),
                child: Icon(g.icon, size: 17, color: on ? Colors.white : AppColors.text2),
              ),
              const SizedBox(height: 8),
              Text(g.name, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(g.subtitle, style: AppText.caption),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: on ? AppColors.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: 1.5),
              ),
              child: on ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 2 · About you ----------------

List<Widget> _bodyStep(SetupAnswers a, Edit edit) {
  void bump(int k, int dir) => edit((a) {
        final f = AuthMock.body[k];
        a.body[k] = (a.body[k] + dir * f.step).clamp(f.min, f.max).toDouble();
      });
  return [
    const QuestionHead('Body basics', subtitle: 'Aman uses this to set your calories and training load.'),
    Column(
      children: [
        for (var r = 0; r < 4; r += 2) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (final k in [r, r + 1]) ...[
                if (k != r) const SizedBox(width: 8),
                Expanded(
                  child: _BodyBox(
                    label: AuthMock.body[k].label,
                    value: a.bodyValue(k),
                    onMinus: () => bump(k, -1),
                    onPlus: () => bump(k, 1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    ),
    Hint(a.bodyLine, icon: Icons.track_changes_rounded),
    const QuestionHead('Where will you train?'),
    SegChoice(items: AuthMock.places, index: a.place, onChanged: (i) => edit((a) => a.place = i)),
    const Caption('Only you and your coach can see this.', icon: Icons.lock_outline_rounded),
  ];
}

class _BodyBox extends StatelessWidget {
  const _BodyBox({required this.label, required this.value, required this.onMinus, required this.onPlus});
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ValueStepper(value: value, onMinus: onMinus, onPlus: onPlus, expand: true),
        ],
      ),
    );
  }
}

// ---------------- 3 · Training days ----------------

List<Widget> _daysStep(SetupAnswers a, Edit edit) => [
      QuestionHead(
        'Which days can you train?',
        subtitle: a.days.isNotEmpty ? '${a.days.length} days a week · ${a.daysLine}' : 'Pick at least 2 days. Rest days are part of the plan.',
      ),
      AppCard(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _DayCell(
                  AuthMock.weekdays[i],
                  on: a.days.contains(i),
                  onTap: () => edit((a) => a.days.contains(i) ? a.days.remove(i) : a.days.add(i)),
                ),
              ),
            ],
          ],
        ),
      ),
      const QuestionHead('How long can you train?'),
      ChipWrap(
        items: AuthMock.lengths,
        isOn: (n) => n == AuthMock.lengths[a.length],
        onTap: (n) => edit((a) => a.length = AuthMock.lengths.indexOf(n)),
      ),
      const QuestionHead('Usual wake-up time'),
      ChipWrap(
        items: AuthMock.wakeTimes,
        isOn: (n) => n == AuthMock.wakeTimes[a.wake],
        onTap: (n) => edit((a) => a.wake = AuthMock.wakeTimes.indexOf(n)),
      ),
    ];

class _DayCell extends StatelessWidget {
  const _DayCell(this.label, {required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: on ? AppColors.accentText : AppColors.text2)),
              const SizedBox(height: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: on ? AppColors.accent : const Color(0xFFE8E8E4), shape: BoxShape.circle),
                child: on ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 4 · Health & injuries (ClientHealth design) ----------------

List<Widget> _healthStep(SetupAnswers a, Edit edit) => [
      const QuestionHead('Any injuries or pain?', subtitle: 'Aman swaps exercises so nothing hurts. Pick all that apply.'),
      ChipWrap(
        items: AuthMock.injuries,
        check: true,
        isOn: a.injuries.contains,
        onTap: (n) => edit((a) => a.injuries = SetupAnswers.toggleMulti(a.injuries, n)),
      ),
      if (a.realInjuries.isNotEmpty) ...[
        FakeField(label: 'Tell Aman more', value: a.activeNote),
        Transform.translate(
          offset: const Offset(0, -6),
          child: ChipWrap(
            small: true,
            items: a.noteOptions,
            isOn: (n) => n == a.activeNote,
            onTap: (n) => edit((a) => a.note = n),
          ),
        ),
      ],
      const QuestionHead('Any health conditions?', subtitle: 'Aman plans food and training around them.'),
      ChipWrap(
        items: AuthMock.conditions,
        check: true,
        isOn: a.conditions.contains,
        onTap: (n) => edit((a) => a.conditions = SetupAnswers.toggleMulti(a.conditions, n)),
      ),
      if (a.heart)
        const Hint(
          'With a heart condition, get your doctor’s OK before you start. Aman checks this before your first session.',
          tone: HintTone.amber,
        ),
      const QuestionHead('Daily activity', subtitle: 'Outside your workouts.'),
      RadioOptions(items: AuthMock.activity, index: a.activity, onChanged: (i) => edit((a) => a.activity = i)),
      CheckRow(
        on: a.doctor,
        onTap: () => edit((a) => a.doctor = !a.doctor),
        title: 'A doctor has cleared me for exercise',
        subtitle: a.heart ? 'Needed with a heart condition' : 'Tick this if you have a heart, bone or joint condition',
      ),
      const Caption('Only you and your coach can see this.', icon: Icons.lock_outline_rounded),
    ];

// ---------------- 5 · Food ----------------

List<Widget> _foodStep(SetupAnswers a, Edit edit) => [
      const QuestionHead('Food preference', subtitle: 'Your meal plan only uses foods you eat.'),
      _DietGrid(selected: a.diet, onPick: (i) => edit((a) => a.diet = i)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meals per day', style: AppText.bodyBold),
                  Text('Including snacks', style: AppText.caption),
                ],
              ),
            ),
            ValueStepper(
              value: '${a.meals} meals',
              valueWidth: 72,
              onMinus: () => edit((a) => a.meals = (a.meals - 1).clamp(2, 7)),
              onPlus: () => edit((a) => a.meals = (a.meals + 1).clamp(2, 7)),
            ),
          ],
        ),
      ),
      const QuestionHead('Foods you avoid', subtitle: 'Allergies or simply don’t like them.'),
      ChipWrap(
        items: AuthMock.avoidFoods,
        check: true,
        isOn: a.avoid.contains,
        onTap: (n) => edit((a) => a.avoid.contains(n) ? a.avoid.remove(n) : a.avoid.add(n)),
      ),
      CheckRow(
        on: a.homeFood,
        onTap: () => edit((a) => a.homeFood = !a.homeFood),
        title: 'I mostly eat home-cooked food',
        subtitle: 'Aman plans dal, roti and sabzi style meals',
      ),
    ];

class _DietGrid extends StatelessWidget {
  const _DietGrid({required this.selected, required this.onPick});
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final diets = AuthMock.diets;
    return Column(
      children: [
        for (var r = 0; r < diets.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _DietCard(diets[r], on: selected == r, onTap: () => onPick(r))),
              const SizedBox(width: 8),
              Expanded(
                child: r + 1 < diets.length
                    ? _DietCard(diets[r + 1], on: selected == r + 1, onTap: () => onPick(r + 1))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DietCard extends StatelessWidget {
  const _DietCard(this.d, {required this.on, required this.onTap});
  final DietOption d;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectCard(
      on: on,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _VegMark(d.mark),
              const SizedBox(width: 8),
              Expanded(child: Text(d.name, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(d.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

/// Indian veg / egg / non-veg mark (wl-dot).
class _VegMark extends StatelessWidget {
  const _VegMark(this.mark);
  final DietMark mark;

  @override
  Widget build(BuildContext context) {
    final c = switch (mark) {
      DietMark.green => const Color(0xFF16A34A),
      DietMark.amber => const Color(0xFFD97706),
      DietMark.red => const Color(0xFFB91C1C),
    };
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: c, width: 1.5)),
      child: mark == DietMark.red
          ? Icon(Icons.arrow_drop_up_rounded, size: 16, color: c)
          : Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    );
  }
}
