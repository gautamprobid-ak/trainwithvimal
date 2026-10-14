import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/state/session.dart';

/// Design: TrainerMoreMobile.dc.html — profile, library and log out.
class TrainerMoreScreen extends ConsumerWidget {
  const TrainerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void lib(String path) => context.push(context.rolePath(path));
    return PageScroll(
      children: [
        const PageHeader(title: 'More'),
        const _MeCard(),
        const Overline('Library'),
        ListCard(children: [
          NavRow(label: 'Programs', icon: Icons.event_note_rounded, tint: Tint.green, onTap: () => lib(Routes.programs)),
          NavRow(label: 'Exercises', icon: Icons.fitness_center_rounded, tint: Tint.amber, onTap: () => lib(Routes.exercises)),
          NavRow(label: 'Nutrition & foods', icon: Icons.restaurant_rounded, tint: Tint.pink, onTap: () => lib(Routes.nutrition)),
          NavRow(label: 'Habits & supplements', icon: Icons.medication_rounded, tint: Tint.teal, onTap: () => lib(Routes.habits)),
          NavRow(label: 'Content library', icon: Icons.video_library_rounded, tint: Tint.blue, onTap: () => lib(Routes.content)),
        ]),
        ListCard(children: [
          NavRow(
            label: 'Log out',
            icon: Icons.logout_rounded,
            destructive: true,
            onTap: () {
              ref.read(sessionProvider.notifier).signOut();
              context.go(Routes.welcome);
            },
          ),
        ]),
      ],
    );
  }
}

class _MeCard extends StatelessWidget {
  const _MeCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(Routes.tMe),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4FB8EE), Color(0xFF2563EB)]),
              boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 3), BoxShadow(color: Color(0xFFCFE3FA), spreadRadius: 4)],
            ),
            child: Text('AV', style: AppText.bodyBold.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aman Verma', style: AppText.cardTitle),
                Text('Trainer · My profile', style: AppText.caption.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
