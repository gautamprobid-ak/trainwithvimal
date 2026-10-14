import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';
import 'me_sheets.dart';

/// Tab bodies of the trainer's own profile (TrainerMeMobile).

class _DocIcon extends StatelessWidget {
  const _DocIcon(this.d);
  final TrainerDoc d;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = d.colors;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(d.icon, size: 16, color: fg),
    );
  }
}

class _ActIcon extends StatelessWidget {
  const _ActIcon(this.k, {this.size = 28});
  final ActivityKind k;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: k.bg, shape: BoxShape.circle),
      child: Icon(k.icon, size: size * .5, color: k.fg),
    );
  }
}

// ------------------------------------------------------------------ Overview

class MeOverviewTab extends StatelessWidget {
  const MeOverviewTab({super.key, required this.accessLevel, required this.accessOn, required this.accessTotal, required this.onDocs, required this.onActivity});
  final String accessLevel;
  final int accessOn;
  final int accessTotal;
  final VoidCallback onDocs;
  final VoidCallback onActivity;

  @override
  Widget build(BuildContext context) {
    final certs = TrainerMock.docs.where((d) => d.type == DocType.cert).take(3).toList();
    final recent = [...TrainerMock.activity[0].items, ...TrainerMock.activity[1].items].take(5).toList();
    return Spaced(children: [
      TrainerSectionCard(
        title: 'Professional details',
        subtitle: 'Clients see only what you switch on in What clients see',
        action: 'Edit',
        onAction: () => showEditMyDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KvGrid([
              (
                'Speciality',
                Wrap(spacing: 4, runSpacing: 4, children: [for (final s in TrainerMock.specialities) AppChip(s)]),
              ),
              for (final (k, v) in TrainerMock.professional) (k, Text(v, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
            ], padding: const EdgeInsets.symmetric(horizontal: 16)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About you', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(TrainerMock.bio, style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.text2)),
                  const SizedBox(height: 12),
                  Text('Social media', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 14), child: SocialLinks()),
          ],
        ),
      ),
      TrainerSectionCard(
        title: 'Contact and account',
        action: 'Edit',
        onAction: () => showEditMyDetails(context),
        child: KvGrid.text([...TrainerMock.contact, ('Access', '$accessLevel · $accessOn of $accessTotal')]),
      ),
      TrainerSectionCard(
        title: 'Certificates',
        subtitle: '3 of 4 verified · one expires soon',
        action: 'All documents',
        onAction: onDocs,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(children: [
            for (final d in certs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  _DocIcon(d),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      Text(d.by, style: AppText.caption),
                    ]),
                  ),
                  AppBadge(d.status, tone: d.tone),
                ]),
              ),
          ]),
        ),
      ),
      TrainerSectionCard(title: 'This week', subtitle: 'Mon 5 – Fri 9 Oct', child: KvGrid.text(TrainerMock.meWeek)),
      TrainerSectionCard(
        title: 'Clients who need you',
        subtitle: 'From your 24 clients',
        action: 'My clients',
        onAction: () => context.go(Routes.tClients),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(children: [
            for (final n in TrainerMock.needsYou)
              InkWell(
                onTap: () => context.push(Routes.tClient(TrainerMock.clientIdFor(n.name))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Avatar(n.initials, size: 34, color: n.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                        Text(n.why, style: AppText.caption),
                      ]),
                    ),
                    AppBadge(n.badge, tone: n.tone),
                  ]),
                ),
              ),
          ]),
        ),
      ),
      TrainerSectionCard(
        title: 'Recent activity',
        action: 'All activity',
        onAction: onActivity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(children: [
            for (final a in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  _ActIcon(a.kind, size: 26),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a.text, style: AppText.body.copyWith(fontSize: 13))),
                  const SizedBox(width: 8),
                  Text(a.when, style: AppText.caption),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }
}

class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key, this.take = 3});
  final int take;
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final (icon, name, n) in TrainerMock.socials.take(take))
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(name, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text)),
            if (n.isNotEmpty) ...[const SizedBox(width: 6), Text(n, style: AppText.caption.copyWith(fontSize: 12.5))],
          ]),
        ),
    ]);
  }
}

// ----------------------------------------------------------------- Documents

