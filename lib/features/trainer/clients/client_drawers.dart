import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';

/// "Add a client" drawer (trainer-scoped: trainer is Aman).
Future<void> showAddClientDrawer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _AddClient(),
  );
}

class _AddClient extends StatefulWidget {
  const _AddClient();
  @override
  State<_AddClient> createState() => _AddClientState();
}

class _AddClientState extends State<_AddClient> {
  int _mode = 0;
  bool _sendLink = true;
  bool _parq = true;
  final _name = TextEditingController(text: 'Kavya Menon');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btn = _mode == 0 ? 'Add client' : 'Add and send to Approvals';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DrawerHead(icon: Icons.person_add_alt_rounded, title: 'Add a client', sub: 'For someone you already know. Link sign-ups go to Approvals.'),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetSection(title: 'Must have', help: 'She logs in with this mobile number. We check it is not already used.', children: [
                    LabeledField(label: 'Full name *', controller: _name),
                    const LabeledField(label: 'Mobile *', prefix: '+91', initialValue: '98450 22118', keyboardType: TextInputType.phone),
                    Row(children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.okText),
                      const SizedBox(width: 5),
                      Text('No client or sign-up with this number', style: AppText.caption.copyWith(color: AppColors.okText, fontWeight: FontWeight.w600)),
                    ]),
                  ]),
                  const SheetSection(title: 'Good to have', help: 'She can fill or change these herself in the app.', children: [
                    LabeledField(label: 'Email', hint: 'For login links and receipts', keyboardType: TextInputType.emailAddress),
                    LabeledField(label: 'Gender', initialValue: 'Female'),
                    LabeledField(label: 'Date of birth', hint: 'DD / MM / YYYY'),
                    LabeledField(label: 'City', initialValue: 'Bengaluru'),
                  ]),
                  const SheetSection(title: 'Goal and body', help: 'Optional. If you leave these empty she fills them in onboarding.', children: [
                    LabeledField(label: 'Goal', initialValue: 'Lose fat'),
                    LabeledField(label: 'Goal weight', initialValue: '62 kg'),
                    LabeledField(label: 'Height', initialValue: '160 cm'),
                    LabeledField(label: 'Current weight', initialValue: '68 kg'),
                    LabeledField(label: 'Injuries or health notes', hint: 'Back pain, thyroid, recent surgery…'),
                  ]),
                  SheetSection(title: 'Coaching', help: 'Optional. Check-in forms are sent later from her profile, under Forms.', children: [
                    const SelectField(label: 'Trainer', value: 'Aman Verma · 24 / 30', hint: 'You can change this later'),
                    SelectField(label: 'Workout program', value: 'Pick later', placeholder: true, onTap: () => _pick('Workout program', ['Pick later', 'Fat Loss Phase 1', 'Strength Base', 'Beginner Full Body'])),
                    SelectField(label: 'Meal plan', value: 'Pick later', placeholder: true, onTap: () => _pick('Meal plan', ['Pick later', '1,500 kcal veg', '1,700 kcal high protein'])),
                    const LabeledField(label: 'Plans start on', initialValue: 'Mon, 12 Oct', help: 'Her day 1 for workout and meal plans'),
                  ]),
                  SheetSection(title: 'Access', children: [
                    PillTabs(labels: const ['Active now', 'Send to Approvals'], index: _mode, onChanged: (i) => setState(() => _mode = i)),
                    Text(
                      _mode == 0 ? 'She can log in as soon as she opens the link.' : 'She shows up in Approvals first, like people who sign up with a link.',
                      style: AppText.caption,
                    ),
                    ToggleRow(title: 'Send her the login link', subtitle: 'WhatsApp and email. She sets her own password.', value: _sendLink, onChanged: (v) => setState(() => _sendLink = v)),
                    ToggleRow(title: 'Ask her to fill the health form (PAR-Q)', subtitle: 'Shown on her first login', value: _parq, onChanged: (v) => setState(() => _parq = v)),
                  ]),
                ],
              ),
            ),
          ),
          _DrawerFoot(
            note: 'Only name and mobile are needed',
            primary: btn,
            onPrimary: () {
              final name = _name.text.trim().isEmpty ? 'Kavya Menon' : _name.text.trim();
              Navigator.of(context).pop();
              showToast(context, _mode == 0 ? 'Client added' : 'Client sent to Approvals',
                  subtitle: _mode == 0 ? '$name · ${_sendLink ? 'login link sent' : 'no link sent'}' : '$name waits for approval', kind: ToastKind.ok);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pick(String title, List<String> opts) async {
    final v = await pickOption(context, title: title, options: opts, current: opts.first);
    if (v != null && v != opts.first && mounted) showToast(context, '$title picked', subtitle: v);
  }
}

class _DrawerHead extends StatelessWidget {
  const _DrawerHead({required this.icon, required this.title, required this.sub});
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        TintIcon(icon, tint: Tint.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(sub, style: AppText.secondary.copyWith(fontSize: 12.5)),
          ]),
        ),
        AppIconButton(Icons.close_rounded, small: true, tooltip: 'Close', onPressed: () => Navigator.of(context).pop()),
      ]),
    );
  }
}

