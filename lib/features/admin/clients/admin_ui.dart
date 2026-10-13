import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/admin.dart';

/// Small building blocks shared by the admin screens (stat grid, drawer
/// sections, toggles, filters, option lists). They mirror the design's
/// .stat / .dr-sec / .dr-sw / .fm-menu / .dr-opt patterns on a phone.

// ---------------------------------------------------------------- Stats

class AdminStat {
  const AdminStat(this.label, this.value, this.delta, {required this.icon, this.tone});
  final String label;
  final String value;
  final String delta;
  final IconData icon;

  /// true = up (green), false = down (red), null = muted.
  final bool? tone;
}

/// 2-column grid of stat cards (.stats on phone).
class AdminStatGrid extends StatelessWidget {
  const AdminStatGrid(this.stats, {super.key});
  final List<AdminStat> stats;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _StatTile(stats[i])),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < stats.length ? _StatTile(stats[i + 1]) : const SizedBox()),
          ],
        ),
      ));
    }
    return Spaced(gap: 10, children: rows);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.s);
  final AdminStat s;

  @override
  Widget build(BuildContext context) {
    final deltaColor = switch (s.tone) {
      true => AppColors.okText,
      false => AppColors.badText,
      null => AppColors.muted,
    };
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(7)),
                child: Icon(s.icon, size: 14, color: AppColors.text2),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(s.label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bigNumber.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (s.tone != null) ...[
                Icon(s.tone! ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 13, color: deltaColor),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(s.delta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: deltaColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Cards

/// Card with a heading row (.card-h) and a body.
class TitledCard extends StatelessWidget {
  const TitledCard({super.key, required this.title, this.subtitle, this.count, this.trailing, required this.child, this.footer});
  final String title;
  final String? subtitle;
  final String? count;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: AppText.cardTitle.copyWith(fontSize: 17))),
                          if (count != null) ...[const SizedBox(width: 8), CountPill(count!)],
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
              ],
            ),
          ),
          child,
          ?footer,
        ],
      ),
    );
  }
}

/// Blue rounded count (.count).
class CountPill extends StatelessWidget {
  const CountPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentText)),
    );
  }
}

/// Grey footnote strip at the bottom of a list card (.ap-foot).
class CardFootnote extends StatelessWidget {
  const CardFootnote(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.caption)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Blue "Show all" / "Show less" link button (.na-more).
class ShowMoreButton extends StatelessWidget {
  const ShowMoreButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: SizedBox(
        height: 34,
        width: double.infinity,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(label, style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.accentText)),
        ),
      ),
    );
  }
}

/// Thin load bar (.dr-bar / .bar).
class MiniBar extends StatelessWidget {
  const MiniBar(this.value, {super.key, this.width = 56, this.color = AppColors.accent, this.height = 5});
  final double value;
  final double width;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: ProgressBar(value, color: color, height: height, track: AppColors.sub));
}

/// Two-column label/value list (.cp-kv.c2).
class KvGrid extends StatelessWidget {
  const KvGrid(this.items, {super.key, this.columns = 2});
  final List<(String, Widget)> items;
  final int columns;

  /// Convenience for plain text values.
  static List<(String, Widget)> text(List<(String, String)> pairs) =>
      [for (final (k, v) in pairs) (k, Text(v, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)))];

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var j = 0; j < columns; j++) ...[
            if (j > 0) const SizedBox(width: 12),
            Expanded(child: i + j < items.length ? _kv(items[i + j]) : const SizedBox()),
          ],
        ],
      ));
    }
    return Spaced(gap: 12, children: rows);
  }

  Widget _kv((String, Widget) kv) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kv.$1, style: AppText.caption.copyWith(fontSize: 11.5)),
          const SizedBox(height: 3),
          kv.$2,
        ],
      );
}

// --------------------------------------------------------------- Tabs

