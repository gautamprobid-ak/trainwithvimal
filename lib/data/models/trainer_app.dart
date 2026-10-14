import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/badges.dart';

/// Models for the trainer app (Aman Verma's workspace).

/// Green / red marker on a check-in number compared with last time.
enum Trend { up, down }

/// A session on the trainer's dashboard "Today" list.
class TodaySession {
  const TodaySession({
    required this.id,
    required this.time,
    required this.minutes,
    required this.client,
    required this.initials,
    required this.color,
    required this.what,
    this.videoCall = false,
    this.clientId,
  });

  final String id;

  /// "HH:MM", 24 h.
  final String time;
  final int minutes;
  final String client;
  final String initials;
  final AvatarColor color;
  final String what;
  final bool videoCall;
  final String? clientId;

  int get startMinute => int.parse(time.substring(0, 2)) * 60 + int.parse(time.substring(3));
}

enum SessionState { done, missed }

/// One number in the top row of a check-in (Weight, Change, Workouts …).
class CheckinKpi {
  const CheckinKpi(this.label, this.value, [this.trend]);
  final String label;
  final String value;
  final Trend? trend;
}

/// One answer, compared with last time.
class CheckinAnswer {
  const CheckinAnswer(this.label, this.value, this.last, [this.trend]);
  final String label;
  final String value;
  final String last;
  final Trend? trend;
}

/// A check-in a client sent to the trainer.
class TrainerCheckin {
  const TrainerCheckin({
    required this.id,
    required this.client,
    required this.initials,
    required this.color,
    required this.kind,
    required this.line,
    required this.age,
    required this.hours,
    required this.sent,
    required this.plan,
    required this.kpis,
    required this.answers,
    required this.note,
    required this.photos,
    this.reviewedReply = '',
    this.reviewedWhen = '',
    this.reviewed = false,
    this.clientId,
    this.lastPhotoDate = 'Last time',
    this.lastWeight = '',
  });

  final String id;
  final String client;
  final String initials;
  final AvatarColor color;

  /// "Weekly", "Daily" or "Monthly progress".
  final String kind;
  final String line;
  final String age;

  /// Hours since it was sent (for sorting and the "late" colour).
  final int hours;
  final String sent;
  final String plan;
  final List<CheckinKpi> kpis;
  final List<CheckinAnswer> answers;
  final String note;
  final List<String> photos;

  /// Reply already sent (for check-ins reviewed before today).
  final String reviewedReply;
  final String reviewedWhen;

  /// Reviewed when the app opens.
  final bool reviewed;
  final String? clientId;

  /// Last photo set, for "Compare with last time".
  final String lastPhotoDate;
  final String lastWeight;

  String get firstName => client.split(' ').first;
  String get kindLabel => kind == 'Monthly progress' ? kind : '$kind check-in';
  bool get late => hours >= 48;
}

/// Why a client needs the trainer (dashboard "Clients who need you").
enum AttentionKind {
  missed('Missed workouts', BadgeTone.warn),
  notLogging('Not logging', BadgeTone.bad),
  planEnding('Plan ending', BadgeTone.info),
  feelingLow('Feeling low', BadgeTone.neutral);

  const AttentionKind(this.label, this.tone);
  final String label;
  final BadgeTone tone;
}

enum AttentionAction { remind, plan, open }

class AttentionItem {
  const AttentionItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.kind,
    required this.why,
    required this.action,
    this.clientId,
  });

  final String id;
  final String name;
  final String initials;
  final AvatarColor color;
  final AttentionKind kind;
  final String why;
  final AttentionAction action;
  final String? clientId;
}

class TrainerNotice {
  const TrainerNotice(this.initials, this.color, this.text, this.when);
  final String initials;
  final AvatarColor color;
  final String text;
  final String when;
}

/// Calendar session kinds (k-ss, k-qc, k-rv).
enum CalKind {
  session('1:1 session', 60, KindColor.session),
  call('Quick call', 15, KindColor.call),
  review('Program review', 30, KindColor.review);

  const CalKind(this.label, this.minutes, this.color);
  final String label;
  final int minutes;
  final KindColor color;
}

/// A booked session in the calendar. [day] is 0 = Monday.
class CalSession {
  const CalSession({
    required this.id,
    required this.day,
    required this.start,
    required this.kind,
    required this.client,
    required this.trainer,
    required this.minutes,
    required this.place,
    required this.note,
    required this.done,
    required this.bookedBy,
  });

  final String id;
  final int day;

  /// Minutes from midnight.
  final int start;
  final CalKind kind;
  final String client;
  final String trainer;
  final int minutes;

  /// Empty = on a call.
  final String place;
  final String note;
  final bool done;
  final String bookedBy;

  int get end => start + minutes;
  bool get onCall => place.isEmpty;

  CalSession copyWith({String? id, int? day, int? start, bool? done}) => CalSession(
        id: id ?? this.id,
        day: day ?? this.day,
        start: start ?? this.start,
        kind: kind,
        client: client,
        trainer: trainer,
        minutes: minutes,
        place: place,
        note: note,
        done: done ?? this.done,
        bookedBy: bookedBy,
      );
}

