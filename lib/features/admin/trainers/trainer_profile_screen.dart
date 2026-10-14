import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';
import 'package:train_with_vimal/data/models/people.dart';

import '../activity/activity_feed.dart';
import '../clients/admin_ui.dart';
import 'trainer_profile_tabs.dart';
import 'trainers_screen.dart';

/// Design: TrainerProfileMobile.dc.html — one trainer: overview, clients,
/// access, activity, documents and what clients see.
class TrainerProfileScreen extends ConsumerStatefulWidget {
  const TrainerProfileScreen({super.key, required this.trainerId});
  final String trainerId;

  @override
  ConsumerState<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

const _tabs = ['ov', 'cl', 'acc', 'act', 'doc', 'cv'];

class _TrainerProfileScreenState extends ConsumerState<TrainerProfileScreen> {
  int _tab = 0;
  bool _readQuery = false;

  /// Access permissions: saved and being edited.
  late Map<String, bool> _saved = defaultPermissions();
  Map<String, bool>? _editing;

  /// Documents (verify changes the list).
  List<TrainerDoc> _docs = List.of(AdminMock.trainerDocs);

  /// What clients see.
  final Map<String, bool> _cv = {for (final r in AdminMock.clientViewRows) r.key: r.defaultOn};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readQuery) return;
    _readQuery = true;
    final q = GoRouterState.of(context).uri.queryParameters['tab'];
    final i = _tabs.indexOf(q ?? '');
    if (i >= 0) _tab = i;
  }

  Trainer get _t => PeopleMock.trainerById(widget.trainerId) ?? PeopleMock.trainers[1];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final active = !ref.watch(inactiveTrainersProvider).contains(t.id);
    final perms = _editing ?? _saved;
    final level = accessLevelOf(perms);
    final first = t.name.split(' ').first;

    final body = switch (_tabs[_tab]) {
      'cl' => TrainerClientsTab(trainer: t, onAssign: () => showAssignClients(context, t)),
      'acc' => AccessTab(
          saved: _saved,
          editing: perms,
          onChanged: (m) => setState(() => _editing = m),
          onReset: () => setState(() => _editing = null),
          onSave: () {
            setState(() {
              _saved = perms;
              _editing = null;
            });
            showToast(context, 'Access saved', subtitle: '$first · ${accessLevelOf(perms)}', kind: ToastKind.ok);
          },
        ),
      'act' => AppCard(
          child: ActivityFeed(
            days: AdminMock.trainerActivity,
            kinds: AdminMock.trainerActivityKinds,
            sourceOf: (e) => e.kind == 'Login' ? '$first · ${e.note}' : '$first · Android app',
            toolbar: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity', style: AppText.cardTitle.copyWith(fontSize: 17)),
                Text('What $first did in the app', style: AppText.caption),
              ],
            ),
          ),
        ),
      'doc' => DocumentsTab(
          docs: _docs,
          trainerName: t.name,
          onVerify: (i) => setState(() => _docs = [for (var j = 0; j < _docs.length; j++) j == i ? _docs[j].verify() : _docs[j]]),
        ),
      'cv' => ClientViewTab(
          trainer: t,
          values: _cv,
          docs: _docs,
          onToggle: (k) => setState(() => _cv[k] = !(_cv[k] ?? false)),
        ),
      _ => _Overview(
          trainer: t,
          level: level,
          onCount: perms.values.where((v) => v).length,
          docs: _docs,
          onTab: (i) => setState(() => _tab = i),
          onEdit: () => showEditTrainer(context, t),
        ),
    };

    return PageScroll(
      children: [
        SubPageHeader(
          title: t.name,
          subtitle: 'Trainers',
          actions: [AppIconButton(Icons.more_horiz_rounded, tooltip: 'More actions', onPressed: () => _menu(context, t, active))],
        ),
        _Hero(trainer: t, active: active, level: level),
        Row(
          children: [
            Expanded(child: AppButton.outline('Edit details', icon: Icons.edit_outlined, onPressed: () => showEditTrainer(context, t))),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Assign clients', icon: Icons.person_add_alt_rounded, onPressed: () => showAssignClients(context, t))),
          ],
        ),
        AdminStatGrid([
          AdminStat('Clients', '${t.clients} / ${t.capacity}', '${t.capacity - t.clients} spots free', icon: Icons.people_outline_rounded),
          AdminStat('Check-ins to review', '${t.pendingCheckins}', 'Oldest from yesterday', icon: Icons.assignment_outlined),
          AdminStat('Avg adherence', '${t.adherence}%', '+2% vs last month', icon: Icons.monitor_heart_outlined, tone: true),
          const AdminStat('Avg reply time', '3 h', 'Team average 4 h', icon: Icons.schedule_rounded, tone: true),
        ]),
        UnderlineTabs(
          labels: ['Overview', 'Clients · ${t.clients}', 'Access and permissions', 'Activity', 'Documents · ${_docs.length}', 'What clients see'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        body,
      ],
    );
  }

  void _menu(BuildContext context, Trainer t, bool active) {
    final first = t.name.split(' ').first;
    showActionSheet(
      context,
      title: t.name,
      actions: [
        SheetAction('Access and permissions', Icons.lock_outline_rounded, () => setState(() => _tab = 2)),
        SheetAction('Send password reset link', Icons.key_rounded,
            () => showToast(context, 'Reset link sent', subtitle: 'WhatsApp and email to $first', kind: ToastKind.ok)),
        SheetAction('Move all clients to another trainer', Icons.swap_horiz_rounded, () => showAssignClients(context, t)),
        if (!t.isYou)
          active
              ? SheetAction('Deactivate $first', Icons.block_rounded, destructive: true, () => confirmDeactivate(context, ref, t))
              : SheetAction('Reactivate $first', Icons.restart_alt_rounded, () => ref.read(inactiveTrainersProvider.notifier).reactivate(t.id)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.trainer, required this.active, required this.level});
  final Trainer trainer;
  final bool active;
  final String level;

  @override
  Widget build(BuildContext context) {
    final t = trainer;
    final meta = AppText.secondary.copyWith(fontSize: 12.5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(t.initials, size: 56, color: t.color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(t.name, style: AppText.sectionTitle),
                  AppBadge.status(active ? 'Active' : 'Inactive', tone: active ? BadgeTone.ok : BadgeTone.neutral),
                ],
              ),
              const SizedBox(height: 4),
              Text.rich(TextSpan(style: meta, children: [
                TextSpan(text: '${t.focus} · 6 years experience · Access '),
                TextSpan(text: level, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                const TextSpan(text: ' · Last login today, 9:40 am'),
              ])),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Overview

class _Overview extends StatelessWidget {
  const _Overview({required this.trainer, required this.level, required this.onCount, required this.docs, required this.onTab, required this.onEdit});
  final Trainer trainer;
  final String level;
  final int onCount;
  final List<TrainerDoc> docs;
  final ValueChanged<int> onTab;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = trainer;
    final first = t.name.split(' ').first;
    final edit = TextButton(onPressed: onEdit, child: const Text('Edit'));
    final total = AdminMock.permissionGroups.fold<int>(0, (a, g) => a + g.items.length);
    return Spaced(
      children: [
        TitledCard(
          title: 'Professional details',
          subtitle: 'Shown to you when you pick a trainer',
          trailing: edit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Spaced(
              gap: 14,
              children: [
                KvGrid([
                  (
                    'Speciality',
                    const Wrap(spacing: 4, runSpacing: 4, children: [AppChip('Strength'), AppChip('Fat loss'), AppChip('Powerlifting')]),
                  ),
                  ...KvGrid.text([
                    ('Experience', '6 years · since 2020'),
                    ('Trains', 'Gym and online'),
                    ('Languages', 'Hindi, English'),
                    ('Gender', 'Male'),
                    ('Best with', 'Beginners and busy office workers'),
                  ]),
                ]),
                _Labeled(
                  'About $first',
                  Text(
                    'Former state-level powerlifter. Focuses on simple strength plans and steady fat loss. Likes to keep check-ins short and reply the same day.',
                    style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.text2),
                  ),
                ),
                const _Labeled('Social media', SocialLinks(withCounts: true)),
              ],
            ),
          ),
        ),
        TitledCard(
          title: 'Contact and account',
          trailing: edit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: KvGrid(KvGrid.text([
              ('Mobile', '+91 98201 55432'),
              ('Email', t.email),
              ('Joined', t.since),
              ('Last login', 'Today, 9:40 am · Android app'),
              ('Most clients', '${t.capacity}'),
              ('Access', '$level · $onCount of $total'),
            ])),
          ),
        ),
        TitledCard(
          title: 'Certificates',
          subtitle: '3 of 4 verified · one expires soon',
          trailing: TextButton(onPressed: () => onTab(4), child: const Text('All documents')),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Spaced(
              gap: 10,
              children: [for (final d in docs.where((d) => d.kind == DocKind.cert).take(3)) DocRow(doc: d)],
            ),
          ),
        ),
        TitledCard(
          title: 'This week',
          subtitle: 'Mon 5 – Fri 9 Oct',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: KvGrid(KvGrid.text([
              ('Check-ins reviewed', '18 of 21'),
              ('Avg reply time', '3 h'),
              ('Plans changed', '5'),
              ('Sessions held', '12'),
            ])),
          ),
        ),
        TitledCard(
          title: 'Clients who need him',
          subtitle: 'From his ${t.clients} clients',
          trailing: TextButton(onPressed: () => onTab(1), child: const Text('All clients')),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Spaced(
              gap: 10,
              children: [
                for (final a in AdminMock.attention)
                  Row(
                    children: [
                      Avatar(a.initials, size: 34, color: a.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                            Text(a.why, style: AppText.caption),
                          ],
                        ),
                      ),
                      PlainBadge(a.badge, tone: a.badge == 'New' ? BadgeTone.info : BadgeTone.bad),
                    ],
                  ),
              ],
            ),
          ),
        ),
        TitledCard(
          title: 'Recent activity',
          trailing: TextButton(onPressed: () => onTab(3), child: const Text('All activity')),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Spaced(
              gap: 10,
              children: [
                for (final e in [...AdminMock.trainerActivity[0].items, ...AdminMock.trainerActivity[1].items].take(5))
                  Row(
                    children: [
                      ActivityIconDot(e, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${e.pre}${e.who.isEmpty ? '' : ' ${e.who}'}${e.post}',
                            style: AppText.secondary.copyWith(fontSize: 13, color: AppColors.text2)),
                      ),
                      const SizedBox(width: 8),
                      Text(e.when, style: AppText.caption),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
