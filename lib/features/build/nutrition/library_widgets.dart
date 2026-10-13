import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

// Small pieces shared by the build library pages (nutrition, meal plan
// builder, habits & supplements, content library).

// ---------------------------------------------------------------------------
// Number formatting (same rules as the design scripts)
// ---------------------------------------------------------------------------

/// One decimal at most, no trailing ".0": 1.5 → "1.5", 2.0 → "2".
String fq(num q) {
  final r = (q * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
}

/// Whole number from 10 up, one decimal below: 12.4 → "12", 3.25 → "3.3".
String nf(num x) => x >= 10 ? x.round().toString() : fq(x);

/// Indian digit grouping: 2150 → "2,150", 125000 → "1,25,000".
String fmtN(num n) {
  final v = n.round();
  final neg = v < 0;
  var s = v.abs().toString();
  if (s.length > 3) {
    final last = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last';
  }
  return neg ? '-$s' : s;
}

/// "1 client" / "3 clients".
String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// A portion label: "150 g", "1 katori", "2 × 1 medium".
String portionLabel(double q, String unit) => unit == 'g' ? '${fq(q)} g' : (q == 1 ? unit : '${fq(q)} × $unit');

/// Default serving of a library food: "1 plate · 180 g".
String servingLabel(Food f) {
  final u = f.unit;
  return portionLabel(f.defaultQty, u.name) + (u.isGrams ? '' : ' · ${fq(f.defaultGrams)} g');
}

/// Closeness of the protein / carbs / fat split per calorie, 0–100.
int macroMatch(List<double> a, List<double> b) {
  List<double> split(List<double> m) {
    final t = (m[0] * 4 + m[1] * 4 + m[2] * 9).clamp(1, double.infinity);
    return [m[0] * 4 / t, m[1] * 4 / t, m[2] * 9 / t];
  }

  final x = split(a), y = split(b);
  final d = (x[0] - y[0]).abs() + (x[1] - y[1]).abs() + (x[2] - y[2]).abs();
  return (100 - 50 * d).round().clamp(0, 100);
}

// ---------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------

/// Opens a client's profile from a name in the design data.
void openClientByName(BuildContext context, String name) {
  for (final c in PeopleMock.clients) {
    if (c.name == name) {
      context.push(Routes.clientProfile(context, c.id));
      return;
    }
  }
  showToast(context, name, subtitle: 'This demo client has no profile page yet');
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

/// Gradient food / media thumbnail (nu-fic t1…t4).
class FoodThumb extends StatelessWidget {
  const FoodThumb({super.key, this.tone = 1, this.size = 34, this.icon = Icons.restaurant_rounded, this.radius = 8});
  final int tone;
  final double size;
  final IconData icon;
  final double radius;

  static const gradients = [
    [Color(0xFFE8EDF7), Color(0xFFD3DCEC)],
    [Color(0xFFEEF0E8), Color(0xFFDADFCF)],
    [Color(0xFFF3ECE6), Color(0xFFE4D6CA)],
    [Color(0xFFECE9F4), Color(0xFFD8D2E8)],
  ];

  static LinearGradient gradient(int tone) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradients[(tone - 1).clamp(0, 3)],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: gradient(tone), borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: size * .52, color: const Color(0x66171717)),
    );
  }
}

/// Indian food-label diet mark (green dot, amber egg, red triangle, vegan).
class DietMark extends StatelessWidget {
  const DietMark(this.diet, {super.key});

  /// null = "Any diet".
  final Diet? diet;

