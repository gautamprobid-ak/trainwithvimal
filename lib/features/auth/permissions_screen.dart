import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/auth_mock.dart';

import 'widgets/auth_widgets.dart';

enum _Result { ask, allowed, blocked }

/// Design: ClientPermissions.dc.html — we explain first, then the phone asks:
/// notifications → camera → photos. After the last one → /intro.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  int _pk = 0;
  final Map<String, _Result> _res = {};

  PermissionKind get _k => AuthMock.permissions[_pk];
  _Result get _r => _res[_k.key] ?? _Result.ask;
  bool get _last => _pk == AuthMock.permissions.length - 1;

  void _toast(String t, String s, [ToastKind k = ToastKind.info]) => showToast(context, t, subtitle: s, kind: k);

  Future<void> _allow() async {
    final yes = await _showSystemDialog(context, _k);
    if (!mounted || yes == null) return;
    setState(() => _res[_k.key] = yes ? _Result.allowed : _Result.blocked);
    if (yes) _toast('You are all set', 'You can change this in your phone settings', ToastKind.ok);
  }

  void _next({String? toastTitle, String? toastSub}) {
    if (_last) {
      context.go(Routes.intro);
      return;
    }
    setState(() => _pk++);
    if (toastTitle != null) _toast(toastTitle, toastSub ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(footer: _footer(), children: _body());
  }

  List<Widget> _body() {
    final k = _k;
    return [
      AuthTop(
        leading: GreyTag(k.when),
        trailing: AuthLink('Help', onTap: () => showHelpSheet(context, AuthMock.accountHelp)),
      ),
      ...switch (_r) {
        _Result.ask => [
            Illustration(k.icon, side: [k.perks[1].icon, k.perks[2].icon]),
            AuthHeading(title: k.title, body: k.body),
            _Perks(k.perks),
            const Caption('You can change this any time in your phone settings.', icon: Icons.lock_outline_rounded),
          ],
        _Result.allowed => [
            const ResultBadge(BadgeKind.ok),
            AuthHeading(title: 'You are all set', body: k.okBody, center: true),
          ],
        _Result.blocked => [
            const ResultBadge(BadgeKind.wait, icon: Icons.block_rounded),
            AuthHeading(title: 'Permission not given', body: k.noBody, center: true),
            _HowToCard(k),
          ],
      },
    ];
  }

  List<Widget> _footer() => switch (_r) {
        _Result.ask => [
            AppButton(_k.allowLabel, expand: true, onPressed: _allow),
            AppButton.outline('Not now', expand: true, onPressed: () => _next(
                  toastTitle: 'No problem',
                  toastSub: 'We will ask again when you need it',
                )),
          ],
        _Result.allowed => [
            AppButton(_last ? 'Done' : 'Continue', icon: Icons.arrow_forward_rounded, expand: true, onPressed: _next),
          ],
        _Result.blocked => [
            AppButton('Open settings', expand: true, onPressed: () => _toast('Opening settings', 'Settings › Apps › Train With Vimal')),
            AppButton.outline('Continue without it', expand: true, onPressed: _next),
          ],
      };
}

class _Perks extends StatelessWidget {
  const _Perks(this.perks);
  final List<PermPerk> perks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final p in perks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                TintIcon(p.icon, tint: p.tint),
                const SizedBox(width: 12),
                Expanded(child: Text(p.text, style: AppText.bodyBold.copyWith(height: 1.35))),
              ],
            ),
          ),
      ],
    );
  }
}

class _HowToCard extends StatelessWidget {
  const _HowToCard(this.k);
  final PermissionKind k;

  @override
  Widget build(BuildContext context) {
    final steps = ['Open your phone Settings', 'Tap Apps, then Train With Vimal', 'Turn on ${k.key}'];
    return AppCard(
      child: Spaced(
        gap: 10,
        children: [
          const CardTitleRow('To turn it on later'),
          for (var i = 0; i < steps.length; i++)
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                  child: Text('${i + 1}',
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentText)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(steps[i], style: AppText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600))),
              ],
            ),
        ],
      ),
    );
  }
}

/// The phone's own permission prompt (ac-sys). Returns true for Allow.
Future<bool?> _showSystemDialog(BuildContext context, PermissionKind k) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black45,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFFF3F4F9),
      insetPadding: const EdgeInsets.symmetric(horizontal: 39),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(k.icon, size: 28, color: AppColors.accent),
            const SizedBox(height: 14),
            Text(k.systemQuestion,
                textAlign: TextAlign.center, style: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _SysButton('Don’t allow', () => Navigator.of(ctx).pop(false))),
                const SizedBox(width: 8),
                Expanded(child: _SysButton('Allow', () => Navigator.of(ctx).pop(true), on: true)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SysButton extends StatelessWidget {
  const _SysButton(this.label, this.onTap, {this.on = false});
  final String label;
  final VoidCallback onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.accent : Colors.white,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          child: Text(label, style: AppText.bodyBold.copyWith(color: on ? Colors.white : AppColors.accentText)),
        ),
      ),
    );
  }
}
