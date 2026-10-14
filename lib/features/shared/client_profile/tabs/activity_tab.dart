import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';

typedef _M = ClientProfileMock;

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});
  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  String range = 'Last 7 days';
  String kind = 'All';
  int limit = 8;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final days = _M.activityRanges.firstWhere((r) => r.$1 == range).$2;
    final inRange = _M.activity.where((d) => d.daysAgo <= days).toList();
    bool ok(ActivityItem x) => kind == 'All' || x.kind == kind;
    final total = inRange.fold(0, (a, d) => a + d.items.where(ok).length);
    var left = limit;
    final shown = <(ActivityDay, List<ActivityItem>, int)>[];
    for (final d in inRange) {
      final all = d.items.where(ok).toList();
      final items = all.take(left.clamp(0, 999)).toList();
      left -= items.length;
      if (items.isNotEmpty) shown.add((d, items, all.length));
    }
    final n = shown.fold(0, (a, d) => a + d.$2.length);
    return CpCard(
      title: 'Activity',
      cap: 'Everything ${c.first} and her coaches did in the app',
      trailing: AppButton.outline(range, icon: Icons.calendar_today_outlined, small: true, onPressed: () async {
        final v = await pickOption(context, title: 'Date range', options: [for (final r in _M.activityRanges) r.$1], current: range);
        if (v != null) setState(() {
          range = v;
          limit = 8;
        });
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final k in _M.activityKinds) ...[
                  FChip(
                    k,
                    selected: k == kind,
                    count: k == 'All' ? inRange.fold(0, (a, d) => a! + d.items.length) : inRange.fold(0, (a, d) => a! + d.items.where((x) => x.kind == k).length),
                    onTap: () => setState(() {
                      kind = k;
                      limit = 8;
                    }),
                  ),
                  const SizedBox(width: 6),
                ],
              ]),
            ),
          ),
          for (final (d, items, count) in shown) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                Text(d.label, style: AppText.bodyBold.copyWith(fontSize: 13)),
                const SizedBox(width: 6),
                CpCount(count),
              ]),
            ),
            for (final a in items) _Row(a, c),
          ],
          if (total == 0)
            Padding(padding: const EdgeInsets.all(16), child: Text('Nothing matches. Try a longer date range or fewer filters.', style: AppText.secondary)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(children: [
              Expanded(child: Text(total > 0 ? 'Showing $n of $total' : '', style: AppText.caption)),
              if (n < total) AppButton.outline('Show more', small: true, onPressed: () => setState(() => limit += 8)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.a, this.c);
  final ActivityItem a;
  final ClientProfileController c;

  static const _icons = {
    'food': (Icons.restaurant_rounded, Tint.amber),
    'clip': (Icons.fact_check_outlined, Tint.purple),
    'edit': (Icons.edit_outlined, Tint.blue),
    'dumb': (Icons.fitness_center_rounded, Tint.green),
    'play': (Icons.play_circle_outline_rounded, Tint.pink),
    'scale': (Icons.monitor_weight_outlined, Tint.teal),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = _icons[a.icon]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintIcon(icon, tint: tint, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(style: AppText.body.copyWith(fontSize: 13.5), children: [
                TextSpan(text: c.r(a.who), style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: a.post),
              ])),
              if (a.old.isNotEmpty)
                Row(children: [
                  Text(a.old, style: AppText.caption.copyWith(decoration: TextDecoration.lineThrough)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.muted)),
                  Text(a.nw, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
                ])
              else if (a.note.isNotEmpty)
                Text(a.note, style: AppText.caption),
            ]),
          ),
          Tooltip(message: c.r(a.source), triggerMode: TooltipTriggerMode.tap, child: Text(a.when, style: AppText.caption.copyWith(fontSize: 11.5))),
        ],
      ),
    );
  }
}
