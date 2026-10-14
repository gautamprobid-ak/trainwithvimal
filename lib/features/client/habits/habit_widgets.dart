import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';

/// Big − value + stepper used by the steps / sleep sheets (ch-big).
class BigValueStepper extends StatelessWidget {
  const BigValueStepper({super.key, required this.value, required this.unit, required this.onMinus, required this.onPlus});
  final String value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(Icons.remove_rounded, tooltip: 'Less', onPressed: onMinus),
        Expanded(
          child: Column(
            children: [
              Text(value, style: AppText.bigNumber),
              Text(unit, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        AppIconButton(Icons.add_rounded, tooltip: 'More', onPressed: onPlus),
      ],
    );
  }
}

/// Row of quick-pick buttons (ch-qs).
class QuickButtons extends StatelessWidget {
  const QuickButtons({super.key, required this.labels, required this.onPick, this.selected = -1});
  final List<String> labels;
  final ValueChanged<int> onPick;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: i == selected ? AppColors.text : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: i == selected ? AppColors.text : AppColors.line),
              ),
              child: InkWell(
                onTap: () => onPick(i),
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 38,
                  child: Center(
                    child: Text(labels[i],
                        style: AppText.bodyBold.copyWith(fontSize: 12.5, color: i == selected ? Colors.white : AppColors.text)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// History line in a habit detail sheet (hk-hi).
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.day, required this.frac, required this.value, required this.met, required this.today});
  final String day;
  final double frac;
  final String value;
  final bool met;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final color = met ? const Color(0xFF22C55E) : today ? const Color(0xFFF59E0B) : const Color(0xFFF2A7A3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(day, style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
          Expanded(child: ProgressBar(frac, height: 5, color: color)),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(value, textAlign: TextAlign.right, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text))),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Pill(met ? 'Done' : today ? 'Today' : 'Missed', tone: met ? PillTone.green : today ? PillTone.blue : PillTone.red),
          ),
        ],
      ),
    );
  }
}

enum DotState { ok, now, no }

/// 7 small day dots with letters (hk-dots).
class DayDots extends StatelessWidget {
  const DayDots({super.key, required this.days, this.large = false});
  final List<(String, DotState)> days;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final s = large ? 18.0 : 12.0;
    return Row(
      mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: large ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: [
        for (final (l, st) in days)
          Padding(
            padding: EdgeInsets.only(right: large ? 0 : 5),
            child: Column(
              children: [
                Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (st) { DotState.ok => const Color(0xFF22C55E), DotState.now => Colors.white, DotState.no => const Color(0xFFF6D2CF) },
                    border: st == DotState.now ? Border.all(color: AppColors.accent, width: 2) : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(l, style: AppText.caption.copyWith(fontSize: large ? 11 : 9.5, fontWeight: FontWeight.w700, height: 1)),
              ],
            ),
          ),
      ],
    );
  }
}

