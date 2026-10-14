import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

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
  del(Color(0xFF2A2C25), Color(0xFFF2F3EC), Icons.delete_rounded),

  /// Admin / trainer toast (.pg-toast): dark card, light-blue Undo.
  dark(Color(0xFF1F1F1F), Colors.white, Icons.check_rounded);

  const ToastKind(this.bg, this.fg, this.icon);
  final Color bg;
  final Color fg;
  final IconData icon;
}

OverlayEntry? _currentToast;
Timer? _toastTimer;

/// Shows the design's toast above the bottom nav. [onUndo] adds an "Undo" action
/// and keeps the toast up longer. In the admin and trainer apps every toast
/// uses the dark .pg-toast style; the client app uses the coloured kinds.
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

  if (_isStaffApp(context)) kind = ToastKind.dark;
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
      // 12 above the 60px tab bar (design: 12 above the bar).
      final bottom = MediaQuery.of(ctx).padding.bottom + 72;
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
  _toastTimer = Timer(Duration(seconds: onUndo != null ? 6 : 4), close);
}

bool _isStaffApp(BuildContext context) {
  try {
    final p = GoRouterState.of(context).uri.path;
    return p.startsWith('/a/') || p.startsWith('/t/');
  } catch (_) {
    return false;
  }
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
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: k.bg,
              borderRadius: BorderRadius.circular(14),
              elevation: 10,
              shadowColor: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Row(
                  children: [
                    if (k != ToastKind.dark) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: k.fg.withValues(alpha: .16), shape: BoxShape.circle),
                        child: Icon(k.icon, color: k.fg, size: 18),
                      ),
                      const SizedBox(width: 12),
                    ] else
                      const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: AppText.bodyBold.copyWith(
                              fontSize: k == ToastKind.dark ? 13.5 : 14,
                              fontWeight: k == ToastKind.dark ? FontWeight.w700 : FontWeight.w800,
                              color: k.fg,
                              height: 1.3,
                            ),
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: k == ToastKind.dark ? const Color(0xFFA3A3A3) : k.fg.withValues(alpha: .78),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.onUndo != null)
                      TextButton(
                        onPressed: widget.onUndo,
                        style: TextButton.styleFrom(foregroundColor: k.fg),
                        child: Text(
                          widget.undoLabel,
                          style: AppText.bodyBold.copyWith(
                            fontSize: 13.5,
                            color: k == ToastKind.dark ? const Color(0xFF93C5FD) : k.fg,
                            decoration: k == ToastKind.dark ? null : TextDecoration.underline,
                            decorationColor: k.fg,
                          ),
                        ),
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
