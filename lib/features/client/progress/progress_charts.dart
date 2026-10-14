import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

/// Weight line chart with goal line and tappable weigh-in dots.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.shown, required this.selected, required this.onPick});
  final List<WeighIn> shown;
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    const goal = ClientTrainingMock.goalKg;
    final x0 = shown.first.date;
    double xOf(DateTime d) => TDate.daysBetween(x0, d).toDouble();
    final vals = [...shown.map((w) => w.kg), goal];
    final ymin = (vals.reduce((a, b) => a < b ? a : b) - .5).floorToDouble();
    final ymax = (vals.reduce((a, b) => a > b ? a : b) + .5).ceilToDouble();
    final maxX = xOf(shown.last.date) < 1 ? 1.0 : xOf(shown.last.date);
    final spots = [for (final w in shown) FlSpot(xOf(w.date), w.kg)];
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minX: -maxX * .03,
          maxX: maxX * 1.03,
          minY: ymin,
          maxY: ymax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (ymax - ymin) / 2,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: (ymax - ymin) / 2,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(TNum.short(v), style: AppText.caption.copyWith(fontSize: 10.5)),
                ),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: goal,
              color: AppColors.ok,
              strokeWidth: 1.2,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.okText),
                labelResolver: (_) => 'Goal 68 kg',
              ),
            ),
          ]),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: false,
            touchSpotThreshold: 22,
            touchCallback: (event, resp) {
              if (event is! FlTapUpEvent) return;
              final s = resp?.lineBarSpots;
              if (s == null || s.isEmpty) return;
              onPick(shown[s.first.spotIndex].date);
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppColors.accent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.accent.withValues(alpha: .16), AppColors.accent.withValues(alpha: 0)],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, i) {
                  final on = shown[i].date == selected;
                  final last = i == shown.length - 1;
                  return FlDotCirclePainter(
                    radius: on ? 6 : (last ? 4.5 : 3),
                    color: on || last ? AppColors.accent : Colors.white,
                    strokeWidth: on ? 3 : 1.5,
                    strokeColor: on ? AppColors.accentSoft : AppColors.accent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny lift trend line.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.points});
  final List<(DateTime, double)> points;

  @override
  Widget build(BuildContext context) {
    final x0 = points.first.$1;
    return SizedBox(
      width: 80,
      height: 28,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (final p in points) FlSpot(TDate.daysBetween(x0, p.$1).toDouble(), p.$2)],
              color: const Color(0xFF22C55E),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Body measurement trend (fl_chart line) shown when a measurement row is open.
class MeasureChart extends StatelessWidget {
  const MeasureChart({super.key, required this.m});
  final Measurement m;

  @override
  Widget build(BuildContext context) {
    final dates = ClientTrainingMock.measurementDates;
    final x0 = dates.first;
    final lo = m.values.reduce((a, b) => a < b ? a : b), hi = m.values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 90,
      child: LineChart(
        LineChartData(
          minY: lo - 2,
          maxY: hi + 2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < dates.length; i++) FlSpot(TDate.daysBetween(x0, dates[i]).toDouble(), m.values[i])],
              color: AppColors.accent,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: .08)),
            ),
          ],
        ),
      ),
    );
  }
}
