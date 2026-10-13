import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';

/// Small pieces shared by the programs and exercise screens.

const weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Program icon tones (pg-ic t1 … t4).
const programTones = [
  (Color(0xFFEAF0FE), Color(0xFF1D4ED8)),
  (Color(0xFFF1EAFE), Color(0xFF5B21B6)),
  (Color(0xFFE8F6EE), Color(0xFF11663D)),
  (Color(0xFFFFF1E6), Color(0xFF9A3A10)),
];

/// "120 s" → "2 min", "45" → "45s", 0 → "No rest".
String restLabel(int s) => s == 0 ? 'No rest' : (s >= 120 && s % 60 == 0 ? '${s ~/ 60} min' : '${s}s');

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Field label above an input (.field > label), with an optional red asterisk.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.bad)),
        ]),
        style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2),
      ),
    );
  }
}

/// Grey help line under a field (.hint / .cap).
class HintText extends StatelessWidget {
  const HintText(this.text, {super.key, this.top = 5});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.only(top: top), child: Text(text, style: AppText.caption.copyWith(fontSize: 12)));
}

/// − value unit + stepper (pg-step).
class NumberStepper extends StatelessWidget {
  const NumberStepper({super.key, required this.value, this.unit = '', required this.onMinus, required this.onPlus, this.height = 40});
  final String value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Row(
        children: [
          _btn(Icons.remove_rounded, onMinus),
          const Spacer(),
          Text(value, style: AppText.bodyBold.copyWith(fontSize: 16)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(unit, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
          const Spacer(),
          _btn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => SizedBox(
        width: 30,
        height: 30,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.line)),
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppColors.text2),
          ),
        ),
      );
}

/// Labelled stepper (field with a pg-step).
class StepperField extends StatelessWidget {
  const StepperField({super.key, required this.label, required this.value, this.unit = '', required this.onMinus, required this.onPlus});
  final String label;
  final String value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        NumberStepper(value: value, unit: unit, onMinus: onMinus, onPlus: onPlus),
      ],
    );
  }
}

/// Seven day boxes, training days blue (pg-week).
class WeekStrip extends StatelessWidget {
  const WeekStrip(this.pattern, {super.key, this.large = false, this.muted = false});
  final List<bool> pattern;
  final bool large;

  /// Archived programs show training days in grey.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Tooltip(
              message: '${weekdayLong[i]} · ${pattern[i] ? 'training' : 'rest'}',
              child: Container(
                height: large ? 32 : 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pattern[i] ? (muted ? AppColors.line : const Color(0xFFDCE7FD)) : AppColors.sub,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  weekLetters[i],
                  style: AppText.caption.copyWith(
                    fontSize: large ? 12 : 10.5,
                    fontWeight: FontWeight.w700,
                    color: pattern[i] ? (muted ? AppColors.text2 : AppColors.accentText) : AppColors.muted,
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

/// Video / image placeholder thumbnail (.media t1 … t4) with an optional play pill.
class MediaThumb extends StatelessWidget {
  const MediaThumb({
    super.key,
    this.tone = 0,
    this.width,
    this.height,
    this.radius = 10,
    this.duration,
    this.icon = Icons.fitness_center_rounded,
    this.iconSize = 24,
    this.youtube = false,
    this.label,
  });
  final int tone;
  final double? width;
  final double? height;
  final double radius;

  /// Shows the play pill ("▶ 0:42") when set.
  final String? duration;
  final IconData icon;
  final double iconSize;
  final bool youtube;

  /// Small text instead of a play pill (e.g. "Image").
  final String? label;

  static const _grads = [
    [Color(0xFFE8EDF7), Color(0xFFD3DCEC)],
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _grads[tone % 4]),
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, size: iconSize, color: const Color(0x47171717))),
          if (duration != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                height: 18,
                padding: const EdgeInsets.fromLTRB(4, 0, 6, 0),
                decoration: BoxDecoration(
                  color: youtube ? const Color(0xFFE11D1D) : const Color(0xB8171717),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(duration!, style: AppText.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          if (label != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xCCFFFFFF), borderRadius: BorderRadius.circular(9)),
                child: Text(label!, style: AppText.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text2)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tick box used in pick lists (pk-chk). [square] for multi select.
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.on, this.square = true, this.disabled = false});
  final bool on;
  final bool square;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? AppColors.accent : (disabled ? AppColors.sub : Colors.white),
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(6) : null,
        border: Border.all(color: on ? AppColors.accent : AppColors.line2, width: 1.5),
      ),
      child: on ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
    );
  }
}

