import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Small client-app mock in the brand colour (st-app).
class BrandPreview extends StatelessWidget {
  const BrandPreview({super.key, required this.color, required this.dark});
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF121212) : const Color(0xFFF5F5F3);
    final card = dark ? const Color(0xFF1F1F1F) : Colors.white;
    final fg = dark ? Colors.white : AppColors.text;
    final muted = dark ? const Color(0xFFA1A1AA) : AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
                  child: Text('TV', style: AppText.caption.copyWith(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Text('Train With Vimal', style: AppText.bodyBold.copyWith(fontSize: 13, color: fg)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Good morning, Sana', style: AppText.cardTitle.copyWith(color: fg)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Today\'s workout', style: AppText.caption.copyWith(color: muted)),
                  Text('Upper body · Week 3', style: AppText.bodyBold.copyWith(color: fg)),
                  const SizedBox(height: 10),
                  ProgressBar(.45, color: color, track: dark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDE9)),
                  const SizedBox(height: 12),
                  Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                    child: Text('Start workout', style: AppText.bodyBold.copyWith(fontSize: 13, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tab(Icons.home_rounded, 'Today', color),
                _tab(Icons.fitness_center_rounded, 'Train', muted),
                _tab(Icons.restaurant_rounded, 'Eat', muted),
                _tab(Icons.trending_up_rounded, 'Progress', muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData i, String t, Color c) => Column(
        children: [Icon(i, size: 18, color: c), Text(t, style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: c))],
      );
}
