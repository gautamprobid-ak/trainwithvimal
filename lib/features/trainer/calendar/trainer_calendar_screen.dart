import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';
import 'calendar_grid.dart';
import 'calendar_sheets.dart';
import 'calendar_utils.dart';

/// Design: TrainerCalendarMobile.dc.html — Aman's sessions by day or 3 days.
class TrainerCalendarScreen extends StatefulWidget {
  const TrainerCalendarScreen({super.key});

  @override
  State<TrainerCalendarScreen> createState() => _TrainerCalendarScreenState();
}

class _TrainerCalendarScreenState extends State<TrainerCalendarScreen> {
  /// This week's sessions (cancel / move / done / new apply here).
  List<CalSession> _week = [...TrainerMock.calendarSessions];

  /// Sessions booked in other weeks from New session.
  final List<(int, CalSession)> _otherWeeks = [];
  List<WorkDay> _hours = [...TrainerMock.workingHours];
  int _wo = 0;
  int _day = TrainerMock.todayIndex;
  bool _dayView = true;
  int _newId = 0;

  /// All sessions of a week, as the design derives them.
  List<CalSession> _sessionsIn(int wo) {
    final base = TrainerMock.calendarSessions;
    final list = switch (wo) {
      0 => _week,
      -1 => [for (var i = 0; i < base.length; i += 2) base[i].copyWith(done: true)],
      1 => [for (var i = 0; i < base.length; i += 3) base[i].copyWith(done: false)],
      _ => <CalSession>[],
    };
    return [...list, for (final (w, s) in _otherWeeks) if (w == wo) s];
  }

  List<CalSession> get _mine => _sessionsIn(_wo).where((s) => s.trainer == TrainerMock.me).toList();

  void _replace(CalSession s) => setState(() => _week = [for (final x in _week) x.id == s.id ? s : x]);

  void _prev() => setState(() {
        if (_dayView) {
          if (_day == 0) {
            _wo--;
            _day = 6;
          } else {
            _day--;
          }
        } else {
          _wo--;
        }
      });

  void _next() => setState(() {
        if (_dayView) {
          if (_day == 6) {
            _wo++;
            _day = 0;
          } else {
            _day++;
          }
        } else {
          _wo++;
        }
      });

  Future<void> _open(CalSession s) async {
    final a = await showSessionDetails(context, s, _wo);
    if (!mounted || a == null) return;
    switch (a) {
      case SessionAction.profile:
        context.push(Routes.tClient(TrainerMock.clientIdFor(s.client)));
      case SessionAction.toggleDone:
        if (_wo == 0) _replace(s.copyWith(done: !s.done));
        showToast(context, s.done ? 'Marked as not done' : 'Session done', subtitle: s.client, kind: ToastKind.ok);
      case SessionAction.reschedule:
        _form(moving: s);
      case SessionAction.cancel:
        _cancel(s);
    }
  }

  Future<void> _cancel(CalSession s) async {
    final ok = await confirmCancelSession(context, s, _wo);
    if (!ok || !mounted) return;
    final before = _week;
    setState(() {
      _week = _week.where((x) => x.id != s.id).toList();
      _otherWeeks.removeWhere((e) => e.$2.id == s.id);
    });
    showToast(context, 'Session cancelled', subtitle: '${s.client} gets a message', kind: ToastKind.del, onUndo: () => setState(() => _week = before));
  }

  Future<void> _form({CalSession? moving}) async {
    final d = await showSessionForm(context, moving: moving, sessionsIn: _sessionsIn, hours: _hours);
    if (d == null || !mounted) return;
    if (moving != null) {
      _replace(moving.copyWith(day: d.day, start: d.start));
      setState(() {
        _day = d.day;
        _wo = 0;
      });
      showToast(context, 'Session moved', subtitle: '${moving.client} · ${dayLabel(0, d.day)}, ${fmtTime(d.start)}', kind: ToastKind.ok);
      return;
    }
    final s = CalSession(
      id: 'n${_newId++}',
      day: d.day,
      start: d.start,
      kind: d.kind,
      client: d.client,
      trainer: TrainerMock.me,
      minutes: d.kind.minutes,
      place: d.place,
      note: d.note,
      done: false,
      bookedBy: TrainerMock.me,
    );
    setState(() {
      if (d.weekOffset == 0) {
        _week = [..._week, s];
      } else {
        _otherWeeks.add((d.weekOffset, s));
      }
      _wo = d.weekOffset;
      _day = d.day;
    });
    showToast(context, 'Session booked', subtitle: '${d.client} · ${dayLabel(d.weekOffset, d.day)}, ${fmtTime(d.start)}', kind: ToastKind.ok);
  }

  Future<void> _workingHours() async {
    final h = await showWorkingHours(context, _hours);
    if (h == null || !mounted) return;
    setState(() => _hours = h);
    showToast(context, 'Availability saved', subtitle: '${h.where((d) => d.open).length} working days', kind: ToastKind.ok);
  }

