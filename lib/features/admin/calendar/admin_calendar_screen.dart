import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import '../clients/admin_ui.dart';
import 'cal_format.dart';
import 'calendar_sheets.dart';

/// Design: CalendarMobile.dc.html — the team's sessions (day / 3-day view).
class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  int _wo = 0;
  int _day = 4;
  bool _dayView = true;
  String _tr = '';

  final _cancelled = <String>{};
  final _done = <String, bool>{};
  final _moved = <String, (int, int)>{};
  final _added = <int, List<CalSession>>{};
  final _hours = <String, List<DayHours>>{};

  List<DayHours> _hoursOf(String t) => _hours[t] ?? AdminMock.hoursOf(t);

  /// Sessions of a week with this session's edits applied.
  List<CalSession> _sessionsIn(int wo) {
    final base = [...AdminMock.sessionsForWeek(wo), ...?_added[wo]];
    if (wo != 0) return base;
    return [
      for (final s in base)
        if (!_cancelled.contains(s.id))
          s.copyWith(day: _moved[s.id]?.$1, start: _moved[s.id]?.$2, done: _done[s.id]),
    ];
  }

  List<CalSession> get _all => _sessionsIn(_wo);
  List<CalSession> get _shown => _all.where((s) => _tr.isEmpty || s.trainer == _tr).toList();

  void _prev() => setState(() {
        if (!_dayView) {
          _wo--;
        } else if (_day == 0) {
          _wo--;
          _day = 6;
        } else {
          _day--;
        }
      });

  void _next() => setState(() {
        if (!_dayView) {
          _wo++;
        } else if (_day == 6) {
          _wo++;
          _day = 0;
        } else {
          _day++;
        }
      });

  // ------------------------------------------------------------- actions

  void _openSession(CalSession s) {
    showSessionSheet(
      context,
      session: s,
      when: '${fmtDayShort(_wo, s.day)} · ${fmtRange(s.start, s.minutes)}',
      onOpenProfile: () {
        final c = PeopleMock.clients.where((c) => c.name == s.client).firstOrNull;
        if (c != null) {
          context.push(Routes.aClient(c.id));
        } else {
          showToast(context, 'Profile not in this demo', subtitle: s.client, kind: ToastKind.info);
        }
      },
      onToggleDone: () {
        final was = s.done;
        setState(() => _done[s.id] = !was);
        showToast(context, was ? 'Marked as not done' : 'Marked as done', subtitle: '${s.client} · ${s.kind.label}', kind: ToastKind.ok,
            onUndo: () => setState(() => _done[s.id] = was));
      },
      onReschedule: () => _openForm(move: s),
      onCancel: () {
        setState(() => _cancelled.add(s.id));
        showToast(context, 'Session cancelled', subtitle: '${s.client} · ${fmtDayShort(_wo, s.day)}', kind: ToastKind.del,
            onUndo: () => setState(() => _cancelled.remove(s.id)));
      },
    );
  }

  void _openForm({CalSession? move}) {
    showSessionForm(
      context,
      move: move,
      moveWhen: move == null ? null : '${fmtDayShort(_wo, move.day)} · ${fmtRange(move.start, move.minutes)}',
      sessionsIn: _sessionsIn,
      hoursOf: _hoursOf,
      onSave: (r) {
        setState(() {
          if (move != null) {
            if (r.week == 0) _moved[move.id] = (r.day, r.start);
          } else {
            (_added[r.week] ??= []).add(CalSession(
              id: 'n${DateTime.now().microsecondsSinceEpoch}',
              day: r.day,
              start: r.start,
              kind: r.kind,
              client: r.client,
              trainer: r.trainer,
              minutes: r.kind.minutes,
              place: r.place,
              note: '',
              done: false,
              bookedBy: 'Vimal',
            ));
          }
        });
        showToast(context, move != null ? 'Session moved' : 'Session created',
            subtitle: '${r.client} · ${fmtDayShort(r.week, r.day)} · ${fmtRange(r.start, r.kind.minutes)}', kind: ToastKind.ok);
      },
    );
  }

  void _openAvailability() {
    showAvailabilitySheet(context, hoursOf: _hoursOf, onSave: (t, h) {
      setState(() => _hours[t] = h);
      showToast(context, 'Availability saved', subtitle: '$t · ${h.where((d) => d.open).length} working days', kind: ToastKind.ok);
    });
  }

  void _pickTrainer() {
    final all = _all;
    showAppSheet(
      context,
      title: 'Show sessions of',
      builder: (ctx) => Column(
        children: [
          for (final t in ['', ...AdminMock.calTrainers])
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(t.isEmpty ? 'All trainers' : t, style: AppText.bodyBold.copyWith(fontWeight: t == _tr ? FontWeight.w800 : FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${t.isEmpty ? all.length : all.where((s) => s.trainer == t).length}', style: AppText.caption),
                  const SizedBox(width: 8),
                  SizedBox(width: 20, child: t == _tr ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null),
                ],
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() => _tr = t);
              },
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final ss = _shown;
    final range = _dayView ? '${calWdLong[_day]}, ${calDay(_wo, _day).day} ${calMonths[calDay(_wo, _day).month - 1]} ${calDay(_wo, _day).year}' : fmtWeek(_wo);
    final start3 = math.min(4, math.max(0, _day - 1));
    final idxs = _dayView ? [_day] : [start3, start3 + 1, start3 + 2];

    return PageScroll(
      children: [
        PageHeader(title: 'Calendar', subtitle: '${_tr.isEmpty ? 'Your team’s' : '$_tr’s'} sessions, ${fmtWeek(_wo)}'),
        Row(
          children: [
            Expanded(child: AppButton.outline('Availability', icon: Icons.schedule_rounded, onPressed: _openAvailability)),
            const SizedBox(width: 10),
            Expanded(child: AppButton('New session', icon: Icons.add_rounded, onPressed: () => _openForm())),
          ],
        ),
        AdminStatGrid(_stats(ss)),
        _Toolbar(
          range: range,
          trainer: _tr.isEmpty ? 'All trainers' : _tr,
          dayView: _dayView,
          onPrev: _prev,
          onNext: _next,
          onToday: () => setState(() {
            _wo = 0;
            _day = 4;
          }),
          onTrainer: _pickTrainer,
          onView: (v) => setState(() => _dayView = v),
        ),
        _DayStrip(
          wo: _wo,
          day: _day,
          window: _dayView ? const [] : idxs,
          has: {for (final s in ss) s.day},
          onPick: (i) => setState(() => _day = i),
        ),
        const _Legend(),
        _Grid(
          wo: _wo,
          days: idxs,
          dayView: _dayView,
          sessions: ss,
          hours: _tr.isEmpty ? null : _hoursOf(_tr),
          showPlace: _tr.isNotEmpty,
          onOpen: _openSession,
          onOpenDay: (i) => setState(() {
            _dayView = true;
            _day = i;
          }),
        ),
      ],
    );
  }

  List<AdminStat> _stats(List<CalSession> ss) {
    final nDone = ss.where((s) => s.done).length;
    final nCall = ss.where((s) => s.place.isEmpty).length;
    final per = <String, int>{};
    for (final s in ss) {
      per[s.trainer] = (per[s.trainer] ?? 0) + 1;
    }
    final busy = per.entries.isEmpty ? null : per.entries.reduce((a, b) => b.value > a.value ? b : a);
    final last = _tr.isNotEmpty
        ? () {
            final h = _hoursOf(_tr);
            final d = h[_day];
            return AdminStat('Working days', '${h.where((x) => x.open).length}',
                d.open ? '${calWd[_day]} ${fmtRange(d.from, d.to - d.from)}' : '${calWd[_day]} off',
                icon: Icons.person_outline_rounded);
          }()
        : AdminStat('Busiest trainer', busy?.key ?? '—', busy == null ? '' : '${busy.value} sessions', icon: Icons.person_outline_rounded);
    return [
      AdminStat('Sessions this week', '${ss.length}', _dayView ? '${ss.where((s) => s.day == _day).length} on ${calWd[_day]}' : '',
          icon: Icons.calendar_today_outlined),
      AdminStat('Done', '$nDone', ss.isEmpty ? '' : '${(nDone / ss.length * 100).round()}% of the week', icon: Icons.check_circle_outline_rounded),
      AdminStat('On a call', '$nCall', 'Quick calls and reviews', icon: Icons.call_outlined),
      last,
    ];
  }
}

// ------------------------------------------------------------ Toolbar

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.range,
    required this.trainer,
    required this.dayView,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onTrainer,
    required this.onView,
  });
  final String range;
  final String trainer;
  final bool dayView;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onTrainer;
  final ValueChanged<bool> onView;

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 10,
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
        Row(
          children: [
            Expanded(child: AppButton.outline(trainer, small: true, icon: Icons.people_outline_rounded, onPressed: onTrainer)),
            const SizedBox(width: 10),
            SegmentedTabs<bool>(items: const [(false, 'Week'), (true, 'Day')], value: dayView, onChanged: onView, expand: false),
          ],
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.wo, required this.day, required this.window, required this.has, required this.onPick});
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
            child: GestureDetector(
              onTap: () => onPick(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.only(top: 6, bottom: 5),
                decoration: BoxDecoration(color: window.contains(i) ? AppColors.sub : null, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Text(calWd[i][0],
                        style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: wo == 0 && i == 4 ? AppColors.accentText : AppColors.muted)),
                    const SizedBox(height: 2),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: i == day ? AppColors.text : null, shape: BoxShape.circle),
                      child: Text(
                        '${calDay(wo, i).day}',
                        style: AppText.bodyBold.copyWith(
                          fontSize: 15,
                          color: i == day ? Colors.white : (wo == 0 && i == 4 ? AppColors.accentText : AppColors.text),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: has.contains(i) ? AppColors.line2 : Colors.transparent, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget sw, String label, [String? extra]) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              sw,
              const SizedBox(width: 6),
              Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
              if (extra != null) ...[const SizedBox(width: 4), Text(extra, style: AppText.caption)],
            ],
          ),
        );
    Widget box(Color c, {Border? border}) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3), border: border),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in SessionKind.values) item(box(k.color.line), k.label, '${k.minutes} min'),
          item(box(const Color(0xFFF1F1EC), border: Border.all(color: AppColors.line)), 'Outside working hours'),
          item(box(const Color(0x6684CC16)), 'Done'),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Grid

