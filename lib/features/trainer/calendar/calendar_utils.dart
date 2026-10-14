import 'package:train_with_vimal/data/mock/trainer_mock.dart';

/// Date and time helpers for the trainer calendar (same formats as the design).

const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// First and last hour drawn in the grid, and pixels per hour.
const calStartHour = 6;
const calEndHour = 22;
const calHourPx = 60.0;

DateTime dayDate(int weekOffset, int day) => TrainerMock.weekStart.add(Duration(days: 7 * weekOffset + day));

/// "7 am", "7:30 pm".
String fmtTime(int m) {
  final h = (m ~/ 60) % 24, mm = m % 60, h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12${mm != 0 ? ':${mm.toString().padLeft(2, '0')}' : ''} ${h < 12 ? 'am' : 'pm'}';
}

/// "7:00 am" (always with minutes).
String fmtTimeLong(int m) {
  final h = (m ~/ 60) % 24, h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${(m % 60).toString().padLeft(2, '0')} ${h < 12 ? 'am' : 'pm'}';
}

/// "7 – 8 am", "11:30 am – 12 pm".
String fmtRange(int m, int len) {
  final a = fmtTime(m), b = fmtTime(m + len);
  return '${a.substring(a.length - 2) == b.substring(b.length - 2) ? a.substring(0, a.length - 3) : a} – $b';
}

/// "5 – 11 Oct 2026" or "28 Sep – 4 Oct 2026".
String weekRange(int wo) {
  final d0 = dayDate(wo, 0), d6 = dayDate(wo, 6);
  return d0.month == d6.month
      ? '${d0.day} – ${d6.day} ${monthNames[d6.month - 1]} ${d6.year}'
      : '${d0.day} ${monthNames[d0.month - 1]} – ${d6.day} ${monthNames[d6.month - 1]} ${d6.year}';
}

/// "Friday, 9 Oct".
String dayLabel(int wo, int day) {
  final d = dayDate(wo, day);
  return '${weekdayLong[day]}, ${d.day} ${monthNames[d.month - 1]}';
}