  List<TrainerStat> _stats(List<CalSession> ss) {
    final done = ss.where((s) => s.done).length;
    final av = _hours[_day];
    return [
      TrainerStat(Icons.calendar_today_rounded, 'Sessions this week', '${ss.length}',
          _dayView ? '${ss.where((s) => s.day == _day).length} on ${weekdayShort[_day]}' : ''),
      TrainerStat(Icons.check_circle_outline_rounded, 'Done', '$done', ss.isEmpty ? '' : '${(done / ss.length * 100).round()}% of the week'),
      TrainerStat(Icons.call_rounded, 'On a call', '${ss.where((s) => s.onCall).length}', 'Quick calls and reviews'),
      TrainerStat(Icons.person_rounded, 'Working days', '${_hours.where((d) => d.open).length}',
          av.open ? '${weekdayShort[_day]} ${fmtRange(av.from, av.to - av.from)}' : '${weekdayShort[_day]} off'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ss = _mine;
    final w0 = (_day - 1).clamp(0, 4);
    final days = _dayView ? [_day] : [w0, w0 + 1, w0 + 2];
    final range = _dayView ? '${dayLabel(_wo, _day)} ${dayDate(_wo, _day).year}' : weekRange(_wo);
    return PageScroll(
      children: [
        PageHeader(title: 'Calendar', subtitle: 'Your sessions, ${weekRange(_wo)}', actions: const [TrainerProfileButton()]),
        Row(
          children: [
            Expanded(child: AppButton.outline('My working hours', icon: Icons.schedule_rounded, small: true, onPressed: _workingHours)),
            const SizedBox(width: 8),
            Expanded(child: AppButton('New session', icon: Icons.add_rounded, small: true, onPressed: () => _form())),
          ],
        ),
        TrainerStatGrid(_stats(ss), compact: true),
        _NavBar(
          range: range,
          dayView: _dayView,
          onPrev: _prev,
          onNext: _next,
          onToday: () => setState(() {
            _wo = 0;
            _day = TrainerMock.todayIndex;
          }),
          onView: (v) => setState(() => _dayView = v),
        ),
        _Strip(
          wo: _wo,
          day: _day,
          window: _dayView ? const [] : days,
          has: {for (final s in ss) s.day},
          onPick: (i) => setState(() => _day = i),
        ),
        const _Legend(),
        if (ss.isEmpty)
          const AppCard(
            child: EmptyState(icon: Icons.event_available_rounded, title: 'No sessions this week', message: 'Use New session to book one.'),
          ),
        CalendarGrid(
          days: days,
          weekOffset: _wo,
          sessions: ss,
          hours: _hours,
          dayView: _dayView,
          onDay: (i) => setState(() {
            _dayView = true;
            _day = i;
          }),
          onSession: _open,
        ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.range, required this.dayView, required this.onPrev, required this.onNext, required this.onToday, required this.onView});
  final String range;
  final bool dayView;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<bool> onView;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous', onPressed: onPrev),
            const SizedBox(width: 6),
            AppButton.outline('Today', small: true, onPressed: onToday),
            const SizedBox(width: 6),
            AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next', onPressed: onNext),
            const SizedBox(width: 10),
            Expanded(child: Text(range, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 14.5))),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedTabs<bool>(expand: false, items: const [(false, 'Week'), (true, 'Day')], value: dayView, onChanged: onView),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.wo, required this.day, required this.window, required this.has, required this.onPick});
  final int wo;
  final int day;
  final List<int> window;
  final Set<int> has;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: window.contains(i) ? AppColors.sub : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onPick(i),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(padding: const EdgeInsets.fromLTRB(0, 6, 0, 5), child: _cell(i)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cell(int i) {
    final on = i == day;
    final today = wo == 0 && i == TrainerMock.todayIndex;
    return Column(
      children: [
        Text(weekdayShort[i][0], style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: today ? AppColors.accentText : AppColors.muted)),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? AppColors.accent : null, shape: BoxShape.circle),
          child: Text('${dayDate(wo, i).day}',
              style: AppText.bodyBold.copyWith(fontSize: 15, color: on ? Colors.white : (today ? AppColors.accentText : AppColors.text))),
        ),
        const SizedBox(height: 2),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: has.contains(i) ? (on ? AppColors.accent : AppColors.line2) : Colors.transparent),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget dot, String label, [String? extra]) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Row(
            children: [
              dot,
              const SizedBox(width: 6),
              Text(label, style: AppText.caption.copyWith(color: AppColors.text, fontWeight: FontWeight.w600)),
              if (extra != null) ...[const SizedBox(width: 4), Text(extra, style: AppText.caption)],
            ],
          ),
        );
    Widget sq(Color c, {Border? border}) =>
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3), border: border));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in CalKind.values) item(sq(k.color.line), k.label, '${k.minutes} min'),
          item(sq(const Color(0xFFF2F2EE), border: Border.all(color: AppColors.line)), 'Outside working hours'),
          item(sq(const Color(0x6684CC16)), 'Done'),
        ],
      ),
    );
  }
}
