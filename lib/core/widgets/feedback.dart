import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Toast kinds from the design (ca-toast.ok / star / water / warn / err / del).
enum ToastKind {
  ok(AppColors.accent, Colors.white, Icons.check_circle_rounded),
  star(AppColors.accent, Colors.white, Icons.star_rounded),
  info(Color(0xFF7CC4FF), Color(0xFF0E0F0C), Icons.info_rounded),
  water(Color(0xFF7CC4FF), Color(0xFF0E0F0C), Icons.water_drop_rounded),
  warn(Color(0xFFFFD166), Color(0xFF0E0F0C), Icons.warning_rounded),
  err(Color(0xFFFF7A45), Color(0xFF0E0F0C), Icons.error_rounded),
  del(Color(0xFF2A2C25), Color(0xFFF2F3EC), Icons.delete_rounded);

  const ToastKind(this.bg, this.fg, this.icon);
  final Color bg;
  final Color fg;
  final IconData icon;
}

OverlayEntry? _currentToast;
Timer? _toastTimer;

/// Shows the design's toast above the bottom nav. [onUndo] adds an "Undo" action
/// and keeps the toast up for 7 s instead of 5 s.
void showToast(
  BuildContext context,
  String title, {
  String? subtitle,
  ToastKind kind = ToastKind.info,
  VoidCallback? onUndo,
  String undoLabel = 'Undo',
}) {
  _toastTimer?.cancel();
  _currentToast?.remove();
  _currentToast = null;

  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  void close() {
    if (_currentToast == entry) {
      entry.remove();
      _currentToast = null;
    }
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).padding.bottom + 82;
      return Positioned(
        left: 12,
        right: 12,
        bottom: bottom,
        child: _ToastCard(
          title: title,
          subtitle: subtitle,
          kind: kind,
          undoLabel: undoLabel,
          onUndo: onUndo == null
              ? null
              : () {
                  close();
                  onUndo();
                },
          onClose: close,
        ),
      );
    },
  );
  _currentToast = entry;
  overlay.insert(entry);
  _toastTimer = Timer(Duration(seconds: onUndo != null ? 7 : 5), close);
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.title, this.subtitle, required this.kind, this.onUndo, required this.undoLabel, required this.onClose});
  final String title;
  final String? subtitle;
  final ToastKind kind;
  final VoidCallback? onUndo;
  final String undoLabel;
  final VoidCallback onClose;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    return SlideTransition(
      position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _c,
        child: Material(
          color: k.bg,
          borderRadius: BorderRadius.circular(8),
          elevation: 10,
          shadowColor: Colors.black54,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Row(
              children: [
                Icon(k.icon, color: k.fg, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800, color: k.fg, height: 1.3)),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                        Text(widget.subtitle!,
                            style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: k.fg.withValues(alpha: .78))),
                    ],
                  ),
                ),
                if (widget.onUndo != null)
                  TextButton(
                    onPressed: widget.onUndo,
                    style: TextButton.styleFrom(foregroundColor: k.fg),
                    child: Text(widget.undoLabel, style: AppText.bodyBold.copyWith(color: k.fg, decoration: TextDecoration.underline, decorationColor: k.fg)),
                  ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded, size: 18, color: k.fg.withValues(alpha: .8)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the design header (title + one line of help + close).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required WidgetBuilder builder,
  List<Widget> Function(BuildContext)? actions,
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
    builder: (ctx) {
      final body = builder(ctx);
      final acts = actions?.call(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppText.secondary.copyWith(fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                  AppIconButton(Icons.close_rounded, small: true, onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: body)
                  : Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: body),
            ),
            if (acts != null && acts.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(ctx).padding.bottom),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                child: Row(
                  children: [
                    for (var i = 0; i < acts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: acts[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// Action list sheet (tapping a row opens its actions in a bottom sheet).
class SheetAction {
  const SheetAction(this.label, this.icon, this.onTap, {this.destructive = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

Future<void> showActionSheet(BuildContext context, {required String title, String? subtitle, required List<SheetAction> actions}) {
  return showAppSheet(
    context,
    title: title,
    subtitle: subtitle,
    builder: (ctx) => Column(
      children: [
        for (final a in actions)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(a.icon, color: a.destructive ? AppColors.bad : AppColors.text2, size: 21),
            title: Text(a.label, style: AppText.bodyBold.copyWith(color: a.destructive ? AppColors.bad : AppColors.text)),
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

/// Confirm modal: icon + title + one line of help; Cancel (outline) then the main action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final r = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: destructive ? AppColors.badBg : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: destructive ? AppColors.bad : AppColors.accent, size: 21),
              ),
              const SizedBox(height: 14),
            ],
            Text(title, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, style: AppText.secondary.copyWith(fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop(false))),
                const SizedBox(width: 10),
                Expanded(
                  child: destructive
                      ? AppButton.danger(confirmLabel, onPressed: () => Navigator.of(ctx).pop(true))
                      : AppButton(confirmLabel, onPressed: () => Navigator.of(ctx).pop(true)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return r ?? false;
}
