import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import '../clients/add_client_sheet.dart';
import '../clients/admin_ui.dart';
import '../clients/invite_links_sheet.dart';
import 'review_signup_sheet.dart';

/// Design: ApprovalsMobile.dc.html — sign-ups waiting for the owner, and history.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  bool _history = false;
  String _query = '';
  FilterValues _filters = {};

  List<FilterGroup> get _groups => _history ? AdminMock.historyFilters : AdminMock.waitFilters;

  bool _matchWait(SignupRequest r) {
    final f = _filters;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !'${r.name} ${r.phone} ${r.email}'.toLowerCase().contains(q)) return false;
    if (f['inv'] != null && f['inv'] != 'Anyone' && r.invitedBy != f['inv']) return false;
    if (f['setup'] != null && f['setup'] != 'Any' && (f['setup'] == 'All 5 done') != (r.steps == 5)) return false;
    if (f['wait'] != null && f['wait'] != 'Any time' && r.hoursWaiting <= (f['wait'] == 'Over 2 days' ? 48 : 24)) return false;
    if (f['health'] != null && f['health'] != 'Any' && (f['health'] == 'Has a health note') != r.healthNote.isNotEmpty) return false;
    if (f['dev'] != null && f['dev'] != 'Any' && r.device != f['dev']) return false;
    return true;
  }

  bool _matchHist(DecisionRecord h) {
    final f = _filters;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !'${h.name} ${h.why} ${h.by}'.toLowerCase().contains(q)) return false;
    if (f['dec'] != null && f['dec'] != 'Any' && (h.decision == Decision.approved ? 'Approved' : 'Rejected') != f['dec']) return false;
    if (f['by'] != null && f['by'] != 'Anyone' && h.by != f['by']) return false;
    if (f['when'] != null && f['when'] != 'All time' && h.daysAgo > (f['when'] == 'Last 7 days' ? 7 : 30)) return false;
    return true;
  }

  void _setTab(bool history) => setState(() {
        _history = history;
        _filters = {};
        _query = '';
      });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(approvalsProvider);
    final groups = _groups;
    final waiting = s.waiting.where(_matchWait).toList();
    final hist = s.history.where(_matchHist).toList();
    void clear() => setState(() => _filters = {});

    return PageScroll(
      children: [
        PageHeader(
          title: 'Approvals',
          subtitle: '${s.waiting.length} people waiting · oldest waiting 2 days · new sign-ups from invite links land here',
        ),
        Row(
          children: [
            Expanded(child: AppButton.outline('Invite link', icon: Icons.link_rounded, onPressed: () => showInviteLinksSheet(context))),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Add client', icon: Icons.add_rounded, onPressed: () => showAddClientSheet(context))),
          ],
        ),
        CountTabs<bool>(
          items: [(false, 'Waiting', s.waiting.length), (true, 'History', s.history.length)],
          value: _history,
          onChanged: _setTab,
        ),
        SearchField(
          key: ValueKey(_history),
          hint: _history ? 'Search history' : 'Search name, phone or email',
          onChanged: (v) => setState(() => _query = v),
          trailing: FilterButton(
            count: _filters.activeCount(groups),
            onTap: () => showFilterSheet(context, groups: groups, values: _filters, onChanged: (v) => setState(() => _filters = v)),
          ),
        ),
        if (_filters.activeCount(groups) > 0) ActiveFilterChips(groups: groups, values: _filters, onChanged: (v) => setState(() => _filters = v)),
        if (!_history) ...[
          if (waiting.isEmpty)
            _NoneCard(text: s.waiting.isEmpty ? 'No one is waiting. New sign-ups show up here.' : 'No one matches these filters.', onClear: clear),
          for (final r in waiting) _RequestCard(request: r, onReview: () => showReviewSignupSheet(context, list: waiting, start: r.id)),
          Text(
            '${waiting.length < s.waiting.length ? 'Showing ${waiting.length} of ${s.waiting.length}. ' : ''}Sorted oldest first. Amber after 1 day, red after 2 days.',
            style: AppText.caption,
          ),
        ] else ...[
          if (hist.isEmpty) _NoneCard(text: 'Nothing matches these filters.', onClear: clear),
          for (final h in hist) _HistoryCard(record: h),
          Text(
            'Rejected people cannot log in. Rejected by mistake? Move them back to Waiting. To stop an approved client, pause them from Clients.',
            style: AppText.caption,
          ),
        ],
      ],
    );
  }
}

