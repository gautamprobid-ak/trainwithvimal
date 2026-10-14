import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Small building blocks shared by Forms, Automations, Emails and Settings
/// (cp-tog, dr-sw, field labels, pg-step steppers, select boxes, em-box).

/// Small switch (cp-tog): 30 x 18.
class MiniToggle extends StatelessWidget {
  const MiniToggle({super.key, required this.value, this.onChanged, this.dim = false});
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Draft rows show the switch faded.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Opacity(
          opacity: dim ? .55 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 30,
            height: 18,
            padding: const EdgeInsets.all(2),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(color: value ? AppColors.accent : AppColors.line2, borderRadius: BorderRadius.circular(9)),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle row with a title and one line of help (dr-sw).
class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.title, this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MiniToggle(value: value, onChanged: onChanged),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  if (subtitle != null) Text(subtitle!, style: AppText.caption.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Field label above a control, with an optional red star.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.bad),
              ),
          ],
        ),
        style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2),
      ),
    );
  }
}

/// Grey hint line under a field.
class FieldHint extends StatelessWidget {
  const FieldHint(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(text, style: AppText.caption.copyWith(height: 1.4)),
  );
}

/// Label + child + hint.
class FieldBlock extends StatelessWidget {
  const FieldBlock({super.key, required this.label, required this.child, this.hint, this.required = false});
  final String label;
  final Widget child;
  final String? hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, required: required),
        child,
        if (hint != null) FieldHint(hint!),
      ],
    );
  }
}

/// Select-looking box (".select"): value + chevron. Tapping opens a picker.
class SelectBox extends StatelessWidget {
  const SelectBox({super.key, required this.value, this.onTap, this.leading, this.placeholder = false});
  final String value;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontSize: 13.5, color: placeholder ? AppColors.muted : AppColors.text),
                ),
              ),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minus / value / unit / plus stepper (pg-step).
class StepperBox extends StatelessWidget {
  const StepperBox({super.key, required this.value, this.unit = '', required this.onMinus, required this.onPlus});
  final String value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(Icons.remove_rounded, small: true, onPressed: onMinus),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: AppText.bodyBold.copyWith(fontSize: 14.5),
                  children: [if (unit.isNotEmpty) TextSpan(text: ' $unit', style: AppText.secondary.copyWith(fontSize: 12.5))],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          AppIconButton(Icons.add_rounded, small: true, onPressed: onPlus),
        ],
      ),
    );
  }
}

/// Square checkbox (em-box). [locked] shows it faded and not tappable.
class TickBox extends StatelessWidget {
  const TickBox({super.key, required this.value, this.onTap, this.locked = false});
  final bool value;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: locked ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Opacity(
          opacity: locked ? .5 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? AppColors.accent : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: value ? AppColors.accent : AppColors.line2, width: 1.5),
            ),
            child: value ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
          ),
        ),
      ),
    );
  }
}

/// Round or square check mark used in option cards (pk-chk).
class PickCheck extends StatelessWidget {
  const PickCheck({super.key, required this.on, this.square = false});
  final bool on;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? AppColors.accent : Colors.white,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(5) : null,
        border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: 1.5),
      ),
      child: on ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
    );
  }
}

/// Selectable option card (fm-nko / au-sc / dr-opt): check, icon, title, lines.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.extra,
    this.icon,
    this.tint = Tint.blue,
    this.onTap,
    this.square = false,
    this.showCheck = true,
  });
  final bool selected;
  final String title;
  final String? subtitle;
  final String? extra;
  final IconData? icon;
  final Tint tint;
  final VoidCallback? onTap;
  final bool square;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.line, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCheck) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: PickCheck(on: selected, square: square),
                ),
                const SizedBox(width: 10),
              ],
              if (icon != null) ...[TintIcon(icon!, tint: tint, size: 32), const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppText.caption.copyWith(height: 1.4))],
                    if (extra != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        extra!,
                        style: AppText.caption.copyWith(fontStyle: FontStyle.italic, color: AppColors.text2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey note with an icon (hb-note).
class NoteBox extends StatelessWidget {
  const NoteBox(this.text, {super.key, this.icon = Icons.info_outline_rounded, this.action});
  final String text;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.caption.copyWith(color: AppColors.text2, height: 1.45)),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Card with an h3 heading and trailing (mb-side / hb-pv).
class SideCard extends StatelessWidget {
  const SideCard({super.key, required this.title, this.trailing, required this.children});
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      clip: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.cardTitle)),
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

/// Editor card heading: big tinted icon + title + one line (hb-eh).
class EditorHead extends StatelessWidget {
  const EditorHead({super.key, required this.icon, required this.tint, required this.title, required this.subtitle});
  final IconData icon;
  final Tint tint;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TintIcon(icon, tint: tint, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(subtitle, style: AppText.caption.copyWith(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stat block (fm-stats): big value and a small label, three in a row.
class StatTriple extends StatelessWidget {
  const StatTriple(this.items, {super.key});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(items[i].$1, style: AppText.bigNumber.copyWith(fontSize: 20)),
                  Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Link row with icon, title, small line and chevron (fm-au).
class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.sub,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.accentText),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.bodyBold.copyWith(fontSize: 13)),
                      if (subtitle != null) Text(subtitle!, style: AppText.caption.copyWith(fontSize: 11.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text button styled like the design's ".btn text".
class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, this.onTap, this.icon, this.danger = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.bad : AppColors.accentText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: c), const SizedBox(width: 5)],
            Text(label, style: AppText.bodyBold.copyWith(fontSize: 13, color: c)),
          ],
        ),
      ),
    );
  }
}

/// Underline page tabs with counts (utabs).
class CountTabs<T> extends StatelessWidget {
  const CountTabs({super.key, required this.items, required this.value, required this.onChanged});
  final List<(T, String, int?)> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (v, label, n) in items)
              InkWell(
                onTap: () => onChanged(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: v == value ? AppColors.accent : Colors.transparent, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: AppText.secondary.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: v == value ? AppColors.accentText : AppColors.muted,
                        ),
                      ),
                      if (n != null && n > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: v == value ? AppColors.accentSoft : AppColors.sub,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$n',
                            style: AppText.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: v == value ? AppColors.accentText : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Picks one item from a list in a bottom sheet. Returns the picked value.
Future<T?> pickFromSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<(T, String)> items,
  T? selected,
  IconData? Function(T)? iconOf,
}) {
  return showAppSheet<T>(
    context,
    title: title,
    subtitle: subtitle,
    builder: (ctx) => Column(
      children: [
        for (final (v, label) in items)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: iconOf?.call(v) == null ? null : Icon(iconOf!(v), size: 20, color: AppColors.text2),
            title: Text(label, style: AppText.bodyBold.copyWith(fontWeight: v == selected ? FontWeight.w800 : FontWeight.w600)),
            trailing: v == selected ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null,
            onTap: () => Navigator.of(ctx).pop(v),
          ),
      ],
    ),
  );
}

/// Tones t1..t4 from the design → tints.
Tint toneTint(int i) => const [Tint.blue, Tint.green, Tint.amber, Tint.purple][(i - 1).clamp(0, 3)];
