import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import 'admin_ui.dart';

/// "Invite links" modal (Clients and Approvals pages): the current link with
/// its QR, a form to make a new link, and the list of all links.
Future<void> showInviteLinksSheet(BuildContext context, {String view = 'main'}) => showFormSheet(
      context,
      title: 'Invite links',
      builder: (_) => _InviteLinksBody(initialView: view),
    );

const _subs = {
  'main': 'Share it on WhatsApp or Instagram. People sign up and fill their own details.',
  'new': 'For a new trainer or a campaign. The old links keep working.',
  'all': 'Every link your team made. Open one to share it again or turn it off.',
};

class _InviteLinksBody extends ConsumerStatefulWidget {
  const _InviteLinksBody({required this.initialView});
  final String initialView;

  @override
  ConsumerState<_InviteLinksBody> createState() => _InviteLinksBodyState();
}

class _InviteLinksBodyState extends ConsumerState<_InviteLinksBody> {
  late String _view = widget.initialView;
  String _from = 'main';
  String? _code;

  void _go(String v) => setState(() {
        _from = _view;
        _view = v;
      });

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: 'https://trainwithvimal.app/join/$code'));
    showToast(context, 'Link copied', subtitle: 'trainwithvimal.app/join/$code', kind: ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    final links = ref.watch(inviteLinksProvider);
    if (links.isEmpty) {
      return const EmptyState(icon: Icons.link_off_rounded, title: 'No links', message: 'Make a new link to invite clients.');
    }
    final current = links.firstWhere((l) => l.code == _code, orElse: () => links.first);
    final onCount = links.where((l) => l.status == LinkStatus.on).length;
    final sumT = '$onCount of ${links.length} links are on';

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_subs[_view]!, style: AppText.secondary.copyWith(fontSize: 12.5)),
        const SizedBox(height: 12),
        CountTabs<String>(
          items: [('main', 'Invite link', null), ('new', 'New link', null), ('all', 'All links', links.length)],
          value: _view,
          onChanged: _go,
        ),
      ],
    );

    return switch (_view) {
      'new' => SheetBody(
          note: 'The old links keep working',
          actions: [
            AppButton.outline('Cancel', onPressed: () => setState(() => _view = _from == 'all' ? 'all' : 'main')),
            AppButton('Create link', icon: Icons.add_link_rounded, onPressed: () {
              ref.read(inviteLinksProvider.notifier).create();
              setState(() {
                _code = AdminMock.newInviteLink.code;
                _view = 'main';
              });
              showToast(context, 'Link created', subtitle: 'trainwithvimal.app/join/AMAN-5530', kind: ToastKind.ok);
            }),
          ],
          children: [header, const _NewLinkForm()],
        ),
      'all' => SheetBody(
          note: sumT,
          actions: [AppButton('Done', onPressed: () => Navigator.of(context).pop())],
          children: [
            header,
            _AllLinks(
              links: links,
              current: current.code,
              onOpen: (c) => setState(() {
                _code = c;
                _view = 'main';
              }),
              onCopy: _copy,
            ),
          ],
        ),
      _ => SheetBody(
          note: sumT,
          actions: [AppButton('Done', onPressed: () => Navigator.of(context).pop())],
          children: [header, _MainLink(link: current, onCopy: () => _copy(current.code))],
        ),
    };
  }
}

// --------------------------------------------------------------- Main tab

