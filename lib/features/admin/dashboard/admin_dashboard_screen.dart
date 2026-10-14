import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import '../clients/add_client_sheet.dart';
import '../clients/admin_ui.dart';

/// Design: AdminDashboardMobile.dc.html — the owner's home.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.people_outline_rounded, Icons.how_to_reg_outlined, Icons.fact_check_outlined, Icons.insights_rounded];
    return PageScroll(
      children: [
        PageHeader(
          title: 'Good evening, Vimal',
          subtitle: 'Thursday, 8 October · 3 things need you today',
          actions: [
            AppIconButton(Icons.search_rounded, tooltip: 'Search', onPressed: () => context.go(Routes.aClients)),
            AppIconButton(Icons.notifications_none_rounded,
                dot: true,
                tooltip: 'Notifications',
                onPressed: () => showToast(context, '3 things need you today', subtitle: 'See Needs action below', kind: ToastKind.info)),
          ],
        ),
        AppButton('Add client', icon: Icons.add_rounded, expand: true, onPressed: () => showAddClientSheet(context)),
        AdminStatGrid([
          for (var i = 0; i < AdminMock.dashboardStats.length; i++)
            AdminStat(AdminMock.dashboardStats[i].$1, AdminMock.dashboardStats[i].$2, AdminMock.dashboardStats[i].$3,
                icon: icons[i], tone: AdminMock.dashboardStats[i].$4),
        ]),
        const _Glance(),
        const _NeedsActionCard(),
        const _TrainerPerformanceCard(),
        const _AtRiskCard(),
        const _RecentActivityCard(),
      ],
    );
  }
}

// ------------------------------------------------------------- At a glance

class _Glance extends StatelessWidget {
  const _Glance();

  static const _icons = [
    Icons.people_outline_rounded,
    Icons.badge_outlined,
    Icons.fact_check_outlined,
    Icons.assignment_outlined,
    Icons.restaurant_outlined,
    Icons.event_repeat_rounded,
  ];

