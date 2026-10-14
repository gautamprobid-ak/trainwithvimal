import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import '../clients/admin_ui.dart';

/// Colours of the timeline icons per kind (.tp-tl-ic.k-*).
const _kindColors = <String, (Color, Color)>{
  'Check-in': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
  'Workout': (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
  'Meal': (Color(0xFFFEF3C7), Color(0xFFB45309)),
  'Body': (Color(0xFFDCFCE7), Color(0xFF15803D)),
  'Plan': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
  'Client': (Color(0xFFCCFBF1), Color(0xFF0F766E)),
};

const _icons = {
  ActivityIcon.clip: Icons.assignment_outlined,
  ActivityIcon.dumbbell: Icons.fitness_center_rounded,
  ActivityIcon.food: Icons.restaurant_rounded,
  ActivityIcon.scale: Icons.monitor_weight_outlined,
  ActivityIcon.edit: Icons.edit_outlined,
  ActivityIcon.users: Icons.people_outline_rounded,
  ActivityIcon.bolt: Icons.bolt_rounded,
  ActivityIcon.play: Icons.play_circle_outline_rounded,
  ActivityIcon.db: Icons.edit_note_rounded,
  ActivityIcon.chat: Icons.chat_bubble_outline_rounded,
  ActivityIcon.login: Icons.login_rounded,
};

/// Round timeline icon for an entry.
class ActivityIconDot extends StatelessWidget {
  const ActivityIconDot(this.entry, {super.key, this.size = 28});
  final ActivityEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _kindColors[entry.kind] ?? (AppColors.sub, AppColors.muted);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(_icons[entry.icon], size: size * .5, color: fg),
    );
  }
}

/// Activity timeline with a date range, kind chips, day groups and
/// "Show more" (Activity log page and the trainer profile's Activity tab).
class ActivityFeed extends StatefulWidget {
  const ActivityFeed({super.key, required this.days, required this.kinds, this.filter, this.sourceOf, this.toolbar});
  final List<ActivityDay> days;
  final List<String> kinds;

  /// Extra filter (search, Who / Person filters).
  final bool Function(ActivityEntry)? filter;

  /// Where the change came from (shown on long press).
  final String Function(ActivityEntry)? sourceOf;

  /// Widgets shown left of the date range button.
  final Widget? toolbar;

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  String _range = 'Last 7 days';
  String _kind = 'All';
  int _limit = 8;

  @override
  Widget build(BuildContext context) {
    final maxDays = AdminMock.activityRanges.firstWhere((r) => r.$1 == _range).$2;
    final inRange = [
      for (final d in widget.days)
        if (d.daysAgo <= maxDays) (d, d.items.where(widget.filter ?? (_) => true).toList()),
    ];
    bool ok(ActivityEntry e) => _kind == 'All' || e.kind == _kind;
    final total = inRange.fold<int>(0, (a, d) => a + d.$2.where(ok).length);

    var left = _limit;
    final shown = <(ActivityDay, int, List<ActivityEntry>)>[];
    for (final (d, xs) in inRange) {
      final all = xs.where(ok).toList();
      final items = all.take(left < 0 ? 0 : left).toList();
      left -= items.length;
      if (items.isNotEmpty) shown.add((d, all.length, items));
    }
    final shownCount = shown.fold<int>(0, (a, d) => a + d.$3.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: widget.toolbar ?? const SizedBox()),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              child: PickerField(
                value: _range,
                options: [for (final r in AdminMock.activityRanges) r.$1],
                onChanged: (v) => setState(() {
                  _range = v;
                  _limit = 8;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        KindChips(
          items: [
            for (final k in widget.kinds)
              (k, k == 'All' ? inRange.fold<int>(0, (a, d) => a + d.$2.length) : inRange.fold<int>(0, (a, d) => a + d.$2.where((x) => x.kind == k).length)),
          ],
          value: _kind,
          onChanged: (k) => setState(() {
            _kind = k;
            _limit = 8;
          }),
        ),
        for (final (d, n, items) in shown) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text.rich(TextSpan(
              text: d.label.toUpperCase(),
              style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: .5),
              children: [TextSpan(text: '  ·  $n', style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0))],
            )),
          ),
          for (var i = 0; i < items.length; i++) _TimelineRow(entry: items[i], last: i == items.length - 1, source: widget.sourceOf?.call(items[i])),
        ],
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Nothing matches. Try a longer date range or fewer filters.', style: AppText.secondary, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(total > 0 ? 'Showing $shownCount of $total' : '', style: AppText.caption)),
            if (shownCount < total) AppButton.outline('Show more', small: true, onPressed: () => setState(() => _limit += 8)),
          ],
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last, this.source});
  final ActivityEntry entry;
  final bool last;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final body = AppText.secondary.copyWith(fontSize: 13.5, color: AppColors.text2, height: 1.35);
    Widget row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              ActivityIconDot(e),
              if (!last) Expanded(child: Container(width: 1.5, margin: const EdgeInsets.only(top: 4), color: AppColors.line)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(style: body, children: [
                    if (e.pre.isNotEmpty) TextSpan(text: '${e.pre} '),
                    TextSpan(text: e.who, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                    TextSpan(text: e.post),
                  ])),
                  if (e.isChange) ...[
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(e.old, style: AppText.caption.copyWith(fontSize: 12.5, decoration: TextDecoration.lineThrough)),
                        const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.muted),
                        Text(e.now, style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.accentText, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  if (e.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(e.note, style: AppText.caption.copyWith(fontSize: 12.5)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(e.when, style: AppText.caption.copyWith(fontSize: 11.5))),
        ],
      ),
    );
    if (source != null) row = Tooltip(message: source!, triggerMode: TooltipTriggerMode.longPress, child: row);
    return row;
  }
}
