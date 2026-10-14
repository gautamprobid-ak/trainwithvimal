import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import 'calendar_utils.dart';

/// Day header + time grid with session blocks (cal-card).
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.days,
    required this.weekOffset,
    required this.sessions,
    required this.hours,
    required this.dayView,
    required this.onDay,
    required this.onSession,
  });

  final List<int> days;
  final int weekOffset;
  final List<CalSession> sessions;
  final List<WorkDay> hours;
  final bool dayView;
  final ValueChanged<int> onDay;
  final ValueChanged<CalSession> onSession;

  static const _timeCol = 46.0;

  bool _isToday(int i) => weekOffset == 0 && i == TrainerMock.todayIndex;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _header(),
          const Divider(height: 1),
          _body(),
        ],
      ),
    );
  }

  Widget _header() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: _timeCol),
          for (final i in days) Expanded(child: _dayHead(i)),
        ],
      ),
    );
  }

  Widget _dayHead(int i) {
    final n = sessions.where((s) => s.day == i).length;
    final today = _isToday(i);
    final cnt = n == 0 ? '' : '$n ${n == 1 ? 'session' : 'sessions'}';
    final num = Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      alignment: Alignment.center,
      decoration: today ? const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle) : null,
      child: Text('${dayDate(weekOffset, i).day}',
          style: AppText.bodyBold.copyWith(fontSize: today ? 15 : 18, color: today ? Colors.white : AppColors.text)),
    );
    final wd = Text(dayView ? weekdayLong[i] : weekdayShort[i],
        style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: today ? AppColors.accentText : AppColors.muted));
    final cntText = Text(cnt, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11));
    return InkWell(
      onTap: () => onDay(i),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: dayView ? null : (today ? const Color(0xFFE8EEFC) : (i > 4 ? const Color(0xFFFAFAF8) : null)),
          border: const Border(left: BorderSide(color: AppColors.line)),
        ),
        child: dayView
            ? Row(children: [wd, const SizedBox(width: 6), num, const SizedBox(width: 6), Expanded(child: cntText)])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [wd, num, cntText]),
      ),
    );
  }

  Widget _body() {
    const height = (calEndHour - calStartHour) * calHourPx;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeCol,
            child: Stack(
              children: [
                for (var h = calStartHour; h < calEndHour; h++)
                  Positioned(
                    top: (h - calStartHour) * calHourPx - (h == calStartHour ? 0 : 7),
                    right: 6,
                    child: Text(fmtTime(h * 60), style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          for (final i in days) Expanded(child: _column(i)),
        ],
      ),
    );
  }

  double _y(int m) => (m - calStartHour * 60) / 60 * calHourPx;

  Widget _column(int i) {
    final today = _isToday(i);
    final av = hours[i];
    final xs = sessions.where((s) => s.day == i).toList()..sort((a, b) => a.start.compareTo(b.start));
    // Put overlapping sessions side by side.
    final colOf = <String, int>{};
    final ends = <int>[];
    for (final s in xs) {
      var c = ends.indexWhere((e) => e <= s.start);
      if (c < 0) {
        c = ends.length;
        ends.add(0);
      }
      ends[c] = s.end;
      colOf[s.id] = c;
    }
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return Container(
        decoration: BoxDecoration(
          color: !dayView && today ? const Color(0xFFE8EEFC) : (!dayView && i > 4 ? const Color(0xFFFAFAF8) : null),
          border: const Border(left: BorderSide(color: AppColors.line)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (var h = 1; h < calEndHour - calStartHour; h++)
              Positioned(top: h * calHourPx, left: 0, right: 0, child: Container(height: 1, color: AppColors.line)),
            if (!av.open)
              Positioned.fill(child: _off(label: true))
            else ...[
              if (av.from > calStartHour * 60) Positioned(top: 0, left: 0, right: 0, height: _y(av.from), child: _off()),
              if (av.to < calEndHour * 60) Positioned(bottom: 0, left: 0, right: 0, height: (calEndHour * 60 - av.to) / 60 * calHourPx, child: _off()),
            ],
            for (final s in xs) _block(s, xs, colOf, w),
            if (today && weekOffset == 0)
              Positioned(
                top: _y(TrainerMock.nowMinute),
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(top: 4, left: 0, right: 0, child: Container(height: 2, color: const Color(0xFFDC2626))),
                      Positioned(
                        top: 0,
                        left: -5,
                        child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _off({bool label = false}) {
    return Container(
      color: const Color(0x0A171717),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 16),
      child: label
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.line)),
              child: Text('Day off', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _block(CalSession s, List<CalSession> xs, Map<String, int> colOf, double w) {
    final grp = xs.where((o) => o.start < s.end && o.end > s.start);
    final n = grp.map((o) => colOf[o.id]!).reduce((a, b) => a > b ? a : b) + 1;
    final col = colOf[s.id]!;
    final h = (s.minutes / 60 * calHourPx - 3).clamp(22.0, double.infinity);
    final tiny = s.minutes < 45;
    final k = s.kind.color;
    return Positioned(
      top: _y(s.start),
      left: col / n * w + 2,
      width: w / n - 4,
      height: h,
      child: Tooltip(
        message: [s.client, s.kind.label, fmtRange(s.start, s.minutes), s.trainer, s.done ? 'Done' : 'Booked'].join(' · '),
        child: GestureDetector(
          onTap: () => onSession(s),
          child: Opacity(
            opacity: s.done ? .55 : 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: tiny ? 0 : 4),
              alignment: tiny ? Alignment.centerLeft : Alignment.topLeft,
              decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(6), border: Border(left: BorderSide(color: k.line, width: 3))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.client, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                  if (!tiny)
                    Text('${fmtTimeLong(s.start)} · ${s.onCall ? 'On a call' : s.place}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11, color: k.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