/// Small segmented tabs with counts (.tabs.sm with .n). Scrolls if wide.
class CountTabs<T> extends StatelessWidget {
  const CountTabs({super.key, required this.items, required this.value, required this.onChanged});
  final List<(T, String, int?)> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [for (final (v, label, n) in items) _tab(label, n, v == value, () => onChanged(v))],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, int? n, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: on ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? AppColors.text : AppColors.text2)),
            if (n != null) ...[
              const SizedBox(width: 5),
              Text('$n', style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of filter chips with counts (.fchip / .na-kinds).
class KindChips extends StatelessWidget {
  const KindChips({super.key, required this.items, required this.value, required this.onChanged, this.padding = EdgeInsets.zero});
  final List<(String, int)> items;
  final String value;
  final ValueChanged<String> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final (label, n) in items) ...[
            ChoicePill(label, selected: label == value, count: n, onTap: () => onChanged(label)),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Filters

/// Filter values keyed by group id. A missing key = the group's first option.
typedef FilterValues = Map<String, String>;

extension FilterValuesX on FilterValues {
  bool isOn(FilterGroup g) => this[g.id] != null && this[g.id] != g.options.first;
  String valueOf(FilterGroup g) => this[g.id] ?? g.options.first;
  int activeCount(List<FilterGroup> groups) => groups.where(isOn).length;
}

/// "Filter · n" outline button.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      AppButton.outline(count > 0 ? 'Filter · $count' : 'Filter', icon: Icons.filter_list_rounded, onPressed: onTap);
}

/// Opens the filter menu as a bottom sheet. Each pick applies right away.
Future<void> showFilterSheet(
  BuildContext context, {
  required List<FilterGroup> groups,
  required FilterValues values,
  required ValueChanged<FilterValues> onChanged,
}) {
  var current = Map<String, String>.of(values);
  return showAppSheet(
    context,
    title: 'Filter',
    subtitle: 'Pick what to show. Changes apply right away.',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        void pick(FilterGroup g, String o) {
          setSheet(() => current = {...current, g.id: o});
          onChanged(current);
        }

        return Spaced(
          gap: 16,
          children: [
            for (final g in groups)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final o in g.options) ChoicePill(o, selected: current.valueOf(g) == o, onTap: () => pick(g, o)),
                    ],
                  ),
                ],
              ),
          ],
        );
      },
    ),
    actions: (ctx) => [
      AppButton.outline('Clear filters', onPressed: () {
        onChanged({});
        Navigator.of(ctx).pop();
      }),
      AppButton('Done', onPressed: () => Navigator.of(ctx).pop()),
    ],
  );
}

/// Active filters as removable dark chips + "Clear" (.ap-fchips).
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({super.key, required this.groups, required this.values, required this.onChanged});
  final List<FilterGroup> groups;
  final FilterValues values;
  final ValueChanged<FilterValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = groups.where(values.isOn).toList();
    if (on.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final g in on)
          ChoicePill('${g.label}: ${values[g.id]}',
              selected: true, icon: Icons.close_rounded, onTap: () => onChanged({...values}..remove(g.id))),
        TextButton(onPressed: () => onChanged({}), child: Text('Clear', style: AppText.bodyBold.copyWith(fontSize: 12.5, color: AppColors.accentText))),
      ],
    );
  }
}

// ---------------------------------------------------------- Sheet forms

/// Body of a drawer-style sheet: scrolling sections + a fixed footer
/// (.drawer-b / .drawer-f). Use with `showAppSheet(..., scrollable: false)`.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.children, this.note, this.actions = const [], this.gap = 22});
  final List<Widget> children;
  final String? note;
  final List<Widget> actions;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(child: SingleChildScrollView(child: Spaced(gap: gap, children: children))),
        if (actions.isNotEmpty || note != null) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (note != null) ...[
            Text(note!, style: AppText.caption),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: actions[i]),
              ],
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ],
    );
  }
}

/// Opens a drawer-style sheet whose body manages its own scroll + footer.
Future<T?> showFormSheet<T>(BuildContext context, {required String title, String? subtitle, required WidgetBuilder builder}) =>
    showAppSheet<T>(context, title: title, subtitle: subtitle, scrollable: false, builder: builder);