class MeDocumentsTab extends StatelessWidget {
  const MeDocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    const docs = TrainerMock.docs;
    final sum = '${docs.length} files · ${docs.where((d) => d.status == 'Verified').length} verified · '
        '${docs.where((d) => d.expiring).length} expiring soon · ${docs.where((d) => d.unchecked).length} not checked';
    final groups = [
      ('Certificates', [for (var i = 0; i < docs.length; i++) if (docs[i].type == DocType.cert) i]),
      ('ID and contract', [for (var i = 0; i < docs.length; i++) if (docs[i].type != DocType.cert) i]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Certificates and documents', style: AppText.cardTitle),
              Text(sum, style: AppText.caption),
            ]),
          ),
          const SizedBox(width: 8),
          AppButton('Upload', icon: Icons.upload_rounded, small: true, onPressed: () => showUploadDocument(context)),
        ]),
        for (final (name, idx) in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
            child: Text('${name.toUpperCase()}  ·  ${idx.length}', style: AppText.overline.copyWith(fontSize: 11.5)),
          ),
          for (final i in idx) ...[_DocCard(i), const SizedBox(height: 10)],
        ],
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard(this.i);
  final int i;
  @override
  Widget build(BuildContext context) {
    final d = TrainerMock.docs[i];
    return AppCard(
      onTap: () => showDocumentViewer(context, i),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _DocIcon(d),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              Text(d.by, style: AppText.caption),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _meta('Issued', d.issued)),
          Expanded(child: _meta('Valid till', d.validTill, warn: d.expiring)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          AppBadge(d.status, tone: d.tone),
          const SizedBox(width: 8),
          Icon(d.clientsSee ? Icons.visibility_outlined : Icons.admin_panel_settings_outlined,
              size: 13, color: d.clientsSee ? const Color(0xFF15803D) : AppColors.muted),
          const SizedBox(width: 4),
          Text(d.clientsSee ? 'Clients see it' : 'Admins only',
              style: AppText.caption.copyWith(color: d.clientsSee ? const Color(0xFF15803D) : AppColors.muted)),
          const Spacer(),
          LinkButton('View', onTap: () => showDocumentViewer(context, i)),
        ]),
      ]),
    );
  }

  Widget _meta(String k, String v, {bool warn = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: AppText.caption.copyWith(fontSize: 11.5)),
        Text(v, style: AppText.bodyBold.copyWith(fontSize: 13, color: warn ? AppColors.warnText : AppColors.text)),
      ]);
}

// --------------------------------------------------------- What clients see

class MeVisibilityTab extends StatelessWidget {
  const MeVisibilityTab({super.key, required this.shown, required this.onToggle});
  final Map<String, bool> shown;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Spaced(children: [
      TrainerSectionCard(
        title: 'What clients see',
        subtitle: 'On “My trainer” in the client app',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(children: [
            for (final r in TrainerMock.visibility)
              ToggleRow(
                title: r.title,
                subtitle: r.sub.isNotEmpty ? r.sub : (shown[r.key]! ? 'Shown' : 'Hidden'),
                value: shown[r.key]!,
                locked: r.locked,
                onChanged: (_) => onToggle(r.key),
              ),
          ]),
        ),
      ),
      Text('LIVE PREVIEW · WHAT RIYA SEES', style: AppText.overline.copyWith(fontSize: 11)),
      _Preview(shown: shown),
      Text('Changes here show up in the client app right away.', style: AppText.caption),
    ]);
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.shown});
  final Map<String, bool> shown;

  @override
  Widget build(BuildContext context) {
    bool on(String k) => shown[k] ?? false;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(k, style: AppText.caption)),
            Flexible(child: Text(v, textAlign: TextAlign.right, style: AppText.bodyBold.copyWith(fontSize: 13))),
          ]),
        );
    final certs = TrainerMock.docs.where((d) => d.type == DocType.cert && d.clientsSee);
    return AppCard(
      color: const Color(0xFFFAFAF8),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Avatar('AV', size: 56, color: AvatarColor.c2),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aman Verma', style: AppText.cardTitle),
            Text('Your trainer', style: AppText.caption),
          ]),
        ]),
        const SizedBox(height: 8),
        if (on('spec')) row('Speciality', 'Strength, Fat loss, Powerlifting'),
        if (on('exp')) row('Experience', '6 years'),
        if (on('lang')) row('Languages', 'Hindi, English'),
        if (on('about'))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(TrainerMock.shortBio, style: AppText.body.copyWith(fontSize: 13, color: AppColors.text2)),
          ),
        if (on('certs')) ...[
          const SizedBox(height: 6),
          Text('Certificates', style: AppText.bodyBold.copyWith(fontSize: 13)),
          for (final c in certs)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                const Icon(Icons.verified_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(child: Text('${c.name} · ${c.by}', style: AppText.caption.copyWith(color: AppColors.text))),
              ]),
            ),
        ],
        if (on('soc')) ...[
          const SizedBox(height: 10),
          Text('Follow', style: AppText.bodyBold.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          const SocialLinks(take: 2),
        ],
        if (on('mob')) row('Mobile', '+91 98201 55432'),
        if (on('mail')) row('Email', 'aman.verma@email.com'),
      ]),
    );
  }
}

