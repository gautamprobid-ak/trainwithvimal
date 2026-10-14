import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/people.dart';

import '../clients/admin_ui.dart';

/// Design: TrainersMobile.dc.html — the coaching team.
class TrainersScreen extends ConsumerStatefulWidget {
  const TrainersScreen({super.key});

  @override
  ConsumerState<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends ConsumerState<TrainersScreen> {
  String _tab = 'all';
  String _query = '';
  FilterValues _filters = {};

  bool _match(Trainer t, bool on) {
    final full = on && t.isFull;
    if (_tab == 'active' && !on) return false;
    if (_tab == 'full' && !full) return false;
    if (_tab == 'inactive' && on) return false;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !'${t.name} ${t.email}'.toLowerCase().contains(q)) return false;
    final f = _filters;
    if (f['acc'] != null && f['acc'] != 'Any' && !t.access.startsWith(f['acc']!)) return false;
    if (f['space'] != null && f['space'] != 'Any' && (f['space'] == 'Full') != t.isFull) return false;
    if (f['spec'] != null && f['spec'] != 'Any' && !t.focus.toLowerCase().contains(f['spec']!.toLowerCase().replaceAll('’s', ''))) return false;
    if (f['ci'] != null && f['ci'] != 'Any' && (f['ci'] == 'All reviewed') != (t.pendingCheckins == 0)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final off = ref.watch(inactiveTrainersProvider);
    const all = PeopleMock.trainers;
    final act = all.where((t) => !off.contains(t.id)).toList();
    final shown = all.where((t) => _match(t, !off.contains(t.id))).toList();
    final sumC = act.fold<int>(0, (a, t) => a + t.clients);
    final sumM = act.fold<int>(0, (a, t) => a + t.capacity);
    final sumCI = act.fold<int>(0, (a, t) => a + t.pendingCheckins);
    final adh = sumC == 0 ? 0 : (act.fold<int>(0, (a, t) => a + t.adherence * t.clients) / sumC).round();
    const groups = AdminMock.trainerFilters;

    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Trainers',
          subtitle: '${all.length} in the team · ${act.length} active · $sumC clients',
          actions: [AppIconButton(Icons.person_add_alt_rounded, filled: true, tooltip: 'Add trainer', onPressed: () => _addTrainer(context))],
        ),
        AdminStatGrid([
          AdminStat('Active trainers', '${act.length}', '${all.length - act.length} inactive', icon: Icons.people_outline_rounded),
          AdminStat('Client spots', '$sumC / $sumM', '${sumM - sumC} spots free', icon: Icons.event_seat_outlined),
          AdminStat('Check-ins to review', '$sumCI', 'Karan has the most (4)', icon: Icons.assignment_outlined),
          AdminStat('Avg adherence', '$adh%', '+2% vs last week', icon: Icons.monitor_heart_outlined, tone: true),
        ]),
        CountTabs<String>(
          items: [
            ('all', 'All', all.length),
            ('active', 'Active', act.length),
            ('full', 'Full', act.where((t) => t.isFull).length),
            ('inactive', 'Inactive', all.length - act.length),
          ],
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        SearchField(
          hint: 'Search name, phone or email',
          onChanged: (v) => setState(() => _query = v),
          trailing: FilterButton(
            count: _filters.activeCount(groups),
            onTap: () => showFilterSheet(context, groups: groups, values: _filters, onChanged: (v) => setState(() => _filters = v)),
          ),
        ),
        if (_filters.activeCount(groups) > 0) ActiveFilterChips(groups: groups, values: _filters, onChanged: (v) => setState(() => _filters = v)),
        if (shown.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.badge_outlined,
              title: 'No trainers match',
              action: AppButton.outline('Clear filters', small: true, onPressed: () => setState(() => _filters = {})),
            ),
          ),
        for (final t in shown) _TrainerCard(trainer: t, active: !off.contains(t.id)),
        Text(
          '${shown.length < all.length ? 'Showing ${shown.length} of ${all.length}. ' : ''}Adherence is the share of planned workouts and meals done in the last 7 days.',
          style: AppText.caption,
        ),
      ],
    );
  }

  void _addTrainer(BuildContext context) {
    showFormSheet(context, title: 'Add a trainer', subtitle: 'They get their own login and see only what you allow.', builder: (_) => const _AddTrainerBody());
  }
}

