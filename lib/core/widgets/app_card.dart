import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White card with a 1px line border (ca-card / card).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color = AppColors.card,
    this.gradient,
    this.radius = AppRadius.card,
    this.borderColor = AppColors.line,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;
  final double radius;
  final Color borderColor;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: r, highlightColor: AppColors.hover, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: r,
          border: Border.all(color: borderColor),
        ),
        child: clip ? ClipRRect(borderRadius: r, child: content) : content,
      ),
    );
  }
}

/// Vertical list of children separated by [gap] — the ca-scroll / wrap column.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// Column of widgets with a uniform gap.
class Spaced extends StatelessWidget {
  const Spaced({super.key, required this.children, this.gap = AppSpace.gap, this.crossAxisAlignment = CrossAxisAlignment.stretch});
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(children[i]);
    }
    return Column(crossAxisAlignment: crossAxisAlignment, mainAxisSize: MainAxisSize.min, children: out);
  }
}