/// Working hours for one weekday.
class WorkDay {
  const WorkDay(this.open, this.from, this.to);
  const WorkDay.off()
      : open = false,
        from = 0,
        to = 0;
  final bool open;
  final int from;
  final int to;
}

/// A client in the "Clients who need you" card on the Me page.
class NeedsYou {
  const NeedsYou(this.name, this.initials, this.color, this.why, this.badge, this.tone);
  final String name;
  final String initials;
  final AvatarColor color;
  final String why;
  final String badge;
  final BadgeTone tone;
}

class Permission {
  const Permission(this.label, this.hint, this.on);
  final String label;
  final String hint;
  final bool on;
}

class PermissionGroup {
  const PermissionGroup(this.name, this.items);
  final String name;
  final List<Permission> items;
}

enum ActivityKind {
  checkin('Check-in', Icons.assignment_turned_in_rounded, Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
  plan('Plan', Icons.fitness_center_rounded, Color(0xFFFCE7F3), Color(0xFFBE185D)),
  client('Client', Icons.group_rounded, Color(0xFFCCFBF1), Color(0xFF0F766E)),
  login('Login', Icons.login_rounded, AppColors.sub, AppColors.muted);

  const ActivityKind(this.label, this.icon, this.bg, this.fg);
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}

class ActivityItem {
  const ActivityItem(this.kind, this.pre, this.who, this.post, this.when, {this.note = '', this.from = '', this.to = ''});
  final ActivityKind kind;
  final String pre;
  final String who;
  final String post;
  final String when;
  final String note;

  /// Before → after for plan changes.
  final String from;
  final String to;

  bool get isChange => from.isNotEmpty;
  String get text => pre + (who.isNotEmpty ? ' $who' : '') + post;
}

class ActivityDay {
  const ActivityDay(this.label, this.daysAgo, this.items);
  final String label;
  final int daysAgo;
  final List<ActivityItem> items;
}

enum DocType { cert, id, file }

class TrainerDoc {
  const TrainerDoc({
    required this.name,
    required this.by,
    required this.type,
    required this.kind,
    required this.issued,
    required this.validTill,
    required this.status,
    required this.tone,
    required this.file,
    required this.clientsSee,
    required this.uploaded,
    required this.size,
    this.expiring = false,
  });

  final String name;
  final String by;
  final DocType type;
  final String kind;
  final String issued;
  final String validTill;
  final String status;
  final BadgeTone tone;
  final String file;
  final bool clientsSee;
  final String uploaded;
  final String size;
  final bool expiring;

  bool get unchecked => status == 'Not checked';

  IconData get icon => switch (type) {
        DocType.cert => Icons.workspace_premium_rounded,
        DocType.id => Icons.badge_rounded,
        DocType.file => Icons.description_rounded,
      };

  (Color, Color) get colors => switch (type) {
        DocType.cert => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
        DocType.id => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
        DocType.file => (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
      };
}

/// A row in "What clients see".
class VisibilityRow {
  const VisibilityRow(this.key, this.title, this.sub, {this.on = true, this.locked = false});
  final String key;
  final String title;
  final String sub;
  final bool on;
  final bool locked;
}

class LoginDevice {
  const LoginDevice(this.id, this.title, this.sub, {this.isThis = false, this.phone = false});
  final String id;
  final String title;
  final String sub;
  final bool isThis;
  final bool phone;
}

class NotifPref {
  const NotifPref(this.key, this.title, this.sub, this.on);
  final String key;
  final String title;
  final String sub;
  final bool on;
}

class AccessAsk {
  const AccessAsk(this.id, this.title, this.sub);
  final String id;
  final String title;
  final String sub;
}

/// Small stat tile used on trainer pages (stat).
class TrainerStat {
  const TrainerStat(this.icon, this.label, this.value, this.delta, {this.good});
  final IconData icon;
  final String label;
  final String value;
  final String delta;

  /// true = green, false = red, null = muted.
  final bool? good;
}

/// A to-do on the trainer dashboard (some come from automations).
class TrainerTask {
  const TrainerTask(this.id, this.text, this.from, {required this.due, this.fromAutomation = false, this.dueToday = false, this.late = false});
  final String id;
  final String text;
  final String from;
  final String due;
  final bool fromAutomation;
  final bool dueToday;
  final bool late;
}

enum LinkStatus { on, off, ended }

/// An invite link people use to sign up.
class InviteLink {
  const InviteLink({
    required this.code,
    required this.name,
    required this.trainer,
    required this.made,
    required this.worksFor,
    required this.till,
    required this.maxPeople,
    required this.joined,
    required this.waiting,
    this.status = LinkStatus.on,
  });

  final String code;
  final String name;
  final String trainer;
  final String made;

  /// "30 days · till 8 Nov".
  final String worksFor;

  /// "till 8 Nov" / "ended 8 Oct".
  final String till;
  final String maxPeople;
  final int joined;
  final int waiting;
  final LinkStatus status;

  InviteLink withStatus(LinkStatus s) => InviteLink(
      code: code, name: name, trainer: trainer, made: made, worksFor: worksFor, till: till, maxPeople: maxPeople, joined: joined, waiting: waiting, status: s);
}