class _MainLink extends ConsumerWidget {
  const _MainLink({required this.link, required this.onCopy});
  final InviteLink link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appr = link.approvals;
    final meta = [
      link.status == LinkStatus.on ? (appr ? 'Sign-ups wait in Approvals' : 'Sign-ups join straight away') : 'This link is ${link.status.label.toLowerCase()}',
      '${link.joined} joined',
      '${link.waiting} waiting',
      link.tillShort,
    ].join(' · ');
    final step3 = appr
        ? 'She waits in Approvals. You or ${link.trainer} approve her, then she can log in.'
        : 'She can log in straight away. ${link.trainer} gets a notice.';
    return Spaced(
      gap: 16,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Qr(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'trainwithvimal.app/join/',
                        style: AppText.body.copyWith(color: AppColors.text2),
                        children: [TextSpan(text: link.code, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800))],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(meta, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton('Copy link', small: true, icon: Icons.copy_rounded, onPressed: onCopy),
            AppButton.outline('WhatsApp', small: true, icon: Icons.chat_rounded,
                onPressed: () => showToast(context, 'Opening WhatsApp', subtitle: 'Link ready to share', kind: ToastKind.info)),
            AppButton.outline('Email', small: true, icon: Icons.mail_outline_rounded,
                onPressed: () => showToast(context, 'Opening email', subtitle: 'Link added to a new email', kind: ToastKind.info)),
            AppButton.ghost('Download QR', small: true, onPressed: () => showToast(context, 'QR code saved', subtitle: '${link.code}.png', kind: ToastKind.ok)),
          ],
        ),
        Text('Link settings', style: AppText.bodyBold.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
        _LinkSettings(link: link),
        SwitchRow(
          title: 'New sign-ups wait in Approvals',
          subtitle: 'You approve each person before they can log in',
          value: appr,
          onChanged: (_) => ref.read(inviteLinksProvider.notifier).toggleApprovals(link.code),
        ),
        _Explain(trainer: link.trainer, step3: step3),
      ],
    );
  }
}

class _LinkSettings extends StatefulWidget {
  const _LinkSettings({required this.link});
  final InviteLink link;

  @override
  State<_LinkSettings> createState() => _LinkSettingsState();
}

class _LinkSettingsState extends State<_LinkSettings> {
  final _over = <String, String>{};

  String _v(String k, String d) => _over['${widget.link.code}:$k'] ?? d;
  void _set(String k, String v) {
    setState(() => _over['${widget.link.code}:$k'] = v);
    showToast(context, 'Link updated', subtitle: v, kind: ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.link;
    return Spaced(
      gap: 12,
      children: [
        PickerField(
          label: 'Clients go to',
          value: _v('tr', l.trainer),
          hint: 'This trainer sees them first',
          options: AdminMock.trainerNames,
          onChanged: (v) => _set('tr', v),
        ),
        PickerField(
          label: 'Link works for',
          value: _v('till', l.till),
          options: const ['7 days · till 16 Oct', '30 days · till 8 Nov', '90 days · till 7 Jan', 'No end date'],
          onChanged: (v) => _set('till', v),
        ),
        PickerField(
          label: 'How many people',
          value: _v('max', l.max),
          options: const ['No limit', '10 people', '20 people', '50 people'],
          onChanged: (v) => _set('max', v),
        ),
      ],
    );
  }
}

class _Explain extends StatelessWidget {
  const _Explain({required this.trainer, required this.step3});
  final String trainer;
  final String step3;

  @override
  Widget build(BuildContext context) {
    Widget step(String n, Widget text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(n, style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentText)),
            ),
            const SizedBox(width: 10),
            Expanded(child: text),
          ],
        );
    final style = AppText.secondary.copyWith(color: AppColors.text2, fontSize: 12.5);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Spaced(
        gap: 10,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 16, color: AppColors.accentText),
              const SizedBox(width: 6),
              Text('What she sees when she opens the link', style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.accentText)),
            ],
          ),
          step(
            '1',
            Text.rich(TextSpan(text: 'A sign-up page: ', style: style, children: [
              TextSpan(text: 'Join $trainer at Train With Vimal', style: style.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
            ])),
          ),
          step('2', Text('She makes her account and fills her details: goal, body, health form, food.', style: style)),
          step('3', Text(step3, style: style)),
        ],
      ),
    );
  }
}

/// 12 × 12 QR pattern from the design.
class _Qr extends StatelessWidget {
  const _Qr();

