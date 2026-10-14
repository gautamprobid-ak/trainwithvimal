import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/state/session.dart';

/// Design: AdminMoreMobile.dc.html — every other admin page.
class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(String path) => context.push(path);
    return PageScroll(
      children: [
        const PageHeader(title: 'More'),
        _MeCard(onTap: () => open(Routes.aSettings)),
        _Group('Pages', [
          NavRow(label: 'Trainers', icon: Icons.badge_outlined, tint: Tint.blue, onTap: () => open(Routes.aTrainers)),
          NavRow(label: 'Activity log', icon: Icons.history_rounded, tint: Tint.teal, onTap: () => open(Routes.aActivity)),
        ]),
        _Group('Build', [
          NavRow(label: 'Programs', icon: Icons.calendar_view_week_rounded, tint: Tint.green, onTap: () => open(context.rolePath(Routes.programs))),
          NavRow(label: 'Exercises', icon: Icons.fitness_center_rounded, tint: Tint.amber, onTap: () => open(context.rolePath(Routes.exercises))),
          NavRow(label: 'Nutrition & foods', icon: Icons.restaurant_rounded, tint: Tint.pink, onTap: () => open(context.rolePath(Routes.nutrition))),
          NavRow(label: 'Habits & supplements', icon: Icons.task_alt_rounded, tint: Tint.teal, onTap: () => open(context.rolePath(Routes.habits))),
          NavRow(label: 'Forms & check-ins', icon: Icons.assignment_outlined, tint: Tint.purple, onTap: () => open(Routes.aForms)),
          NavRow(label: 'Content library', icon: Icons.video_library_outlined, tint: Tint.blue, onTap: () => open(context.rolePath(Routes.content))),
        ]),
        _Group('Engage', [
          NavRow(label: 'Automations', icon: Icons.bolt_rounded, tint: Tint.amber, onTap: () => open(Routes.aAutomations)),
          NavRow(label: 'Emails & alerts', icon: Icons.mail_outline_rounded, tint: Tint.purple, onTap: () => open(Routes.aEmails)),
        ]),
        _Group('Workspace', [
          NavRow(label: 'Settings', icon: Icons.settings_outlined, tint: Tint.gray, onTap: () => open(Routes.aSettings)),
        ]),
        ListCard(
          children: [
            NavRow(
              label: 'Log out',
              icon: Icons.logout_rounded,
              destructive: true,
              onTap: () {
                ref.read(sessionProvider.notifier).signOut();
                context.go(Routes.welcome);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _MeCard extends StatelessWidget {
  const _MeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Avatar('V', size: 44, color: AvatarColor.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vimal', style: AppText.bodyBold.copyWith(fontSize: 15)),
                Text('Owner · Train With Vimal', style: AppText.caption.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.rows);
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Overline(title, padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6)),
        ListCard(children: rows),
      ],
    );
  }
}
