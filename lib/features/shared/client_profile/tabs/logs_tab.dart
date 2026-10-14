import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import '../sheets/detail_sheets.dart';

typedef _M = ClientProfileMock;

/// Date range picker button shared by Logs, Progress and the Overview weight card.
class RangeButton extends StatelessWidget {
  const RangeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final label = _M.ranges.firstWhere((r) => r.$1 == c.range).$2;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final v = await pickOption(context, title: 'Date range', options: [for (final r in _M.ranges) r.$2], current: label);
        if (v != null) c.setRange(_M.ranges.firstWhere((r) => r.$2 == v).$1);
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text))),
          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
        ]),
      ),
    );
  }
}

BadgeTone _statusTone(String s) => switch (s) {
      'done' || 'ok' => BadgeTone.ok,
      'part' => BadgeTone.warn,
      _ => BadgeTone.bad,
    };

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    if (c.compare) return const ComparePlans();
    final r = _M.ranges.firstWhere((x) => x.$1 == c.range);
    return Spaced(
      children: [
        CpSubTabs(items: _M.logTabs, value: c.logTab, onChanged: c.setLogTab),
        Row(children: [
          const Flexible(child: RangeButton()),
          const SizedBox(width: 8),
          AppButton.outline('Compare plans', icon: Icons.compare_arrows_rounded, small: true, onPressed: () => c.setCompare(true)),
        ]),
        Text('${r.$2} · ${r.$3}', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
        switch (c.logTab) {
          'meals' => const _Meals(),
          'daily' => const _Daily(),
          'weekly' => const _Weekly(),
          'habits' => const _Ticks(habits: true),
          'supps' => const _Ticks(habits: false),
          _ => const _Workouts(),
        },
      ],
    );
  }
}

class _Workouts extends StatelessWidget {
  const _Workouts();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    const l = _M.workoutLog;
    return CpCard(
      title: 'Workout log',
      cap: 'Open a workout to see every set',
      child: PfCards([
        for (var i = 0; i < l.length; i++)
          PfItem(
            head: Text(l[i].date),
            action: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.chevron_right_rounded, color: AppColors.muted)),
            onTap: () => showLogSheet(context, c, 'workouts', i),
            fields: [
              ('Workout', PfText(l[i].workout, bold: true)),
              ('Sets done', PfText(l[i].sets)),
              ('Volume', PfText(l[i].volume)),
              ('Time', PfText(l[i].time)),
              ('Status', AppBadge.status(switch (l[i].status) { 'done' => 'Done', 'part' => 'Partly', _ => 'Missed' }, tone: _statusTone(l[i].status))),
            ],
          ),
      ]),
    );
  }
}

class _Meals extends StatelessWidget {
  const _Meals();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    const l = _M.mealLog;
    return CpCard(
      title: 'Meal log',
      cap: 'Target 1,650 kcal · 120 g protein',
      child: PfCards([
        for (var i = 0; i < l.length; i++)
          PfItem(
            head: Text(l[i].date),
            action: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.chevron_right_rounded, color: AppColors.muted)),
            onTap: () => showLogSheet(context, c, 'meals', i),
            wide: Row(children: [
              SizedBox(width: 140, child: ProgressBar(l[i].pct, color: l[i].status == 'over' ? AppColors.bad : AppColors.accent)),
              const SizedBox(width: 8),
              Text(l[i].kcal, style: AppText.bodyBold.copyWith(fontSize: 13)),
              Text(' / 1,650', style: AppText.caption),
            ]),
            fields: [
              ('Protein', PfText(l[i].protein)),
              ('Carbs', PfText(l[i].carbs)),
              ('Fat', PfText(l[i].fat)),
              ('Meals logged', PfText(l[i].meals)),
              ('On plan', AppBadge.status(switch (l[i].status) { 'ok' => 'On plan', 'over' => 'Over', _ => 'Partly' }, tone: _statusTone(l[i].status))),
            ],
          ),
      ]),
    );
  }
}

class _Daily extends StatelessWidget {
  const _Daily();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    const l = _M.dailyLog;
    return CpCard(
      title: 'Daily check-ins',
      cap: '6 of 7 sent this week',
      child: PfCards([
        for (var i = 0; i < l.length; i++)
          PfItem(
            head: Text(l[i].date),
            onTap: () => showLogSheet(context, c, 'daily', i),
            fields: [
              ('Sleep', PfText(l[i].sleep)),
              ('Energy', PfText(l[i].energy)),
              ('Mood', PfText(l[i].mood)),
              ('Hunger', PfText(l[i].hunger)),
              ('Steps', PfText(l[i].steps)),
              ('Note', l[i].sent ? PfText(l[i].note, muted: true) : const AppBadge.status('Not sent', tone: BadgeTone.bad)),
            ],
          ),
      ]),
    );
  }
}

class _Weekly extends StatelessWidget {
  const _Weekly();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    const l = _M.weeklyLog;
    return CpCard(
      title: 'Weekly check-ins',
      cap: 'Due every Sunday',
      child: CpRows([
        for (var i = 0; i < l.length; i++)
          CpRow(
            title: l[i].week,
            sub: l[i].sub.replaceAll('Aman Verma', c.trainer),
            trailing: AppBadge.status(l[i].badge, tone: l[i].tone),
            chevron: true,
            onTap: () => showLogSheet(context, c, 'weekly', i),
          ),
      ]),
    );
  }
}