class _DrawerFoot extends StatelessWidget {
  const _DrawerFoot({required this.note, required this.primary, required this.onPrimary, this.cancel = 'Cancel', this.onCancel});
  final String note;
  final String primary;
  final VoidCallback onPrimary;
  final String cancel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (note.isNotEmpty) ...[Text(note, style: AppText.caption), const SizedBox(height: 8)],
        Row(children: [
          if (cancel.isNotEmpty) ...[
            Expanded(child: AppButton.outline(cancel, onPressed: onCancel ?? () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
          ],
          Expanded(child: AppButton(primary, icon: Icons.check_rounded, onPressed: onPrimary)),
        ]),
      ]),
    );
  }
}

/// "Invite links" drawer with tabs Invite link · New link · All links.
Future<void> showInviteLinks(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _InviteLinks(),
  );
}

class _InviteLinks extends StatefulWidget {
  const _InviteLinks();
  @override
  State<_InviteLinks> createState() => _InviteLinksState();
}

class _InviteLinksState extends State<_InviteLinks> {
  List<InviteLink> _links = [...TrainerMock.inviteLinks];
  String _code = TrainerMock.inviteLinks.first.code;
  int _tab = 0;
  final Map<String, bool> _approvals = {};

  static const _subs = [
    'Share it on WhatsApp or Instagram. People sign up and fill their own details.',
    'For a new trainer or a campaign. The old links keep working.',
    'Every link your team made. Open one to share it again or turn it off.',
  ];

  InviteLink get _cur => _links.firstWhere((l) => l.code == _code, orElse: () => _links.first);
  int get _onCount => _links.where((l) => l.status == LinkStatus.on).length;
  String get _sumT => '$_onCount of ${_links.length} links are on';

