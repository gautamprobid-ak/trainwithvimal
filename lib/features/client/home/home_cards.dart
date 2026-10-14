import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_training_mock.dart';
import 'package:train_with_vimal/data/models/training.dart';

import '../train/training_widgets.dart';

const _green = Color(0xFF22C55E);
const _warm = Color(0xFFFF7A45);

/// "1.5 L", "1.75 L", "2 L".
String fmtLitres(int ml) {
  final dec = ml % 1000 == 0 ? 0 : (ml % 500 == 0 ? 1 : 2);
  var s = (ml / 1000).toStringAsFixed(dec);
  if (s.contains('.')) s = s.replaceAll(RegExp(r'\.?0+$'), '');
  return '$s L';
}

/// "7 h 20 min".
String fmtHm(int m) => '${m ~/ 60} h${m % 60 != 0 ? ' ${m % 60} min' : ''}';

/// Card header row (ch-ch): tinted icon, title, subtitle, trailing.
class HomeCardHead extends StatelessWidget {
  const HomeCardHead({super.key, required this.icon, required this.tint, required this.title, required this.subtitle, this.trailing});
  final IconData icon;
  final String tint;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TintIcon(icon, tint: tintOf(tint), size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontSize: 12.5)),
          ]),
        ),
        ?trailing,
      ],
    );
  }
}

/// Thin bar (ch-mb).
class MiniBar extends StatelessWidget {
  const MiniBar(this.value, this.color, {super.key, this.height = 5});
  final double value;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => ProgressBar(value, color: color, height: height);
}

// ---------------------------------------------------------------- water

class WaterCard extends StatelessWidget {
  const WaterCard({super.key, required this.ml, required this.onPlus, required this.onMinus});
  final int ml;
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  @override
  Widget build(BuildContext context) {
    const goal = ClientTrainingMock.waterGoalMl;
    final gl = (ml / 250).round();
    final leftG = ((goal - ml) / 250).ceil().clamp(0, 999);
    final sub = ml >= goal ? 'Goal complete · nice work' : '${fmtLitres(goal - ml)} to go · $leftG ${leftG == 1 ? 'glass' : 'glasses'} more';
    return AppCard(
      child: Spaced(
        gap: 12,
        children: [
          HomeCardHead(icon: Icons.water_drop_outlined, tint: 'warm', title: 'Water', subtitle: sub),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(fmtLitres(ml), style: AppText.bigNumber.copyWith(fontSize: 30)),
              const SizedBox(width: 6),
              Text('/ 3 L · $gl ${gl == 1 ? 'glass' : 'glasses'}', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          Row(children: [
            for (var i = 0; i < 12; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 8,
                  decoration: BoxDecoration(color: i < gl ? _warm : const Color(0xFFEDEDE9), borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ]),
          Row(children: [
            Expanded(child: AppButton.outline('−250 ml', small: true, expand: true, onPressed: onMinus)),
            const SizedBox(width: 8),
            Expanded(child: AppButton.dark('+250 ml · 1 glass', small: true, expand: true, onPressed: onPlus)),
          ]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- food

class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.eaten, required this.onOpen, required this.onLog, required this.onEat});
  final List<int> eaten;
  final VoidCallback onOpen;
  final VoidCallback onLog;
  final ValueChanged<int> onEat;

  @override
  Widget build(BuildContext context) {
    const meals = ClientTrainingMock.meals;
    const tg = ClientTrainingMock.foodTargets;
    final tot = [0, 0, 0, 0];
    for (final i in eaten) {
      final m = meals[i];
      tot[0] += m.kcal;
      tot[1] += m.protein;
      tot[2] += m.carbs;
      tot[3] += m.fat;
    }
    final nxt = [for (var i = 0; i < meals.length; i++) i].where((i) => !eaten.contains(i)).firstOrNull;
    final left = (tg[0] - tot[0]).clamp(0, 99999);
    const macros = [('Protein', AppColors.protein), ('Carbs', AppColors.carbs), ('Fat', AppColors.fat)];
    return AppCard(
      onTap: onOpen,
      child: Spaced(
        gap: 12,
        children: [
          HomeCardHead(
            icon: Icons.restaurant_rounded,
            tint: 'green',
            title: 'Food',
            subtitle: '1,650 kcal plan · Fat loss',
            trailing: AppButton.outline('Log food', icon: Icons.add_rounded, small: true, onPressed: onLog),
          ),
          Row(children: [
            RingProgress(
              value: tot[0] / tg[0],
              size: 92,
              stroke: 8,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(TNum.n(left), style: AppText.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('kcal left', style: AppText.caption.copyWith(fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Spaced(gap: 9, children: [
                for (var k = 0; k < 3; k++)
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text(macros[k].$1, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      Text('${tot[k + 1]} / ${tg[k + 1]} g', style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                    ]),
                    const SizedBox(height: 4),
                    MiniBar(tot[k + 1] / tg[k + 1], macros[k].$2, height: 6),
                  ]),
              ]),
            ),
          ]),
          if (nxt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF7F7F4), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Up next · ${meals[nxt].meal}, ${meals[nxt].time}', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    Text(meals[nxt].food, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    Text('${meals[nxt].kcal} kcal', style: AppText.caption),
                  ]),
                ),
                AppButton.outline('Ate it', icon: Icons.check_rounded, small: true, onPressed: () => onEat(nxt)),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.okBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.okText),
                const SizedBox(width: 8),
                Text('All meals logged for today', style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.okText)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- habits

class HabitItem {
  const HabitItem(this.icon, this.tint, this.name, this.value, this.ratio, this.button, this.onTap);
  final IconData icon;
  final String tint;
  final String name;
  final String value;
  final double ratio;
  final String button;
  final VoidCallback onTap;
}

class HabitsCard extends StatelessWidget {
  const HabitsCard({super.key, required this.items, required this.onSeeAll});
  final List<HabitItem> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final met = items.where((h) => h.ratio >= 1).length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeCardHead(
            icon: Icons.track_changes_rounded,
            tint: 'amber',
            title: 'Habits',
            subtitle: '$met of ${items.length} done today',
            trailing: AppButton.outline('See all', small: true, onPressed: onSeeAll),
          ),
          const SizedBox(height: 8),
          for (final h in items) _HabitRow(h: h),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(child: Text('No sugar after 7 pm starts on Mon, 12 Oct', style: AppText.secondary.copyWith(fontSize: 12.5))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.h});
  final HabitItem h;

  @override
  Widget build(BuildContext context) {
    final met = h.ratio >= 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(children: [
        TintIcon(h.icon, tint: tintOf(h.tint), size: 34),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(h.name, style: AppText.bodyBold)),
              if (met) ...[const SizedBox(width: 8), const OkLabel('Done')],
            ]),
            const SizedBox(height: 2),
            Text(h.value, style: AppText.caption),
            const SizedBox(height: 5),
            MiniBar(h.ratio, met ? _green : const Color(0xFFF59E0B)),
          ]),
        ),
        const SizedBox(width: 10),
        AppButton.outline(h.button, small: true, onPressed: h.onTap),
      ]),
    );
  }
}

