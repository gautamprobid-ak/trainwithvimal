import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';
import 'package:train_with_vimal/data/state/session.dart';

import 'widgets/auth_widgets.dart';

enum _Stage { inbox, checking, ok, bad }

/// Design: ClientVerifyEmail.dc.html — check your inbox → email verified → setup.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  _Stage _stage = _Stage.inbox;
  String _email = AuthMock.email;
  bool _checking = false;
  int _left = 30;
  Timer? _timer;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _restartCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _delay?.cancel();
    super.dispose();
  }

  void _restartCountdown() {
    _timer?.cancel();
    _left = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  void _toast(String t, String s, [ToastKind k = ToastKind.info]) => showToast(context, t, subtitle: s, kind: k);

  void _check() {
    setState(() => _checking = true);
    _delay = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _checking = false);
      _toast('Not verified yet', 'Open the link in the email first', ToastKind.warn);
    });
  }

  void _resend() {
    if (_left > 0) {
      _toast('Wait $_left s', 'Then you can send the email again');
      return;
    }
    setState(_restartCountdown);
    _toast('Email sent again', _email);
  }

  void _openLink({required bool old}) {
    setState(() => _stage = _Stage.checking);
    _delay = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _stage = old ? _Stage.bad : _Stage.ok);
    });
  }

  void _logOut() {
    final router = GoRouter.of(context);
    ref.read(sessionProvider.notifier).signOut();
    router.go(Routes.welcome);
    _toast('Logged out', 'Log in again to finish verifying');
  }

  Future<void> _changeEmail() async {
    final picked = await showModalChangeEmail(context);
    if (picked == null || !mounted) return;
    setState(() {
      _email = picked;
      _stage = _Stage.inbox;
      _restartCountdown();
    });
    _toast('Email changed', 'A new link went to $picked', ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(children: _body(), footer: _footer());
  }

  List<Widget> _body() {
    switch (_stage) {
      case _Stage.inbox:
        return [
          AuthTop(
            onBack: _logOut,
            trailing: AuthLink('Help', onTap: () => showHelpSheet(context, AuthMock.accountHelp)),
          ),
          const Illustration(Icons.mark_email_read_rounded, side: [Icons.send_rounded, Icons.verified_rounded]),
          AuthHeading(
            title: 'Check your inbox',
            bodySpan: TextSpan(children: [
              const TextSpan(text: 'We sent a link to '),
              emSpan(_email),
              const TextSpan(text: '. Open it to confirm this is your email. Check spam if it is not there in a minute.'),
            ]),
          ),
          const Hint('The link works once, for 24 hours. Coach Aman sees your account after this.'),
        ];
      case _Stage.checking:
        return const [CheckingSpinner(title: 'Checking your link…', subtitle: 'This takes a second')];
      case _Stage.ok:
        return [
          const ResultBadge(BadgeKind.ok),
          AuthHeading(title: 'Email verified', body: 'Thanks, ${AuthMock.firstName}! $_email is confirmed.', center: true),
          NextCard(items: [
            TimelineEntry('Email verified', '$_email · just now', FlowState.done),
            const TimelineEntry('Set up your profile', 'Goal, body, training days, health, food', FlowState.current),
            const TimelineEntry('Turn on notifications', 'So you know the moment Aman approves you', FlowState.todo),
            const TimelineEntry('Coach approval', 'Aman Verma · usually within 24 hours', FlowState.todo),
          ]),
        ];
      case _Stage.bad:
        return const [
          ResultBadge(BadgeKind.wait, icon: Icons.link_off_rounded),
          AuthHeading(
            title: 'Link not valid',
            body: 'This link was already used or has expired. Links work once, for 24 hours. Send a new one.',
            center: true,
          ),
        ];
    }
  }

  List<Widget> _footer() {
    switch (_stage) {
      case _Stage.inbox:
        return [
          AppButton(_checking ? 'Checking…' : 'I’ve verified', expand: true, loading: _checking, onPressed: _check),
          Opacity(
            opacity: _left > 0 ? .6 : 1,
            child: AppButton.outline(
              _left > 0 ? 'Resend in $_left s' : 'Resend email',
              icon: Icons.refresh_rounded,
              expand: true,
              onPressed: _resend,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthLink('Change email', onTap: _changeEmail),
              const SizedBox(width: 22),
              AuthLink('Log out', muted: true, onTap: _logOut),
            ],
          ),
          DemoBox(children: [
            DemoLink('Open the link', onTap: () => _openLink(old: false)),
            DemoLink('Open an old link', onTap: () => _openLink(old: true)),
          ]),
        ];
      case _Stage.checking:
        return const [];
      case _Stage.ok:
        return [
          AppButton('Continue', icon: Icons.arrow_forward_rounded, expand: true, onPressed: () => context.go('${Routes.healthSetup}?step=0')),
        ];
      case _Stage.bad:
        return [
          AppButton('Back to verification', expand: true, onPressed: () => setState(() {
                _stage = _Stage.inbox;
                _restartCountdown();
              })),
        ];
    }
  }
}

/// "Change email" sheet. Tap the field to cycle demo values, or pick a suggestion.
/// Returns the new email when saved.
Future<String?> showModalChangeEmail(BuildContext context) {
  var index = 0;
  return showAppSheet<String>(
    context,
    title: 'Change email',
    subtitle: 'Typed it wrong? Fix it and we send a new link.',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final (value, err) = AuthMock.changeEmails[index];
        return Spaced(
          gap: 10,
          children: [
            FakeField(
              label: 'New email',
              value: value,
              error: err.isEmpty ? null : err,
              onTap: () => setLocal(() => index = (index + 1) % AuthMock.changeEmails.length),
            ),
            ChipWrap(
              small: true,
              items: [for (final (e, _) in AuthMock.changeEmails) e],
              isOn: (e) => e == value,
              onTap: (e) => setLocal(() => index = AuthMock.changeEmails.indexWhere((x) => x.$1 == e)),
            ),
            const Caption('The old link stops working.'),
          ],
        );
      },
    ),
    actions: (ctx) => [
      AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
      AppButton('Save and send link', onPressed: () {
        final (value, err) = AuthMock.changeEmails[index];
        if (err.isNotEmpty) {
          showToast(ctx, 'Fix the email first', subtitle: err, kind: ToastKind.warn);
          return;
        }
        Navigator.of(ctx).pop(value);
      }),
    ],
  );
}
