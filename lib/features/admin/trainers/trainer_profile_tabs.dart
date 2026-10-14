import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';
import 'package:train_with_vimal/data/models/people.dart';

import '../clients/admin_ui.dart';

// ------------------------------------------------------------ Permissions

String _key(String group, String label) => '$group:$label';

/// The "Assigned clients" preset.
Map<String, bool> defaultPermissions() => {
      for (final g in AdminMock.permissionGroups)
        for (final p in g.items) _key(g.name, p.$1): p.$3,
    };

Map<String, bool> _allOn() => {for (final k in defaultPermissions().keys) k: true};

String accessLevelOf(Map<String, bool> pm) {
  final d = defaultPermissions();
  if (pm.values.every((v) => v)) return 'All clients';
  if (d.entries.every((e) => pm[e.key] == e.value)) return 'Assigned clients';
  return 'Custom';
}

class AccessTab extends StatelessWidget {
  const AccessTab({super.key, required this.saved, required this.editing, required this.onChanged, required this.onReset, required this.onSave});
  final Map<String, bool> saved;
  final Map<String, bool> editing;
  final ValueChanged<Map<String, bool>> onChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final level = accessLevelOf(editing);
    final onN = editing.values.where((v) => v).length;
    final changes = editing.keys.where((k) => editing[k] != saved[k]).length;
    final levels = [
      ('Assigned clients', 'Only the clients you give him: plans and check-ins. Default for new trainers.', defaultPermissions),
      ('All clients', 'Sees and can cover every client of the gym. For senior trainers.', _allOn),
      ('Custom', 'Switch each permission on or off below.', () => editing),
    ];
    return Spaced(
      children: [
        TitledCard(
          title: 'Access level',
          subtitle: 'Pick a starting point, then switch single permissions below',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: OptionList(children: [
              for (final (t, s, f) in levels) OptionRow(title: t, subtitle: s, selected: level == t, onTap: () => onChanged(f())),
            ]),
          ),
        ),
        TitledCard(
          title: 'Summary',
          subtitle: level,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Spaced(
              gap: 14,
              children: [
                KvGrid([
                  ...KvGrid.text([
                    ('Switched on', '$onN of ${editing.length}'),
                    ('Clients he sees', editing[_key('Clients', 'View all clients')] == true ? 'Every client of the gym' : 'Only his clients'),
                  ]),
                  (
                    'Not saved',
                    Text(changes == 0 ? 'Nothing' : '$changes ${changes == 1 ? 'change' : 'changes'}',
                        style: AppText.bodyBold.copyWith(fontSize: 13.5, color: changes > 0 ? const Color(0xFFB45309) : AppColors.text)),
                  ),
                ]),
                Row(
                  children: [
                    Expanded(child: AppButton.outline('Undo changes', onPressed: changes > 0 ? onReset : null)),
                    const SizedBox(width: 10),
                    Expanded(child: AppButton(changes > 0 ? 'Save access · $changes' : 'Saved', onPressed: changes > 0 ? onSave : null)),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (final g in AdminMock.permissionGroups)
          TitledCard(
            title: g.name,
            trailing: Text('${g.items.where((p) => editing[_key(g.name, p.$1)] == true).length} of ${g.items.length}', style: AppText.caption),
            child: Column(
              children: [
                for (final p in g.items) _permRow(g.name, p),
                const SizedBox(height: 6),
              ],
            ),
          ),
        InfoBanner(
          icon: Icons.lock_outline_rounded,
          bg: AppColors.sub,
          fg: AppColors.text2,
          text: 'Only for admins. Never given to a trainer.\nAdd trainers · Gym settings · Approve sign-ups for other trainers · Delete gym data',
        ),
      ],
    );
  }

  Widget _permRow(String group, (String, String, bool) p) {
    final k = _key(group, p.$1);
    final on = editing[k] == true;
    final changed = on != (saved[k] == true);
    return InkWell(
      onTap: () => onChanged({...editing, k: !on}),
      child: Container(
        color: changed ? const Color(0xFFFFFBEB) : null,
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$1, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                  Text(p.$2.isNotEmpty ? p.$2 : (on ? 'On' : 'Off'), style: AppText.caption),
                ],
              ),
            ),
            MiniToggle(on),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Clients

class TrainerClientsTab extends StatefulWidget {
  const TrainerClientsTab({super.key, required this.trainer, required this.onAssign});
  final Trainer trainer;
  final VoidCallback onAssign;

  @override
  State<TrainerClientsTab> createState() => _TrainerClientsTabState();
}

class _TrainerClientsTabState extends State<TrainerClientsTab> {
  FilterValues _f = {};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    const groups = AdminMock.trainerClientFilters;
    final rows = AdminMock.trainerClients.where((c) {
      if (_q.isNotEmpty && !c.name.toLowerCase().contains(_q.toLowerCase())) return false;
      if (_f.isOn(groups[0]) && c.status != _f['st']) return false;
      if (_f.isOn(groups[1]) && c.goal != _f['goal']) return false;
      return true;
    }).toList();
    return Spaced(
      children: [
        SearchField(
          hint: 'Search his clients',
          onChanged: (v) => setState(() => _q = v.trim()),
          trailing: FilterButton(
            count: _f.activeCount(groups),
            onTap: () => showFilterSheet(context, groups: groups, values: _f, onChanged: (v) => setState(() => _f = v)),
          ),
        ),
        ActiveFilterChips(groups: groups, values: _f, onChanged: (v) => setState(() => _f = v)),
        AppButton('Assign clients', icon: Icons.person_add_alt_rounded, expand: true, onPressed: widget.onAssign),
        for (final c in rows) _card(context, c),
        Text('Showing ${rows.length} of ${widget.trainer.clients} · most recent first', style: AppText.caption),
      ],
    );
  }

  Widget _card(BuildContext context, TrainerClientRow c) {
    final adhColor = c.adherence == 0 ? AppColors.muted : c.adherence < 70 ? const Color(0xFFB45309) : AppColors.text;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      onTap: () => _menu(context, c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(c.initials, size: 38, color: c.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                    Text(c.goal, style: AppText.caption),
                  ],
                ),
              ),
              AppBadge.status(c.status, tone: AppBadge.toneFor(c.status)),
              IconButton(icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.muted), onPressed: () => _menu(context, c)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: KvGrid([
              ...KvGrid.text([('Program', c.program)]),
              ('Adherence', Text(c.adherence == 0 ? '—' : '${c.adherence}%', style: AppText.bodyBold.copyWith(fontSize: 13.5, color: adhColor))),
              ...KvGrid.text([('Last check-in', c.lastCheckin), ('With him since', c.since)]),
            ]),
          ),
        ],
      ),
    );
  }

  void _menu(BuildContext context, TrainerClientRow c) {
    final match = PeopleMock.clients.where((x) => x.name == c.name).firstOrNull;
    showActionSheet(context, title: c.name, subtitle: c.program, actions: [
      SheetAction('Open profile', Icons.person_outline_rounded, () {
        if (match != null) {
          context.push(Routes.aClient(match.id));
        } else {
          showToast(context, 'Profile not in this demo', subtitle: c.name, kind: ToastKind.info);
        }
      }),
      SheetAction('Move to another trainer', Icons.swap_horiz_rounded,
          () => showToast(context, '${c.name} moved', subtitle: 'Now with Sahil Kapoor', kind: ToastKind.ok, onUndo: () {})),
    ]);
  }
}

