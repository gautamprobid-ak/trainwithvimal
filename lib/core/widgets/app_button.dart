import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outline, dark, soft, danger, ghost }

/// Button from the design system (ca-btn). Height 44 (default) or 34 (small).
class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.small = false,
    this.expand = false,
    this.loading = false,
  });

  const AppButton.outline(this.label, {super.key, this.onPressed, this.icon, this.small = false, this.expand = false, this.loading = false})
      : variant = AppButtonVariant.outline;
  const AppButton.dark(this.label, {super.key, this.onPressed, this.icon, this.small = false, this.expand = false, this.loading = false})
      : variant = AppButtonVariant.dark;
  const AppButton.soft(this.label, {super.key, this.onPressed, this.icon, this.small = false, this.expand = false, this.loading = false})
      : variant = AppButtonVariant.soft;
  const AppButton.danger(this.label, {super.key, this.onPressed, this.icon, this.small = false, this.expand = false, this.loading = false})
      : variant = AppButtonVariant.danger;
  const AppButton.ghost(this.label, {super.key, this.onPressed, this.icon, this.small = false, this.expand = false, this.loading = false})
      : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool small;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (AppColors.accent, Colors.white, Colors.transparent),
      AppButtonVariant.outline => (Colors.white, AppColors.text, AppColors.line),
      AppButtonVariant.dark => (AppColors.text, Colors.white, Colors.transparent),
      AppButtonVariant.soft => (AppColors.accentSoft, AppColors.accentText, Colors.transparent),
      AppButtonVariant.danger => (AppColors.bad, Colors.white, Colors.transparent),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.text2, Colors.transparent),
    };
    final disabled = onPressed == null || loading;
    final h = small ? 34.0 : 44.0;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: small ? 15 : 17, color: fg),
        if ((icon != null || loading) && label.isNotEmpty) SizedBox(width: small ? 5 : 7),
        if (label.isNotEmpty)
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyBold.copyWith(fontSize: small ? 13 : 14.5, color: fg),
            ),
          ),
      ],
    );
    return Opacity(
      opacity: disabled && !loading ? .5 : 1,
      child: SizedBox(
        height: h,
        width: expand ? double.infinity : null,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(small ? 10 : AppRadius.button),
            side: BorderSide(color: border),
          ),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 10 : AppRadius.button)),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16), child: child),
          ),
        ),
      ),
    );
  }
}

/// Square icon button with border (ca-ib). Optional red notification dot.
class AppIconButton extends StatelessWidget {
  const AppIconButton(this.icon, {super.key, this.onPressed, this.dot = false, this.small = false, this.tooltip, this.filled = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final bool dot;
  final bool small;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final s = small ? 34.0 : 38.0;
    final r = BorderRadius.circular(small ? 10 : 12);
    Widget w = SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: filled ? AppColors.accent : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: filled ? AppColors.accent : AppColors.line)),
              child: InkWell(
                onTap: onPressed,
                customBorder: RoundedRectangleBorder(borderRadius: r),
                child: Icon(icon, size: small ? 16 : 19, color: filled ? Colors.white : AppColors.text2),
              ),
            ),
          ),
          if (dot)
            Positioned(
              top: small ? 6 : 8,
              right: small ? 7 : 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.bad, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
    if (tooltip != null) w = Tooltip(message: tooltip!, child: w);
    return w;
  }
}