/// One habit (steps / water / sleep) for the picked day.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.line,
    required this.met,
    required this.missed,
    required this.frac,
    required this.barColor,
    required this.streak,
    required this.dots,
    required this.button,
    required this.onOpen,
    required this.onTap,
    required this.onMinus,
    required this.onPlus,
  });
  final HabitDef habit;
  final String line;
  final bool met;
  final bool missed;
  final double frac;
  final Color barColor;
  final String streak;
  final List<(String, DotState)> dots;
  final String button;
  final VoidCallback onOpen;
  final VoidCallback onTap;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (habit.id) {
      'steps' => (Icons.directions_walk_rounded, Tint.green),
      'water' => (Icons.water_drop_rounded, Tint.orange),
      _ => (Icons.bedtime_rounded, Tint.purple),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TintIcon(icon, tint: tint, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(habit.name, style: AppText.bodyBold.copyWith(fontSize: 14.5))),
                        if (met) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_rounded, size: 13, color: AppColors.okText),
                          Text('Done', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.okText)),
                        ],
                        if (missed) ...[
                          const SizedBox(width: 6),
                          Text('Missed', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.badText)),
                        ],
                      ]),
                      Text(line, style: AppText.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (habit.id == 'water') ...[
                AppIconButton(Icons.remove_rounded, small: true, tooltip: 'Remove 250 ml', onPressed: onMinus),
                const SizedBox(width: 6),
                AppButton.dark('250 ml', small: true, icon: Icons.add_rounded, onPressed: onPlus),
              ] else
                AppButton.outline(button, small: true, onPressed: onTap),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(frac, height: 5, color: barColor),
          const SizedBox(height: 10),
          Row(
            children: [
              DayDots(days: dots),
              const Spacer(),
              const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFFF7A45)),
              const SizedBox(width: 3),
              Text(streak, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
              const SizedBox(width: 6),
              InkWell(
                onTap: onOpen,
                child: Row(children: [
                  Text('Details', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentText)),
                  const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.accentText),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "No sugar after 7 pm" — starts next Monday.
class SugarCard extends StatelessWidget {
  const SugarCard({super.key, required this.onOpen, required this.onTick});
  final VoidCallback onOpen;
  final VoidCallback onTick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const TintIcon(Icons.no_food_rounded, tint: Tint.gray, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('No sugar after 7 pm', style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                      const Pill('Starts Mon, 12 Oct', tone: PillTone.amber),
                    ],
                  ),
                  Text('Yes / no · tick it each evening', style: AppText.caption),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Tick no sugar after 7 pm',
            child: InkWell(
              onTap: onTick,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCFCFC9), width: 1.5)),
                child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFFCFCFC9)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One supplement row with its tick box (hk-sr).
class SupplementRow extends StatelessWidget {
  const SupplementRow({
    super.key,
    required this.name,
    required this.detail,
    required this.taken,
    required this.missed,
    required this.onTick,
    required this.onInfo,
    required this.trailing,
  });
  final String name;
  final String detail;
  final bool taken;
  final bool missed;
  final VoidCallback onTick;
  final VoidCallback onInfo;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onTick,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: taken ? const Color(0xFF22C55E) : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: taken ? const Color(0xFF22C55E) : (missed ? const Color(0xFFF2A7A3) : AppColors.line2), width: 1.5),
              ),
              child: taken ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onInfo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(detail, style: AppText.caption),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

enum CellState { ok, no, now, fut, off }

class WeekCell {
  const WeekCell(this.state, this.onTap);
  final CellState state;
  final VoidCallback onTap;
}

class WeekGridRow {
  const WeekGridRow({required this.name, required this.sub, required this.count, required this.onOpen, required this.cells});
  final String name;
  final String sub;
  final String count;
  final VoidCallback onOpen;
  final List<WeekCell> cells;
}

/// Week grid (hk-wg): one row per habit / supplement, 7 day cells.
class WeekGridCard extends StatelessWidget {
  const WeekGridCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.dayLetters,
    required this.rows,
    this.legend = false,
  });
  final IconData icon;
  final Tint tint;
  final String title;
  final String subtitle;
  final List<(String, bool)> dayLetters;
  final List<WeekGridRow> rows;
  final bool legend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHead(icon: icon, tint: tint, title: title, subtitle: subtitle),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              for (final (l, today) in dayLetters)
                SizedBox(
                  width: 26,
                  child: Text(l,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: today ? AppColors.accentText : AppColors.muted)),
                ),
              const SizedBox(width: 30),
            ],
          ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: r.onOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                          Text(r.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  for (final c in r.cells) SizedBox(width: 26, child: Center(child: _Cell(c))),
                  SizedBox(width: 30, child: Text(r.count, textAlign: TextAlign.right, style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          if (legend) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final (s, l) in const [(CellState.ok, 'Done'), (CellState.no, 'Missed'), (CellState.now, 'Today, not yet'), (CellState.fut, 'Coming')])
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _CellBox(s, size: 12),
                    const SizedBox(width: 5),
                    Text(l, style: AppText.caption.copyWith(fontSize: 11.5)),
                  ]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.cell);
  final WeekCell cell;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: cell.onTap, child: _CellBox(cell.state));
  }
}

class _CellBox extends StatelessWidget {
  const _CellBox(this.state, {this.size = 22});
  final CellState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color? border, IconData? icon, Color fg) = switch (state) {
      CellState.ok => (const Color(0xFF22C55E), null, Icons.check_rounded, Colors.white),
      CellState.no => (AppColors.badBg, null, Icons.close_rounded, AppColors.badText),
      CellState.now => (Colors.white, AppColors.accent, null, AppColors.accent),
      CellState.fut => (const Color(0xFFF5F5F2), const Color(0xFFD6D6D0), null, AppColors.muted),
      CellState.off => (const Color(0xFFF3F3F0), null, null, AppColors.muted),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * .32),
        border: border == null ? null : Border.all(color: border, width: state == CellState.now ? 2 : 1),
      ),
      child: icon != null && size > 14 ? Icon(icon, size: 12, color: fg) : null,
    );
  }
}