// ------------------------------------------------------------------ Access

class MeAccessTab extends StatelessWidget {
  const MeAccessTab({super.key, required this.asked, required this.onAsk});
  final String? asked;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final total = TrainerMock.permissions.fold<int>(0, (a, g) => a + g.items.length);
    final on = TrainerMock.permissions.fold<int>(0, (a, g) => a + g.items.where((p) => p.on).length);
    final askT = asked == null ? 'Nothing' : '${TrainerMock.accessAsks.firstWhere((a) => a.id == asked).title} · waiting';
    return Spaced(children: [
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const TintIcon(Icons.shield_outlined, tint: Tint.blue, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your access', style: AppText.caption),
                Row(children: [
                  Text('Assigned clients', style: AppText.cardTitle.copyWith(fontSize: 16)),
                  const SizedBox(width: 6),
                  const Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message: 'Only the clients given to you: their plans, logs and check-ins. Set by Vimal · last changed 12 Mar 2025.',
                    child: Icon(Icons.info_outline_rounded, size: 16, color: AppColors.muted),
                  ),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          KvGrid.text([
            ('Switched on', '$on of $total'),
            ('Clients you see', 'Only yours (24)'),
            ('Asked for', askT),
          ], padding: EdgeInsets.zero),
          const SizedBox(height: 12),
          AppButton.outline('Ask for more access', icon: Icons.key_rounded, onPressed: onAsk),
        ]),
      ),
      TrainerSectionCard(
        title: 'What you can do',
        subtitle: 'Ticked ones are on for you. The rest only Vimal can switch on.',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final g in TrainerMock.permissions) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(g.name, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                Text('${g.items.where((p) => p.on).length} of ${g.items.length}', style: AppText.caption),
              ]),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final p in g.items) _PermChip(p)]),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _PermChip extends StatelessWidget {
  const _PermChip(this.p);
  final Permission p;
  @override
  Widget build(BuildContext context) {
    final fg = p.on ? const Color(0xFF05603A) : AppColors.muted;
    return Tooltip(
      message: p.hint.isNotEmpty ? p.hint : (p.on ? 'On' : 'Off'),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: p.on ? const Color(0xFFECFDF3) : const Color(0xFFF4F4F2), borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(p.on ? Icons.check_rounded : Icons.lock_outline_rounded, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(p.label, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Activity

class MeActivityTab extends StatefulWidget {
  const MeActivityTab({super.key});
  @override
  State<MeActivityTab> createState() => _MeActivityTabState();
}

class _MeActivityTabState extends State<MeActivityTab> {
  String _range = 'Last 7 days';
  ActivityKind? _kind;
  int _limit = 8;

  static const _keep = Object();

  void _set({String? range, Object? kind = _keep}) {
    if (range != null) _range = range;
    if (kind != _keep) _kind = kind as ActivityKind?;
    _limit = 8;
  }

  @override
  Widget build(BuildContext context) {
    final days = TrainerMock.activityRanges.firstWhere((r) => r.$1 == _range).$2;
    final inRange = TrainerMock.activity.where((d) => d.daysAgo <= days).toList();
    bool ok(ActivityItem x) => _kind == null || x.kind == _kind;
    final total = inRange.fold<int>(0, (a, d) => a + d.items.where(ok).length);
    var left = _limit;
    final shown = <(ActivityDay, List<ActivityItem>, int)>[];
    for (final d in inRange) {
      final all = d.items.where(ok).toList();
      final items = all.take(left < 0 ? 0 : left).toList();
      left -= items.length;
      if (items.isNotEmpty) shown.add((d, items, all.length));
    }
    final n = shown.fold<int>(0, (a, s) => a + s.$2.length);

    return TrainerSectionCard(
      title: 'My activity',
      subtitle: 'What you did in the app',
      trailing: AppButton.outline(_range, icon: Icons.calendar_today_rounded, small: true, onPressed: () async {
        final v = await pickOption(context, title: 'Date range', options: [for (final r in TrainerMock.activityRanges) r.$1], current: _range);
        if (v != null) setState(() => _set(range: v));
      }),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ChipStrip(children: [
          CountChip('All', selected: _kind == null, count: inRange.fold<int>(0, (a, d) => a + d.items.length), onTap: () => setState(() => _set(kind: null))),
          for (final k in ActivityKind.values)
            CountChip(k.label,
                selected: _kind == k,
                count: inRange.fold<int>(0, (a, d) => a + d.items.where((x) => x.kind == k).length),
                onTap: () => setState(() => _set(kind: k))),
        ]),
        for (final (d, items, cnt) in shown) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text('${d.label.toUpperCase()} · $cnt', style: AppText.overline.copyWith(fontSize: 11.5)),
          ),
          for (final a in items) _ActRow(a),
        ],
        if (total == 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Nothing matches. Try a longer date range or fewer filters.', style: AppText.caption),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(children: [
            Expanded(child: Text(total > 0 ? 'Showing $n of $total' : '', style: AppText.caption)),
            if (n < total) AppButton.outline('Show more', small: true, onPressed: () => setState(() => _limit += 8)),
          ]),
        ),
      ]),
    );
  }
}

