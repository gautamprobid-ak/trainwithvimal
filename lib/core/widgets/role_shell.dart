import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'badges.dart';

/// One bottom-nav destination.
class ShellTab {
  const ShellTab(this.label, this.icon, this.activeIcon, {this.badge});
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Red count on the tab (e.g. pending check-ins). 0/null hides it.
  final int Function()? badge;
}

/// Phone shell: the page with the 5-tab bottom nav (ca-tabs / mb-nav).
/// Sub pages stay inside their tab's branch, so the bar stays visible and
/// the parent tab stays highlighted — same as the design.
class RoleShell extends StatelessWidget {
  const RoleShell({super.key, required this.shell, required this.tabs});
  final StatefulNavigationShell shell;
  final List<ShellTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: tabs[i],
                      selected: shell.currentIndex == i,
                      // Tapping the current tab goes back to its root page.
                      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.selected, required this.onTap});
  final ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.muted;
    final n = tab.badge?.call() ?? 0;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(selected ? tab.activeIcon : tab.icon, size: 23, color: color),
              if (n > 0) Positioned(top: -5, left: 14, child: CountBadge(n)),
            ],
          ),
          const SizedBox(height: 3),
          Text(tab.label, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Plain page used by auth / onboarding screens (no bottom nav).
class BarePage extends StatelessWidget {
  const BarePage({super.key, required this.child, this.background = AppColors.bg});
  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: background, body: SafeArea(child: child));
  }
}

/// Helpers for screens shared by the admin (`/a`) and trainer (`/t`) apps:
/// `context.go(context.rolePath('/more/programs'))` keeps you inside the
/// current role's shell.
extension RolePath on BuildContext {
  String get roleBase {
    final p = GoRouterState.of(this).uri.path;
    if (p.startsWith('/t/')) return '/t';
    if (p.startsWith('/c/')) return '/c';
    return '/a';
  }

  bool get isTrainerApp => roleBase == '/t';
  bool get isAdminApp => roleBase == '/a';

  String rolePath(String path) => '$roleBase$path';
}
