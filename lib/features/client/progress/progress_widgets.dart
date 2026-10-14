import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/training.dart';

/// Placeholder progress photo (px-tile): tinted gradient with a figure icon.
class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.tint, this.none = false, this.aspect = 3 / 4, this.badge, this.badgeAccent = true, this.tag, this.noneText = 'No photo', this.selected = false, this.iconSize = 34});
  final PhotoTint tint;
  final bool none;
  final double aspect;
  final String? badge;
  final bool badgeAccent;
  final String? tag;
  final String noneText;
  final bool selected;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final (c1, c2, fg) = switch (tint) {
      PhotoTint.t1 => (const Color(0xFFEEF3FE), const Color(0xFFD9E4FC), const Color(0xFF7B95D6)),
      PhotoTint.t2 => (const Color(0xFFEDF7F1), const Color(0xFFD3EEDD), const Color(0xFF5E9F78)),
      PhotoTint.t3 => (const Color(0xFFFFF6E8), const Color(0xFFFBE3BE), const Color(0xFFC08A3A)),
      PhotoTint.t4 => (const Color(0xFFF4F0FE), const Color(0xFFE1D7FB), const Color(0xFF8B72CF)),
    };
    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: none ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
          color: none ? const Color(0xFFF6F6F3) : null,
          border: selected
              ? Border.all(color: AppColors.accent, width: 2)
              : (none ? Border.all(color: AppColors.line2) : null),
          boxShadow: selected ? const [BoxShadow(color: AppColors.accentSoft, spreadRadius: 3)] : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_rounded, size: iconSize, color: none ? const Color(0xFFC9C9C4) : fg),
                if (none) Text(noneText, textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
            if (badge != null && badge!.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: badgeAccent ? AppColors.accent : AppColors.text, shape: BoxShape.circle),
                  child: Text(badge!, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            if (tag != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(6)),
                  child: Text(tag!, style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card title + subtitle (px-ch).
class PxHead extends StatelessWidget {
  const PxHead({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
          if (subtitle != null) Text(subtitle!, style: AppText.secondary.copyWith(fontSize: 12.5)),
        ]),
      ),
      ?trailing,
    ]);
  }
}

/// A row of a before/after table.
class CmpRow {
  const CmpRow(this.label, this.a, this.b, this.unit);
  final String label;
  final double a;
  final double b;
  final String unit;
}

/// Before / now / change table (px-tbl).
class CompareTable extends StatelessWidget {
  const CompareTable({super.key, required this.ha, required this.hb, required this.rows});
  final String ha;
  final String hb;
  final List<CmpRow> rows;

  @override
  Widget build(BuildContext context) {
    final h = AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700);
    Widget row(List<Widget> c, {bool top = true}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(border: top ? const Border(top: BorderSide(color: AppColors.line)) : null),
          child: Row(children: [
            Expanded(flex: 5, child: c[0]),
            Expanded(flex: 4, child: c[1]),
            Expanded(flex: 4, child: c[2]),
            Expanded(flex: 4, child: c[3]),
          ]),
        );
    return Column(children: [
      row([const SizedBox(), Text(ha, style: h), Text(hb, style: h), Text('Change', style: h, textAlign: TextAlign.right)], top: false),
      for (final r in rows)
        row([
          Text(r.label, style: AppText.secondary.copyWith(color: AppColors.text2)),
          Text(TNum.amount(r.a, r.unit), style: AppText.secondary),
          Text(TNum.amount(r.b, r.unit), style: AppText.bodyBold.copyWith(fontSize: 13)),
          Text(TNum.change(r.b - r.a, r.unit),
              textAlign: TextAlign.right,
              style: AppText.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: r.b < r.a ? AppColors.okText : (r.b > r.a ? AppColors.warnText : AppColors.muted),
              )),
        ]),
    ]);
  }
}

/// Key / value line (fd-kv).
class KvLine extends StatelessWidget {
  const KvLine(this.k, this.v, {super.key});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(k, style: AppText.secondary)),
        const SizedBox(width: 12),
        Flexible(child: Text(v, textAlign: TextAlign.right, style: AppText.bodyBold.copyWith(fontSize: 13))),
      ]),
    );
  }
}

/// Small back link at the top of sub views (px-back).
class BackLink extends StatelessWidget {
  const BackLink(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.accent),
            Text(label, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.accent)),
          ]),
        ),
      ),
    );
  }
}
