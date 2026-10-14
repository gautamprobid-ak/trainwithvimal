import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import '../sheets/detail_sheets.dart';
import '../sheets/profile_sheets.dart';
import 'logs_tab.dart';

typedef _M = ClientProfileMock;

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Spaced(
      children: [
        _About(),
        _WeightCard(),
        _Last7(),
        _LatestNote(),
        _Attention(),
        _Coaching(),
        _CurrentPlans(),
        _Schedule(),
      ],
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'About ${c.first}',
      cap: 'From onboarding · edit in Edit profile',
      action: 'Edit',
      onAction: () => showEditProfileSheet(context, c),
      child: KvGrid(
        _M.about,
        valueBuilder: (i, v) => v == 'Knee pain'
            ? Text(v, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: const Color(0xFF9A5B00)))
            : null,
      ),
    );
  }
}

/// Weight line chart with the goal line (cp-chart). Shared with the Progress tab.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = [for (final p in _M.weight) FlSpot(p.day.toDouble(), p.kg)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 67.5,
                maxY: 75.5,
                minX: 0,
                maxX: 29,
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.line, strokeWidth: 1),
                ),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 68,
                    color: AppColors.ok,
                    strokeWidth: 1.2,
                    dashArray: [5, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.okText),
                      labelResolver: (_) => 'Goal 68 kg',
                    ),
                  ),
                ]),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.text,
                    getTooltipItems: (s) => [
                      for (final x in s)
                        LineTooltipItem('${x.y.toStringAsFixed(1)} kg', AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: .25,
                    color: AppColors.accent,
                    barWidth: 2.2,
                    dotData: FlDotData(
                      getDotPainter: (s, _, _, i) => FlDotCirclePainter(
                        radius: i == spots.length - 1 ? 4 : 2.2,
                        color: Colors.white,
                        strokeColor: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.accent.withValues(alpha: .18), AppColors.accent.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10 Sep · 74.8 kg', style: AppText.caption.copyWith(fontSize: 11)),
              Text('25 Sep', style: AppText.caption.copyWith(fontSize: 11)),
              Text('9 Oct · 71.2 kg', style: AppText.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'Weight trend',
      cap: '−3.6 kg in 30 days · 3.2 kg to goal',
      action: 'Open progress',
      onAction: () => c.goTab('progress'),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 4), child: RangeButton()),
          WeightChart(),
        ],
      ),
    );
  }
}

class _Last7 extends StatelessWidget {
  const _Last7();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'Last 7 days',
      cap: 'What ${c.first} did each day',
      action: 'Open logs',
      onAction: () => c.goTab('logs'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Column(
          children: [
            Row(children: [
              const SizedBox(width: 64),
              for (final d in _M.weekDays)
                Expanded(child: Text(d, textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700))),
            ]),
            for (final r in _M.week)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  SizedBox(width: 64, child: Text(r.label, style: AppText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2))),
                  for (final m in r.marks) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _Cell(m))),
                ]),
              ),
            const SizedBox(height: 12),
            Wrap(spacing: 14, runSpacing: 6, children: const [
              _Legend(AppColors.okBg, 'Done'),
              _Legend(Color(0xFFFFF4DB), 'Partly'),
              _Legend(AppColors.badBg, 'Missed'),
              _Legend(AppColors.sub, 'Rest day'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.m);
  final DayMark m;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (m) {
      DayMark.done => (AppColors.okBg, AppColors.okText, Icons.check_rounded),
      DayMark.part => (AppColors.warnBg, AppColors.warnText, Icons.remove_rounded),
      DayMark.miss => (AppColors.badBg, AppColors.badText, Icons.close_rounded),
      DayMark.rest => (AppColors.sub, AppColors.muted, null),
    };
    return Container(
      height: 24,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: icon == null ? null : Icon(icon, size: 13, color: fg),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: AppText.caption.copyWith(fontSize: 11.5)),
      ]);
}

/// A staff note card (cp-note).
class NoteCard extends StatelessWidget {
  const NoteCard(this.note, {super.key, this.avatar = false});
  final ProfileNote note;
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF5E6B8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text, style: AppText.body.copyWith(fontSize: 13.5)),
          const SizedBox(height: 6),
          Row(children: [
            if (avatar) ...[Avatar(Avatar.initialsOf(note.by), size: 20, color: AvatarColor.c2), const SizedBox(width: 6)],
            Text('${note.by} · ${note.when}', style: AppText.caption),
          ]),
        ],
      ),
    );
  }
}

class _LatestNote extends StatelessWidget {
  const _LatestNote();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'Latest note',
      cap: 'Staff only',
      action: 'All notes',
      onAction: () => c.goTab('notes'),
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: NoteCard(c.latestNote, avatar: true)),
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention();
  static const _icons = [Icons.flag_outlined, Icons.fact_check_outlined, Icons.event_busy_outlined];

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: 'Needs attention',
      child: CpRows([
        for (var i = 0; i < _M.attention.length; i++)
          CpRow(
            icon: _icons[i],
            tone: _M.attention[i].tone,
            title: _M.attention[i].title,
            sub: _M.attention[i].sub,
            chevron: _M.attention[i].target != null,
            onTap: switch (_M.attention[i].target) {
              'checkin' => () => showLogSheet(context, c, 'weekly', 0),
              'log' => () => showLogSheet(context, c, 'workouts', 2),
              _ => () => c.goTab('notes'),
            },
          ),
      ]),
    );
  }
}

class _Coaching extends StatelessWidget {
  const _Coaching();
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final items = [('Trainer', c.trainer), ..._M.coaching];
    return CpCard(
      title: 'Coaching',
      child: KvGrid(
        items,
        valueBuilder: (i, v) => i != 0
            ? null
            : Row(children: [
                Avatar(Avatar.initialsOf(v), size: 20, color: AvatarColor.c2),
                const SizedBox(width: 6),
                Flexible(child: Text(c.isAdmin ? v : '$v (you)', overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                if (c.isAdmin) ...[const Spacer(), CpTextButton('Change', onTap: () => showChangeTrainerSheet(context, c))],
              ]),
      ),
    );
  }
}

class _CurrentPlans extends StatelessWidget {
  const _CurrentPlans();
  static const _icons = [Icons.fitness_center_rounded, Icons.restaurant_rounded, Icons.medication_outlined, Icons.check_circle_outline_rounded];

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    void open(String p) {
      c.setPlanTab(p);
      c.goTab('plans');
    }

    return CpCard(
      title: 'Current plans',
      action: 'Open plans',
      onAction: () => open('workout'),
      child: CpRows([
        for (var i = 0; i < _M.currentPlans.length; i++)
          CpRow(
            icon: _icons[i],
            title: _M.currentPlans[i].$2,
            sub: c.r(_M.currentPlans[i].$3),
            chevron: true,
            onTap: () => open(_M.currentPlans[i].$1),
          ),
      ]),
    );
  }
}

class _Schedule extends StatelessWidget {
  const _Schedule();
  static const _icons = [Icons.wb_sunny_outlined, Icons.calendar_month_outlined, Icons.straighten_rounded, Icons.photo_camera_outlined];

  @override
  Widget build(BuildContext context) {
    return CpCard(
      title: 'Check-ins and schedule',
      child: CpRows([
        for (var i = 0; i < _M.schedule.length; i++)
          CpRow(
            icon: _icons[i],
            title: _M.schedule[i].title,
            sub: _M.schedule[i].sub,
            trailing: AppBadge(_M.schedule[i].badge, tone: _M.schedule[i].tone),
          ),
      ]),
    );
  }
}
