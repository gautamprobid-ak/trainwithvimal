import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../checkins/checkin_review_state.dart';
import 'dashboard_sections.dart';
import 'dashboard_sheets.dart';
import 'trainer_widgets.dart';

/// Design: TrainerDashboardMobile.dc.html — Aman's home.
class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends ConsumerState<TrainerDashboardScreen> {
  bool _unread = true;

  // Today
  final List<TodaySession> _added = [];
  final Set<String> _cancelled = {};
  final Map<String, SessionState> _sessionState = {for (final id in TrainerMock.todayDone) id: SessionState.done};

  // Clients who need you
  AttentionKind? _attKind;
  bool _attAll = false;
  final Set<String> _reminded = {};

  // Tasks
  final List<TrainerTask> _addedTasks = [];
  final Set<String> _tasksDone = {...TrainerMock.tasksDone};
  bool _tasksAll = false;

  List<TodaySession> get _sessions =>
      [...TrainerMock.todaySessions, ..._added].where((s) => !_cancelled.contains(s.id)).toList()..sort((a, b) => a.startMinute.compareTo(b.startMinute));

  void _openProfile(String? id, String name) => context.push(Routes.tClient(id ?? TrainerMock.clientIdFor(name)));

  void _setSession(String id, SessionState? v) => setState(() => v == null ? _sessionState.remove(id) : _sessionState[id] = v);

  void _sessionMenu(TodaySession s) {
    final st = _sessionState[s.id];
    showActionSheet(context, title: s.client, subtitle: '${s.time} · ${s.what}', actions: [
      if (st == null) SheetAction('Mark as missed', Icons.event_busy_rounded, () => _setSession(s.id, SessionState.missed)),
      if (st == SessionState.done) SheetAction('Mark as not done', Icons.undo_rounded, () => _setSession(s.id, null)),
      SheetAction('Open client profile', Icons.person_outline_rounded, () => _openProfile(s.clientId, s.client)),
      SheetAction('Cancel session', Icons.close_rounded, () {
        setState(() => _cancelled.add(s.id));
        showToast(context, 'Session cancelled',
            subtitle: '${s.client} gets a message in the app', kind: ToastKind.del, onUndo: () => setState(() => _cancelled.remove(s.id)));
      }, destructive: true),
    ]);
  }

  Future<void> _newSession() async {
    final r = await showNewSessionSheet(context);
    if (r == null || !mounted) return;
    final s = TodaySession(
      id: 'n${_added.length}',
      time: '17:30',
      minutes: r.minutes,
      client: r.client,
      initials: Avatar.initialsOf(r.client),
      color: TrainerMock.colorFor(r.client),
      what: '${r.videoCall ? 'Video call' : 'Gym floor'} · Extra session',
      videoCall: r.videoCall,
      clientId: TrainerMock.clientIdFor(r.client),
    );
    setState(() => _added.add(s));
    showToast(context, 'Session added',
        subtitle: '${r.client} · today 17:30', kind: ToastKind.ok, onUndo: () => setState(() => _added.remove(s)));
  }

  void _pickKind(AttentionKind? k) => setState(() {
        _attKind = k;
        _attAll = false;
      });

