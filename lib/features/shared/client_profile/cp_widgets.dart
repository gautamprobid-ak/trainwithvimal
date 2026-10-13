import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Small building blocks used by every client profile tab and sheet.

/// Blue text button (btn text).
class CpTextButton extends StatelessWidget {
  const CpTextButton(this.label, {super.key, this.onTap, this.icon, this.danger = false, this.size = 12.5});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool danger;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.badText : AppColors.accentText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: size + 3, color: color), const SizedBox(width: 4)],
            Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: size, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card with the design's card header: h3 title, caption, right-side action.
class CpCard extends StatelessWidget {
  const CpCard({
    super.key,
    this.title,
    this.titleWidget,
    this.cap,
    this.action,
    this.onAction,
    this.trailing,
    required this.child,
    this.count,
  });
  final String? title;
  final Widget? titleWidget;
  final String? cap;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || titleWidget != null;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleWidget ??
                            Row(
                              children: [
                                Flexible(child: Text(title!, style: AppText.cardTitle)),
                                if (count != null) ...[const SizedBox(width: 6), CpCount(count!)],
                              ],
                            ),
                        if (cap != null) ...[const SizedBox(height: 2), Text(cap!, style: AppText.caption)],
                      ],
                    ),
                  ),
                  if (action != null) CpTextButton(action!, onTap: onAction),
                  ?trailing,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Grey number next to a heading (cp-n).
class CpCount extends StatelessWidget {
  const CpCount(this.n, {super.key});
  final int n;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(6)),
      child: Text('$n', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
    );
  }
}

/// Small rounded icon square (cp-ric) with tone.
class CpIcon extends StatelessWidget {
  const CpIcon(this.icon, {super.key, this.tone, this.size = 30});
  final IconData icon;
  final BadgeTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.warn => (AppColors.warnBg, AppColors.warnText),
      BadgeTone.info => (AppColors.accentSoft, AppColors.accent),
      BadgeTone.bad => (AppColors.badBg, AppColors.badText),
      BadgeTone.ok => (AppColors.okBg, AppColors.okText),
      _ => (AppColors.sub, AppColors.text2),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: size * .53, color: fg),
    );
  }
}

/// List row inside a card (row cmp): icon, title, subtitle, trailing, optional chevron.
class CpRow extends StatelessWidget {
  const CpRow({
    super.key,
    this.icon,
    this.tone,
    this.leading,
    required this.title,
    this.titleWidget,
    this.sub,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.selected = false,
    this.bold = false,
  });
  final IconData? icon;
  final BadgeTone? tone;
  final Widget? leading;
  final String title;
  final Widget? titleWidget;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final bool selected;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.hover : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)] else if (icon != null) ...[
                CpIcon(icon!, tone: tone),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget ??
                        Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
                    if (sub != null) ...[const SizedBox(height: 1), Text(sub!, style: AppText.caption)],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (chevron) const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rows separated by thin lines (card-b).
class CpRows extends StatelessWidget {
  const CpRows(this.children, {super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Definition grid (cp-kv): label above bold value, thin line under each.
class KvGrid extends StatelessWidget {
  const KvGrid(this.items, {super.key, this.columns = 2, this.valueBuilder});
  final List<(String, String)> items;
  final int columns;
  final Widget? Function(int index, String value)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 16.0;
          final w = (c.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  width: w,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].$1, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      valueBuilder?.call(i, items[i].$2) ??
                          Text(items[i].$2, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One "card" of a table that turns into cards on the phone (tbl pf-cards).
class PfItem {
  const PfItem({required this.head, this.fields = const [], this.wide, this.action, this.onTap});
  final Widget head;
  final List<(String, Widget)> fields;
  final Widget? wide;
  final Widget? action;
  final VoidCallback? onTap;
}

class PfCards extends StatelessWidget {
  const PfCards(this.items, {super.key, this.columns = 3});
  final List<PfItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _PfCard(items[i], columns),
          ],
        ],
      ),
    );
  }
}

class _PfCard extends StatelessWidget {
  const _PfCard(this.item, this.columns);
  final PfItem item;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(right: item.action != null ? 40 : 0),
            child: DefaultTextStyle.merge(style: AppText.bodyBold, child: item.head),
          ),
          if (item.fields.isNotEmpty) ...[
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                const gap = 12.0;
                final w = (c.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: 8,
                  children: [
                    for (final (label, value) in item.fields)
                      SizedBox(
                        width: w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (label.isNotEmpty)
                              Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            DefaultTextStyle.merge(style: AppText.body.copyWith(fontSize: 13), child: value),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (item.wide != null) ...[const SizedBox(height: 8), item.wide!],
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Stack(
          children: [
            body,
            if (item.action != null) Positioned(top: 6, right: 8, child: item.action!),
          ],
        ),
      ),
    );
  }
}

/// Plain text cell for [PfCards].
class PfText extends StatelessWidget {
  const PfText(this.text, {super.key, this.bold = false, this.color, this.muted = false});
  final String text;
  final bool bold;
  final Color? color;
  final bool muted;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: (muted ? AppText.caption : AppText.body.copyWith(fontSize: 13))
            .copyWith(fontWeight: bold ? FontWeight.w700 : null, color: color),
      );
}

