import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';
import 'checkin_review_state.dart';
import 'checkin_review_view.dart';
import 'photo_viewer.dart';

enum _Tab { review, reviewed, all }

/// Design: TrainerCheckinsMobile.dc.html — list of check-ins, tap one to review it.
class TrainerCheckinsScreen extends ConsumerStatefulWidget {
  const TrainerCheckinsScreen({super.key});

  @override
  ConsumerState<TrainerCheckinsScreen> createState() => _TrainerCheckinsScreenState();
}

class _TrainerCheckinsScreenState extends ConsumerState<TrainerCheckinsScreen> {
  _Tab _tab = _Tab.review;
  String _kind = 'all';
  String _query = '';
  String? _sel;
  bool _detail = false;

  bool _inTab(TrainerCheckin c, CheckinReviewState s) => switch (_tab) {
        _Tab.all => true,
        _Tab.review => !s.isDone(c.id),
        _Tab.reviewed => s.isDone(c.id),
      };

  List<TrainerCheckin> _list(CheckinReviewState s) {
    final q = _query.trim().toLowerCase();
    final l = TrainerMock.checkins
        .where((c) => _inTab(c, s) && (_kind == 'all' || c.kind == _kind) && (q.isEmpty || c.client.toLowerCase().contains(q)))
        .toList();
    l.sort((a, b) {
      final da = s.isDone(a.id), db = s.isDone(b.id);
      if (da != db) return da ? 1 : -1;
      return da ? a.hours.compareTo(b.hours) : b.hours.compareTo(a.hours);
    });
    return l;
  }