  void _remind(AttentionItem a) {
    setState(() => _reminded.add(a.id));
    showToast(context, 'Reminder sent to ${a.name.split(' ').first}',
        subtitle: 'Push and WhatsApp', kind: ToastKind.ok, onUndo: () => setState(() => _reminded.remove(a.id)));
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(checkinReviewProvider);
    final toReview = review.toReview
      ..sort((a, b) => TrainerMock.checkins.indexOf(a).compareTo(TrainerMock.checkins.indexOf(b)));
    final sessions = _sessions;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _HeroAndStats(
          hero: DashboardHero(
            subline: 'Thursday, 8 October · 24 clients · ${sessions.length} sessions today',
            unread: _unread,
            onBell: () => showTrainerNotices(context, unread: _unread, onReadAll: () => setState(() => _unread = false)),
            onNew: _newSession,
            onMe: () => context.push(Routes.tMe),
          ),
          stats: TrainerStatGrid(_stats(toReview), shadow: true),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Spaced(children: [
            _todayCard(sessions),
            _attentionCard(),
            _checkinsCard(toReview),
            _tasksCard(),
            ThisWeekCard(onProfile: () => context.push(Routes.tMe)),
            NoticesCard(unread: _unread, onReadAll: () => setState(() => _unread = false)),
          ]),
        ),
      ],
    );
  }

  List<TrainerStat> _stats(List<TrainerCheckin> toReview) {
    final late = toReview.where((c) => c.late).length;
    return [
      const TrainerStat(Icons.group_rounded, 'My clients', '24 / 30', '6 spots free'),
      TrainerStat(Icons.assignment_rounded, 'Check-ins to review', '${toReview.length}',
          late > 0 ? '$late waiting over 48 hours' : 'None waiting long', good: late == 0),
      const TrainerStat(Icons.fitness_center_rounded, 'Workouts done', '76%', '+4% vs last week', good: true),
      const TrainerStat(Icons.schedule_rounded, 'Avg reply time', '1.4 h', 'Team average 2.1 h'),
    ];
  }

  Widget _todayCard(List<TodaySession> sessions) {
    final left = sessions.where((s) => _sessionState[s.id] == null).length;
    final next = sessions.where((s) => _sessionState[s.id] == null && s.startMinute >= TrainerMock.dashboardNow).firstOrNull;
    return TrainerSectionCard(
      title: 'Today',
      caption: left > 0 ? '$left left' : 'All done',
      action: 'Calendar',
      onAction: () => context.go(Routes.tCalendar),
      child: sessions.isEmpty
          ? Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 14), child: Text('No sessions left today.', style: AppText.caption))
          : Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                children: [
                  for (final s in sessions)
                    TodaySessionRow(
                      s: s,
                      state: _sessionState[s.id],
                      isNext: next?.id == s.id,
                      onDone: () => _setSession(s.id, SessionState.done),
                      onMenu: () => _sessionMenu(s),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _attentionCard() {
    const all = TrainerMock.attention;
    final list = all.where((a) => _attKind == null || a.kind == _attKind).toList();
    final shown = _attAll ? list : list.take(4).toList();
    return TrainerSectionCard(
      title: 'Clients who need you',
      count: all.length,
      trailing: Padding(padding: const EdgeInsets.only(right: 6), child: Text('Only your clients', style: AppText.caption)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChipStrip(children: [
            CountChip('All', selected: _attKind == null, count: all.length, onTap: () => _pickKind(null)),
            for (final k in AttentionKind.values)
              CountChip(k.label,
                  selected: _attKind == k,
                  count: all.where((a) => a.kind == k).length,
                  onTap: () => _pickKind(k)),
          ]),
          for (final a in shown)
            AttentionRow(a: a, reminded: _reminded.contains(a.id), onRemind: () => _remind(a), onOpen: () => _openProfile(a.clientId, a.name)),
          if (list.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TextButton(
                onPressed: () => setState(() => _attAll = !_attAll),
                child: Text(_attAll ? 'Show less' : 'Show ${list.length - 4} more',
                    style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.accentText)),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _tasksCard() {
    final all = [..._addedTasks, ...TrainerMock.tasks];
    final sorted = [...all.where((t) => !_tasksDone.contains(t.id)), ...all.where((t) => _tasksDone.contains(t.id))];
    final open = all.length - all.where((t) => _tasksDone.contains(t.id)).length;
    final shown = _tasksAll ? sorted : sorted.take(5).toList();
    return TrainerSectionCard(
      title: 'Tasks',
      caption: open > 0 ? '$open open' : 'All done',
      action: 'Add task',
      onAction: _addTask,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in shown)
            TaskRow(
              t: t,
              done: _tasksDone.contains(t.id),
              onTick: () => setState(() => _tasksDone.contains(t.id) ? _tasksDone.remove(t.id) : _tasksDone.add(t.id)),
            ),
          if (sorted.length > 5)
            TextButton(
              onPressed: () => setState(() => _tasksAll = !_tasksAll),
              child: Text(_tasksAll ? 'Show less' : 'Show ${sorted.length - 5} more',
                  style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.accentText)),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    final ctrl = TextEditingController(text: 'Check Neha’s squat video');
    final text = await showAppSheet<String>(
      context,
      title: 'Add a task',
      subtitle: 'Only you see it. Due tomorrow.',
      builder: (_) => LabeledField(label: 'Task', controller: ctrl),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Add task', onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim())),
      ],
    );
    ctrl.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    final t = TrainerTask('n${_addedTasks.length}', text, 'Added by you', due: 'Tomorrow');
    setState(() => _addedTasks.insert(0, t));
    showToast(context, 'Task added', subtitle: 'Due tomorrow', kind: ToastKind.ok, onUndo: () => setState(() => _addedTasks.remove(t)));
  }

  Widget _checkinsCard(List<TrainerCheckin> toReview) {
    return TrainerSectionCard(
      title: 'Check-ins to review',
      count: toReview.isEmpty ? null : toReview.length,
      action: 'View all',
      onAction: () => context.go(Routes.tCheckins),
      child: toReview.isEmpty
          ? const AllReviewed()
          : Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(children: [
                for (final c in toReview) CheckinRow(c: c, onTap: () => showCheckinReviewSheet(context, ref, c)),
              ]),
            ),
    );
  }
}

/// Hero with the stat tiles overlapping its bottom edge by 50 px.
class _HeroAndStats extends StatelessWidget {
  const _HeroAndStats({required this.hero, required this.stats});
  final Widget hero;
  final Widget stats;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: DashboardHero.contentHeight + 50,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment(-.35, -1),
                end: Alignment(.35, 1),
                colors: [Color(0xFF4FB8EE), Color(0xFF2F8FE6), Color(0xFF2563EB)],
                stops: [0, .55, 1],
              ),
            ),
          ),
        ),
        Column(
          children: [
            hero,
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: stats),
          ],
        ),
      ],
    );
  }
}