/// A selectable row inside a joined option list (dr-opt).
class PickRow extends StatelessWidget {
  const PickRow({super.key, required this.selected, required this.child, this.onTap, this.disabled = false, this.square = true});
  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  final bool disabled;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF5F8FF) : Colors.white,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? .6 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CheckMark(on: selected, square: square, disabled: disabled),
                const SizedBox(width: 12),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Joined list of [PickRow]s in one bordered box.
class JoinedList extends StatelessWidget {
  const JoinedList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadius.menu)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Grey note box with an info icon (pb-acn).
class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.child, this.icon = Icons.info_outline_rounded});
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 15, color: AppColors.muted)),
          const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle(
              style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2, height: 1.5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet footer with Cancel (outline) and a main action — used inside stateful sheet bodies.
class SheetButtons extends StatelessWidget {
  const SheetButtons({super.key, required this.label, this.icon, this.onPressed, this.cancelLabel = 'Cancel', this.danger = false, this.note});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String cancelLabel;
  final bool danger;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note != null) ...[
            Text(note!, style: AppText.caption, textAlign: TextAlign.center),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(child: AppButton.outline(cancelLabel, expand: true, onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: danger
                    ? AppButton.danger(label, icon: icon, expand: true, onPressed: onPressed)
                    : AppButton(label, icon: icon, expand: true, onPressed: onPressed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small horizontal tabs (tabs sm) that wrap to the content width.
class MiniTabs extends StatelessWidget {
  const MiniTabs({super.key, required this.labels, required this.index, required this.onChanged, this.counts, this.expand = false});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<int>? counts;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (var i = 0; i < labels.length; i++)
        GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i == index ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: i == index ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.secondary.copyWith(
                      fontSize: 12.5,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w600,
                      color: i == index ? AppColors.text : AppColors.text2,
                    ),
                  ),
                ),
                if (counts != null) ...[
                  const SizedBox(width: 5),
                  Text('${counts![i]}', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [for (final t in tabs) expand ? Expanded(child: t) : t],
      ),
    );
  }
}

/// Title + caption on one line at the top of a card (sec-h).
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.caption, this.trailing});
  final String title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: Text(title, style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800))),
        const SizedBox(width: 8),
        if (caption != null)
          Expanded(child: Text(caption!, textAlign: TextAlign.right, style: AppText.caption, maxLines: 2))
        else
          const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// One row of a [showMenuSheet] (row-menu item, optional second line).
class MenuItem {
  const MenuItem(this.label, this.icon, this.onTap, {this.subtitle, this.destructive = false, this.enabled = true});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;
  final bool destructive;
  final bool enabled;
}

/// Phone version of the 3-dot row menu: a bottom sheet with the same items.
Future<void> showMenuSheet(BuildContext context, {required String title, String? subtitle, required List<MenuItem> items}) {
  return showAppSheet<void>(
    context,
    title: title,
    subtitle: subtitle,
    builder: (ctx) => Column(
      children: [
        for (final a in items)
          ListTile(
            enabled: a.enabled,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(a.icon, color: a.destructive ? AppColors.bad : AppColors.text2, size: 21),
            title: Text(a.label, style: AppText.bodyBold.copyWith(color: a.destructive ? AppColors.bad : (a.enabled ? AppColors.text : AppColors.muted))),
            subtitle: a.subtitle == null ? null : Text(a.subtitle!, style: AppText.caption),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () {
              Navigator.of(ctx).pop();
              a.onTap();
            },
          ),
      ],
    ),
  );
}
