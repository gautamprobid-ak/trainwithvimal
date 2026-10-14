import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';
import 'package:train_with_vimal/data/state/session.dart';

import 'widgets/auth_widgets.dart';

enum _View { inv, form, made, log, ready, bad }

/// Design: ClientJoinLink.dc.html — what opens from a coach's link.
///
/// Invite link: invite → create account → account created → /verify-email.
/// Login link (coach added you): set password → you're in → setup.
/// Broken links: expired, turned off, full, already used (demo cycles them).
class JoinLinkScreen extends ConsumerStatefulWidget {
  const JoinLinkScreen({super.key});

  @override
  ConsumerState<JoinLinkScreen> createState() => _JoinLinkScreenState();
}

class _JoinLinkScreenState extends ConsumerState<JoinLinkScreen> {
  _View _v = _View.inv;
  int _bk = 0;
  Map<String, String> _fv = {};
  bool _tried = false;
  bool _showPw = false;
  String _p1 = '';
  String _p2 = '';
  bool _agree = false;
  bool _busy = false;
  Timer? _delay;

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  void _toast(String t, String s, [ToastKind k = ToastKind.info]) => showToast(context, t, subtitle: s, kind: k);

  void _go(_View v, {bool reset = false}) => setState(() {
        _v = v;
        if (reset) {
          _fv = {};
          _p1 = '';
          _p2 = '';
          _agree = false;
          _tried = false;
          _showPw = false;
        }
      });

  // ---- form rules ----
  bool get _r8 => _p1.length >= 8;
  bool get _rMix => RegExp('[a-zA-Z]').hasMatch(_p1) && RegExp(r'\d').hasMatch(_p1);
  bool get _rSame => _p1.isNotEmpty && _p1 == _p2;
  bool get _emailBad => _fv['email'] == AuthMock.registerTypo;
  String get _first => (_fv['name'] ?? AuthMock.firstName).split(' ').first;
  String get _emailV => _fv['email'] ?? AuthMock.email;

  void _fill(String k) {
    final val = _fv[k] ?? '';
    final def = AuthMock.registerDefaults[k]!;
    setState(() => _fv = {..._fv, k: k == 'email' && val == def ? AuthMock.registerTypo : def});
  }

  String? _fieldError(String k) {
    final val = _fv[k] ?? '';
    final miss = _tried && (val.isEmpty || (k == 'email' && _emailBad));
    if (!miss) return null;
    return k == 'email' && _emailBad ? 'Check the email: did you mean riya.sharma@email.com?' : AuthMock.registerErrors[k];
  }