class _ActRow extends StatelessWidget {
  const _ActRow(this.a);
  final ActivityItem a;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ActIcon(a.kind),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(style: AppText.body.copyWith(fontSize: 13), children: [
              TextSpan(text: '${a.pre} '),
              TextSpan(text: a.who, style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: a.post),
            ])),
            if (a.isChange)
              Row(children: [
                Text(a.from, style: AppText.caption.copyWith(fontSize: 12.5, decoration: TextDecoration.lineThrough)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.muted)),
                Flexible(child: Text(a.to, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.accentText))),
              ])
            else if (a.note.isNotEmpty)
              Text(a.note, style: AppText.caption.copyWith(fontSize: 12.5)),
          ]),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: a.kind == ActivityKind.login ? 'Aman · ${a.note}' : 'Aman · Android app',
          child: Text(a.when, style: AppText.caption),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------- Account

class MeAccountTab extends StatelessWidget {
  const MeAccountTab({
    super.key,
    required this.devices,
    required this.notif,
    required this.onPassword,
    required this.onLogOut,
    required this.onLogOutAll,
    required this.onNotif,
  });

  final List<LoginDevice> devices;
  final Map<String, bool> notif;
  final VoidCallback onPassword;
  final ValueChanged<LoginDevice> onLogOut;
  final VoidCallback onLogOutAll;
  final ValueChanged<String> onNotif;

  @override
  Widget build(BuildContext context) {
    return Spaced(children: [
      TrainerSectionCard(
        title: 'Password',
        subtitle: 'Last changed 3 months ago',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('••••••••••', style: AppText.bodyBold),
                Text('Use at least 8 letters and a number', style: AppText.caption),
              ]),
            ),
            AppButton.outline('Change password', icon: Icons.lock_outline_rounded, small: true, onPressed: onPassword),
          ]),
        ),
      ),
      TrainerSectionCard(
        title: 'Where you are logged in',
        subtitle: '${devices.length} ${devices.length == 1 ? 'device' : 'devices'}',
        action: devices.length > 1 ? 'Log out of all others' : null,
        onAction: onLogOutAll,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(children: [
            for (final d in devices)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  TintIcon(d.phone ? Icons.smartphone_rounded : Icons.computer_rounded, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      Text(d.sub, style: AppText.caption),
                    ]),
                  ),
                  if (d.isThis) const AppBadge('This device', tone: BadgeTone.ok) else AppButton.outline('Log out', small: true, onPressed: () => onLogOut(d)),
                ]),
              ),
          ]),
        ),
      ),
      TrainerSectionCard(
        title: 'Notifications',
        subtitle: 'Push to your phone and email',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(children: [
            for (final n in TrainerMock.notifPrefs)
              ToggleRow(title: n.title, subtitle: n.sub, value: notif[n.key]!, onChanged: (_) => onNotif(n.key)),
          ]),
        ),
      ),
    ]);
  }
}
