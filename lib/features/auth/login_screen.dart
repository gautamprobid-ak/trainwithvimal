import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';
import 'package:train_with_vimal/data/state/session.dart';

import 'widgets/auth_widgets.dart';

/// Design: ClientLogin.dc.html — log in.
///
/// The password field starts with a typo (demo): Log in shows the error, tapping the
/// field types it again correctly. "Demo · after log in" picks where a client lands:
/// waiting for approval, setup not done, or home. The role row signs straight in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: AuthMock.email);
  bool _pwOk = false;
  bool _showPw = false;
  bool _err = false;
  bool _keep = true;
  int _after = 2;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String get _pw => _showPw ? (_pwOk ? 'Riya@2026' : 'riya2026') : (_pwOk ? '•••••••••' : '••••••••');

  void _retype() {
    if (_pwOk) {
      setState(() {
        _pwOk = false;
        _err = false;
      });
      return;
    }
    final wasErr = _err;
    setState(() {
      _pwOk = true;
      _err = false;
    });
    if (wasErr) showToast(context, 'Password typed again', subtitle: 'Tap Log in to continue', kind: ToastKind.info);
  }

  void _login() {
    if (!_pwOk) {
      setState(() => _err = true);
      showToast(context, 'Wrong password', subtitle: '4 tries left before a 15 minute lock', kind: ToastKind.warn);
      return;
    }
    final account = DemoAccounts.forEmail(_email.text);
    final router = GoRouter.of(context);
    final session = ref.read(sessionProvider.notifier);
    final first = account.name.split(' ').first;
    if (account.role == Role.client && _after < 2) {
      // Client who joined from an invite (pending) or was added by the coach (setup to do).
      session.signIn(account.copyWith(onboarded: false));
      router.go(_after == 0 ? '${Routes.healthSetup}?view=pending' : '${Routes.healthSetup}?step=0&approved=1');
    } else {
      session.signInWithEmail(_email.text);
      router.go(homeFor(account.role));
    }
    showToast(context, 'Logged in', subtitle: 'Welcome back, $first', kind: ToastKind.ok);
  }

  void _demoSignIn(Session s) {
    final router = GoRouter.of(context);
    _email.text = s.email;
    ref.read(sessionProvider.notifier).signIn(s);
    router.go(homeFor(s.role));
    showToast(context, 'Logged in', subtitle: 'Welcome back, ${s.name.split(' ').first}', kind: ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      children: [
        AuthTop(
          onBack: () => context.go(Routes.welcome),
          trailing: AuthLink('Help', onTap: () => showHelpSheet(
                context,
                AuthMock.welcomeHelp,
                caption: 'Most login problems are a pending approval or a missing invite. The gym team can check both.',
              )),
        ),
        const _Heading(),
        AuthInput(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
        FakeField(
          label: 'Password',
          value: _pw,
          bad: _err,
          error: _err ? 'Wrong password. Tap the field to type it again, or reset it.' : null,
          onTap: _retype,
          toggleLabel: _showPw ? 'Hide' : 'Show',
          onToggle: () => setState(() => _showPw = !_showPw),
        ),
        Row(
          children: [
            Expanded(
              child: CheckRow(on: _keep, onTap: () => setState(() => _keep = !_keep), title: 'Keep me logged in'),
            ),
            AuthLink('Forgot password?', onTap: () => context.push(Routes.resetPassword)),
          ],
        ),
        const SizedBox(height: 2),
        AppButton('Log in', expand: true, onPressed: _login),
        _NewHere(onTap: () => context.go(Routes.join)),
        DemoBox(
          label: 'Demo · after log in',
          children: [
            for (var i = 0; i < AuthMock.afterLogin.length; i++)
              DemoLink(AuthMock.afterLogin[i], selected: i == _after, onTap: () => setState(() => _after = i)),
          ],
        ),
        _RoleRow(onPick: _demoSignIn),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLogo(size: 56),
        SizedBox(height: 10),
        AuthHeading(title: 'Log in', body: 'Welcome back to Train With Vimal.'),
      ],
    );
  }
}

class _NewHere extends StatelessWidget {
  const _NewHere({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Text(
            'New here? Open the invite link your coach sent you.',
            textAlign: TextAlign.center,
            style: AppText.secondary,
          ),
        ),
      ),
    );
  }
}

/// Subtle quick sign-in for the demo accounts.
class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.onPick});
  final ValueChanged<Session> onPick;

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption.copyWith(fontSize: 12, color: AppColors.muted);
    Widget link(String label, Session s) => InkWell(
          onTap: () => onPick(s),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Text(label, style: style.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Demo: ', style: style),
        link('Client', DemoAccounts.client),
        Text(' · ', style: style),
        link('Trainer', DemoAccounts.trainer),
        Text(' · ', style: style),
        link('Admin', DemoAccounts.admin),
      ],
    );
  }
}