  void _create() {
    final regOk = (_fv['name'] ?? '').isNotEmpty &&
        (_fv['email'] ?? '').isNotEmpty &&
        !_emailBad &&
        (_fv['phone'] ?? '').isNotEmpty &&
        _r8 &&
        _rMix;
    if (!regOk) {
      setState(() => _tried = true);
      _toast('Fill in every field', 'Tap a field to type (demo)', ToastKind.warn);
      return;
    }
    if (!_agree) {
      setState(() => _tried = true);
      _toast('Please accept the terms first', 'Tick the checkbox, then continue', ToastKind.warn);
      return;
    }
    setState(() => _busy = true);
    _delay = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // New client account: signed in, setup still to do.
      ref.read(sessionProvider.notifier).signIn(DemoAccounts.client.copyWith(onboarded: false));
      setState(() {
        _busy = false;
        _tried = false;
        _v = _View.made;
      });
      _toast('Account created', 'Aman approves it next · usually within 24 hours', ToastKind.ok);
    });
  }

  void _setPassword() {
    if (!(_r8 && _rMix && _rSame)) {
      setState(() => _tried = true);
      _toast('Meet every rule below first', 'Tap a field to type (demo)', ToastKind.warn);
      return;
    }
    if (!_agree) {
      setState(() => _tried = true);
      _toast('Please accept the terms first', 'Tick the checkbox, then continue', ToastKind.warn);
      return;
    }
    setState(() => _busy = true);
    _delay = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      ref.read(sessionProvider.notifier).signIn(DemoAccounts.client.copyWith(onboarded: false));
      setState(() {
        _busy = false;
        _tried = false;
        _v = _View.ready;
      });
      _toast('Password set', 'You are logged in', ToastKind.ok);
    });
  }

  Future<void> _openTerms() async {
    final ok = await showTermsSheet(context, AuthMock.joinTerms, subtitle: 'The short version · last updated 1 Sep 2026');
    if (ok && mounted) setState(() => _agree = true);
  }

  void _openWrong() {
    showActionSheet(
      context,
      title: 'Details not right?',
      subtitle: 'Aman typed these in when he added you.',
      actions: [
        for (final o in AuthMock.wrongDetails)
          SheetAction(o.title, o.icon, () => _toast(o.toastTitle, o.toastSubtitle)),
      ],
    );
  }

  String get _url => switch (_v) {
        _View.log || _View.ready => AuthMock.loginUrl,
        _View.bad => AuthMock.badLinks[_bk].url,
        _ => AuthMock.inviteUrl,
      };

  @override
  Widget build(BuildContext context) {
    return AuthLayout(footer: _footer(), children: _body());
  }

  Widget _urlTop() => AuthTop(
        leading: GreyTag(_url, icon: Icons.link_rounded),
        trailing: AuthLink('Help', onTap: () => showHelpSheet(context, AuthMock.accountHelp)),
      );

  List<Widget> _body() => switch (_v) {
        _View.inv => [
            _urlTop(),
            const Illustration(Icons.person_add_alt_1_rounded, side: [Icons.fitness_center_rounded, Icons.restaurant_rounded]),
            const AuthHeading(
              kicker: 'You’re invited',
              title: 'Join Coach Aman at Train With Vimal',
              body: 'Aman sent you this link to start online coaching. Make your account, then he sets up your workouts and meals.',
            ),
            const _InviteCard(),
            const _HowItWorks(),
          ],
        _View.form => _formBody(),
        _View.made => [
            const ResultBadge(BadgeKind.ok),
            AuthHeading(
              title: 'Account created',
              body: 'Welcome, $_first! Two quick things and Aman can start on your plan.',
              center: true,
            ),
            NextCard(items: [
              TimelineEntry('Account created', '$_emailV · just now', FlowState.done),
              TimelineEntry('Confirm your email', 'We sent a link to $_emailV', FlowState.current),
              const TimelineEntry('Coach approval', 'Aman Verma · usually within 24 hours', FlowState.todo),
              const TimelineEntry('Get the app and set up your profile', '5 short steps while you wait', FlowState.todo),
            ]),
            _AppCard(line: 'Log in there with $_emailV after you confirm your email.', onToast: _toast),
          ],
        _View.log => _logBody(),
        _View.ready => [
            const Illustration(Icons.celebration_rounded, side: [Icons.check_rounded, Icons.star_rounded]),
            const AuthHeading(
              title: 'You’re in, Kavya',
              body: 'Your password is set. You log in with +91 98450 22118 or kavya.menon@email.com.',
              center: true,
            ),
            const NextCard(items: [
              TimelineEntry('Password set', 'Just now', FlowState.done),
              TimelineEntry('Get the app', 'Log in with your mobile number and this password', FlowState.current),
              TimelineEntry('Set up your profile', 'Goal, body, training days, health, food · about 3 minutes', FlowState.todo),
              TimelineEntry('Aman builds your plan', 'Workouts and meals start Mon, 12 Oct', FlowState.todo),
            ]),
            _AppCard(line: 'Log in with +91 98450 22118 and the password you just set.', onToast: _toast),
          ],
        _View.bad => [
            _urlTop(),
            Illustration(AuthMock.badLinks[_bk].secure ? Icons.lock_clock_rounded : Icons.timer_off_rounded,
                side: const [Icons.link_off_rounded, Icons.schedule_rounded]),
            AuthHeading(title: AuthMock.badLinks[_bk].title, body: AuthMock.badLinks[_bk].message, center: true),
            Hint(AuthMock.badLinks[_bk].hint, tone: HintTone.amber),
          ],
      };

  List<Widget> _formBody() {
    return [
      AuthTop(
        onBack: () => setState(() {
          _v = _View.inv;
          _tried = false;
        }),
        trailing: AuthLink('Help', onTap: () => showHelpSheet(context, AuthMock.accountHelp)),
      ),
      const AuthHeading(title: 'Create your account', body: 'Takes about a minute. Coach Aman approves it next.'),
      const _InviteChip(),
      for (final (k, label) in const [('name', 'Full name'), ('email', 'Email'), ('phone', 'Phone number')])
        FakeField(
          label: label,
          value: _fv[k] ?? AuthMock.registerPlaceholders[k]!,
          placeholder: (_fv[k] ?? '').isEmpty,
          onTap: () => _fill(k),
          error: _fieldError(k),
        ),
      ..._passwordFields(confirm: false),
      TermsCheck(on: _agree, onToggle: () => setState(() => _agree = !_agree), onOpenTerms: _openTerms),
      const Caption('Tap a field to type (demo).'),
    ];
  }

  List<Widget> _logBody() {
    return [
      _urlTop(),
      Row(
        children: [
          const Avatar('KM', size: 52, color: AvatarColor.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR COACH ADDED YOU', style: AppText.overline.copyWith(fontSize: 11, color: AppColors.accentText)),
                const SizedBox(height: 4),
                Text('Hi Kavya, set your password', style: AppText.heroTitle.copyWith(height: 1.2)),
              ],
            ),
          ),
        ],
      ),
      Text(
        'Aman Verma made your Train With Vimal account. Pick a password and you are in. No approval needed.',
        style: AppText.secondary.copyWith(fontSize: 13.5, height: 1.45),
      ),
      AppCard(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < AuthMock.addedAccount.length; i++) KvRow(AuthMock.addedAccount[i], first: i == 0),
            AuthLink('These are not my details', onTap: _openWrong),
          ],
        ),
      ),
      ..._passwordFields(confirm: true),
      TermsCheck(on: _agree, onToggle: () => setState(() => _agree = !_agree), onOpenTerms: _openTerms),
      const Caption('Tap a field to type (demo).'),
    ];
  }

  List<Widget> _passwordFields({required bool confirm}) {
    final toggle = _showPw ? 'Hide' : 'Show';
    String dots(String s) => _showPw ? s : '•' * s.length;
    void flip() => setState(() => _showPw = !_showPw);
    return [
      FakeField(
        label: confirm ? 'New password' : 'Password',
        value: _p1.isEmpty ? 'At least 8 characters' : dots(_p1),
        placeholder: _p1.isEmpty,
        bad: _tried && !(_r8 && _rMix),
        onTap: () => setState(() => _p1 = AuthMock.demoP1[(AuthMock.demoP1.indexOf(_p1) + 1) % 3]),
        toggleLabel: toggle,
        onToggle: flip,
      ),
      Transform.translate(offset: const Offset(0, -6), child: StrengthMeter(_p1)),
      if (confirm)
        FakeField(
          label: 'Confirm password',
          value: _p2.isEmpty ? 'Type it again' : dots(_p2),
          placeholder: _p2.isEmpty,
          bad: _tried && !_rSame,
          onTap: () => setState(() => _p2 = AuthMock.demoP2[(AuthMock.demoP2.indexOf(_p2) + 1) % 3]),
          toggleLabel: toggle,
          onToggle: flip,
        ),
      PasswordRules([
        ('At least 8 characters', _r8),
        ('Letters and numbers', _rMix),
        if (confirm) ('Both passwords match', _rSame),
      ], tried: _tried),
    ];
  }

  Widget _demo() => DemoBox(children: [
        DemoLink('Invite link', onTap: () => _go(_View.inv, reset: true)),
        DemoLink('Login link', onTap: () => _go(_View.log, reset: true)),
        DemoLink(_v == _View.bad ? 'Next broken link' : 'Broken link', onTap: () => setState(() {
              _bk = _v == _View.bad ? (_bk + 1) % AuthMock.badLinks.length : 0;
              _v = _View.bad;
            })),
      ]);

  List<Widget> _footer() => switch (_v) {
        _View.inv => [
            AppButton('Create my account', icon: Icons.arrow_forward_rounded, expand: true, onPressed: () => _go(_View.form)),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Already have an account?', style: AppText.secondary),
                const SizedBox(width: 5),
                AuthLink('Log in', onTap: () => context.go(Routes.login)),
              ],
            ),
            _demo(),
          ],
        _View.form => [
            AppButton(_busy ? 'Creating your account…' : 'Create account', expand: true, loading: _busy, onPressed: _create),
          ],
        _View.made => [
            AppButton('Confirm my email', icon: Icons.arrow_forward_rounded, expand: true, onPressed: () => context.go(Routes.verifyEmail)),
            _demo(),
          ],
        _View.log => [
            AppButton(_busy ? 'Saving…' : 'Set password and continue', expand: true, loading: _busy, onPressed: _setPassword),
            _demo(),
          ],
        _View.ready => [
            AppButton('Get the app', icon: Icons.download_rounded, expand: true, onPressed: () => _toast(
                'Opening the store', 'Search “Train With Vimal” on Google Play or the App Store')),
            Center(
              child: AuthLink('Set up my profile on the web instead',
                  onTap: () => context.go('${Routes.healthSetup}?step=0&approved=1')),
            ),
            _demo(),
          ],
        _View.bad => [
            AppButton(AuthMock.badLinks[_bk].goLabel, icon: Icons.chat_rounded, expand: true, onPressed: () => _toast(
                'Opening WhatsApp', 'Message to Aman Verma · +91 98111 20456')),
            AppButton.outline(AuthMock.badLinks[_bk].loginLabel, expand: true, onPressed: () => context.go(Routes.login)),
            _demo(),
          ],
      };
}

