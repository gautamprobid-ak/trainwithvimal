import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';

import 'widgets/auth_widgets.dart';

/// Design: ClientWelcome.dc.html — first screen of the phone app.
/// Log in → /login, invite link → /join, help sheet.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      footerBorder: false,
      footer: [
        AppButton('Log in', expand: true, onPressed: () => context.go(Routes.login)),
        const SizedBox(height: 2),
        _InviteLine(onTap: () => context.go(Routes.join)),
        Center(
          child: AuthLink('Need help logging in?', small: false, onTap: () => showHelpSheet(
                context,
                AuthMock.welcomeHelp,
                caption: 'Most login problems are a pending approval or a missing invite. The gym team can check both.',
              )),
        ),
      ],
      children: const [
        BrandRow(),
        Illustration(Icons.sports_gymnastics_rounded, side: [Icons.restaurant_rounded, Icons.trending_up_rounded]),
        _WelcomeText(),
        _Pills(),
      ],
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your coach. Your plan. One app.', style: AppText.pageTitle.copyWith(fontSize: 26, height: 1.15)),
          const SizedBox(height: 6),
          Text(
            'Workouts, meals and check-ins in one place, made for you by your coach.',
            style: AppText.secondary.copyWith(fontSize: 14.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (icon, label) in AuthMock.welcomePills)
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(label, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
              ],
            ),
          ),
      ],
    );
  }
}

/// "New here? Open the invite link your coach sent you." — tapping opens the invite.
class _InviteLine extends StatelessWidget {
  const _InviteLine({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'New here? Open the invite link your coach sent you.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(fontSize: 12.5),
        ),
        AuthLink('I have an invite', onTap: onTap),
      ],
    );
  }
}
