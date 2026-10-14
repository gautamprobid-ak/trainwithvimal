import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';

typedef _M = ClientProfileMock;

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String filter = 'all';
  bool all = false;

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final months = [
      for (final m in _M.history)
        HistoryMonth(m.month, m.summary, m.items.where((e) => filter == 'all' || _M.historyKind[e.kind] == filter).toList()),
    ].where((m) => m.items.isNotEmpty).toList();
    final shown = all ? months : months.take(4).toList();
    return Spaced(
      children: [
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final s in _M.historySummary)
              SizedBox(
                width: w,
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(s.$2, style: AppText.bodyBold.copyWith(fontSize: 17)),
                    Text(s.$3, style: AppText.caption.copyWith(color: s.$4 ? AppColors.okText : AppColors.muted, fontWeight: s.$4 ? FontWeight.w700 : null)),
                  ]),
                ),
              ),
          ]);
        }),
        CpCard(
          title: 'Plans over time',
          cap: 'Every plan ${c.first} has been on, and who coached her. Tap a bar for dates.',
          child: const _Timeline(),
        ),
        CpCard(
          title: 'Journey',
          cap: 'Everything that mattered, month by month. Day to day actions are in Activity.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  Expanded(child: FChipBar(items: _M.historyFilters, value: filter, onChanged: (v) => setState(() => filter = v))),
                  const SizedBox(width: 8),
                  AppButton.outline('Export', icon: Icons.download_rounded, small: true, onPressed: () => showToast(context, 'History exported', subtitle: '${c.name} · PDF', kind: ToastKind.ok)),
                ]),
              ),
              for (final m in shown) _Month(m, c),
              if (!all && months.length > 4)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: AppButton.outline('Show earlier months', small: true, expand: true, onPressed: () => setState(() => all = true)),
                )
              else
                const SizedBox(height: 10),
            ],
          ),
        ),
        CpCard(
          title: 'About her journey',
          child: KvGrid([for (final (k, v) in _M.journey) (k, k == 'Trainer' ? '${c.trainer} · only trainer so far' : v)], columns: 1),
        ),
        CpCard(
          title: 'Health over time',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: [
              for (final (tone, t, d) in _M.healthOverTime)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.only(top: 5), child: _Dot(tone == 'warn' ? AppColors.warn : tone == 'ok' ? AppColors.ok : AppColors.line2)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                        Text(d, style: AppText.caption),
                      ]),
                    ),
                  ]),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Month extends StatelessWidget {
  const _Month(this.m, this.c);
  final HistoryMonth m;
  final ClientProfileController c;

  static const _colors = {
    'plan': AppColors.accent,
    'trainer': AppColors.accent,
    'check': Color(0xFF8B5CF6),
    'form': Color(0xFF8B5CF6),
    'mile': AppColors.ok,
    'goal': AppColors.warn,
    'health': AppColors.bad,
    'acct': AppColors.line2,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(m.month, style: AppText.bodyBold),
          Text(m.summary, style: AppText.caption),
          const SizedBox(height: 6),
          for (final e in m.items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line, width: 2))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Transform.translate(offset: const Offset(-6, 4), child: _Dot(_colors[e.kind]!)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(e.title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                      if (e.badge.isNotEmpty) AppBadge(e.badge, tone: e.tone),
                    ]),
                    const SizedBox(height: 2),
                    Text(e.detail, style: AppText.secondary.copyWith(fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text('${e.when} · ${c.r(e.who)}', style: AppText.caption.copyWith(fontSize: 11.5)),
                  ]),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Gantt-like "Plans over time" (hg): one row per plan type, bars per plan, today line.
class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    const trackW = 760.0;
    final c = ProfileScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 22),
                  for (final r in _M.timelineRows)
                    SizedBox(height: 34, child: Align(alignment: Alignment.centerLeft, child: Text(r.$1, style: AppText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)))),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: trackW,
                    height: 22 + 34.0 * _M.timelineRows.length,
                    child: Stack(
                      children: [
                        for (final (m, x) in _M.timelineMonths) ...[
                          Positioned(left: x * trackW, top: 0, child: Text(m, style: AppText.caption.copyWith(fontSize: 11))),
                          Positioned(left: x * trackW, top: 18, bottom: 0, child: Container(width: 1, color: AppColors.line)),
                        ],
                        Positioned(left: _M.timelineToday * trackW, top: 14, bottom: 0, child: Container(width: 2, color: AppColors.bad)),
                        for (final (ri, r) in _M.timelineRows.indexed)
                          for (final b in r.$2)
                            Positioned(
                              left: b.start * trackW,
                              top: 22 + ri * 34.0 + 6,
                              width: b.width * trackW - 2,
                              height: 22,
                              child: _Bar(b, label: b.label == 'Aman Verma' ? c.trainer : b.label),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Wrap(spacing: 14, runSpacing: 6, children: const [
            _Key(AppColors.accent, 'Now'),
            _Key(Color(0xFFDCEBDF), 'Completed'),
            _Key(Color(0xFFEDEDE8), 'Replaced'),
            _Key(Colors.white, 'Up next', dashed: true),
            _Key(AppColors.bad, 'Today'),
          ]),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.b, {required this.label});
  final TimelineBar b;
  final String label;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (b.state) {
      'cur' => (AppColors.accent, Colors.white),
      'done' => (const Color(0xFFDCEBDF), AppColors.okText),
      'old' => (const Color(0xFFEDEDE8), AppColors.muted),
      _ => (Colors.white, AppColors.accentText),
    };
    return Tooltip(
      message: b.tip,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: b.state == 'next' ? Border.all(color: AppColors.accent) : null,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.color, this.label, {this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3), border: dashed ? Border.all(color: AppColors.accent) : null),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.caption.copyWith(fontSize: 11.5)),
      ]);
}