/// A titled block inside a drawer (.dr-sec with h4 + p).
class SheetSection extends StatelessWidget {
  const SheetSection({super.key, required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.bodyBold.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppText.caption.copyWith(fontSize: 12.5)),
        ],
        const SizedBox(height: 12),
        Spaced(gap: 12, children: children),
      ],
    );
  }
}

/// Small blue toggle (.cp-tog).
class MiniToggle extends StatelessWidget {
  const MiniToggle(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 34,
      height: 20,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: on ? AppColors.accent : AppColors.line2, borderRadius: BorderRadius.circular(10)),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
      ),
    );
  }
}

/// Toggle + title + help line (.dr-sw). Keeps its own state unless [value] is given.
class SwitchRow extends StatefulWidget {
  const SwitchRow({super.key, required this.title, this.subtitle, this.initial = false, this.value, this.onChanged});
  final String title;
  final String? subtitle;
  final bool initial;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  @override
  State<SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<SwitchRow> {
  late bool _on = widget.value ?? widget.initial;

  @override
  void didUpdateWidget(SwitchRow old) {
    super.didUpdateWidget(old);
    if (widget.value != null) _on = widget.value!;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() => _on = !_on);
        widget.onChanged?.call(_on);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: MiniToggle(_on)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(widget.subtitle!, style: AppText.caption.copyWith(fontSize: 12.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Select box (.select) that opens a list of options in a sheet.
class PickerField extends StatelessWidget {
  const PickerField({super.key, this.label, required this.value, required this.options, required this.onChanged, this.hint, this.placeholder = false, this.trailingOf});
  final String? label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? hint;

  /// Show [value] greyed out (nothing picked yet).
  final bool placeholder;

  /// Optional right-side note for an option ("Their trainer").
  final String Function(String)? trailingOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button), side: const BorderSide(color: AppColors.line)),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            onTap: () => _open(context),
            child: SizedBox(
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(color: placeholder ? AppColors.muted : AppColors.text)),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 5),
          Text(hint!, style: AppText.caption),
        ],
      ],
    );
  }

  void _open(BuildContext context) {
    showAppSheet(
      context,
      title: label ?? 'Pick one',
      builder: (ctx) => Column(
        children: [
          for (final o in options)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text(o, style: AppText.bodyBold.copyWith(fontWeight: o == value ? FontWeight.w800 : FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingOf != null && trailingOf!(o).isNotEmpty) Text(trailingOf!(o), style: AppText.caption),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: o == value ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null,
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onChanged(o);
              },
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------- Option lists

/// Joined list of options (.dr-opts.joined).
class OptionList extends StatelessWidget {
  const OptionList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One row of an [OptionList]: radio or checkbox, optional avatar, title, hint.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    this.onTap,
    this.multi = false,
    this.leading,
    this.badge,
    this.trailing,
    this.disabled = false,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool multi;
  final Widget? leading;
  final Widget? badge;
  final Widget? trailing;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? .5 : 1,
      child: Material(
        color: selected ? const Color(0xFFF5F8FF) : Colors.white,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                _mark(),
                const SizedBox(width: 10),
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                          ?badge,
                        ],
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.caption.copyWith(fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mark() {
    if (multi) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.accent : AppColors.line2, width: 1.5),
        ),
        child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.accent : AppColors.line2, width: selected ? 6 : 1.5),
      ),
    );
  }
}

/// Small plain badge used inside option rows (.badge.plain).
class PlainBadge extends StatelessWidget {
  const PlainBadge(this.label, {super.key, this.tone = BadgeTone.neutral});
  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(AppRadius.badge)),
      child: Text(label, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: tone.fg)),
    );
  }
}

/// Bulleted list of "What happens" points (.ap-bl).
class BulletList extends StatelessWidget {
  const BulletList(this.points, {super.key});
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 6,
      children: [
        for (final p in points)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8, left: 2),
                child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle)),
              ),
              Expanded(child: Text(p, style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.text2))),
            ],
          ),
      ],
    );
  }
}

/// Small grey label above a group (.ap-lbl).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2));
}

/// Green "all good" line under a field (.ai-ok).
class OkLine extends StatelessWidget {
  const OkLine(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.ok),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: AppText.caption.copyWith(color: AppColors.okText, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
