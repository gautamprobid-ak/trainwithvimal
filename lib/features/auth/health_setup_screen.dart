import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';
import 'package:train_with_vimal/data/state/session.dart';

import 'setup/setup_answers.dart';
import 'setup/setup_steps.dart';
import 'widgets/auth_widgets.dart';

enum _View { pending, onb, resume, done }

/// Designs: ClientHealth.dc.html (setup step 4, health & injuries) plus the
/// pending / setup / checklist / all-set views of ClientWelcome.dc.html.
///
/// The whole 5-step profile setup lives on this route:
///   /setup/health                 → step 4 (Health & injuries), steps 1–3 done
///   /setup/health?step=0          → start at step 1 (from verify email / login link)
///   /setup/health?view=pending    → waiting for coach approval
///   &approved=1                   → the coach already approved the account
/// Finish → "You're all set" → /permissions → /intro → home.
class HealthSetupScreen extends ConsumerStatefulWidget {
  const HealthSetupScreen({super.key});

  @override
  ConsumerState<HealthSetupScreen> createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends ConsumerState<HealthSetupScreen> {
  final _a = SetupAnswers();
  _View _view = _View.onb;
  int _step = 3;
  final Set<int> _dn = {};
  bool _approved = false;
  bool _fromDone = false;
  int _rem = 1;
  int _checks = 0;
  bool _notif = true;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final q = GoRouterState.of(context).uri.queryParameters;
    _approved = q['approved'] == '1';
    final step = int.tryParse(q['step'] ?? '');
    if (q['view'] == 'pending') {
      _view = _View.pending;
      _step = 0;
    } else if (step != null) {
      _step = step.clamp(0, 4);
    } else {
      // Straight to step 4, as in the ClientHealth design: goal, body and days done.
      _step = 3;
      _dn.addAll([0, 1, 2]);
      _a.goal = 0;
      _a.injuries = ['Knee'];
      _approved = true;
    }
  }

  void _toast(String t, String s, [ToastKind k = ToastKind.info]) => showToast(context, t, subtitle: s, kind: k);

  void _edit(void Function(SetupAnswers a) fn) => setState(() => fn(_a));

  int get _firstTodo {
    for (var i = 0; i < 5; i++) {
      if (!_dn.contains(i)) return i;
    }
    return -1;
  }

  void _goView(_View v, {int? step, bool fromDone = false}) => setState(() {
        _view = v;
        if (step != null) _step = step;
        _fromDone = fromDone;
      });

  void _approve() {
    setState(() => _approved = true);
    _toast('Aman approved your account', 'You can use the app now', ToastKind.star);
  }

  // ---------------- onboarding actions ----------------

  void _back() {
    if (_fromDone) return _goView(_View.done);
    if (_step == 0) return _goView(_View.pending);
    setState(() => _step--);
  }

  void _next() {
    final bad = _a.problem(_step);
    if (bad != null) {
      _toast(bad.$1, bad.$2, ToastKind.warn);
      return;
    }
    final title = AuthMock.steps[_step].title;
    setState(() => _dn.add(_step));
    if (_fromDone) {
      _goView(_View.done);
      _toast('$title saved', 'Aman sees the change right away', ToastKind.ok);
      return;
    }
    final nx = _firstTodo;
    if (nx < 0) {
      _goView(_View.done);
      _toast('Profile complete', 'Aman can now build your plan', ToastKind.star);
    } else {
      if (_step == 3) _toast('Health & injuries saved', 'Next: food preferences', ToastKind.ok);
      setState(() => _step = nx);
    }
  }

  Future<void> _later() async {
    var rem = _rem;
    final save = await showAppSheet<bool>(
      context,
      title: 'Finish setup later?',
      subtitle: 'Your answers so far are saved.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Spaced(
          gap: 10,
          children: [
            const QuestionHead('Remind me'),
            ChipWrap(
              items: [for (final (n, _) in AuthMock.reminders) n],
              isOn: (n) => n == AuthMock.reminders[rem].$1,
              onTap: (n) => setLocal(() => rem = AuthMock.reminders.indexWhere((r) => r.$1 == n)),
            ),
            const Caption('Aman can’t build your plan until setup is done. He can see that it is not finished yet.'),
          ],
        ),
      ),
      actions: (ctx) => [
        AppButton.outline('Keep going', onPressed: () => Navigator.of(ctx).pop(false)),
        AppButton('Save & leave', onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    );
    if (save != true || !mounted) return;
    setState(() {
      _rem = rem;
      if (_view == _View.onb && _a.problem(_step) == null) _dn.add(_step);
      _view = _View.resume;
      _fromDone = false;
    });
    _toast('Progress saved', rem == 3 ? 'No reminder set' : 'We will remind you ${AuthMock.reminders[rem].$2}', ToastKind.ok);
  }