  void _open(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go(Routes.aClients);
      case 1:
        context.go(Routes.aTrainers);
      case 3:
        context.go(Routes.aApprovals);
      case 4:
        context.go(context.rolePath(Routes.nutrition));
      case 5:
        context.go(context.rolePath(Routes.programs));
      default:
        showToast(context, '12 check-ins to review', subtitle: 'Trainers review them from their Check-ins tab', kind: ToastKind.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    const g = AdminMock.glance;
    final rows = <Widget>[];
    for (var i = 0; i < g.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _tile(context, i)),
            const SizedBox(width: 10),
            Expanded(child: _tile(context, i + 1)),
          ],
        ),
      ));
    }
    return Spaced(gap: 10, children: rows);
  }

  Widget _tile(BuildContext context, int i) {
    final t = AdminMock.glance[i];
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: () => _open(context, i),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: t.warn ? AppColors.warnBg : AppColors.sub, borderRadius: BorderRadius.circular(8)),
            child: Icon(_icons[i], size: 15, color: t.warn ? AppColors.warnText : AppColors.text2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.value, style: AppText.bodyBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800, height: 1.15)),
                Text(t.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 12.5, height: 1.3)),
                const SizedBox(height: 2),
                Text(t.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11.5, height: 1.35, color: t.warn ? AppColors.warnText : AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Needs action

class _NeedsActionCard extends StatefulWidget {
  const _NeedsActionCard();

  @override
  State<_NeedsActionCard> createState() => _NeedsActionCardState();
}

class _NeedsActionCardState extends State<_NeedsActionCard> {
  final _gone = <String>{};
  ActionKind? _kind;
  bool _more = false;

  static const _icons = {
    ActionKind.approval: Icons.how_to_reg_outlined,
    ActionKind.client: Icons.person_outline_rounded,
    ActionKind.checkin: Icons.fact_check_outlined,
    ActionKind.trainer: Icons.badge_outlined,
    ActionKind.program: Icons.event_note_outlined,
  };

  void _dismiss(NeedsAction a) {
    setState(() => _gone.add(a.id));
    showToast(context, 'Dismissed', subtitle: a.title, kind: ToastKind.del, onUndo: () => setState(() => _gone.remove(a.id)));
  }

  void _act(NeedsAction a) {
    switch (a.kind) {
      case ActionKind.approval:
        context.go(Routes.aApprovals);
      case ActionKind.client:
        context.go(Routes.aClients);
      case ActionKind.trainer:
        context.go(Routes.aTrainers);
      case ActionKind.program:
        context.go(context.rolePath(Routes.programs));
      case ActionKind.checkin:
        context.go(Routes.aActivity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = AdminMock.needsAction.where((a) => !_gone.contains(a.id)).toList();
    final kind = _kind != null && open.any((a) => a.kind == _kind) ? _kind : null;
    final list = open.where((a) => kind == null || a.kind == kind).toList();
    final rows = _more ? list : list.take(5).toList();
    final kinds = <(String, int)>[
      ('All', open.length),
      for (final k in ActionKind.values)
        if (open.any((a) => a.kind == k)) (k.label, open.where((a) => a.kind == k).length),
    ];

    return TitledCard(
      title: 'Needs action',
      count: '${open.length}',
      trailing: Text('Oldest first', style: AppText.caption),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KindChips(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            items: kinds,
            value: kind?.label ?? 'All',
            onChanged: (l) => setState(() => _kind = ActionKind.values.where((k) => k.label == l).firstOrNull),
          ),
          for (final a in rows) _row(a),
          if (list.length > 5) ShowMoreButton(_more ? 'Show less' : 'Show all ${list.length}', onTap: () => setState(() => _more = !_more)),
          if (open.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Text('All clear. Nothing needs you right now.', style: AppText.caption),
            ),
        ],
      ),
    );
  }

  Widget _row(NeedsAction a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: a.kind.color.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(_icons[a.kind], size: 18, color: a.kind.color.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text(a.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton.outline(a.cta, small: true, onPressed: () => _act(a)),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
            onPressed: () => _dismiss(a),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------ Trainer performance

class _TrainerPerformanceCard extends StatefulWidget {
  const _TrainerPerformanceCard();

  @override
  State<_TrainerPerformanceCard> createState() => _TrainerPerformanceCardState();
}

class _TrainerPerformanceCardState extends State<_TrainerPerformanceCard> {
  bool _more = false;
  String _range = 'This week';

  @override
  Widget build(BuildContext context) {
    const all = AdminMock.trainerPerformance;
    final rows = _more ? all : all.take(5).toList();
    return TitledCard(
      title: 'Trainer performance',
      subtitle: 'Lowest adherence first',
      trailing: SizedBox(
        width: 128,
        child: PickerField(
          value: _range,
          options: const ['This week', 'Last week', 'This month'],
          onChanged: (v) => setState(() => _range = v),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _row(rows[i]),
          ],
          if (all.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ShowMoreButton(_more ? 'Show less' : 'Show all ${all.length} trainers', onTap: () => setState(() => _more = !_more)),
            ),
        ],
      ),
    );
  }

  Widget _row(TrainerPerformance t) {
    final over = t.clients > 20;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Avatar(t.initials, size: 30, color: t.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: AppText.bodyBold),
                Text.rich(
                  TextSpan(
                    style: AppText.caption.copyWith(fontSize: 12.5),
                    children: [
                      TextSpan(
                        text: '${t.clients} / 20 clients',
                        style: over ? const TextStyle(color: AppColors.badText, fontWeight: FontWeight.w700) : null,
                      ),
                      TextSpan(text: '  · Avg reply ${t.reply}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MiniBar(t.adherence / 100, width: 56, height: 6),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('${t.adherence}%', style: AppText.caption)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- At risk

class _AtRiskCard extends StatefulWidget {
  const _AtRiskCard();

  @override
  State<_AtRiskCard> createState() => _AtRiskCardState();
}

class _AtRiskCardState extends State<_AtRiskCard> {
  bool _more = false;
  final _reminded = <String>{};

  void _remindAll() {
    showConfirmDialog(
      context,
      title: 'Remind 7 at-risk clients?',
      message: "Each client gets a push and WhatsApp message to log today's workout. Their trainer is copied.\n\n"
          'Skipping clients reminded in the last 24 hours (2).',
      confirmLabel: 'Remind 5 clients',
      icon: Icons.notifications_active_outlined,
    ).then((ok) {
      if (!ok || !mounted) return;
      setState(() => _reminded.addAll(AdminMock.atRisk.map((r) => r.name)));
      showToast(context, 'Reminders sent to 5 clients', subtitle: 'Push and WhatsApp · trainers copied', kind: ToastKind.ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    const all = AdminMock.atRisk;
    final rows = _more ? all : all.take(3).toList();
    return TitledCard(
      title: 'At-risk clients',
      count: '${all.length}',
      trailing: TextButton(onPressed: _remindAll, child: const Text('Remind all')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 12, 7),
              child: Row(
                children: [
                  Avatar(r.initials, size: 32, color: r.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                        Text(r.why, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _reminded.contains(r.name)
                      ? const AppBadge('Reminded', tone: BadgeTone.ok, icon: Icons.check_rounded)
                      : AppButton.outline('Remind', small: true, onPressed: () {
                          setState(() => _reminded.add(r.name));
                          showToast(context, '${r.name.split(' ').first} reminded', subtitle: 'Push and WhatsApp', kind: ToastKind.ok,
                              onUndo: () => setState(() => _reminded.remove(r.name)));
                        }),
                ],
              ),
            ),
          ShowMoreButton(_more ? 'Show less' : 'Show all ${all.length}', onTap: () => setState(() => _more = !_more)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------- Recent activity

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return TitledCard(
      title: 'Recent activity',
      trailing: TextButton(
        onPressed: () {
          context.go(Routes.aActivity);
        },
        child: const Text('View all'),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            for (final a in AdminMock.recentActivity)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                child: Row(
                  children: [
                    Avatar(a.initials, size: 28, color: a.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppText.secondary.copyWith(color: AppColors.text2),
                          children: [
                            TextSpan(text: a.who, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                            TextSpan(text: ' ${a.text}'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(a.when, style: AppText.caption),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