  @override
  Widget build(BuildContext context) {
    final color = switch (diet) {
      Diet.veg => const Color(0xFF16A34A),
      Diet.egg => const Color(0xFFD97706),
      Diet.nonVeg => const Color(0xFFB91C1C),
      Diet.vegan => const Color(0xFF15803D),
      null => AppColors.line2,
    };
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: diet == Diet.vegan ? const Color(0xFFE8F6EE) : null,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: diet == Diet.nonVeg
          ? Icon(Icons.change_history_rounded, size: 8, color: color)
          : Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

/// Bordered − value unit + stepper (pg-step).
class NumStepper extends StatelessWidget {
  const NumStepper({super.key, required this.value, this.unit = '', required this.onMinus, required this.onPlus});
  final String value;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(10), color: Colors.white),
      child: Row(
        children: [
          AppIconButton(Icons.remove_rounded, small: true, onPressed: onMinus, tooltip: 'Less'),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800))),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Flexible(child: Text(unit, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                ],
              ],
            ),
          ),
          AppIconButton(Icons.add_rounded, small: true, onPressed: onPlus, tooltip: 'More'),
        ],
      ),
    );
  }
}

/// Small toggle (cp-tog).
class TogSwitch extends StatelessWidget {
  const TogSwitch(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 34,
      height: 20,
      padding: const EdgeInsets.all(2),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(color: on ? AppColors.accent : AppColors.line2, borderRadius: BorderRadius.circular(10)),
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

/// Switch row with a title and one line of help (dr-sw).
class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.on, required this.title, this.subtitle, required this.onTap});
  final bool on;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            TogSwitch(on),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  if (subtitle != null) Text(subtitle!, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small segmented tabs with optional counts (tabs sm). Scrolls when wide.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({super.key, required this.items, required this.value, required this.onChanged, this.expand = false});
  final List<(T, String, int?)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final (v, label, n) in items)
        GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: v == value ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: v == value
                  ? const [BoxShadow(color: Color(0x14171717), blurRadius: 2, offset: Offset(0, 1)), BoxShadow(color: AppColors.line, spreadRadius: 1)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: v == value ? AppColors.text : AppColors.text2)),
                ),
                if (n != null) ...[
                  const SizedBox(width: 5),
                  Text('$n', style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
    ];
    final track = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            expand ? Expanded(child: tabs[i]) : tabs[i],
          ],
        ],
      ),
    );
    if (expand) return track;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: track);
  }
}

/// Page tabs with a count pill (utabs).
class CountTabs<T> extends StatelessWidget {
  const CountTabs({super.key, required this.items, required this.value, required this.onChanged});
  final List<(T, String, int)> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          for (final (v, label, n) in items)
            InkWell(
              onTap: () => onChanged(v),
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: v == value ? AppColors.text : Colors.transparent, width: 2))),
                child: Row(
                  children: [
                    Text(label,
                        style: AppText.secondary.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: v == value ? AppColors.text : AppColors.muted)),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(9)),
                      child: Text('$n', style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Round filter chip with a count (nu-g / ct-cat on phone).
class CountChip extends StatelessWidget {
  const CountChip(this.label, {super.key, required this.count, required this.selected, required this.onTap});
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.text : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.text : AppColors.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppText.secondary.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.text2)),
              const SizedBox(width: 6),
              Text('$count',
                  style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? const Color(0xFFC9C9C4) : AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label above a form control (.field > label), with optional help tooltip.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.info, this.trailing});
  final String text;
  final bool required;
  final String? info;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: text),
                if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.bad)),
              ]),
              style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2),
            ),
          ),
          if (info != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: info!,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              child: const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.muted),
            ),
          ],
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// A form field block: label + control.
class FieldBlock extends StatelessWidget {
  const FieldBlock({super.key, required this.label, required this.child, this.required = false, this.info, this.hint, this.trailing});
  final String label;
  final Widget child;
  final bool required;
  final String? info;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label, required: required, info: info, trailing: trailing),
        child,
        if (hint != null) ...[const SizedBox(height: 5), Text(hint!, style: AppText.caption)],
      ],
    );
  }
}