// -------------------------------------------------------------- Documents

const _docIcons = {DocKind.cert: Icons.workspace_premium_outlined, DocKind.id: Icons.badge_outlined, DocKind.file: Icons.description_outlined};
const _docTints = {DocKind.cert: Tint.amber, DocKind.id: Tint.blue, DocKind.file: Tint.purple};

BadgeTone _docTone(TrainerDoc d) => d.expiring
    ? BadgeTone.warn
    : d.unchecked
        ? BadgeTone.neutral
        : BadgeTone.ok;

/// One certificate line (Overview card).
class DocRow extends StatelessWidget {
  const DocRow({super.key, required this.doc});
  final TrainerDoc doc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TintIcon(_docIcons[doc.kind]!, tint: _docTints[doc.kind]!, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              Text(doc.by, style: AppText.caption),
            ],
          ),
        ),
        PlainBadge(doc.status, tone: _docTone(doc)),
      ],
    );
  }
}

class DocumentsTab extends StatelessWidget {
  const DocumentsTab({super.key, required this.docs, required this.trainerName, required this.onVerify});
  final List<TrainerDoc> docs;
  final String trainerName;
  final ValueChanged<int> onVerify;

  @override
  Widget build(BuildContext context) {
    final sum = '${docs.length} files · ${docs.where((d) => d.verified).length} verified · '
        '${docs.where((d) => d.expiring).length} expiring soon · ${docs.where((d) => d.unchecked).length} not checked';
    return Spaced(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Certificates and documents', style: AppText.cardTitle.copyWith(fontSize: 17)),
                  Text(sum, style: AppText.caption),
                ],
              ),
            ),
            AppIconButton(Icons.upload_rounded, filled: true, tooltip: 'Upload document', onPressed: () => _upload(context)),
          ],
        ),
        for (final (name, test) in [('Certificates', (TrainerDoc d) => d.kind == DocKind.cert), ('ID and contract', (TrainerDoc d) => d.kind != DocKind.cert)]) ...[
          Overline('$name · ${docs.where(test).length}'),
          for (var i = 0; i < docs.length; i++)
            if (test(docs[i])) _docCard(context, i),
        ],
      ],
    );
  }

  Widget _docCard(BuildContext context, int i) {
    final d = docs[i];
    return AppCard(
      onTap: () => _view(context, i),
      child: Spaced(
        gap: 10,
        children: [
          DocRow(doc: d),
          KvGrid([
            ...KvGrid.text([('Issued', d.issued)]),
            ('Valid till', Text(d.validTill, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: d.expiring ? const Color(0xFFB45309) : AppColors.text))),
          ]),
          Row(
            children: [
              Icon(d.clientsSee ? Icons.visibility_outlined : Icons.lock_outline_rounded, size: 15, color: d.clientsSee ? AppColors.okText : AppColors.muted),
              const SizedBox(width: 5),
              Text(d.clientsSee ? 'Clients see it' : 'Admins only', style: AppText.caption.copyWith(color: d.clientsSee ? AppColors.okText : AppColors.muted)),
              const Spacer(),
              TextButton(onPressed: () => _view(context, i), child: const Text('View')),
            ],
          ),
        ],
      ),
    );
  }

  void _view(BuildContext context, int start) {
    var i = start;
    var zoom = 100;
    showAppSheet(
      context,
      title: 'Document',
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final d = docs[i];
        return Spaced(
          gap: 14,
          children: [
            Row(
              children: [
                TintIcon(_docIcons[d.kind]!, tint: _docTints[d.kind]!, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: AppText.bodyBold),
                      Text('${i + 1} of ${docs.length} · ${d.kindLabel}', style: AppText.caption),
                    ],
                  ),
                ),
                AppIconButton(Icons.chevron_left_rounded, small: true, onPressed: () => set(() {
                      i = (i - 1 + docs.length) % docs.length;
                      zoom = 100;
                    })),
                const SizedBox(width: 6),
                AppIconButton(Icons.chevron_right_rounded, small: true, onPressed: () => set(() {
                      i = (i + 1) % docs.length;
                      zoom = 100;
                    })),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(child: Text(d.file, style: AppText.caption)),
                Text('Page 1 of 1', style: AppText.caption),
                IconButton(icon: const Icon(Icons.zoom_out_rounded, size: 20), onPressed: () => set(() => zoom = (zoom - 25).clamp(50, 150))),
                Text('$zoom%', style: AppText.caption),
                IconButton(icon: const Icon(Icons.zoom_in_rounded, size: 20), onPressed: () => set(() => zoom = (zoom + 25).clamp(50, 150))),
              ],
            ),
            Container(
              height: 220,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Transform.scale(scale: zoom / 100, child: _Paper(doc: d, trainerName: trainerName)),
            ),
            PlainBadge(d.status, tone: _docTone(d)),
            KvGrid(KvGrid.text([
              ('Type', d.kindLabel),
              ('Issued by', d.by),
              ('Issued on', d.issued),
              ('Valid till', d.validTill),
              ('Who can see it', d.clientsSee ? 'Clients see it' : 'Admins only'),
              ('Uploaded', d.uploaded),
              ('File', d.size),
            ])),
            if (d.unchecked) ...[
              Text('Check the name and dates on the file, then mark it verified. Until then clients do not see it.', style: AppText.caption),
              AppButton('Mark as verified', icon: Icons.verified_outlined, onPressed: () {
                onVerify(i);
                showToast(ctx, 'Document verified', subtitle: d.name, kind: ToastKind.ok);
                Navigator.of(ctx).pop();
              }),
            ],
            Row(
              children: [
                AppButton.outline('Replace file', small: true, icon: Icons.upload_file_rounded,
                    onPressed: () => showToast(ctx, 'File replaced', subtitle: d.file, kind: ToastKind.ok)),
                const Spacer(),
                AppButton.ghost('Delete', small: true, icon: Icons.delete_outline_rounded,
                    onPressed: () => showToast(ctx, 'Document deleted', subtitle: d.name, kind: ToastKind.del, onUndo: () {})),
              ],
            ),
          ],
        );
      }),
    );
  }

  void _upload(BuildContext context) {
    showAppSheet(
      context,
      title: 'Upload a document',
      subtitle: 'Certificates, ID proof or contract. PDF or photo, up to 10 MB.',
      builder: (ctx) => Spaced(
        gap: 12,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(border: Border.all(color: AppColors.line2), borderRadius: BorderRadius.circular(12), color: AppColors.sub),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.muted),
                const SizedBox(height: 6),
                Text('Drop a file here or browse', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text('PDF, JPG or PNG', style: AppText.caption),
              ],
            ),
          ),
          PickerField(label: 'Type', value: 'Certificate', options: const ['Certificate', 'ID proof', 'Contract'], onChanged: (_) {}),
          const LabeledField(label: 'Name', hint: 'Kettlebell Level 1'),
          const LabeledField(label: 'Issued by', hint: 'StrongFirst'),
          const Row(
            children: [
              Expanded(child: LabeledField(label: 'Issued on', hint: 'MM / YYYY')),
              SizedBox(width: 10),
              Expanded(child: LabeledField(label: 'Valid till', hint: 'MM / YYYY or no end')),
            ],
          ),
          PickerField(
            label: 'Who can see it',
            value: 'Admins and clients',
            hint: 'Only after you mark it verified',
            options: const ['Admins and clients', 'Admins only'],
            onChanged: (_) {},
          ),
          const SwitchRow(title: 'Remind me before it expires', subtitle: '30 days before, on the Dashboard', initial: true),
        ],
      ),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Upload', icon: Icons.upload_rounded, onPressed: () {
          showToast(ctx, 'Document uploaded', subtitle: 'Mark it verified to show it to clients', kind: ToastKind.ok);
          Navigator.of(ctx).pop();
        }),
      ],
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.doc, required this.trainerName});
  final TrainerDoc doc;
  final String trainerName;

  @override
  Widget build(BuildContext context) {
    final small = AppText.caption.copyWith(fontSize: 10.5);
    final lines = switch (doc.kind) {
      DocKind.cert => [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFB45309), size: 26),
          Text('CERTIFICATE', style: small.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w800)),
          Text('This certifies that', style: small),
          Text(trainerName, style: AppText.cardTitle),
          Text('has completed', style: small),
          Text(doc.name, style: AppText.bodyBold.copyWith(fontSize: 12), textAlign: TextAlign.center),
          Text('${doc.by} · ${doc.issued}', style: small, textAlign: TextAlign.center),
        ],
      DocKind.id => [
          Text('Government of India', style: small.copyWith(fontWeight: FontWeight.w800)),
          Text(trainerName, style: AppText.cardTitle),
          Text('DOB 14/02/1994 · Male', style: small),
          Text('XXXX XXXX 4821', style: small.copyWith(letterSpacing: 1.5)),
          Text('Numbers are hidden in the preview', style: small),
        ],
      DocKind.file => [
          Text('Trainer agreement', style: AppText.cardTitle),
          Text('Between Train With Vimal and $trainerName', style: small, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Vimal          $trainerName', style: small.copyWith(fontStyle: FontStyle.italic)),
        ],
    };
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [for (final w in lines) Padding(padding: const EdgeInsets.only(bottom: 3), child: w)]),
    );
  }
}