class _Grid extends StatelessWidget {
  const _Grid({
    required this.wo,
    required this.days,
    required this.dayView,
    required this.sessions,
    required this.hours,
    required this.showPlace,
    required this.onOpen,
    required this.onOpenDay,
  });
  final int wo;
  final List<int> days;
  final bool dayView;
  final List<CalSession> sessions;
  final List<DayHours>? hours;
  final bool showPlace;
  final ValueChanged<CalSession> onOpen;
  final ValueChanged<int> onOpenDay;

  static double _y(int m) => (m - calH0 * 60) / 60 * calHourPx;

  @override
  Widget build(BuildContext context) {
    const height = (calH1 - calH0) * calHourPx;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(
              children: [
                const SizedBox(width: 56),
                for (final i in days) Expanded(child: _head(i)),
              ],
            ),
          ),
          if (sessions.isEmpty)
            const EmptyState(icon: Icons.event_busy_rounded, title: 'No sessions this week', message: 'Use New session to book one.'),
          SizedBox(
            height: height + 12,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var h = calH0; h < calH1; h++)
                          Positioned(
                            top: _y(h * 60) - 7,
                            right: 8,
                            child: Text(fmtTime(h * 60), style: AppText.caption.copyWith(fontSize: 10.5)),
                          ),
                      ],
                    ),
                  ),
                  for (final i in days) Expanded(child: _column(i, height)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _head(int i) {
    final n = sessions.where((s) => s.day == i).length;
    final today = wo == 0 && i == 4;
    return InkWell(
      onTap: () => onOpenDay(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(dayView ? calWdLong[i] : calWd[i], style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: today ? AppColors.accentText : AppColors.muted)),
            Text('${calDay(wo, i).day}', style: AppText.bodyBold.copyWith(fontSize: 16, color: today ? AppColors.accentText : AppColors.text)),
            Text(n == 0 ? '' : '$n ${n == 1 ? 'session' : 'sessions'}', style: AppText.caption.copyWith(fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  Widget _column(int i, double height) {
    final av = hours?[i];
    final xs = sessions.where((s) => s.day == i).toList()..sort((a, b) => a.start.compareTo(b.start));
    // Lay out overlapping sessions side by side.
    final colEnds = <int>[];
    final colOf = <CalSession, int>{};
    for (final s in xs) {
      var c = colEnds.indexWhere((end) => end <= s.start);
      if (c < 0) {
        c = colEnds.length;
        colEnds.add(0);
      }
      colEnds[c] = s.end;
      colOf[s] = c;
    }
    const offFill = Color(0xFFF4F4F0);
    return Container(
      height: height,
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line))),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var h = calH0; h < calH1; h++)
                Positioned(top: _y(h * 60), left: 0, right: 0, child: const Divider(height: 1, color: Color(0xFFF0F0EC))),
              if (av != null && !av.open)
                Positioned.fill(
                  child: Container(
                    color: offFill,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 20),
                    child: Text('Day off', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              if (av != null && av.open && av.from > calH0 * 60) Positioned(top: 0, left: 0, right: 0, height: _y(av.from), child: const ColoredBox(color: offFill)),
              if (av != null && av.open && av.to < calH1 * 60)
                Positioned(bottom: 0, left: 0, right: 0, height: (calH1 * 60 - av.to) / 60 * calHourPx, child: const ColoredBox(color: offFill)),
              for (final s in xs) _block(s, xs, colOf, w),
              if (wo == 0 && i == 4)
                Positioned(
                  top: _y(1090),
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.bad, shape: BoxShape.circle)),
                      Expanded(child: Container(height: 1.5, color: AppColors.bad)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _block(CalSession s, List<CalSession> xs, Map<CalSession, int> colOf, double w) {
    final group = xs.where((o) => o.start < s.end && o.end > s.start);
    final n = group.map((o) => colOf[o]!).reduce(math.max) + 1;
    final c = colOf[s]!;
    final h = math.max(22.0, s.minutes / 60 * calHourPx - 3);
    final tiny = s.minutes < 45;
    final k = s.kind.color;
    final sub = '${fmtTimeLong(s.start)} · ${showPlace ? (s.place.isEmpty ? 'On a call' : s.place) : s.trainer.split(' ').first}';
    return Positioned(
      top: _y(s.start),
      left: c / n * w + 2,
      width: w / n - 4,
      height: h,
      child: Tooltip(
        message: '${s.client} · ${s.kind.label} · ${fmtRangeLong(s.start, s.minutes)} · ${s.trainer} · ${s.done ? 'Done' : 'Booked'}',
        triggerMode: TooltipTriggerMode.longPress,
        child: Material(
          color: s.done ? Color.alphaBlend(Colors.white.withValues(alpha: .45), k.bg) : k.bg,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onOpen(s),
            child: Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: k.line, width: 3))),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: tiny ? 2 : 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyBold.copyWith(fontSize: 12, color: AppColors.text, decoration: s.done ? TextDecoration.none : null)),
                  if (!tiny) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11, color: k.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
