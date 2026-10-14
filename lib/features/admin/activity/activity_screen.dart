import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import '../clients/admin_ui.dart';
import 'activity_feed.dart';

/// Design: ActivityMobile.dc.html — every change by the team, clients and system.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _query = '';
  FilterValues _filters = {};

  static const _roles = {
    'Team': [ActivityRole.admin, ActivityRole.trainer],
    'Clients': [ActivityRole.client],
    'Automations': [ActivityRole.system],
  };

  static String _source(ActivityEntry e) => switch (e.role) {
        ActivityRole.admin => 'Admin · Web',
        ActivityRole.trainer => 'Trainer · Web',
        ActivityRole.client => 'Client · Android app',
        ActivityRole.system => 'Automation · Push and WhatsApp',
      };

  bool _match(ActivityEntry e) {
    final role = _filters['role'];
    if (role != null && role != 'Everyone' && !_roles[role]!.contains(e.role)) return false;
    final by = _filters['by'];
    if (by != null && by != 'Anyone' && e.who != by) return false;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !'${e.pre} ${e.who}${e.post} ${e.note} ${e.old} ${e.now}'.toLowerCase().contains(q)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const groups = AdminMock.activityFilters;
    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Activity log',
          subtitle: 'Every change by your team, your clients and the system.',
          actions: [
            AppIconButton(Icons.download_rounded,
                tooltip: 'Export', onPressed: () => showToast(context, 'Export started', subtitle: 'Activity log · CSV file', kind: ToastKind.ok)),
          ],
        ),
        SearchField(
          hint: 'Search person, client or item',
          onChanged: (v) => setState(() => _query = v),
          trailing: FilterButton(
            count: _filters.activeCount(groups),
            onTap: () => showFilterSheet(context, groups: groups, values: _filters, onChanged: (v) => setState(() => _filters = v)),
          ),
        ),
        if (_filters.activeCount(groups) > 0) ActiveFilterChips(groups: groups, values: _filters, onChanged: (v) => setState(() => _filters = v)),
        AppCard(
          child: ActivityFeed(
            days: AdminMock.activity,
            kinds: AdminMock.activityKinds,
            filter: _match,
            sourceOf: _source,
            toolbar: Text('Timeline', style: AppText.cardTitle),
          ),
        ),
      ],
    );
  }
}
