/// Time / date helpers for the admin calendar (same rules as the design).
library;

const calMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const calWd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const calWdLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// First hour shown and the hour after the last one.
const calH0 = 6;
const calH1 = 22;

/// Pixels per hour in the grid.
const calHourPx = 60.0;

/// Date of weekday [i] (0 = Mon) in the week [weekOffset] from 5 Oct 2026.
DateTime calDay(int weekOffset, int i) => DateTime(2026, 10, 5 + 7 * weekOffset + i);

String _ampm(int h) => h % 24 < 12 ? 'am' : 'pm';
int _h12(int h) => h % 12 == 0 ? 12 : h % 12;

/// 7 am, 7:30 am
String fmtTime(int m) {
  final h = (m ~/ 60) % 24, mm = m % 60;
  return '${_h12(h)}${mm > 0 ? ':${mm.toString().padLeft(2, '0')}' : ''} ${_ampm(h)}';
}

/// 7:00 am (always minutes)
String fmtTimeLong(int m) {
  final h = (m ~/ 60) % 24;
  return '${_h12(h)}:${(m % 60).toString().padLeft(2, '0')} ${_ampm(h)}';
}

String _range(String a, String b) => '${a.substring(a.length - 2) == b.substring(b.length - 2) ? a.substring(0, a.length - 3) : a} – $b';

/// 7 – 8 am
String fmtRange(int m, int len) => _range(fmtTime(m), fmtTime(m + len));

/// 7:00 – 8:00 am
String fmtRangeLong(int m, int len) => _range(fmtTimeLong(m), fmtTimeLong(m + len));

/// 5 – 11 Oct 2026
String fmtWeek(int wo) {
  final a = calDay(wo, 0), b = calDay(wo, 6);
  return a.month == b.month
      ? '${a.day} – ${b.day} ${calMonths[b.month - 1]} ${b.year}'
      : '${a.day} ${calMonths[a.month - 1]} – ${b.day} ${calMonths[b.month - 1]} ${b.year}';
}

/// Friday, 9 Oct
String fmtDayShort(int wo, int i) {
  final d = calDay(wo, i);
  return '${calWdLong[i]}, ${d.day} ${calMonths[d.month - 1]}';
}