class _Ticks extends StatelessWidget {
  const _Ticks({required this.habits});
  final bool habits;
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final l = habits ? _M.habitLog : _M.suppLog;
    final names = habits ? _M.habitNames : _M.suppNames;
    return CpCard(
      title: habits ? 'Habit log' : 'Supplement log',
      cap: habits ? '3 habits a day' : 'Ticked by ${c.first} in the app',
      child: PfCards([
        for (var i = 0; i < l.length; i++)
          PfItem(
            head: Text(l[i].date),
            onTap: () => showLogSheet(context, c, habits ? 'habits' : 'supps', i),
            fields: [
              for (var j = 0; j < names.length; j++) (names[j], Align(alignment: Alignment.centerLeft, child: TickMark(l[i].ticks[j]))),
              ('Done', AppBadge.status('${l[i].done} / 3', tone: l[i].done == 3 ? BadgeTone.ok : BadgeTone.warn)),
            ],
          ),
      ]),
    );
  }
}

// ───────────────────────── Compare plans ─────────────────────────

class ComparePlans extends StatefulWidget {
  const ComparePlans({super.key});
  @override
  State<ComparePlans> createState() => _ComparePlansState();
}

class _ComparePlansState extends State<ComparePlans> {
  String aspect = 'all';
  bool swapped = false;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final a = swapped ? _M.comparePlanB : _M.comparePlanA;
    final b = swapped ? _M.comparePlanA : _M.comparePlanB;
    return Spaced(
      children: [
        Align(alignment: Alignment.centerLeft, child: AppButton.outline('Back to logs', icon: Icons.arrow_back_rounded, small: true, onPressed: () => c.setCompare(false))),
        Text.rich(TextSpan(style: AppText.secondary, children: const [
          TextSpan(text: 'Averages per week of each plan · B is better on '),
          TextSpan(text: '39 of 46', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.okText)),
          TextSpan(text: ' numbers'),
        ])),
        _PlanPick('A', a, const Color(0xFFB8C2D3)),
        Center(
          child: AppIconButton(Icons.swap_vert_rounded, small: true, tooltip: 'Swap A and B', onPressed: () => setState(() => swapped = !swapped)),
        ),
        _PlanPick('B', b, AppColors.accent),
        FChipBar(items: _M.compareAspects, value: aspect, onChanged: (v) => setState(() => aspect = v)),
        for (final s in _M.compare)
          if (aspect == 'all' || aspect == s.id) _CompareCard(s, swapped),
      ],
    );
  }
}

class _PlanPick extends StatelessWidget {
  const _PlanPick(this.letter, this.plan, this.color);
  final String letter;
  final (String, String) plan;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => showToast(context, 'Only 2 plans so far', subtitle: 'More plans show here once ${ProfileScope.read(context).first} finishes them', kind: ToastKind.info),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
          child: Text(letter, style: AppText.bodyBold.copyWith(color: Colors.white, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.$1, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
            Text(plan.$2, style: AppText.caption),
          ]),
        ),
        const Icon(Icons.expand_more_rounded, color: AppColors.muted),
      ]),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard(this.s, this.swapped);
  final CompareSection s;
  final bool swapped;

  static const _icons = {
    'workouts': Icons.fitness_center_rounded,
    'meals': Icons.restaurant_rounded,
    'checkins': Icons.fact_check_outlined,
    'habits': Icons.check_circle_outline_rounded,
    'supps': Icons.medication_outlined,
    'body': Icons.monitor_weight_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return CpCard(
      titleWidget: Row(children: [
        CpIcon(_icons[s.id]!, tone: BadgeTone.info, size: 26),
        const SizedBox(width: 8),
        Text(s.title, style: AppText.cardTitle),
      ]),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text.rich(TextSpan(style: AppText.caption, children: [
          const TextSpan(text: 'B better on '),
          TextSpan(text: s.better, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.okText)),
        ])),
      ),
      child: Column(children: [
        for (final t in s.tables) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Align(alignment: Alignment.centerLeft, child: Text(t.head.toUpperCase(), style: AppText.overline.copyWith(fontSize: 10.5))),
          ),
          PfCards([
            for (final r in t.rows)
              PfItem(
                head: Text(r.label),
                fields: [
                  ('A', PfText(swapped ? r.b : r.a)),
                  ('B', PfText(swapped ? r.a : r.b, bold: true)),
                  ('Change', r.change.isEmpty ? const PfText('—', muted: true) : Align(alignment: Alignment.centerLeft, child: AppBadge(r.change, tone: r.tone))),
                ],
                wide: r.barA == null
                    ? null
                    : Column(children: [
                        ProgressBar(swapped ? r.barB! : r.barA!, color: const Color(0xFFB8C2D3), height: 5),
                        const SizedBox(height: 3),
                        ProgressBar(swapped ? r.barA! : r.barB!, height: 5),
                      ]),
              ),
          ]),
        ],
      ]),
    );
  }
}
