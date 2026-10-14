import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';

import '../dashboard/trainer_widgets.dart';
import 'me_sheets.dart';
import 'me_tabs.dart';

/// Design: TrainerMeMobile.dc.html — Aman's own profile.
class TrainerMeScreen extends StatefulWidget {
  const TrainerMeScreen({super.key});

  @override
  State<TrainerMeScreen> createState() => _TrainerMeScreenState();
}

class _TrainerMeScreenState extends State<TrainerMeScreen> {
  int _tab = 0;
  String? _asked;
  final Map<String, bool> _shown = {for (final r in TrainerMock.visibility) r.key: r.on};
  final Map<String, bool> _notif = {for (final n in TrainerMock.notifPrefs) n.key: n.on};
  final Set<String> _loggedOut = {};

  static const _tabs = ['Overview', 'Documents 6', 'What clients see', 'My access', 'My activity', 'Account'];

  int get _permTotal => TrainerMock.permissions.fold<int>(0, (a, g) => a + g.items.length);
  int get _permOn => TrainerMock.permissions.fold<int>(0, (a, g) => a + g.items.where((p) => p.on).length);

  Future<void> _ask() async {
    final id = await showAskAccess(context);
    if (id == null || !mounted) return;
    setState(() => _asked = id);
    showToast(context, 'Request sent to Vimal', subtitle: TrainerMock.accessAsks.firstWhere((a) => a.id == id).title, kind: ToastKind.ok);
  }

  Future<void> _password() async {
    final ok = await showChangePassword(context);
    if (ok == true && mounted) showToast(context, 'Password changed', subtitle: 'Other devices need the new password', kind: ToastKind.ok);
  }

  Widget _body() => switch (_tab) {
        0 => MeOverviewTab(
            accessLevel: 'Assigned clients',
            accessOn: _permOn,
            accessTotal: _permTotal,
            onDocs: () => setState(() => _tab = 1),
            onActivity: () => setState(() => _tab = 4),
          ),
        1 => const MeDocumentsTab(),
        2 => MeVisibilityTab(shown: _shown, onToggle: (k) => setState(() => _shown[k] = !_shown[k]!)),
        3 => MeAccessTab(asked: _asked, onAsk: _ask),
        4 => const MeActivityTab(),
        _ => MeAccountTab(
            devices: TrainerMock.devices.where((d) => !_loggedOut.contains(d.id)).toList(),
            notif: _notif,
            onPassword: _password,
            onNotif: (k) => setState(() => _notif[k] = !_notif[k]!),
            onLogOut: (d) {
              setState(() => _loggedOut.add(d.id));
              showToast(context, 'Logged out', subtitle: d.title, kind: ToastKind.ok);
            },
            onLogOutAll: () {
              setState(() => _loggedOut.addAll(['d2', 'd3']));
              showToast(context, 'Logged out of 2 devices', subtitle: 'Only this phone stays logged in', kind: ToastKind.ok);
            },
          ),
      };

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      children: [
        const SubPageHeader(title: 'My profile'),
        _Hero(onEdit: () => showEditMyDetails(context)),
        TrainerStatGrid(TrainerMock.meStats),
        UnderlineTabs(labels: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
        _body(),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final meta = AppText.caption.copyWith(fontSize: 12.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: Text('AV', style: AppText.bodyBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF166534))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Aman Verma', style: AppText.sectionTitle.copyWith(fontSize: 22)),
                      const AppBadge.status('Active', tone: BadgeTone.ok),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(style: meta, children: [
                      const TextSpan(text: 'Strength, fat loss · 6 years experience · Access '),
                      TextSpan(text: 'Assigned clients', style: meta.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
                      const TextSpan(text: ' · Last login today, 9:40 am'),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: AppButton.outline('Edit my details', icon: Icons.edit_outlined, small: true, onPressed: onEdit)),
      ],
    );
  }
}