  void _logOut() {
    final router = GoRouter.of(context);
    ref.read(sessionProvider.notifier).signOut();
    router.go(Routes.welcome);
    _toast('Logged out', 'Log in again any time with ${AuthMock.email}');
  }

  void _pendingGo() {
    if (_dn.length == 5) return _goView(_View.done);
    if (_firstTodo == 0 && _dn.isEmpty) return _goView(_View.onb, step: 0);
    _goView(_View.resume);
  }

  void _toggleNotif() {
    final was = _notif;
    setState(() => _notif = !was);
    if (was) {
      showToast(context, 'Notifications off',
          subtitle: 'You will still get an email', kind: ToastKind.info, onUndo: () => setState(() => _notif = true));
    } else {
      _toast('Notifications on', 'We will ping you as soon as you are approved', ToastKind.ok);
    }
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _View.pending => AuthLayout(footer: _pendingFooter(), children: _pendingBody()),
      _View.onb => AuthLayout(footer: _onbFooter(), children: _onbBody()),
      _View.resume => AuthLayout(footer: _resumeFooter(), children: _resumeBody()),
      _View.done => AuthLayout(footer: _doneFooter(), children: _doneBody()),
    };
  }

  List<FlowState> get _segs => [
        for (var i = 0; i < 5; i++)
          _dn.contains(i) ? FlowState.done : (_view == _View.onb && i == _step ? FlowState.current : FlowState.todo),
      ];

  // ---- pending approval ----

  List<Widget> _pendingBody() {
    final ok = _approved;
    final n = _dn.length;
    return [
      AuthTop(trailing: AuthLink('Need help?', onTap: () => showHelpSheet(context, AuthMock.welcomeHelp))),
      ResultBadge(ok ? BadgeKind.ok : BadgeKind.wait),
      AuthHeading(
        title: ok ? 'You’re approved, Riya!' : 'Almost there, Riya!',
        body: ok
            ? 'Aman approved your account. Finish your profile so he can build your plan.'
            : 'Your account is created. Coach Aman approves it next, usually within 24 hours.',
        center: true,
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardTitleRow('What happens next', trailing: Pill(ok ? 'Approved' : 'In review', tone: ok ? HintTone.green : HintTone.amber)),
            const SizedBox(height: 12),
            AuthTimeline([
              const TimelineEntry('Account created', '${AuthMock.email} · just now', FlowState.done),
              TimelineEntry(
                'Coach approval',
                ok ? 'Approved by Aman Verma · just now' : 'Aman Verma · usually within 24 hours',
                ok ? FlowState.done : FlowState.current,
              ),
              TimelineEntry(
                'Complete your profile',
                n == 5 ? 'All 5 steps done' : '$n of 5 steps done · goal, body, health, food',
                n == 5 ? FlowState.done : (ok ? FlowState.current : FlowState.todo),
              ),
            ]),
            if (!ok) ...[
              const SizedBox(height: 12),
              AppButton.outline(_checks > 0 ? 'Check again' : 'Check status', small: true, onPressed: () {
                if (_checks > 0) return _approve();
                setState(() => _checks = 1);
                _toast('Still in review', 'Checked just now · we will ping you when it is approved');
              }),
            ],
          ],
        ),
      ),
      if (!ok)
        CheckRow(
          boxed: true,
          on: _notif,
          onTap: _toggleNotif,
          title: 'Get the approval alert right away',
          subtitle: _notif ? 'Push notification and email' : 'You will still get an email',
        ),
    ];
  }

  List<Widget> _pendingFooter() => [
        AppButton(
          _dn.length == 5 ? 'See your profile' : (_approved ? 'Set up your profile' : 'Finish your profile meanwhile'),
          expand: true,
          onPressed: _pendingGo,
        ),
        AppButton.outline('Log out', icon: Icons.logout_rounded, expand: true, onPressed: _logOut),
      ];

  // ---- onboarding steps ----

  List<Widget> _onbBody() {
    final s = AuthMock.steps[_step];
    return [
      Row(
        children: [
          AppIconButton(Icons.arrow_back_rounded, small: true, onPressed: _back),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP ${_step + 1} OF 5',
                    style: AppText.overline.copyWith(fontSize: 11, letterSpacing: .9, color: AppColors.accentText)),
                Text(s.title, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          AuthLink('Finish later', onTap: _later),
        ],
      ),
      Transform.translate(offset: const Offset(0, -4), child: SegProgress(_segs)),
      ...setupStepBody(_step, _a, _edit),
    ];
  }

  List<Widget> _onbFooter() {
    final label = _fromDone
        ? 'Save changes'
        : _step == 4
            ? 'Finish'
            : 'Continue · ${AuthMock.steps[_step + 1].short}';
    final next = AppButton(label, expand: true, onPressed: _next);
    return [
      if (_step > 0 && !_fromDone) ButtonPair(firstWidth: 96, first: AppButton.outline('Back', expand: true, onPressed: _back), second: next) else next,
    ];
  }

  // ---- checklist (finish later) ----

  List<Widget> _resumeBody() {
    final ft = _firstTodo;
    return [
      AuthTop(onBack: () => _goView(_View.pending)),
      const AuthHeading(title: 'You’re almost there, Riya', body: 'Your coach can’t build your plan until these are done.'),
      AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardTitleRow('Your checklist', trailing: Pill('${_dn.length} of 5 done', tone: HintTone.blue)),
            const SizedBox(height: 10),
            SegProgress(_segs),
            const SizedBox(height: 6),
            for (var i = 0; i < 5; i++)
              MenuRow(
                first: i == 0,
                leading: _dn.contains(i) ? const MenuIcon(icon: Icons.check_rounded, ok: true) : MenuIcon(text: '${i + 1}'),
                title: AuthMock.steps[i].title,
                subtitle: AuthMock.steps[i].subtitle,
                trailing: Pill(
                  _dn.contains(i) ? 'Done' : (i == ft ? 'Next' : 'To do'),
                  tone: _dn.contains(i) ? HintTone.green : (i == ft ? HintTone.blue : null),
                ),
                onTap: () => _goView(_View.onb, step: i),
              ),
          ],
        ),
      ),
      Hint(
        _rem == 3 ? 'Reminders are off' : 'We will remind you ${AuthMock.reminders[_rem].$2}',
        icon: Icons.notifications_none_rounded,
        trailing: AuthLink('Change', onTap: _later),
      ),
    ];
  }

  List<Widget> _resumeFooter() {
    final ft = _firstTodo;
    return [
      AppButton(
        ft < 0 ? 'See your profile' : 'Continue · ${AuthMock.steps[ft].short}',
        expand: true,
        onPressed: () => ft < 0 ? _goView(_View.done) : _goView(_View.onb, step: ft),
      ),
    ];
  }

  // ---- all set ----

  List<Widget> _doneBody() {
    final rows = _a.summary;
    return [
      const ResultBadge(BadgeKind.big),
      const AuthHeading(title: 'You’re all set, Riya!', body: 'Aman has what he needs to build your plan.', center: true),
      if (_approved)
        const Hint('Aman approved your account · you can start now', tone: HintTone.green)
      else
        Hint(
          'Aman is still reviewing your account',
          tone: HintTone.amber,
          icon: Icons.schedule_rounded,
          trailing: AuthLink('Check status', onTap: _approve),
        ),
      AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardTitleRow('Your profile', trailing: Text('Tap a row to change it', style: AppText.caption)),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++)
              MenuRow(
                first: i == 0,
                labelFirst: true,
                subtitle: rows[i].$1,
                title: rows[i].$2,
                onTap: () => _goView(_View.onb, step: i, fromDone: true),
              ),
          ],
        ),
      ),
      AppCard(
        child: Row(
          children: [
            const Avatar('AV', color: AvatarColor.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coach Aman will guide you', style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Your first plan arrives within 24 hours. First check-in on day 7.',
                      style: AppText.caption.copyWith(fontSize: 12.5, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _doneFooter() => [
        Opacity(
          opacity: _approved ? 1 : .55,
          child: AppButton(
            'Continue',
            icon: Icons.arrow_forward_rounded,
            expand: true,
            onPressed: () => _approved
                ? context.go(Routes.permissions)
                : _toast('Waiting for Aman’s approval', 'Tap Check status, or we will ping you when it is done', ToastKind.warn),
          ),
        ),
      ];
}