// ------------------------------------------------------- What clients see

class ClientViewTab extends StatelessWidget {
  const ClientViewTab({super.key, required this.trainer, required this.values, required this.docs, required this.onToggle});
  final Trainer trainer;
  final Map<String, bool> values;
  final List<TrainerDoc> docs;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    bool on(String k) => values[k] == true;
    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [SizedBox(width: 90, child: Text(k, style: AppText.caption)), Expanded(child: Text(v, style: AppText.bodyBold.copyWith(fontSize: 13)))]),
        );
    return Spaced(
      children: [
        TitledCard(
          title: 'What clients see',
          subtitle: 'On “My trainer” in the client app',
          child: Column(
            children: [
              for (final r in AdminMock.clientViewRows)
                InkWell(
                  onTap: r.locked ? null : () => onToggle(r.key),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                              Text(r.sub.isNotEmpty ? r.sub : (on(r.key) ? 'Shown' : 'Hidden'), style: AppText.caption),
                            ],
                          ),
                        ),
                        if (r.locked)
                          Row(children: [
                            const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.muted),
                            const SizedBox(width: 3),
                            Text('Always', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                          ])
                        else
                          MiniToggle(on(r.key)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        Overline('Live preview · what Riya sees'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(trainer.initials, size: 56, color: trainer.color),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(trainer.name, style: AppText.cardTitle), Text('Your trainer', style: AppText.caption)],
                  ),
                ],
              ),
              if (on('spec')) kv('Speciality', 'Strength, Fat loss, Powerlifting'),
              if (on('exp')) kv('Experience', '6 years'),
              if (on('lang')) kv('Languages', 'Hindi, English'),
              if (on('about'))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Former state-level powerlifter. Focuses on simple strength plans and steady fat loss.',
                      style: AppText.body.copyWith(fontSize: 13, color: AppColors.text2)),
                ),
              if (on('certs')) ...[
                const SizedBox(height: 12),
                Text('Certificates', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                for (final d in docs.where((d) => d.kind == DocKind.cert && d.clientsSee))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Expanded(child: Text.rich(TextSpan(text: d.name, style: AppText.bodyBold.copyWith(fontSize: 13), children: [TextSpan(text: ' · ${d.by}', style: AppText.caption)]))),
                    ]),
                  ),
              ],
              if (on('soc')) ...[
                const SizedBox(height: 12),
                Text('Follow', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const SocialLinks(),
              ],
              if (on('mob')) kv('Mobile', '+91 98201 55432'),
              if (on('mail')) kv('Email', trainer.email),
            ],
          ),
        ),
        Text('Changes here show up in the client app right away.', style: AppText.caption),
      ],
    );
  }
}

