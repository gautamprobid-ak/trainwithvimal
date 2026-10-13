import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';

import 'widgets/auth_widgets.dart';

enum _Stage { forgot, sent, set, done, bad }

/// Design: ClientResetPassword.dc.html — forgot password → check email → set new → done.
/// "Open the link" / "Open an old link" in the demo box move through the flow.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  _Stage _stage = _Stage.forgot;
  bool _emailBad = false;
  bool _emailTried = false;
  String _p1 = '';
  String _p2 = '';
  bool _showPw = false;
  bool _tried = false;
  int _left = 30;
  Timer? _timer;

  String get _email => _emailBad ? 'riya.sharma@emal.com' : AuthMock.email;

  @override
  void dispose() {
    _timer?.cancel();
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

  void _toLogin() => context.go(Routes.login);

  void _send() {
    if (_emailBad) {
      setState(() => _emailTried = true);
      _toast('No account with this email', 'Tap the field to fix the typo', ToastKind.warn);
      return;
    }
    setState(() {
      _stage = _Stage.sent;
      _restartCountdown();
    });
    _toast('Check your email', 'Reset link sent · valid for 15 minutes', ToastKind.ok);
  }

  void _resend() {
    if (_left > 0) {
      _toast('Wait $_left s', 'Then you can send the email again');
      return;
    }
    setState(_restartCountdown);
    _toast('Email sent again', AuthMock.email);
  }

  void _toForgot() => setState(() {
        _stage = _Stage.forgot;
        _emailTried = false;
      });

  bool get _r8 => _p1.length >= 8;
  bool get _rMix => RegExp('[a-zA-Z]').hasMatch(_p1) && RegExp(r'\d').hasMatch(_p1);
  bool get _rSame => _p1.isNotEmpty && _p1 == _p2;

  void _save() {
    if (_r8 && _rMix && _rSame) {
      setState(() => _stage = _Stage.done);
      _toast('Password updated', 'Log in with your new password', ToastKind.ok);
    } else {
      setState(() => _tried = true);
      _toast('Meet every rule below first', 'Tap a field to type (demo)', ToastKind.warn);
    }
  }

  String _dots(String s) => _showPw ? s : '•' * s.length;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(children: _body(), footer: _footer());
  }

  Widget _helpLink() => AuthLink('Help', onTap: () => showHelpSheet(context, AuthMock.accountHelp));

  List<Widget> _body() {
    switch (_stage) {
      case _Stage.forgot:
        return [
          AuthTop(onBack: _toLogin, trailing: _helpLink()),
          const Illustration(Icons.lock_reset_rounded, side: [Icons.mail_rounded, Icons.key_rounded]),
          const AuthHeading(
            title: 'Forgot your password?',
            body: 'Enter the email you joined with. We will send you a link to set a new one.',
          ),
          FakeField(
            label: 'Email',
            value: _email,
            onTap: () => setState(() {
              _emailBad = !_emailBad;
              _emailTried = false;
            }),
            error: _emailBad && _emailTried ? 'No account uses this email. Check for a typo.' : null,
          ),
        ];
      case _Stage.sent:
        return [
          AuthTop(onBack: _toForgot, trailing: _helpLink()),
          const Illustration(Icons.mark_email_unread_rounded, side: [Icons.lock_rounded, Icons.schedule_rounded]),
          AuthHeading(
            title: 'Check your email',
            bodySpan: TextSpan(children: [
              const TextSpan(text: 'We sent a reset link to '),
              emSpan(_email),
              const TextSpan(text: '. It works once, for 15 minutes.'),
            ]),
          ),
          const Hint('Not there? Check spam, or make sure this is the email you joined with.'),
        ];
      case _Stage.set:
        return [
          const SizedBox(height: 4),
          const Illustration(Icons.verified_user_rounded, side: [Icons.key_rounded, Icons.check_rounded]),
          AuthHeading(title: 'Set a new password', body: 'For $_email. Pick one you do not use anywhere else.'),
          ..._passwordForm(),
        ];
      case _Stage.done:
        return const [
          ResultBadge(BadgeKind.ok),
          AuthHeading(
            title: 'Password updated',
            body: 'Log in with your new password. For your safety we logged you out on your other devices.',
            center: true,
          ),
        ];
      case _Stage.bad:
        return const [
          ResultBadge(BadgeKind.wait, icon: Icons.link_off_rounded),
          AuthHeading(
            title: 'Link not valid',
            body: 'This link has expired or was already used. Links work once, for 15 minutes.',
            center: true,
          ),
        ];
    }
  }

  List<Widget> _passwordForm() {
    final toggle = _showPw ? 'Hide' : 'Show';
    void flip() => setState(() => _showPw = !_showPw);
    return [
      FakeField(
        label: 'New password',
        value: _p1.isEmpty ? 'At least 8 characters' : _dots(_p1),
        placeholder: _p1.isEmpty,
        onTap: () => setState(() => _p1 = AuthMock.demoP1[(AuthMock.demoP1.indexOf(_p1) + 1) % 3]),
        toggleLabel: toggle,
        onToggle: flip,
      ),
      Transform.translate(offset: const Offset(0, -6), child: StrengthMeter(_p1)),
      FakeField(
        label: 'Confirm new password',
        value: _p2.isEmpty ? 'Type it again' : _dots(_p2),
        placeholder: _p2.isEmpty,
        onTap: () => setState(() => _p2 = AuthMock.demoP2[(AuthMock.demoP2.indexOf(_p2) + 1) % 3]),
        toggleLabel: toggle,
        onToggle: flip,
      ),
      PasswordRules(
        [('At least 8 characters', _r8), ('Letters and numbers', _rMix), ('Both passwords match', _rSame)],
        tried: _tried,
      ),
      const Caption('Tap a field to type (demo).'),
    ];
  }

  List<Widget> _footer() {
    switch (_stage) {
      case _Stage.forgot:
        return [
          AppButton('Send reset link', expand: true, onPressed: _send),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Remembered it?', style: AppText.secondary),
              const SizedBox(width: 5),
              AuthLink('Log in', onTap: _toLogin),
            ],
          ),
        ];
      case _Stage.sent:
        return [
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
              AuthLink('Use a different email', onTap: _toForgot),
              const SizedBox(width: 22),
              AuthLink('Back to log in', muted: true, onTap: _toLogin),
            ],
          ),
          DemoBox(children: [
            DemoLink('Open the link', onTap: () => setState(() {
                  _stage = _Stage.set;
                  _p1 = '';
                  _p2 = '';
                  _tried = false;
                })),
            DemoLink('Open an old link', onTap: () => setState(() => _stage = _Stage.bad)),
          ]),
        ];
      case _Stage.set:
        return [AppButton('Save new password', expand: true, onPressed: _save)];
      case _Stage.done:
        return [AppButton('Back to log in', expand: true, onPressed: _toLogin)];
      case _Stage.bad:
        return [
          AppButton('Send a new link', expand: true, onPressed: _toForgot),
          Center(child: AuthLink('Back to log in', onTap: _toLogin)),
        ];
    }
  }
}