class _NoneCard extends StatelessWidget {
  const _NoneCard({required this.text, required this.onClear});
  final String text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: EmptyState(
        icon: Icons.how_to_reg_outlined,
        title: text,
        action: AppButton.outline('Clear filters', small: true, onPressed: onClear),
      ),
    );
  }
}

// ------------------------------------------------------------- Waiting

/// Waiting-time colour: amber after 1 day, red after 2 days.
Color waitColor(WaitLevel w) => switch (w) {
      WaitLevel.late => const Color(0xFFB91C1C),
      WaitLevel.old => const Color(0xFFB45309),
      WaitLevel.normal => AppColors.text2,
    };

/// 5 setup pips (.ap-pips).
class SetupPips extends StatelessWidget {
  const SetupPips(this.done, {super.key});
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 12,
            height: 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(color: i < done ? AppColors.ok : AppColors.sub, borderRadius: BorderRadius.circular(3)),
          ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onReview});
  final SignupRequest request;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return AppCard(
      onTap: onReview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(r.initials, size: 40, color: r.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(r.name, style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                        if (r.movedBack) const PlainBadge('Moved back', tone: BadgeTone.info),
                      ],
                    ),
                    Text(r.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                  ],
                ),
              ),
              Text(r.wait, style: AppText.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: waitColor(r.waitLevel))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('+91 ${r.phone}', style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2, fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 10),
              Avatar(r.inviterInitials, size: 20, color: r.inviterColor),
              const SizedBox(width: 5),
              Expanded(child: Text(r.invitedBy, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontSize: 12.5))),
              Text(r.device, style: AppText.caption),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SetupPips(r.steps),
              const SizedBox(width: 4),
              Text('${r.steps} of 5', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              if (r.healthNote.isNotEmpty) const PlainBadge('Health note', tone: BadgeTone.warn) else Text('No health note', style: AppText.caption),
              const Spacer(),
              AppButton.outline('Review', small: true, onPressed: onReview),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- History

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.record});
  final DecisionRecord record;

  void _moveBack(BuildContext context, WidgetRef ref) {
    final h = record;
    final ok = h.decision == Decision.approved;
    final tr = h.why.replaceFirst('Trainer ', '');
    final points = ok
        ? [
            'She cannot log in until someone approves her again. Her data stays.',
            '$tr stops seeing her as a client. Plans you assigned are paused, not deleted.',
            'She shows at the top of Waiting with a "Moved back" tag.',
          ]
        : [
            'Her rejection is undone. She still cannot log in until you approve her.',
            'The reason "${h.why}" stays in her history.',
            'She shows at the top of Waiting with a "Moved back" tag.',
          ];
    showAppSheet(
      context,
      title: 'Move ${h.first} back to Waiting?',
      subtitle: 'You can decide again from the Waiting tab.',
      builder: (ctx) => Spaced(
        gap: 14,
        children: [
          Row(
            children: [
              Avatar(h.initials, size: 36, color: h.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: AppText.bodyBold),
                    Text('${ok ? 'Approved' : 'Rejected'} by ${h.by} · ${h.when}', style: AppText.caption),
                  ],
                ),
              ),
              AppBadge(ok ? 'Approved' : 'Rejected', tone: ok ? BadgeTone.ok : BadgeTone.bad),
            ],
          ),
          const FieldLabel('What happens'),
          BulletList(points),
          const SwitchRow(title: 'Tell her by email', subtitle: 'Only if you want her to know it is being looked at again'),
        ],
      ),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Move back', icon: Icons.undo_rounded, onPressed: () {
          ref.read(approvalsProvider.notifier).moveBack(h);
          showToast(ctx, '${h.first} moved back to Waiting', subtitle: 'Decide again from the Waiting tab', kind: ToastKind.ok);
          Navigator.of(ctx).pop();
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = record;
    final ok = h.decision == Decision.approved;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Avatar(h.initials, size: 40, color: h.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 14.5))),
                    const SizedBox(width: 6),
                    AppBadge(ok ? 'Approved' : 'Rejected', tone: ok ? BadgeTone.ok : BadgeTone.bad),
                  ],
                ),
                Text('Signed up ${h.signedUp}', style: AppText.caption),
                const SizedBox(height: 4),
                Text(h.why, style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.text2)),
                Text('${h.by} · ${h.when}', style: AppText.caption),
              ],
            ),
          ),
          if (h.decision == Decision.rejected)
            IconButton(
              tooltip: 'Move back to Waiting',
              icon: const Icon(Icons.undo_rounded, color: AppColors.muted, size: 20),
              onPressed: () => _moveBack(context, ref),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