/// Social media chips (Instagram, YouTube, website).
class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key, this.withCounts = false});
  final bool withCounts;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.camera_alt_outlined, '@aman.lifts', '12.4k'),
      (Icons.smart_display_outlined, 'Aman Verma Fitness', '3.1k'),
      if (withCounts) (Icons.language_rounded, 'amanlifts.in', ''),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (icon, label, n) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.text2),
                const SizedBox(width: 5),
                Text(label, style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                if (withCounts && n.isNotEmpty) ...[const SizedBox(width: 5), Text(n, style: AppText.caption)],
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Sheets

void showEditTrainer(BuildContext context, Trainer t) {
  final first = t.name.split(' ').first;
  showFormSheet(
    context,
    title: 'Edit $first’s details',
    subtitle: 'Personal, professional and work details',
    builder: (ctx) => SheetBody(
      note: 'Access is changed in the Access tab',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Save', icon: Icons.check_rounded, onPressed: () {
          showToast(ctx, 'Details saved', subtitle: t.name, kind: ToastKind.ok);
          Navigator.of(ctx).pop();
        }),
      ],
      children: [
        SheetSection(title: 'Personal', children: [
          LabeledField(label: 'Full name *', initialValue: t.name),
          const LabeledField(label: 'Mobile *', initialValue: '98201 55432', prefix: '+91'),
          LabeledField(label: 'Email *', initialValue: t.email),
          PickerField(label: 'Gender', value: 'Male', options: const ['Female', 'Male', 'Other'], onChanged: (_) {}),
          const LabeledField(label: 'Date of birth', initialValue: '14 / 02 / 1994'),
          const LabeledField(label: 'City', initialValue: 'Mumbai'),
        ]),
        SheetSection(title: 'Professional', children: [
          const LabeledField(label: 'Speciality', initialValue: 'Strength, Fat loss, Powerlifting', help: 'Separate with a comma'),
          const LabeledField(label: 'Experience (years)', initialValue: '6', help: 'Since 2020'),
          PickerField(label: 'Trains', value: 'Gym and online', options: const ['Gym and online', 'Gym only', 'Online only'], onChanged: (_) {}),
          const LabeledField(label: 'Languages', initialValue: 'Hindi, English'),
          const LabeledField(label: 'Best with', initialValue: 'Beginners and busy office workers'),
          const LabeledField(
            label: 'About (shown to you, not to clients)',
            maxLines: 3,
            initialValue: 'Former state-level powerlifter. Focuses on simple strength plans and steady fat loss.',
          ),
        ]),
        const SheetSection(
          title: 'Social media',
          subtitle: 'Optional. Clients see these only if you switch on Social media under Documents, What clients see.',
          children: [
            LabeledField(label: 'Instagram', initialValue: '@aman.lifts'),
            LabeledField(label: 'YouTube', initialValue: 'youtube.com/@amanvermafit'),
            LabeledField(label: 'Facebook', hint: 'Page link'),
            LabeledField(label: 'Website', initialValue: 'amanlifts.in'),
          ],
        ),
        SheetSection(title: 'Work', children: [
          LabeledField(label: 'Most clients', initialValue: '${t.capacity}', help: 'He has ${t.clients} now', keyboardType: TextInputType.number),
          LabeledField(label: 'Joined on', initialValue: t.since),
        ]),
        const SheetSection(title: 'Login', children: [
          SwitchRow(title: 'Send password reset link', subtitle: 'He gets a link on WhatsApp and email'),
        ]),
      ],
    ),
  );
}