/// Underlined sub tabs inside a tab (tabs / cp-subbar) — grey track, scrolls sideways.
class CpSubTabs extends StatelessWidget {
  const CpSubTabs({super.key, required this.items, required this.value, required this.onChanged});
  final List<(String, String)> items;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            for (final (id, label) in items)
              GestureDetector(
                onTap: () => onChanged(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: id == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: id == value ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
                  ),
                  child: Text(
                    label,
                    style: AppText.secondary.copyWith(
                      fontSize: 12.5,
                      fontWeight: id == value ? FontWeight.w700 : FontWeight.w600,
                      color: id == value ? AppColors.text : AppColors.text2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip (fchip): white pill, selected = dark.
class FChip extends StatelessWidget {
  const FChip(this.label, {super.key, required this.selected, this.onTap, this.count});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  @override
  Widget build(BuildContext context) => ChoicePill(label, selected: selected, onTap: onTap, count: count);
}

/// Horizontal list of filter chips.
class FChipBar extends StatelessWidget {
  const FChipBar({super.key, required this.items, required this.value, required this.onChanged, this.counts});
  final List<(String, String)> items;
  final String value;
  final ValueChanged<String> onChanged;
  final Map<String, int>? counts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (id, label) in items) ...[
            FChip(label, selected: id == value, onTap: () => onChanged(id), count: counts?[id]),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// Exercise tag circle (dr-num): number, superset tag (A1) or status colour.
class NumTag extends StatelessWidget {
  const NumTag(this.text, {super.key, this.superset = false, this.tone});
  final String text;
  final bool superset;
  final BadgeTone? tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = superset
        ? (const Color(0xFFEFE9FB), const Color(0xFF6D3FC9))
        : switch (tone) {
            BadgeTone.ok => (AppColors.okBg, AppColors.okText),
            BadgeTone.warn => (AppColors.warnBg, AppColors.warnText),
            _ => (AppColors.sub, AppColors.text2),
          };
    return Container(
      height: 22,
      constraints: const BoxConstraints(minWidth: 22),
      padding: EdgeInsets.symmetric(horizontal: superset ? 5 : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(superset ? 6 : 11)),
      child: Text(text, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// Coloured placeholder for a photo / video (media t1–t4).
class MediaBox extends StatelessWidget {
  const MediaBox({super.key, this.tone = 0, this.width, this.height, this.icon = Icons.image_outlined, this.radius = 10, this.child});
  final int tone;
  final double? width;
  final double? height;
  final IconData? icon;
  final double radius;
  final Widget? child;

  static const _g = [
    [Color(0xFFE6EEF9), Color(0xFFCCDAF0)],
    [Color(0xFFEEF0E8), Color(0xFFDADFCF)],
    [Color(0xFFF3ECE6), Color(0xFFE4D6CA)],
    [Color(0xFFECE9F4), Color(0xFFD8D2E8)],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _g[tone % 4]),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (icon != null) Icon(icon, color: const Color(0x66000000), size: 22),
          ?child,
        ],
      ),
    );
  }
}

/// Little blue dot that marks a change for this client (cp-chd).
class ChangeDot extends StatelessWidget {
  const ChangeDot({super.key, this.on = true});
  final bool on;
  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(color: on ? AppColors.accent : Colors.transparent, shape: BoxShape.circle),
      );
}

/// Small "i" that explains something on tap (cp-info tooltip).
class InfoTip extends StatelessWidget {
  const InfoTip(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.info_outline_rounded, size: 16, color: AppColors.muted),
      ),
    );
  }
}