// ---------------------------------------------------------------- supplements

class SupplementsCard extends StatelessWidget {
  const SupplementsCard({super.key, required this.taken, required this.onTake, required this.onSeeAll});
  final List<String> taken;
  final ValueChanged<Supplement> onTake;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    const list = ClientTrainingMock.supplements;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeCardHead(
            icon: Icons.medication_outlined,
            tint: 'purple',
            title: 'Supplements',
            subtitle: '${list.where((s) => taken.contains(s.id)).length} of ${list.length} taken',
            trailing: AppButton.outline('See all', small: true, onPressed: onSeeAll),
          ),
          const SizedBox(height: 8),
          for (final s in list) _SuppRow(s: s, on: taken.contains(s.id), onTake: () => onTake(s)),
        ],
      ),
    );
  }
}

class _SuppRow extends StatelessWidget {
  const _SuppRow({required this.s, required this.on, required this.onTake});
  final Supplement s;
  final bool on;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: on ? null : onTake,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? _green : null,
              border: Border.all(color: on ? _green : const Color(0xFFCFCFC9), width: 1.5),
            ),
            child: on ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name,
                  style: AppText.bodyBold.copyWith(
                    color: on ? AppColors.muted : AppColors.text,
                    decoration: on ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFFB5B5AF),
                  )),
              Text(s.dose, style: AppText.caption),
            ]),
          ),
          on ? const OkLabel('Taken', icon: false) : AppButton.outline('Take', small: true, onPressed: onTake),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- coming up

class UpcomingCard extends StatelessWidget {
  const UpcomingCard({super.key, required this.onTap});
  final ValueChanged<UpcomingItem> onTap;

  @override
  Widget build(BuildContext context) {
    const items = ClientHomeMock.upcoming;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(children: [
        for (var i = 0; i < items.length; i++)
          InkWell(
            onTap: () => onTap(items[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.line))),
              child: Row(children: [
                TintIcon(feedIcon(items[i].icon), tint: tintOf(items[i].tint), size: 34),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(items[i].title, style: AppText.bodyBold),
                    Text(items[i].subtitle, style: AppText.caption),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFA1A19B)),
              ]),
            ),
          ),
      ]),
    );
  }
}
