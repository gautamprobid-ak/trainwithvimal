import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/people.dart';

import '../dashboard/trainer_widgets.dart';

/// Design: TrainerClientsMobile.dc.html — the clients given to Aman.
class TrainerClientsScreen extends StatefulWidget {
  const TrainerClientsScreen({super.key});

  @override
  State<TrainerClientsScreen> createState() => _TrainerClientsScreenState();
}

class _TrainerClientsScreenState extends State<TrainerClientsScreen> {
  ClientStatus? _status;
  String _query = '';

  /// Filter group label → picked option (missing = first option).
  Map<String, String> _filters = {};

  int get _activeFilters =>
      TrainerMock.clientFilters.where((g) => (_filters[g.$1] ?? g.$2.first) != g.$2.first).length;

  bool _matches(ClientSummary c) {
    final q = _query.trim().toLowerCase();
    if (_status != null && c.status != _status) return false;
    if (q.isNotEmpty && !c.name.toLowerCase().contains(q) && !c.email.toLowerCase().contains(q)) return false;
    final goal = _filters['Goal'];
    if (goal != null && goal != 'Any' && c.goal != goal) return false;
    final onb = _filters['Onboarding'];
    if (onb != null && onb != 'Any') {
      final ok = switch (onb) {
        'Done' => c.thisWeek == 'Done',
        'Not started' => c.thisWeek == 'Not started',
        _ => c.thisWeek.endsWith('%'),
      };
      if (!ok) return false;
    }
    final ci = _filters['Next check-in'];
    if (ci != null && ci != 'Any') {
      final ok = switch (ci) {
        'Today' => c.nextCheckin == 'Today',
        'Overdue' => c.nextCheckin == 'Overdue',
        _ => c.nextCheckin == 'Today' || c.nextCheckin.startsWith('Sun'),
      };
      if (!ok) return false;
    }
    final joined = _filters['Joined'];
    if (joined == 'Last 30 days' && !(c.joined.endsWith('Oct 2026') || c.joined.contains('Sep 2026'))) return false;
    if (joined == 'This year' && !c.joined.endsWith('2026')) return false;
    return true;
  }

  Future<void> _openFilters() async {
    final picked = await showAppSheet<Map<String, String>>(
      context,
      title: 'Filter',
      subtitle: 'Show only the clients you need',
      builder: (ctx) => _FilterBody(initial: _filters),
    );
    if (picked != null) setState(() => _filters = picked);
  }

  void _rowMenu(ClientSummary c) {
    showActionSheet(context, title: c.name, subtitle: c.email, actions: [
      SheetAction('View profile', Icons.person_outline_rounded, () => context.push(Routes.tClient(c.id))),
      SheetAction('Edit details', Icons.edit_outlined, () => _editDetails(c)),
    ]);
  }