/// Plain text input with the app's input style.
class PlainInput extends StatelessWidget {
  const PlainInput({super.key, this.controller, this.hint, this.maxLines = 1, this.onChanged, this.keyboardType, this.suffix, this.autofocus = false});
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final String? suffix;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      onChanged: onChanged,
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        suffixText: suffix,
        suffixStyle: AppText.caption,
      ),
    );
  }
}

/// Buttons at the bottom of a sheet whose body holds its own state.
class SheetButtons extends StatelessWidget {
  const SheetButtons({super.key, required this.children, this.note});
  final List<Widget> children;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note != null && note!.isNotEmpty) ...[
            Text(note!, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Multi-select client row with a square check (dr-opt sm).
class ClientPickRow extends StatelessWidget {
  const ClientPickRow({super.key, required this.name, required this.subtitle, required this.selected, required this.onTap, this.tag});
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.accentSoft : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : Colors.white,
                border: Border.all(color: selected ? AppColors.accent : AppColors.line2, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Avatar(Avatar.initialsOf(name), size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            if (tag != null && tag!.isNotEmpty) AppBadge(tag!, tone: BadgeTone.warn),
          ],
        ),
      ),
    );
  }
}

/// Bordered list of [ClientPickRow]s (dr-opts joined).
class JoinedList extends StatelessWidget {
  const JoinedList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
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

/// Client link row (mb-cl / nu-urow): avatar, name, line, trailing.
class ClientLinkRow extends StatelessWidget {
  const ClientLinkRow({super.key, required this.name, required this.subtitle, this.trailing, required this.onTap});
  final String name;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Avatar(Avatar.initialsOf(name), size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Grey note with an icon (hb-note / mb-tip / pb-acn).
class GreyNote extends StatelessWidget {
  const GreyNote({super.key, required this.child, this.icon = Icons.info_outline_rounded});
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
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: AppColors.muted)),
          const SizedBox(width: 8),
          Expanded(child: DefaultTextStyle.merge(style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2, height: 1.5), child: child)),
        ],
      ),
    );
  }
}

/// Empty hint inside a card (mb-sempty).
class SideEmpty extends StatelessWidget {
  const SideEmpty(this.text, {super.key, this.icon = Icons.person_off_outlined});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.secondary.copyWith(fontSize: 12.5))),
      ],
    );
  }
}

/// Wide dashed button (mb-addm).
class DashedAddButton extends StatelessWidget {
  const DashedAddButton(this.label, {super.key, required this.onTap, this.icon = Icons.add_rounded});
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: CustomPaint(
        painter: DashedBorderPainter(radius: AppRadius.card),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.text2),
              const SizedBox(width: 6),
              Text(label, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.text2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded border.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({this.radius = 12, this.color = AppColors.line2, this.dash = 5, this.gap = 4, this.strokeWidth = 1.5});
  final double radius;
  final Color color;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color || old.radius != radius;
}

/// Dashed drop zone (nu-drop / ct-drop).
class DropZone extends StatelessWidget {
  const DropZone({super.key, required this.title, required this.subtitle, required this.onTap, this.icon = Icons.upload_file_rounded});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: DashedBorderPainter(radius: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, size: 26, color: AppColors.accent),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: AppText.bodyBold),
              const SizedBox(height: 2),
              Text(subtitle, textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bordered file row (ct-file / nu-file).
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.leading, required this.title, required this.subtitle, this.trailing});
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13)),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Three-dot menu button used on rows and cards.
class DotsButton extends StatelessWidget {
  const DotsButton({super.key, required this.onPressed, this.tooltip = 'Options'});
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.muted),
    );
  }
}

/// Grey pill (nu-meals span / ct-u.none).
class GreyTag extends StatelessWidget {
  const GreyTag(this.text, {super.key, this.blue = false, this.icon});
  final String text;
  final bool blue;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = blue ? const Color(0xFF1D4ED8) : AppColors.text2;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: blue ? const Color(0xFFEAF0FE) : AppColors.sub, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(text,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: fg, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
