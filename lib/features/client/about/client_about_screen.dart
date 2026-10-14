import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';

import '../more/client_ui.dart';

/// Design: ClientAbout.dc.html — app, coach, contact and legal.
class ClientAboutScreen extends StatelessWidget {
  const ClientAboutScreen({super.key});

  static const _ver = '1.0.0 (1)';
  static const _phone = '+91 70874 03476';
  static const _email = 'trainwithvimal@gmail.com';

  static const _news = [
    ('Verify your email', 'New accounts confirm their email with a one-tap link.'),
    ('Reset your password', 'Forgot it? Get a link and set a new one in a minute.'),
    ('Health & injuries', 'Tell your coach about injuries and health conditions in setup.'),
    ('Smarter permissions', 'We explain notifications and camera before your phone asks.'),
  ];
  static const _terms = [
    ('Coaching, not medical care', 'Your coach gives training and food advice. See a doctor for medical problems.'),
    ('Your account', 'Keep your password safe. One account per person.'),
    ('Health waiver', 'You confirm you are fit to exercise and will tell your coach about any injury or pain.'),
    ('Leaving', 'You can delete your account any time from My account.'),
  ];
  static const _privacy = [
    ('What we keep', 'Only what coaching needs: workouts, meals, check-ins and progress.'),
    ('Progress photos', 'Private. Only you and your coach see them.'),
    ('Who sees your data', 'Your coach and the Train With Vimal team. We never sell it.'),
    ('Your control', 'Download or delete your data any time from Privacy & data.'),
  ];
  static const _licences = [
    ('Flutter', 'BSD-3-Clause · Google'),
    ('Riverpod', 'MIT · Remi Rousselet'),
    ('go_router', 'BSD-3-Clause · Flutter team'),
    ('freezed', 'MIT · Remi Rousselet'),
    ('shared_preferences', 'BSD-3-Clause · Flutter team'),
    ('Plus Jakarta Sans', 'SIL Open Font License'),
    ('unDraw illustrations', 'unDraw licence · Katerina Limpitsouni'),
  ];

  void _toast(BuildContext context, String t, String s, [ToastKind k = ToastKind.info]) => showToast(context, t, subtitle: s, kind: k);

  void _listSheet(BuildContext context, String title, String subtitle, List<(String, String)> rows, {bool primary = false}) {
    showClientSheet<void>(
      context,
      builder: (ctx) => ClientSheet(
        title: title,
        subtitle: subtitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (t, s) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(s, style: AppText.secondary),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          primary ? AppButton('Got it', onPressed: () => Navigator.of(ctx).pop()) : AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      children: [
        ClientTop(
          title: 'About',
          subtitle: 'Train With Vimal · Version $_ver',
          onBack: () => context.canPop() ? context.pop() : context.go(Routes.cMore),
        ),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Train With Vimal', style: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('Online coaching for weight gain and muscle gain', style: AppText.caption),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _toast(context, 'Version copied', 'Train With Vimal $_ver · paste it when you report a problem', ToastKind.ok),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Version $_ver', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, size: 13, color: AppColors.muted),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Avatar('V', size: 44, color: AvatarColor.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vimal', style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w800)),
                        Text('Head coach · Online', style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Vimal coaches people online to gain weight and build muscle, with plans that fit home food and a busy day.',
                  style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.text2)),
              const SizedBox(height: 12),
              const StatCells([('10+', 'Years coaching'), ('300+', 'Transformations'), ('17,000+', 'Followers')]),
            ],
          ),
        ),
        const Overline('Contact'),
        MenuList(children: [
          MenuRow(icon: Icons.chat_rounded, title: 'WhatsApp', subtitle: _phone, onTap: () => _toast(context, 'Opening WhatsApp', 'Chat with $_phone')),
          MenuRow(icon: Icons.call_rounded, title: 'Call', subtitle: _phone, onTap: () => _toast(context, 'Calling $_phone', 'Mon–Sat, 9 am – 9 pm')),
          MenuRow(icon: Icons.mail_rounded, title: 'Email', subtitle: _email, onTap: () => _toast(context, 'Email draft opened', 'To $_email')),
          MenuRow(icon: Icons.language_rounded, title: 'Website', subtitle: 'trainwithvimal.com', onTap: () => _toast(context, 'Opening trainwithvimal.com', 'In your browser')),
          const MenuRow(icon: Icons.schedule_rounded, title: 'Support hours', subtitle: 'Mon–Sat, 9 am – 9 pm', chevron: false),
        ]),
        const Overline('App'),
        MenuList(children: [
          MenuRow(
            icon: Icons.auto_awesome_rounded,
            title: 'What’s new',
            subtitle: 'Version $_ver · 12 Oct 2026',
            trailing: const Pill('New', tone: PillTone.blue),
            onTap: () => _listSheet(context, 'What’s new', 'Version $_ver · 12 Oct 2026', _news, primary: true),
          ),
          MenuRow(icon: Icons.star_rounded, title: 'Rate the app', subtitle: 'Tell others what you think', onTap: () => _toast(context, 'Opening the store', 'Rate Train With Vimal')),
          MenuRow(icon: Icons.description_rounded, title: 'Terms of use', onTap: () => _listSheet(context, 'Terms of use', 'Last updated · 1 Sep 2026', _terms)),
          MenuRow(icon: Icons.shield_rounded, title: 'Privacy policy', onTap: () => _listSheet(context, 'Privacy policy', 'Last updated · 1 Sep 2026', _privacy)),
          MenuRow(
            icon: Icons.code_rounded,
            title: 'Open-source licences',
            subtitle: 'Software that helps run this app',
            onTap: () => _listSheet(context, 'Open-source licences', 'Thank you to these projects', _licences),
          ),
        ]),
        Center(child: Text('© 2026 Train With Vimal · Made in India', style: AppText.caption)),
      ],
    );
  }
}