  @override
  Widget build(BuildContext context) {
    const q = AdminMock.qr;
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (var r = 0; r < 12; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 12; c++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(.5),
                        color: q[r * 12 + c] == '1' ? AppColors.text : Colors.white,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- New tab

class _NewLinkForm extends StatefulWidget {
  const _NewLinkForm();

  @override
  State<_NewLinkForm> createState() => _NewLinkFormState();
}

class _NewLinkFormState extends State<_NewLinkForm> {
  String _trainer = 'Aman Verma';
  String _till = '30 days · till 8 Nov';
  String _max = 'No limit';

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 12,
      children: [
        PickerField(
          label: 'Clients go to',
          value: _trainer,
          hint: 'This trainer sees them first',
          options: AdminMock.trainerNames,
          onChanged: (v) => setState(() => _trainer = v),
        ),
        const LabeledField(label: 'Name for the link (optional)', initialValue: 'Instagram · October', help: 'Only you see this'),
        PickerField(
          label: 'Link works for',
          value: _till,
          options: const ['7 days · till 16 Oct', '30 days · till 8 Nov', '90 days · till 7 Jan', 'No end date'],
          onChanged: (v) => setState(() => _till = v),
        ),
        PickerField(
          label: 'How many people',
          value: _max,
          options: const ['No limit', '10 people', '20 people', '50 people'],
          onChanged: (v) => setState(() => _max = v),
        ),
        PickerField(label: 'Code', value: 'AMAN-5530', hint: 'Made from the trainer name', options: const ['AMAN-5530'], onChanged: (_) {}),
        const SwitchRow(title: 'New sign-ups wait in Approvals', subtitle: 'You approve each person before they can log in', initial: true),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, size: 17, color: AppColors.text2),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(TextSpan(
                  text: 'Her link will be ',
                  style: AppText.secondary.copyWith(color: AppColors.text2),
                  children: [TextSpan(text: 'trainwithvimal.app/join/AMAN-5530', style: AppText.bodyBold.copyWith(fontSize: 13))],
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- All tab

class _AllLinks extends ConsumerWidget {
  const _AllLinks({required this.links, required this.current, required this.onOpen, required this.onCopy});
  final List<InviteLink> links;
  final String current;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sum = [
      (links.length, 'links'),
      (links.where((l) => l.status == LinkStatus.on).length, 'on now'),
      (links.fold<int>(0, (a, l) => a + l.joined), 'people joined'),
      (links.fold<int>(0, (a, l) => a + l.waiting), 'waiting now'),
    ];
    return Spaced(
      gap: 14,
      children: [
        Row(
          children: [
            for (final (v, k) in sum)
              Expanded(
                child: Column(
                  children: [
                    Text('$v', style: AppText.bigNumber.copyWith(fontSize: 20)),
                    Text(k, style: AppText.caption.copyWith(fontSize: 11.5), textAlign: TextAlign.center),
                  ],
                ),
              ),
          ],
        ),
        OptionList(
          children: [for (final l in links) _linkRow(context, ref, l)],
        ),
        Text(
          'Turning a link off stops new sign-ups. People who already joined keep their account. Deleting also hides it from this list.',
          style: AppText.caption,
        ),
      ],
    );
  }

  Widget _linkRow(BuildContext context, WidgetRef ref, InviteLink l) {
    final on = l.status == LinkStatus.on;
    return Opacity(
      opacity: on ? 1 : .6,
      child: Material(
        color: l.code == current ? const Color(0xFFF5F8FF) : Colors.white,
        child: InkWell(
          onTap: () => onOpen(l.code),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                const TintIcon(Icons.link_rounded, tint: Tint.blue, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(l.code, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                          PlainBadge(l.status.label, tone: on ? BadgeTone.ok : BadgeTone.neutral),
                          if (l.name.isNotEmpty) Text(l.name, style: AppText.caption),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${l.trainer} · ${l.made} · ${l.tillShort}', style: AppText.caption),
                      Text('${l.joined} joined · ${l.waiting > 0 ? '${l.waiting} waiting' : 'none waiting'}',
                          style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
                  onPressed: () => _menu(context, ref, l),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _menu(BuildContext context, WidgetRef ref, InviteLink l) {
    final n = ref.read(inviteLinksProvider.notifier);
    showActionSheet(
      context,
      title: l.code,
      subtitle: '${l.trainer} · ${l.tillShort}',
      actions: [
        SheetAction('Open link and QR', Icons.qr_code_rounded, () => onOpen(l.code)),
        SheetAction('Copy link', Icons.copy_rounded, () => onCopy(l.code)),
        if (l.status != LinkStatus.ended)
          SheetAction(l.status == LinkStatus.off ? 'Turn on' : 'Turn off', Icons.power_settings_new_rounded, () {
            n.toggle(l.code);
            showToast(context, l.status == LinkStatus.off ? 'Link turned on' : 'Link turned off', subtitle: l.code, kind: ToastKind.ok);
          }),
        SheetAction('Delete link', Icons.delete_outline_rounded, destructive: true, () {
          n.delete(l.code);
          showToast(context, 'Link deleted', subtitle: l.code, kind: ToastKind.del);
        }),
      ],
    );
  }
}