  void _done(String t, [String? s]) => showToast(context, t, subtitle: s, kind: ToastKind.ok);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DrawerHead(icon: Icons.link_rounded, title: 'Invite links', sub: _subs[_tab]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: PillTabs(labels: ['Invite link', 'New link', 'All links ${_links.length}'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: switch (_tab) { 0 => _main(), 1 => _new(), _ => _all() },
          ),
        ),
        switch (_tab) {
          1 => _DrawerFoot(
              note: 'The old links keep working',
              primary: 'Create link',
              onCancel: () => setState(() => _tab = 0),
              onPrimary: () => setState(() {
                if (!_links.any((l) => l.code == TrainerMock.newInviteLink.code)) _links = [TrainerMock.newInviteLink, ..._links];
                _code = TrainerMock.newInviteLink.code;
                _tab = 0;
                _done('Link created', 'trainwithvimal.app/join/${TrainerMock.newInviteLink.code}');
              }),
            ),
          _ => _DrawerFoot(note: _sumT, primary: 'Done', cancel: '', onPrimary: () => Navigator.of(context).pop()),
        },
      ],
    );
  }

  Widget _main() {
    if (_links.isEmpty) {
      return EmptyState(
        icon: Icons.link_off_rounded,
        title: 'No links',
        message: 'Make a new link to invite people.',
        action: AppButton('New link', small: true, onPressed: () => setState(() => _tab = 1)),
      );
    }
    final l = _cur;
    final appr = _approvals[l.code] ?? true;
    final meta = '${l.status == LinkStatus.on ? (appr ? 'Sign-ups wait in Approvals' : 'Sign-ups join straight away') : 'This link is ${l.status.name}'}'
        ' · ${l.joined} joined · ${l.waiting} waiting · ${l.till}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.qr_code_2_rounded, size: 60),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'trainwithvimal.app/join/', style: AppText.body.copyWith(fontSize: 13)),
                  TextSpan(text: l.code, style: AppText.bodyBold.copyWith(fontSize: 13)),
                ])),
                const SizedBox(height: 4),
                Text(meta, style: AppText.caption),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            AppButton('Copy link', icon: Icons.copy_rounded, small: true, onPressed: () => _done('Link copied', l.code)),
            AppButton.outline('WhatsApp', icon: Icons.chat_rounded, small: true, onPressed: () => _done('Shared on WhatsApp', l.code)),
            AppButton.outline('Email', icon: Icons.mail_outline_rounded, small: true, onPressed: () => _done('Email drafted', l.code)),
            AppButton.ghost('Download QR', small: true, onPressed: () => _done('QR downloaded', '${l.code}.png')),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      SheetSection(title: 'Link settings', children: [
        SelectField(label: 'Clients go to', value: l.trainer, hint: 'This trainer sees them first'),
        SelectField(label: 'Link works for', value: l.worksFor),
        SelectField(label: 'How many people', value: l.maxPeople),
        ToggleRow(
          title: 'New sign-ups wait in Approvals',
          subtitle: 'You approve each person before they can log in',
          value: appr,
          onChanged: (v) => setState(() => _approvals[l.code] = v),
        ),
      ]),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.visibility_outlined, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text('What she sees when she opens the link', style: AppText.bodyBold.copyWith(fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          _step(1, 'A sign-up page: Join ${l.trainer} at Train With Vimal'),
          _step(2, 'She makes her account and fills her details: goal, body, health form, food.'),
          _step(3, appr ? 'She waits in Approvals. You or ${l.trainer} approve her, then she can log in.' : 'She can log in straight away. ${l.trainer} gets a notice.'),
        ]),
      ),
    ]);
  }

  Widget _step(int n, String t) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Text('$n', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.text2))),
        ]),
      );

  Widget _new() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Spaced(children: [
        const SelectField(label: 'Clients go to', value: 'Aman Verma', hint: 'This trainer sees them first'),
        const LabeledField(label: 'Name for the link (optional)', initialValue: 'Instagram · October', help: 'Only you see this'),
        const SelectField(label: 'Link works for', value: '30 days · till 8 Nov'),
        const SelectField(label: 'How many people', value: 'No limit'),
        const SelectField(label: 'Code', value: 'AMAN-5530', hint: 'Made from the trainer name'),
        const ToggleRow(title: 'New sign-ups wait in Approvals', subtitle: 'You approve each person before they can log in', value: true),
        InfoBanner(text: 'Her link will be trainwithvimal.app/join/AMAN-5530', icon: Icons.link_rounded),
      ]),
    ]);
  }

  Widget _all() {
    final joined = _links.fold<int>(0, (a, l) => a + l.joined), waiting = _links.fold<int>(0, (a, l) => a + l.waiting);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        for (final (v, k) in [(_links.length, 'links'), (_onCount, 'on now'), (joined, 'people joined'), (waiting, 'waiting now')])
          Expanded(
            child: Column(children: [
              Text('$v', style: AppText.cardTitle.copyWith(fontSize: 18)),
              Text(k, style: AppText.caption.copyWith(fontSize: 11.5)),
            ]),
          ),
      ]),
      const SizedBox(height: 12),
      ListCard(children: [for (final l in _links) _linkRow(l)]),
      const SizedBox(height: 10),
      Text('Turning a link off stops new sign-ups. People who already joined keep their account. Deleting also hides it from this list.',
          style: AppText.caption),
    ]);
  }

  Widget _linkRow(InviteLink l) {
    final (b, tone) = switch (l.status) {
      LinkStatus.on => ('On', BadgeTone.ok),
      LinkStatus.off => ('Off', BadgeTone.neutral),
      LinkStatus.ended => ('Ended', BadgeTone.neutral),
    };
    void open() => setState(() {
          _code = l.code;
          _tab = 0;
        });
    return InkWell(
      onTap: open,
      child: Opacity(
        opacity: l.status == LinkStatus.on ? 1 : .6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
          child: Row(children: [
            const TintIcon(Icons.link_rounded, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(l.code, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  AppBadge(b, tone: tone),
                  if (l.name.isNotEmpty) Text(l.name, style: AppText.caption),
                ]),
                Text('${l.trainer} · ${l.made} · ${l.till}', style: AppText.caption),
                Text('${l.joined} joined · ${l.waiting > 0 ? '${l.waiting} waiting' : 'none waiting'}',
                    style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2)),
              ]),
            ),
            IconButton(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_vert_rounded, size: 19, color: AppColors.muted),
              onPressed: () => showActionSheet(context, title: l.code, actions: [
                SheetAction('Open link and QR', Icons.qr_code_rounded, open),
                SheetAction('Copy link', Icons.copy_rounded, () => _done('Link copied', l.code)),
                SheetAction(l.status == LinkStatus.off ? 'Turn on' : 'Turn off', Icons.power_settings_new_rounded, () {
                  setState(() => _links = [
                        for (final x in _links) x.code == l.code ? x.withStatus(l.status == LinkStatus.off ? LinkStatus.on : LinkStatus.off) : x
                      ]);
                  _done(l.status == LinkStatus.off ? 'Link turned on' : 'Link turned off', l.code);
                }),
                SheetAction('Delete link', Icons.delete_outline_rounded, () {
                  final before = _links;
                  setState(() => _links = _links.where((x) => x.code != l.code).toList());
                  showToast(context, 'Link deleted', subtitle: l.code, kind: ToastKind.del, onUndo: () {
                    if (mounted) setState(() => _links = before);
                  });
                }, destructive: true),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
