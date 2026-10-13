import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/people.dart';

import 'add_client_sheet.dart';
import 'admin_ui.dart';
import 'invite_links_sheet.dart';

/// Design: ClientsMobile.dc.html — the admin's client list. On a phone the
/// table rows become cards; row actions open in a bottom sheet.
class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  ClientStatus? _tab;
  String _query = '';
  FilterValues _filters = {};

  bool _matches(ClientSummary c) {
    if (_tab != null && c.status != _tab) return false;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !c.name.toLowerCase().contains(q) && !c.email.toLowerCase().contains(q)) return false;
    final f = _filters;
    if (f['tr'] != null && f['tr'] != 'Anyone' && c.trainer != f['tr']) return false;
    if (f['goal'] != null && f['goal'] != 'Any' && c.goal != f['goal']) return false;
    switch (f['onb']) {
      case 'Done' when c.thisWeek != 'Done':
      case 'Not started' when c.thisWeek != 'Not started':
      case 'In progress' when !c.thisWeek.endsWith('%'):
        return false;
    }
    switch (f['ci']) {
      case 'Today' when c.nextCheckin != 'Today':
      case 'Overdue' when c.nextCheckin != 'Overdue':
      case 'This week' when !(c.nextCheckin == 'Today' || c.nextCheckin.contains('Oct')):
        return false;
    }
    switch (f['joined']) {
      case 'Last 30 days' when !(c.joined.contains('Oct 2026') || c.joined.contains('Sep 2026')):
      case 'This year' when !c.joined.contains('2026'):
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(adminClientsProvider);
    final shown = all.where(_matches).toList();
    int count(ClientStatus s) => all.where((c) => c.status == s).length;
    final noTrainer = all.where((c) => c.trainer == 'No trainer').length;
    final groups = AdminMock.clientFilters;

    return PageScroll(
      children: [
        PageHeader(
          title: 'Clients',
          subtitle: '${all.length} clients · ${count(ClientStatus.active)} active · $noTrainer need a trainer',
        ),
        Row(
          children: [
            Expanded(child: AppButton.outline('Invite link', icon: Icons.link_rounded, onPressed: () => showInviteLinksSheet(context))),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Add client', icon: Icons.add_rounded, onPressed: () => showAddClientSheet(context))),
          ],
        ),
        CountTabs<ClientStatus?>(
          items: [
            (null, 'All', all.length),
            (ClientStatus.active, 'Active', count(ClientStatus.active)),
            (ClientStatus.pending, 'Pending', count(ClientStatus.pending)),
            (ClientStatus.paused, 'Paused', count(ClientStatus.paused)),
            (ClientStatus.atRisk, 'At risk', count(ClientStatus.atRisk)),
          ],
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        SearchField(
          hint: 'Search name or email',
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
              icon: Icons.person_search_rounded,
              title: 'No clients match',
              message: 'Try another tab, search or filter.',
              action: AppButton.outline('Clear filters', small: true, onPressed: () => setState(() {
                _filters = {};
                _tab = null;
              })),
            ),
          )
        else
          for (final c in shown) _ClientCard(client: c),
        _ListFooter(shown: shown.length, total: all.length),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.shown, required this.total});
  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(shown == 0 ? 'No clients shown' : 'Showing 1–$shown of $total', style: AppText.caption)),
        AppButton.outline(
          'Export',
          small: true,
          icon: Icons.download_rounded,
          onPressed: () => showToast(context, 'Export started', subtitle: '$shown clients · CSV file', kind: ToastKind.ok),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Client card

class _ClientCard extends ConsumerWidget {
  const _ClientCard({required this.client});
  final ClientSummary client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = client;
    final progress = switch (c.thisWeek) {
      'Done' => 1.0,
      'Not started' => 0.0,
      _ => (int.tryParse(c.thisWeek.replaceAll('%', '')) ?? 0) / 100,
    };
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      onTap: () => context.push(Routes.aClient(c.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(c.initials, size: 40, color: AdminMock.colorFor(c)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                    Text(c.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                  ],
                ),
              ),
              AppBadge.status(c.status.label, tone: AppBadge.toneFor(c.status.label)),
              IconButton(
                tooltip: 'More actions',
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted, size: 20),
                onPressed: () => showClientActions(context, ref, c),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (c.trainer == 'No trainer')
                      const AppBadge('No trainer', tone: BadgeTone.warn)
                    else
                      Flexible(child: _Meta(Icons.person_outline_rounded, c.trainer)),
                    const SizedBox(width: 12),
                    Flexible(child: _Meta(Icons.flag_outlined, c.goal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Onboarding', style: AppText.caption),
                    const SizedBox(width: 8),
                    MiniBar(progress, width: 56, height: 6),
                    const SizedBox(width: 6),
                    Text(c.thisWeek, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(c.lastActive, style: AppText.caption),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _Meta(Icons.event_outlined, 'Next check-in: ${c.nextCheckin}')),
                    Text(c.phone, style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Row actions

/// Row actions (View profile, Edit, Change trainer, Pause, Delete).
void showClientActions(BuildContext context, WidgetRef ref, ClientSummary c) {
  final n = ref.read(adminClientsProvider.notifier);
  final paused = c.status == ClientStatus.paused;
  showActionSheet(
    context,
    title: c.name,
    subtitle: '${c.trainer} · ${c.goal}',
    actions: [
      SheetAction('View profile', Icons.person_outline_rounded, () => context.push(Routes.aClient(c.id))),
      SheetAction('Edit details', Icons.edit_outlined, () => _editClient(context, ref, c)),
      SheetAction('Change trainer', Icons.swap_horiz_rounded, () => _changeTrainer(context, ref, c)),
      SheetAction(paused ? 'Resume' : 'Pause', paused ? Icons.play_arrow_rounded : Icons.pause_rounded, () {
        n.setStatus(c.id, paused ? ClientStatus.active : ClientStatus.paused);
        showToast(
          context,
          paused ? '${c.name} resumed' : '${c.name} paused',
          subtitle: paused ? 'Plans and reminders are back on' : 'No reminders until you resume',
          kind: ToastKind.ok,
          onUndo: () => n.setStatus(c.id, c.status),
        );
      }),
      SheetAction('Delete client', Icons.delete_outline_rounded, destructive: true, () async {
        final ok = await showConfirmDialog(
          context,
          title: 'Delete ${c.name}?',
          message: 'Her plans, logs and check-ins are removed. This cannot be undone after a few seconds.',
          confirmLabel: 'Delete client',
          destructive: true,
          icon: Icons.delete_outline_rounded,
        );
        if (!ok || !context.mounted) return;
        final i = n.remove(c.id);
        showToast(context, '${c.name} deleted', subtitle: 'Removed from your clients', kind: ToastKind.del, onUndo: () => n.insert(i, c));
      }),
    ],
  );
}

void _changeTrainer(BuildContext context, WidgetRef ref, ClientSummary c) {
  final n = ref.read(adminClientsProvider.notifier);
  showAppSheet(
    context,
    title: 'Change trainer',
    subtitle: '${c.name} · now ${c.trainer}',
    builder: (ctx) => OptionList(
      children: [
        for (final t in AdminMock.trainerChoices)
          OptionRow(
            title: t.name,
            subtitle: '${t.focus} · ${t.clients} / ${t.capacity}',
            selected: t.name == c.trainer,
            disabled: t.full && t.name != c.trainer,
            leading: Avatar(t.initials, size: 32, color: t.color),
            badge: t.full ? const PlainBadge('Full', tone: BadgeTone.warn) : null,
            onTap: () {
              Navigator.of(ctx).pop();
              if (t.name == c.trainer) return;
              n.setTrainer(c.id, t.name);
              showToast(context, '${c.name} moved to ${t.name}', subtitle: '${t.name.split(' ').first} sees her plans and check-ins now', kind: ToastKind.ok,
                  onUndo: () => n.setTrainer(c.id, c.trainer));
            },
          ),
      ],
    ),
  );
}

void _editClient(BuildContext context, WidgetRef ref, ClientSummary c) {
  final name = TextEditingController(text: c.name);
  final email = TextEditingController(text: c.email);
  final phone = TextEditingController(text: c.phone.replaceFirst('+91 ', ''));
  var goal = c.goal;
  showAppSheet(
    context,
    title: 'Edit details',
    subtitle: c.name,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Spaced(
        gap: 12,
        children: [
          LabeledField(label: 'Full name', controller: name),
          LabeledField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress),
          LabeledField(label: 'Mobile', controller: phone, prefix: '+91', keyboardType: TextInputType.phone),
          PickerField(
            label: 'Goal',
            value: goal,
            options: const ['Fat loss', 'Muscle gain', 'Strength', 'Recomp', 'General fitness'],
            onChanged: (v) => setSheet(() => goal = v),
          ),
        ],
      ),
    ),
    actions: (ctx) => [
      AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
      AppButton('Save', icon: Icons.check_rounded, onPressed: () {
        ref.read(adminClientsProvider.notifier).replace(ClientSummary(
              id: c.id,
              name: name.text.trim().isEmpty ? c.name : name.text.trim(),
              email: email.text.trim(),
              trainer: c.trainer,
              goal: goal,
              status: c.status,
              thisWeek: c.thisWeek,
              phone: '+91 ${phone.text.trim()}',
              joined: c.joined,
              nextCheckin: c.nextCheckin,
              lastActive: c.lastActive,
              program: c.program,
              adherence: c.adherence,
            ));
        showToast(ctx, 'Details saved', subtitle: name.text.trim(), kind: ToastKind.ok);
        Navigator.of(ctx).pop();
      }),
    ],
  );
}
