import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Scrolling page body used by every phone screen (ca-scroll / wrap):
/// 16px side padding, 12px gap between blocks.
class PageScroll extends StatelessWidget {
  const PageScroll({super.key, required this.children, this.gap = AppSpace.gap, this.padding, this.onRefresh, this.controller});
  final List<Widget> children;
  final double gap;
  final EdgeInsets? padding;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      controller: controller,
      padding: padding ?? const EdgeInsets.fromLTRB(16, 6, 16, 28),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, i) => children[i],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Top of a tab page: big title, optional small line above/below, actions on the right.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.overline, this.subtitle, this.actions = const [], this.compact = false});
  final String title;
  final String? overline;
  final String? subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) Text(overline!, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: compact ? AppText.sectionTitle.copyWith(fontSize: 22) : AppText.pageTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.secondary),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 8), a],
        ],
      ),
    );
  }
}

/// Header for pushed (sub) pages: back button + title + actions.
class SubPageHeader extends StatelessWidget {
  const SubPageHeader({super.key, required this.title, this.subtitle, this.actions = const [], this.onBack});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(Icons.arrow_back_rounded, onPressed: onBack ?? () => context.canPop() ? context.pop() : null),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.sectionTitle),
              if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.secondary),
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 8), a],
      ],
    );
  }
}

/// Uppercase grey label above a group (".over").
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.trailing, this.padding = const EdgeInsets.only(left: 4, top: 4)});
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.overline.copyWith(fontSize: 11, letterSpacing: .9))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Card heading: tinted icon + title + subtitle + trailing.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.title, this.subtitle, this.icon, this.tint = Tint.gray, this.trailing});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Tint tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[TintIcon(icon!, tint: tint), const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.cardTitle),
              if (subtitle != null) Text(subtitle!, style: AppText.secondary.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Tinted rounded square icon (ch-ic / mb-ric).
class TintIcon extends StatelessWidget {
  const TintIcon(this.icon, {super.key, this.tint = Tint.gray, this.size = 34});
  final IconData icon;
  final Tint tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(size * .28)),
      child: Icon(icon, size: size * .52, color: tint.fg),
    );
  }
}

/// Navigation row inside a list card (mb-row): icon, label, chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.label,
    this.icon,
    this.tint = Tint.blue,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });
  final String label;
  final IconData? icon;
  final Tint tint;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppColors.hover,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                destructive
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: AppColors.badBg, borderRadius: BorderRadius.circular(9)),
                        child: Icon(icon, size: 17, color: AppColors.bad),
                      )
                    : TintIcon(icon!, tint: tint, size: 32),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w600, color: destructive ? AppColors.bad : AppColors.text)),
                    if (subtitle != null) Text(subtitle!, style: AppText.caption),
                  ],
                ),
              ),
              ?trailing,
              if (showChevron && !destructive) const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card containing rows separated by thin lines.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children, this.dividerIndent = 0});
  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: dividerIndent),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Grey segmented control (tabs track). Selected segment is white.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({super.key, required this.items, required this.value, required this.onChanged, this.expand = true});
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final (v, label) in items)
        _seg(
          label,
          v == value,
          () => onChanged(v),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [for (final t in tabs) expand ? Expanded(child: t) : t],
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: on ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.secondary.copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w600, color: on ? AppColors.text : AppColors.text2),
        ),
      ),
    );
  }
}

/// Underline tabs that scroll horizontally (profile sections).
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: i == index ? AppColors.accent : Colors.transparent, width: 2)),
                  ),
                  child: Text(
                    labels[i],
                    style: AppText.secondary.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: i == index ? AppColors.accentText : AppColors.muted,
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

/// Thin rounded progress bar (ch-prog).
class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key, this.color = AppColors.accent, this.height = 6, this.track = const Color(0xFFEDEDE9)});
  final double value;
  final Color color;
  final double height;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1).toDouble(),
              child: ColoredBox(color: color, child: SizedBox(height: height)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular ring (calorie ring, adherence).
class RingProgress extends StatelessWidget {
  const RingProgress({super.key, required this.value, this.size = 84, this.stroke = 9, this.color = AppColors.accent, this.child});
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: stroke,
              color: const Color(0xFFEDEDE9),
            ),
          ),
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 500),
              builder: (_, v, _) => CircularProgressIndicator(value: v, strokeWidth: stroke, color: color, strokeCap: StrokeCap.round),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// Stat card: label, big value, delta line.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.delta, this.deltaTone, this.icon, this.tint = Tint.blue, this.onTap});
  final String label;
  final String value;
  final String? delta;

  /// true = good (green), false = bad (red), null = muted.
  final bool? deltaTone;
  final IconData? icon;
  final Tint tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600))),
              if (icon != null) TintIcon(icon!, tint: tint, size: 26),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppText.bigNumber.copyWith(fontSize: 24)),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(
              delta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: deltaTone == null ? AppColors.muted : (deltaTone! ? AppColors.okText : AppColors.badText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label above value with a bottom line (Details pattern).
class DetailField extends StatelessWidget {
  const DetailField(this.label, this.value, {super.key, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line))),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 2),
          Text(value, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Search box with leading icon.
class SearchField extends StatelessWidget {
  const SearchField({super.key, this.hint = 'Search', this.onChanged, this.controller, this.trailing});
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.body,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Labelled text field (label above, optional hint below).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.hint,
    this.help,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.onChanged,
    this.error,
  });
  final String label;
  final String? hint;
  final String? help;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? prefix;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: maxLines,
          onChanged: onChanged,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixText: prefix == null ? null : '$prefix  ',
            prefixStyle: AppText.body.copyWith(color: AppColors.muted),
            errorText: error,
          ),
        ),
        if (help != null) ...[
          const SizedBox(height: 5),
          Text(help!, style: AppText.caption),
        ],
      ],
    );
  }
}

/// Empty state block.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          TintIcon(icon, tint: Tint.gray, size: 48),
          const SizedBox(height: 12),
          Text(title, style: AppText.cardTitle, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: AppText.secondary, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

/// Simple coloured banner (info / warning strip inside a page).
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline_rounded, this.bg = AppColors.accentSoft, this.fg = const Color(0xFF1E3A8A), this.action});
  final String text;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.secondary.copyWith(color: fg, fontWeight: FontWeight.w600))),
          ?action,
        ],
      ),
    );
  }
}