  void _mark(TrainerCheckin c, List<TrainerCheckin> list) {
    final s = ref.read(checkinReviewProvider);
    final hadReply = s.replyOf(c.id).trim().isNotEmpty;
    final next = s.toReview.where((x) => x.id != c.id && (_kind == 'all' || x.kind == _kind)).firstOrNull;
    final before = ref.read(checkinReviewProvider.notifier).markReviewed(c.id);
    setState(() => _sel = _tab == _Tab.review && next != null ? next.id : c.id);
    if (_tab == _Tab.review && next == null) setState(() => _detail = false);
    showToast(
      context,
      '${c.firstName}’s check-in reviewed',
      subtitle: hadReply ? 'Your reply was sent' : 'Moved to Reviewed',
      kind: ToastKind.ok,
      onUndo: () {
        ref.read(checkinReviewProvider.notifier).restore(before);
        if (mounted) setState(() => _sel = c.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(checkinReviewProvider);
    final list = _list(s);
    final sel = list.where((c) => c.id == _sel).firstOrNull ?? list.firstOrNull;
    final toRev = s.toReview;
    final showDetail = _detail && sel != null;

    return PageScroll(
      children: [
        PageHeader(
          title: 'Check-ins',
          subtitle: toRev.isNotEmpty ? '${toRev.length} to review · oldest from ${toRev.first.age} ago' : 'All check-ins reviewed',
          actions: const [TrainerProfileButton()],
        ),
        if (showDetail)
          _Detail(
            checkin: sel,
            state: s,
            list: list,
            onBack: () => setState(() => _detail = false),
            onSelect: (id) => setState(() => _sel = id),
            onMark: () => _mark(sel, list),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Tabs(
                  tab: _tab,
                  counts: {
                    _Tab.review: toRev.length,
                    _Tab.reviewed: TrainerMock.checkins.length - toRev.length,
                    _Tab.all: TrainerMock.checkins.length,
                  },
                  onChanged: (t) => setState(() {
                    _tab = t;
                    _sel = null;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: SearchField(hint: 'Search client', onChanged: (v) => setState(() => _query = v)),
                ),
                ChipStrip(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  children: [
                    for (final (id, label) in TrainerMock.checkinKinds)
                      CountChip(
                        label,
                        selected: _kind == id,
                        count: TrainerMock.checkins.where((c) => _inTab(c, s) && (id == 'all' || c.kind == id)).length,
                        onTap: () => setState(() {
                          _kind = id;
                          _sel = null;
                        }),
                      ),
                  ],
                ),
                _Items(
                  list: list,
                  state: s,
                  selected: sel?.id,
                  emptyTitle: _tab == _Tab.review ? 'All caught up' : 'Nothing here',
                  emptyText: _tab == _Tab.review ? 'New check-ins show up here as clients send them.' : 'Try another type.',
                  onPick: (id) => setState(() {
                    _sel = id;
                    _detail = true;
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.counts, required this.onChanged});
  final _Tab tab;
  final Map<_Tab, int> counts;
  final ValueChanged<_Tab> onChanged;

  static const _labels = {_Tab.review: 'To review', _Tab.reviewed: 'Reviewed', _Tab.all: 'All'};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          for (final t in _Tab.values) ...[
            InkWell(
              onTap: () => onChanged(t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t == tab ? AppColors.text : Colors.transparent, width: 2))),
                child: Row(
                  children: [
                    Text(_labels[t]!,
                        style: AppText.secondary.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: t == tab ? AppColors.text : AppColors.muted)),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(9)),
                      child: Text('${counts[t]}', style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.list, required this.state, required this.selected, required this.onPick, required this.emptyTitle, required this.emptyText});
  final List<TrainerCheckin> list;
  final CheckinReviewState state;
  final String? selected;
  final ValueChanged<String> onPick;
  final String emptyTitle;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return EmptyState(icon: Icons.task_alt_rounded, title: emptyTitle, message: emptyText);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Column(children: [for (final c in list) _Item(c: c, state: state, selected: c.id == selected, onTap: () => onPick(c.id))]),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.c, required this.state, required this.selected, required this.onTap});
  final TrainerCheckin c;
  final CheckinReviewState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = state.isDone(c.id);
    final reply = state.replyOf(c.id);
    final line = done ? 'Replied: ${reply.isNotEmpty ? reply : (c.reviewedReply.isNotEmpty ? c.reviewedReply : 'Reviewed')}' : c.line;
    final late = !done && c.late;
    return Material(
      color: selected ? AppColors.hover : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(c.initials, size: 32, color: c.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.client, style: AppText.bodyBold.copyWith(fontWeight: done ? FontWeight.w600 : FontWeight.w700)),
                        ),
                        Text(c.age,
                            style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: late ? const Color(0xFFB42318) : AppColors.muted)),
                      ],
                    ),
                    Text(c.kindLabel, style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.text2)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (done) ...[const Icon(Icons.check_rounded, size: 13, color: Color(0xFF027A48)), const SizedBox(width: 4)],
                        Expanded(
                          child: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.checkin, required this.state, required this.list, required this.onBack, required this.onSelect, required this.onMark});
  final TrainerCheckin checkin;
  final CheckinReviewState state;
  final List<TrainerCheckin> list;
  final VoidCallback onBack;
  final ValueChanged<String> onSelect;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = checkin;
    final done = state.isDone(c.id);
    final i = list.indexOf(c);
    final profile = Routes.tClient(c.clientId ?? TrainerMock.clientIdFor(c.client));
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailHeader(
            c: c,
            onBack: onBack,
            onPrev: i > 0 ? () => onSelect(list[i - 1].id) : null,
            onNext: i >= 0 && i < list.length - 1 ? () => onSelect(list[i + 1].id) : null,
            onProfile: () => context.push(profile),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckinReviewBody(checkin: c, onPhoto: (p) => showCheckinPhotos(context, c, p)),
                const SizedBox(height: 16),
                const ReviewHeading('Your reply',
                    info: 'The client gets your reply in the app with their check-in. To change their plan, open their profile.'),
                if (done)
                  _ReviewedBox(c: c, state: state, onReopen: () => ref.read(checkinReviewProvider.notifier).reopen(c.id))
                else
                  CheckinReplyBox(checkin: c),
              ],
            ),
          ),
          if (!done) _Footer(c: c, state: state, onMark: onMark),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.c, required this.onBack, required this.onPrev, required this.onNext, required this.onProfile});
  final TrainerCheckin c;
  final VoidCallback onBack;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIconButton(Icons.arrow_back_rounded, small: true, tooltip: 'Back to check-ins', onPressed: onBack),
              const SizedBox(width: 10),
              Avatar(c.initials, size: 38, color: c.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(onTap: onProfile, child: Text(c.client, style: AppText.cardTitle)),
                    Text('${c.kindLabel} · sent ${c.sent} · ${c.plan}', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous', onPressed: onPrev),
              const SizedBox(width: 6),
              AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next', onPressed: onNext),
              const Spacer(),
              AppButton.outline('Open profile', icon: Icons.person_outline_rounded, small: true, onPressed: onProfile),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewedBox extends StatelessWidget {
  const _ReviewedBox({required this.c, required this.state, required this.onReopen});
  final TrainerCheckin c;
  final CheckinReviewState state;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final typed = state.replyOf(c.id).trim();
    final reply = typed.isNotEmpty ? typed : (c.reviewedReply.isNotEmpty ? c.reviewedReply : 'No reply, marked as seen');
    final when = state.reviewedNow.contains(c.id) || c.reviewedWhen.isEmpty ? 'just now' : c.reviewedWhen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF5),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFCDEFD9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF027A48)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reviewed $when', style: AppText.bodyBold.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(reply, style: AppText.body.copyWith(fontSize: 13, color: AppColors.text2)),
                const SizedBox(height: 4),
                LinkButton('Mark as not reviewed', onTap: onReopen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.c, required this.state, required this.onMark});
  final TrainerCheckin c;
  final CheckinReviewState state;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context) {
    final left = state.toReview.length - 1;
    final hasReply = state.replyOf(c.id).trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(child: Text(left > 0 ? '$left more to review after this' : 'Last one to review', style: AppText.caption)),
          const SizedBox(width: 10),
          AppButton(hasReply ? 'Send and mark reviewed' : 'Mark reviewed', icon: Icons.check_rounded, small: true, onPressed: onMark),
        ],
      ),
    );
  }
}
