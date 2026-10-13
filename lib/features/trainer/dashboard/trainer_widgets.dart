import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

/// Small building blocks shared by the trainer app pages.

/// "AV" avatar at the top right of trainer pages (opens My profile).
class TrainerProfileButton extends StatelessWidget {
  const TrainerProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Aman Verma · Trainer',
      child: InkWell(
        onTap: () => context.push(Routes.tMe),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFDCE6FB), shape: BoxShape.circle),
          child: Text('AV', style: AppText.bodyBold.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accentText)),
        ),
      ),
    );
  }
}

/// 2-column grid of stat tiles (stats / stat).
class TrainerStatGrid extends StatelessWidget {
  const TrainerStatGrid(this.stats, {super.key, this.shadow = false, this.compact = false});
  final List<TrainerStat> stats;
  final bool shadow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _StatTile(stats[i], shadow: shadow, compact: compact)),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < stats.length ? _StatTile(stats[i + 1], shadow: shadow, compact: compact) : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.s, {required this.shadow, required this.compact});
  final TrainerStat s;
  final bool shadow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final deltaColor = switch (s.good) { true => AppColors.okText, false => AppColors.badText, null => AppColors.muted };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: shadow ? const [BoxShadow(color: Color(0x14171717), blurRadius: 18, offset: Offset(0, 6))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Icon(s.icon, size: 15, color: AppColors.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.label,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.secondary.copyWith(fontSize: compact ? 12 : 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bigNumber.copyWith(fontSize: compact ? 19 : 24, height: 1.1)),
          if (s.delta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(s.delta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: compact ? 11.5 : 12, fontWeight: FontWeight.w700, color: deltaColor)),
          ],
        ],
      ),
    );
  }
}

/// Card with the design's card header: title (+count / caption) and a link on the right.
class TrainerSectionCard extends StatelessWidget {
  const TrainerSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.caption,
    this.subtitle,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;
  final Widget child;
  final int? count;

  /// Grey text next to the title.
  final String? caption;

  /// Grey line under the title.
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: AppText.cardTitle),
                          if (count != null) _Count(count!),
                          if (caption != null) Text(caption!, style: AppText.caption),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.caption),
                      ],
                    ],
                  ),
                ),
                ?trailing,
                if (action != null) LinkButton(action!, onTap: onAction),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.n);
  final int n;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(9)),
      child: Text('$n', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.text2)),
    );
  }
}

/// Blue text link button ("Calendar", "View all", "Edit").
class LinkButton extends StatelessWidget {
  const LinkButton(this.label, {super.key, this.onTap, this.color = AppColors.accentText, this.icon});
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 4)],
            Text(label, style: AppText.bodyBold.copyWith(fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Label / value pairs in a 2-column grid with bottom lines (cp-kv c2).
class KvGrid extends StatelessWidget {
  const KvGrid(this.pairs, {super.key, this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 14), this.columns = 2});
  final List<(String, Widget)> pairs;
  final EdgeInsets padding;
  final int columns;

  factory KvGrid.text(List<(String, String)> pairs, {Key? key, EdgeInsets padding = const EdgeInsets.fromLTRB(16, 0, 16, 14), int columns = 2}) =>
      KvGrid([for (final (k, v) in pairs) (k, Text(v, style: AppText.bodyBold.copyWith(fontSize: 13.5)))], key: key, padding: padding, columns: columns);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < pairs.length; i += columns) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var j = 0; j < columns; j++) ...[
            if (j > 0) const SizedBox(width: 20),
            Expanded(child: i + j < pairs.length ? _kv(pairs[i + j]) : const SizedBox()),
          ],
        ],
      ));
    }
    return Padding(padding: padding, child: Column(children: rows));
  }

  Widget _kv((String, Widget) p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.$1, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          p.$2,
        ],
      ),
    );
  }
}

/// Small on/off switch (cp-tog).
class MiniToggle extends StatelessWidget {
  const MiniToggle(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 30,
      height: 18,
      padding: const EdgeInsets.all(2),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(color: on ? AppColors.accent : AppColors.line2, borderRadius: BorderRadius.circular(9)),
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
      ),
    );
  }
}

/// A switch row with title and help line (dr-sw / tp-perm).
class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.title, this.subtitle, required this.value, this.onChanged, this.locked = false});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked || onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty) Text(subtitle!, style: AppText.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (locked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 13, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text('Always', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                ],
              )
            else
              MiniToggle(value),
          ],
        ),
      ),
    );
  }
}

/// Filter chip with a count (fchip). Selected = dark.
class CountChip extends StatelessWidget {
  const CountChip(this.label, {super.key, required this.selected, this.count, this.onTap});
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.text : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? AppColors.text : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.text2)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text('$count',
                    style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? const Color(0xFFC9C9CF) : AppColors.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of [CountChip]s (na-kinds).
class ChipStrip extends StatelessWidget {
  const ChipStrip({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 2, 16, 8)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 6), children[i]]]),
    );
  }
}

/// Grey photo placeholder (td-phi).
class PhotoTile extends StatelessWidget {
  const PhotoTile(this.label, {super.key, this.onTap, this.tone = 0});
  final String label;
  final VoidCallback? onTap;
  final int tone;

  static const _tones = [Color(0xFFF1F1EE), Color(0xFFEAEFF5), Color(0xFFF3EEE8)];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tones[tone % 3],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 92,
          height: 112,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined, size: 22, color: AppColors.muted),
              const SizedBox(height: 6),
              Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of tab-like pills inside a grey track (tabs sm fit) for sheets.
class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedTabs<int>(
          expand: false,
          items: [for (var i = 0; i < labels.length; i++) (i, labels[i])],
          value: index,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Section heading inside a sheet (dr-st h4 + p).
class SheetSection extends StatelessWidget {
  const SheetSection({super.key, required this.title, this.help, required this.children});
  final String title;
  final String? help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppText.bodyBold.copyWith(fontSize: 14)),
          if (help != null) ...[const SizedBox(height: 2), Text(help!, style: AppText.caption)],
          const SizedBox(height: 10),
          ...[for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 12), children[i]]],
        ],
      ),
    );
  }
}

/// Read-only "select" box (label above, value + chevron) that opens a picker.
class SelectField extends StatelessWidget {
  const SelectField({super.key, required this.label, required this.value, this.onTap, this.hint, this.placeholder = false});
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? hint;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.line2)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(color: placeholder ? AppColors.muted : AppColors.text)),
                  ),
                  const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
        if (hint != null) ...[const SizedBox(height: 5), Text(hint!, style: AppText.caption)],
      ],
    );
  }
}

/// Opens a list picker sheet and returns the chosen option.
Future<String?> pickOption(BuildContext context, {required String title, required List<String> options, required String current, Map<String, String> ends = const {}}) {
  return showAppSheet<String>(
    context,
    title: title,
    builder: (ctx) => Column(
      children: [
        for (final o in options)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(o, style: AppText.bodyBold.copyWith(fontWeight: o == current ? FontWeight.w800 : FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ends[o] != null && ends[o]!.isNotEmpty) Text(ends[o]!, style: AppText.caption),
                const SizedBox(width: 8),
                SizedBox(width: 20, child: o == current ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null),
              ],
            ),
            onTap: () => Navigator.of(ctx).pop(o),
          ),
      ],
    ),
  );
}