  void _editDetails(ClientSummary c) {
    showAppSheet(
      context,
      title: 'Edit details',
      subtitle: c.name,
      builder: (_) => Spaced(children: [
        LabeledField(label: 'Full name', initialValue: c.name),
        LabeledField(label: 'Email', initialValue: c.email, keyboardType: TextInputType.emailAddress),
        LabeledField(label: 'Mobile', initialValue: c.phone, keyboardType: TextInputType.phone),
        LabeledField(label: 'Goal', initialValue: c.goal),
      ]),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Save', onPressed: () {
          Navigator.of(ctx).pop();
          showToast(context, 'Details saved', subtitle: c.name, kind: ToastKind.ok);
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = TrainerMock.myClients.where(_matches).toList();
    final f = _activeFilters;
    return PageScroll(
      children: [
        const PageHeader(
          title: 'My clients',
          subtitle: '24 clients given to you · 21 active · 2 at risk',
          actions: [TrainerProfileButton()],
        ),
        _StatusTabs(value: _status, onChanged: (s) => setState(() => _status = s)),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SearchField(
                  hint: 'Search name or email',
                  onChanged: (v) => setState(() => _query = v),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton.outline(f > 0 ? '· $f' : '', icon: Icons.filter_list_rounded, small: true, onPressed: _openFilters),
                      const SizedBox(width: 6),
                      AppButton.outline('', icon: Icons.download_rounded, small: true, onPressed: () {
                        showToast(context, 'Export ready', subtitle: 'CSV with ${rows.length} clients', kind: ToastKind.ok);
                      }),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              if (rows.isEmpty)
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No clients match',
                  message: 'Try another search or clear the filters.',
                  action: AppButton.outline('Clear filters', small: true, onPressed: () => setState(() {
                    _filters = {};
                    _status = null;
                  })),
                )
              else
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ClientRow(c: rows[i], onTap: () => context.push(Routes.tClient(rows[i].id)), onMenu: () => _rowMenu(rows[i])),
                ],
            ],
          ),
        ),
        _Pager(shown: rows.length),
      ],
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.value, required this.onChanged});
  final ClientStatus? value;
  final ValueChanged<ClientStatus?> onChanged;

  static const _order = <ClientStatus?>[null, ClientStatus.active, ClientStatus.pending, ClientStatus.paused, ClientStatus.atRisk];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              for (final s in _order)
                GestureDetector(
                  onTap: () => onChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s == value ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: s == value ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
                    ),
                    child: Row(
                      children: [
                        Text(s?.label ?? 'All',
                            style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: s == value ? AppColors.text : AppColors.text2)),
                        const SizedBox(width: 5),
                        Text('${TrainerMock.statusCounts[s]}', style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.c, required this.onTap, required this.onMenu});
  final ClientSummary c;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  static BadgeTone _tone(ClientStatus s) => switch (s) {
        ClientStatus.active => BadgeTone.ok,
        ClientStatus.pending => BadgeTone.warn,
        ClientStatus.atRisk => BadgeTone.bad,
        ClientStatus.paused => BadgeTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppColors.hover,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Avatar(c.initials, size: 36, color: TrainerMock.colorFor(c.name)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold),
                  Text(c.goal, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppBadge.status(c.status.label, tone: _tone(c.status)),
            IconButton(
              onPressed: onMenu,
              tooltip: 'More actions',
              icon: const Icon(Icons.more_vert_rounded, size: 19, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.shown});
  final int shown;

  @override
  Widget build(BuildContext context) {
    void other(int p) => showToast(context, 'Page $p of 3', subtitle: 'The demo has the first 8 clients only');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(shown == 8 ? 'Showing 1–8 of 24' : 'Showing $shown of 24', style: AppText.caption)),
          const AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous page'),
          const SizedBox(width: 4),
          _pg('1', true, null),
          _pg('2', false, () => other(2)),
          _pg('3', false, () => other(3)),
          const SizedBox(width: 4),
          AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next page', onPressed: () => other(2)),
        ],
      ),
    );
  }

  Widget _pg(String t, bool on, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: on ? AppColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(child: Text(t, style: AppText.bodyBold.copyWith(fontSize: 13, color: on ? Colors.white : AppColors.text2))),
            ),
          ),
        ),
      );
}

class _FilterBody extends StatefulWidget {
  const _FilterBody({required this.initial});
  final Map<String, String> initial;

  @override
  State<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends State<_FilterBody> {
  late final Map<String, String> _v = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, opts) in TrainerMock.clientFilters)
          SheetSection(title: label, children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in opts)
                  ChoicePill(o, selected: (_v[label] ?? opts.first) == o, onTap: () => setState(() => _v[label] = o)),
              ],
            ),
          ]),
        Row(
          children: [
            Expanded(child: AppButton.outline('Clear filters', onPressed: () => Navigator.of(context).pop(<String, String>{}))),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Show clients', onPressed: () => Navigator.of(context).pop(_v))),
          ],
        ),
      ],
    );
  }
}