class _InviteCard extends StatelessWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Avatar('AV', color: AvatarColor.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aman Verma', style: AppText.bodyBold.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Trainer at Train With Vimal', style: AppText.caption.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
              const Pill('Link works', tone: HintTone.green, icon: Icons.check_rounded),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < AuthMock.invite.length; i++) KvRow(AuthMock.invite[i], first: i == 0),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
      child: Spaced(
        gap: 8,
        children: [
          Text('How it works', style: AppText.secondary.copyWith(fontWeight: FontWeight.w800, color: AppColors.text)),
          for (var i = 0; i < AuthMock.inviteHow.length; i++)
            Row(
              children: [
                _NumDot(i + 1),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(AuthMock.inviteHow[i],
                      style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NumDot extends StatelessWidget {
  const _NumDot(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
      child: Text('$n', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.accentText)),
    );
  }
}

class _InviteChip extends StatelessWidget {
  const _InviteChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Avatar('AV', size: 32, color: AvatarColor.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite from Coach Aman', style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
                Text('Code AMAN-4821 · filled in from your link', style: AppText.caption),
              ],
            ),
          ),
          const Icon(Icons.check_rounded, size: 18, color: AppColors.okText),
        ],
      ),
    );
  }
}

/// "Get the app" card with store buttons (jl-app).
class _AppCard extends StatelessWidget {
  const _AppCard({required this.line, required this.onToast});
  final String line;
  final void Function(String, String, [ToastKind]) onToast;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.smartphone_rounded, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Get the app', style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800)),
                    Text(line, style: AppText.caption.copyWith(fontSize: 12.5, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ButtonPair(
            first: AppButton.outline('Google Play', small: true, onPressed: () => onToast('Opening Google Play', 'Train With Vimal · free')),
            second: AppButton.outline('App Store', small: true, onPressed: () => onToast('Opening the App Store', 'Train With Vimal · free')),
          ),
        ],
      ),
    );
  }
}