// ------------------------------------------------------------ Trainer card

class _TrainerCard extends ConsumerWidget {
  const _TrainerCard({required this.trainer, required this.active});
  final Trainer trainer;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = trainer;
    final full = active && t.isFull;
    final pct = t.capacity == 0 ? 0.0 : t.clients / t.capacity;
    final barColor = full ? const Color(0xFFB91C1C) : pct >= .8 ? const Color(0xFFD97706) : const Color(0xFFC9C9C4);
    final adhColor = !active || t.clients == 0 ? AppColors.muted : t.adherence < 80 ? const Color(0xFFB45309) : AppColors.text;
    final ciColor = t.pendingCheckins >= 3 ? const Color(0xFFB45309) : t.pendingCheckins == 0 ? AppColors.muted : AppColors.text;
    return Opacity(
      opacity: active ? 1 : .65,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        onTap: () => context.push(Routes.aTrainer(t.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(t.initials, size: 40, color: t.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(t.name, style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                          if (t.isYou) const PlainBadge('You'),
                        ],
                      ),
                      Text(t.focus, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                    ],
                  ),
                ),
                AppBadge.status(active ? 'Active' : 'Inactive', tone: active ? BadgeTone.ok : BadgeTone.neutral),
                IconButton(
                  tooltip: 'More actions',
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.muted),
                  onPressed: () => _menu(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  MiniBar(pct, width: 44, color: barColor),
                  const SizedBox(width: 6),
                  Text.rich(TextSpan(
                    style: AppText.caption.copyWith(fontSize: 12.5),
                    children: [
                      TextSpan(text: '${t.clients}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                      TextSpan(text: ' / ${t.capacity}'),
                    ],
                  )),
                  if (full) ...[const SizedBox(width: 6), const PlainBadge('Full', tone: BadgeTone.warn)],
                  const Spacer(),
                  _Num('Check-ins', active ? '${t.pendingCheckins}' : '—', ciColor),
                  const SizedBox(width: 14),
                  _Num('Adherence', active && t.clients > 0 ? '${t.adherence}%' : '—', adhColor),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('${t.access} · Joined ${t.since}', style: AppText.caption),
          ],
        ),
      ),
    );
  }

  void _menu(BuildContext context, WidgetRef ref) {
    final t = trainer;
    final n = ref.read(inactiveTrainersProvider.notifier);
    showActionSheet(
      context,
      title: t.name,
      subtitle: t.focus,
      actions: [
        SheetAction('Open profile', Icons.person_outline_rounded, () => context.push(Routes.aTrainer(t.id))),
        if (!t.isYou) ...[
          SheetAction('Access and permissions', Icons.lock_outline_rounded, () => context.push('${Routes.aTrainer(t.id)}?tab=acc')),
          SheetAction('Edit details', Icons.edit_outlined, () => context.push(Routes.aTrainer(t.id))),
          SheetAction('Move clients to another trainer', Icons.swap_horiz_rounded,
              () => showToast(context, 'Pick clients to move', subtitle: 'Open ${t.name.split(' ').first}’s Clients tab', kind: ToastKind.info)),
          if (active)
            SheetAction('Deactivate', Icons.block_rounded, destructive: true, () => confirmDeactivate(context, ref, t))
          else
            SheetAction('Reactivate', Icons.restart_alt_rounded, () {
              n.reactivate(t.id);
              showToast(context, '${t.name} reactivated', subtitle: 'They can log in again', kind: ToastKind.ok);
            }),
        ],
      ],
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: AppText.bodyBold.copyWith(fontSize: 13, color: color)),
        Text(label, style: AppText.caption.copyWith(fontSize: 10.5)),
      ],
    );
  }
}