void showAssignClients(BuildContext context, Trainer t) {
  showFormSheet(
    context,
    title: 'Assign clients to ${t.name.split(' ').first}',
    builder: (_) => _AssignBody(trainer: t),
  );
}

class _AssignBody extends StatefulWidget {
  const _AssignBody({required this.trainer});
  final Trainer trainer;

  @override
  State<_AssignBody> createState() => _AssignBodyState();
}

class _AssignBodyState extends State<_AssignBody> {
  final _picked = <String>{'Sana Khan'};
  String _kind = 'No trainer';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = widget.trainer;
    final room = t.capacity - t.clients;
    final free = room - _picked.length;
    const all = AdminMock.assignCandidates;
    final list = all.where((a) {
      if (_kind == 'No trainer' && a.hasTrainer) return false;
      if (_kind == 'With another trainer' && !a.hasTrainer) return false;
      return _q.isEmpty || a.name.toLowerCase().contains(_q.toLowerCase());
    }).toList();
    final n = _picked.length;
    return SheetBody(
      note: '$n picked',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Assign $n ${n == 1 ? 'client' : 'clients'}', icon: Icons.check_rounded, onPressed: n == 0
            ? null
            : () {
                showToast(context, '$n ${n == 1 ? 'client' : 'clients'} assigned', subtitle: '${t.name} is their trainer now', kind: ToastKind.ok);
                Navigator.of(context).pop();
              }),
      ],
      children: [
        Text('He has ${t.clients} of ${t.capacity} · $free spots left after this', style: AppText.secondary),
        SheetSection(
          title: 'Pick clients',
          subtitle: 'He can take $room more. Full trainers’ clients can be moved to him.',
          children: [
            SearchField(hint: 'Search clients', onChanged: (v) => setState(() => _q = v.trim())),
            KindChips(
              items: [
                ('No trainer', all.where((a) => !a.hasTrainer).length),
                ('With another trainer', all.where((a) => a.hasTrainer).length),
                ('All', all.length),
              ],
              value: _kind,
              onChanged: (v) => setState(() => _kind = v),
            ),
            OptionList(children: [
              for (final a in list)
                OptionRow(
                  title: a.name,
                  subtitle: a.sub,
                  multi: true,
                  selected: _picked.contains(a.name),
                  disabled: !_picked.contains(a.name) && free <= 0,
                  leading: Avatar(a.initials, size: 28, color: a.color),
                  trailing: PlainBadge(a.badge, tone: a.hasTrainer ? BadgeTone.neutral : BadgeTone.warn),
                  onTap: () => setState(() => _picked.contains(a.name) ? _picked.remove(a.name) : _picked.add(a.name)),
                ),
            ]),
          ],
        ),
        SheetSection(title: 'When you assign', children: [
          SwitchRow(title: 'Tell the clients', subtitle: 'Push notice: "${t.name} is your trainer now"', initial: true),
          SwitchRow(title: 'Keep their current plans', subtitle: '${t.name.split(' ').first} can change them later', initial: true),
        ]),
      ],
    );
  }
}