/// Section title inside a sheet (dr-st): h4 + optional help line.
class SheetSection extends StatelessWidget {
  const SheetSection({super.key, required this.title, this.help, this.trailing, required this.children});
  final String title;
  final String? help;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                    if (help != null) Text(help!, style: AppText.caption),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Toggle line in a sheet (dr-sw).
class ToggleLine extends StatelessWidget {
  const ToggleLine({super.key, required this.title, this.sub, required this.value, required this.onChanged});
  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Transform.scale(
              scale: .8,
              child: Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.accent),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (sub != null) Text(sub!, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A select-like field (label + box with chevron). Tapping picks from [options].
class SelectField extends StatelessWidget {
  const SelectField({super.key, this.label, required this.value, this.options = const [], this.onChanged, this.onTap});
  final String? label;
  final String value;
  final List<String> options;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(height: 6),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ??
              (options.isEmpty
                  ? null
                  : () async {
                      final v = await pickOption(context, title: label ?? 'Choose', options: options, current: value);
                      if (v != null) onChanged?.call(v);
                    }),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: AppText.body)),
                const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet list of options with a tick on the current one.
Future<String?> pickOption(BuildContext context, {required String title, required List<String> options, String? current}) {
  return showAppSheet<String>(
    context,
    title: title,
    builder: (ctx) => Column(
      children: [
        for (final o in options)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(o, style: AppText.bodyBold.copyWith(fontWeight: o == current ? FontWeight.w700 : FontWeight.w600)),
            trailing: o == current ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null,
            onTap: () => Navigator.of(ctx).pop(o),
          ),
      ],
    ),
  );
}

/// Sheet content with a fixed footer (drawer-b + drawer-f).
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.children, this.note, this.actions = const [], this.lead});
  final List<Widget> children;
  final String? note;
  final List<Widget> actions;
  final Widget? lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?lead,
              if (note != null && note!.isNotEmpty) ...[
                Text(note!, style: AppText.caption),
                const SizedBox(height: 8),
              ],
              if (actions.isNotEmpty)
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens a full-height sheet whose body manages its own footer ([SheetBody]).
Future<T?> showCpSheet<T>(BuildContext context, {required String title, String? subtitle, required WidgetBuilder builder}) {
  return showAppSheet<T>(context, title: title, subtitle: subtitle, scrollable: false, builder: builder);
}