/// "Deactivate X?" modal; on confirm the trainer goes inactive (with undo).
void confirmDeactivate(BuildContext context, WidgetRef ref, Trainer t) {
  final off = ref.read(inactiveTrainersProvider);
  final first = t.name.split(' ').first;
  final others = PeopleMock.trainers.where((o) => o.id != t.id && o.id != 'vimal' && !off.contains(o.id) && o.clients < o.capacity);
  showAppSheet(
    context,
    title: 'Deactivate ${t.name}?',
    subtitle: 'You can reactivate $first any time.',
    builder: (ctx) => Spaced(
      gap: 14,
      children: [
        const FieldLabel('What happens'),
        BulletList([
          '$first cannot log in from now.',
          t.clients > 0
              ? 'Their ${t.clients} clients stay with them until you move them. Those clients get no check-in reviews meanwhile.'
              : 'They have no clients right now.',
          'Their plans, notes and check-in history stay.',
        ]),
        PickerField(
          label: 'Move their clients to',
          value: t.clients > 0 ? 'Share between trainers with space' : 'Nothing to move',
          hint: t.clients > 0 ? others.map((o) => '${o.name.split(' ').first} (${o.capacity - o.clients} free)').join(', ') : null,
          options: [if (t.clients > 0) 'Share between trainers with space' else 'Nothing to move', ...others.map((o) => o.name)],
          onChanged: (_) {},
        ),
      ],
    ),
    actions: (ctx) => [
      AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
      AppButton.danger('Deactivate', onPressed: () {
        final n = ref.read(inactiveTrainersProvider.notifier);
        n.deactivate(t.id);
        showToast(ctx, '${t.name} deactivated', subtitle: '$first cannot log in now', kind: ToastKind.del, onUndo: () => n.reactivate(t.id));
        Navigator.of(ctx).pop();
      }),
    ],
  );
}

// ------------------------------------------------------------ Add trainer

class _AddTrainerBody extends StatefulWidget {
  const _AddTrainerBody();

  @override
  State<_AddTrainerBody> createState() => _AddTrainerBodyState();
}

class _AddTrainerBodyState extends State<_AddTrainerBody> {
  String _mode = 'assigned';
  String _gender = 'Female';

  @override
  Widget build(BuildContext context) {
    final mode = AdminMock.accessModes.firstWhere((m) => m.$1 == _mode);
    return SheetBody(
      note: 'They cannot add trainers or change gym settings',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Add trainer', icon: Icons.person_add_alt_rounded, onPressed: () {
          showToast(context, 'Tara Pillai added', subtitle: 'Login invite sent on WhatsApp and email', kind: ToastKind.ok);
          Navigator.of(context).pop();
        }),
      ],
      children: [
        SheetSection(
          title: 'Login details',
          subtitle: 'They log in with this mobile number or email.',
          children: [
            const LabeledField(label: 'Full name *', initialValue: 'Tara Pillai'),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField(label: 'Mobile *', initialValue: '98330 41207', prefix: '+91', keyboardType: TextInputType.phone),
                SizedBox(height: 6),
                OkLine('No trainer or client uses this number'),
              ],
            ),
            const LabeledField(label: 'Email *', initialValue: 'tara.pillai@email.com', keyboardType: TextInputType.emailAddress),
            PickerField(
              label: 'Gender',
              value: _gender,
              hint: 'For clients who ask for a woman trainer',
              options: const ['Female', 'Male', 'Other'],
              onChanged: (v) => setState(() => _gender = v),
            ),
          ],
        ),
        const SheetSection(
          title: 'Work',
          children: [
            LabeledField(label: 'Speciality', initialValue: 'Strength, Fat loss', help: 'Separate with a comma'),
            LabeledField(label: 'Most clients they can take', initialValue: '30', help: 'A number. You can change this later', keyboardType: TextInputType.number),
            LabeledField(label: 'Experience (years)', initialValue: '4', help: 'Shown on their profile', keyboardType: TextInputType.number),
            LabeledField(label: 'Joined on', initialValue: 'Fri, 9 Oct 2026'),
            Text('Certificates and ID documents are added from their profile, under Documents.'),
          ],
        ),
        SheetSection(
          title: 'What can they see?',
          subtitle: 'You can change every permission later under Access and permissions.',
          children: [
            SegmentedTabs<String>(
              items: [for (final m in AdminMock.accessModes) (m.$1, m.$2)],
              value: _mode,
              onChanged: (v) => setState(() => _mode = v),
            ),
            Text(mode.$3, style: AppText.caption.copyWith(fontSize: 12.5)),
          ],
        ),
        const SheetSection(
          title: 'After you add',
          children: [
            SwitchRow(title: 'Send the login invite', subtitle: 'WhatsApp and email. They set their own password.', initial: true),
            SwitchRow(title: 'Give them clients now', subtitle: 'Opens the Clients page to pick clients for them'),
          ],
        ),
      ],
    );
  }
}