/// KPI strip (dr-kpis): small label over bold value, split by thin lines.
class KpiStrip extends StatelessWidget {
  const KpiStrip(this.items, {super.key, this.columns});
  final List<(String, String)> items;
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? (items.length > 4 ? 3 : items.length);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / cols;
          return Wrap(
            runSpacing: 10,
            children: [
              for (final (k, v) in items)
                SizedBox(
                  width: w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(v, maxLines: 2, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Question / answer list (dr-qa).
class QaList extends StatelessWidget {
  const QaList(this.items, {super.key});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (q, a) in items)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(a, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Quote block (dr-quote): bold lead + text.
class QuoteBox extends StatelessWidget {
  const QuoteBox({super.key, required this.lead, required this.text});
  final String lead;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.sub,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lead, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(text, style: AppText.body.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }
}

/// Grey label line inside sheets (dr-sub).
class SubLabel extends StatelessWidget {
  const SubLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: AppText.overline.copyWith(fontSize: 11, letterSpacing: .8)),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Reply box under a log (dr-reply): text field + Send.
class ReplyBox extends StatefulWidget {
  const ReplyBox({super.key, required this.hint, required this.firstName});
  final String hint;
  final String firstName;
  @override
  State<ReplyBox> createState() => _ReplyBoxState();
}

class _ReplyBoxState extends State<ReplyBox> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    if (_c.text.trim().isEmpty) {
      showToast(context, 'Write something first', kind: ToastKind.warn);
      return;
    }
    _c.clear();
    FocusScope.of(context).unfocus();
    showToast(context, 'Sent to ${widget.firstName}', subtitle: '${widget.firstName} gets it as a message in the app', kind: ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _c, minLines: 3, maxLines: 5, style: AppText.body, decoration: InputDecoration(hintText: widget.hint)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('${widget.firstName} gets it as a message in the app', style: AppText.caption)),
              AppButton.outline('Send', icon: Icons.send_rounded, small: true, onPressed: _send),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selectable option row with a radio or check (dr-opt).
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.selected,
    required this.title,
    this.titleExtras = const [],
    this.sub,
    this.trailing,
    this.leading,
    this.onTap,
    this.disabled = false,
    this.multi = false,
  });
  final bool selected;
  final String title;
  final List<Widget> titleExtras;
  final String? sub;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool disabled;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? .55 : 1,
      child: Material(
        color: selected ? AppColors.hover : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.accent : AppColors.line),
        ),
        child: InkWell(
          onTap: disabled ? null : onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  multi
                      ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                      : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                  size: 20,
                  color: selected ? AppColors.accent : AppColors.line2,
                ),
                const SizedBox(width: 10),
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)), ...titleExtras],
                      ),
                      if (sub != null) ...[const SizedBox(height: 2), Text(sub!, style: AppText.caption)],
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
}

/// Column of [OptionTile]s with a small gap.
class OptionList extends StatelessWidget {
  const OptionList(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 6), children[i]],
        ],
      );
}

/// Static search box used in sheets (search).
class SheetSearch extends StatelessWidget {
  const SheetSearch(this.hint, {super.key, this.onChanged});
  final String hint;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SearchField(hint: hint, onChanged: onChanged),
      );
}

/// Grey hint line (cp-hint).
class HintLine extends StatelessWidget {
  const HintLine(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: AppText.caption.copyWith(fontSize: 12.5)),
      );
}

/// Two fields side by side.
class FieldPair extends StatelessWidget {
  const FieldPair(this.a, this.b, {super.key});
  final Widget a;
  final Widget b;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
      );
}

/// Dashed "+ Add …" button (cp-add).
class AddButton extends StatelessWidget {
  const AddButton(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line2),
          color: const Color(0xFFFAFAF8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 17, color: AppColors.text2),
            const SizedBox(width: 6),
            Text(label, style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.text2)),
          ],
        ),
      ),
    );
  }
}

/// Inline editable cell (cp-ci): small bordered box showing a value. Tap to edit text.
class EditCell extends StatelessWidget {
  const EditCell(this.value, {super.key, this.select = false, this.changed = false, this.onTap, this.width});
  final String value;
  final bool select;
  final bool changed;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: changed ? AppColors.accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: changed ? const Color(0xFFBFD3FB) : AppColors.line),
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(child: Text(value, style: AppText.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600))),
            if (select) const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Asks for a new text value in a small sheet.
Future<String?> editText(BuildContext context, {required String title, required String value, String? hint}) {
  final c = TextEditingController(text: value);
  return showAppSheet<String>(
    context,
    title: title,
    builder: (ctx) => TextField(controller: c, autofocus: true, style: AppText.body, decoration: InputDecoration(hintText: hint)),
    actions: (ctx) => [
      AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
      AppButton('Save', onPressed: () => Navigator.of(ctx).pop(c.text)),
    ],
  );
}
