import '../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/// Kinds of "Needs action" items on the admin dashboard.
enum ActionKind {
  approval('Approvals', AvatarColor.c4),
  client('Clients', AvatarColor.c1),
  checkin('Check-ins', AvatarColor.c3),
  trainer('Trainers', AvatarColor.c5),
  program('Programs', AvatarColor.c6);

  const ActionKind(this.label, this.color);
  final String label;
  final AvatarColor color;
}

class NeedsAction {
  const NeedsAction(this.id, this.kind, this.title, this.sub, this.cta);
  final String id;
  final ActionKind kind;
  final String title;
  final String sub;
  final String cta;
}

class RiskClient {
  const RiskClient(this.initials, this.color, this.name, this.why);
  final String initials;
  final AvatarColor color;
  final String name;
  final String why;
}

class TrainerPerformance {
  const TrainerPerformance(this.initials, this.color, this.name, this.clients, this.adherence, this.reply);
  final String initials;
  final AvatarColor color;
  final String name;
  final int clients;
  final int adherence;
  final String reply;
}

class MiniActivity {
  const MiniActivity(this.initials, this.color, this.who, this.text, this.when);
  final String initials;
  final AvatarColor color;
  final String who;
  final String text;
  final String when;
}

class GlanceTile {
  const GlanceTile(this.value, this.label, this.sub, {this.warn = false});
  final String value;
  final String label;
  final String sub;
  final bool warn;
}

// ---------------------------------------------------------------------------
// Invite links (Clients + Approvals)
// ---------------------------------------------------------------------------

enum LinkStatus { on, off, ended }

extension LinkStatusX on LinkStatus {
  String get label => switch (this) {
        LinkStatus.on => 'On',
        LinkStatus.off => 'Off',
        LinkStatus.ended => 'Ended',
      };
}

class InviteLink {
  const InviteLink({
    required this.code,
    required this.name,
    required this.trainer,
    required this.made,
    required this.till,
    required this.tillShort,
    required this.max,
    required this.plan,
    required this.joined,
    required this.waiting,
    required this.status,
    this.approvals = true,
  });

  final String code;
  final String name;
  final String trainer;
  final String made;
  final String till;
  final String tillShort;
  final String max;
  final String plan;
  final int joined;
  final int waiting;
  final LinkStatus status;

  /// New sign-ups wait in Approvals.
  final bool approvals;

  InviteLink copyWith({LinkStatus? status, bool? approvals}) => InviteLink(
        code: code,
        name: name,
        trainer: trainer,
        made: made,
        till: till,
        tillShort: tillShort,
        max: max,
        plan: plan,
        joined: joined,
        waiting: waiting,
        status: status ?? this.status,
        approvals: approvals ?? this.approvals,
      );
}

// ---------------------------------------------------------------------------
// Approvals
// ---------------------------------------------------------------------------

enum WaitLevel { normal, old, late }

class SignupRequest {
  const SignupRequest({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.email,
    required this.phone,
    required this.invitedBy,
    required this.inviterInitials,
    required this.inviterColor,
    required this.code,
    required this.plan,
    required this.device,
    required this.steps,
    required this.wait,
    required this.when,
    required this.waitLevel,
    required this.answers,
    required this.healthNote,
    required this.hoursWaiting,
    this.movedBack = false,
  });

  final String id;
  final String name;
  final String initials;
  final AvatarColor color;
  final String email;
  final String phone;
  final String invitedBy;
  final String inviterInitials;
  final AvatarColor inviterColor;
  final String code;
  final String plan;
  final String device;

  /// Profile setup steps done (of 5).
  final int steps;
  final String wait;
  final String when;
  final WaitLevel waitLevel;
  final List<(String, String)> answers;
  final String healthNote;
  final double hoursWaiting;
  final bool movedBack;

  String get first => name.split(' ').first;
}

class TrainerChoice {
  const TrainerChoice(this.name, this.initials, this.color, this.focus, this.clients, this.capacity);
  final String name;
  final String initials;
  final AvatarColor color;
  final String focus;
  final int clients;
  final int capacity;
  bool get full => clients >= capacity;
}

enum Decision { approved, rejected }

class DecisionRecord {
  const DecisionRecord({
    required this.name,
    required this.initials,
    required this.color,
    required this.signedUp,
    required this.decision,
    required this.why,
    required this.by,
    required this.when,
    required this.daysAgo,
  });
  final String name;
  final String initials;
  final AvatarColor color;
  final String signedUp;
  final Decision decision;
  final String why;
  final String by;
  final String when;
  final int daysAgo;
  String get first => name.split(' ').first;
}

/// A titled option with a one-line hint (reject reasons, ask-for-info items).
class HintOption {
  const HintOption(this.id, this.title, this.sub);
  final String id;
  final String title;
  final String sub;
}

/// Filter group: id, label and options (first option = no filter).
class FilterGroup {
  const FilterGroup(this.id, this.label, this.options);
  final String id;
  final String label;
  final List<String> options;
}

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

enum SessionKind {
  session('1:1 session', 60, KindColor.session),
  call('Quick call', 15, KindColor.call),
  review('Program review', 30, KindColor.review);

  const SessionKind(this.label, this.minutes, this.color);
  final String label;
  final int minutes;
  final KindColor color;
}

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

  /// 0 = Monday.
  final int day;

  /// Minutes from midnight.
  final int start;
  final SessionKind kind;
  final String client;
  final String trainer;
  final int minutes;

  /// Empty = on a call.
  final String place;
  final String note;
  final bool done;
  final String bookedBy;

  int get end => start + minutes;

  CalSession copyWith({int? day, int? start, bool? done}) => CalSession(
        id: id,
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
class DayHours {
  const DayHours(this.open, this.from, this.to);
  final bool open;
  final int from;
  final int to;
}

// ---------------------------------------------------------------------------
// Activity
// ---------------------------------------------------------------------------

enum ActivityIcon { clip, dumbbell, food, scale, edit, users, bolt, play, db, chat, login }

enum ActivityRole { admin, trainer, client, system }

class ActivityEntry {
  const ActivityEntry({
    required this.icon,
    required this.kind,
    required this.who,
    required this.when,
    this.pre = '',
    this.post = '',
    this.note = '',
    this.old = '',
    this.now = '',
    this.role = ActivityRole.trainer,
  });

  final ActivityIcon icon;

  /// Filter kind: Check-in, Plan, Workout, Meal, Body, Client, Content, System, Login.
  final String kind;
  final String pre;
  final String who;
  final String post;
  final String when;
  final String note;
  final String old;
  final String now;
  final ActivityRole role;

  bool get isChange => old.isNotEmpty;
}

class ActivityDay {
  const ActivityDay(this.label, this.daysAgo, this.items);
  final String label;
  final int daysAgo;
  final List<ActivityEntry> items;
}

// ---------------------------------------------------------------------------
// Trainers
// ---------------------------------------------------------------------------

class PermissionGroup {
  const PermissionGroup(this.name, this.items);
  final String name;

  /// (label, hint, on in the Assigned clients preset)
  final List<(String, String, bool)> items;
}

class TrainerClientRow {
  const TrainerClientRow(this.name, this.initials, this.color, this.goal, this.program, this.adherence, this.lastCheckin, this.status, this.since);
  final String name;
  final String initials;
  final AvatarColor color;
  final String goal;
  final String program;
  final int adherence;
  final String lastCheckin;
  final String status;
  final String since;
}

enum DocKind { cert, id, file }

class TrainerDoc {
  const TrainerDoc({
    required this.name,
    required this.by,
    required this.kind,
    required this.kindLabel,
    required this.issued,
    required this.validTill,
    required this.status,
    required this.clientsSee,
    required this.uploaded,
    required this.size,
    required this.file,
    this.expiring = false,
  });
  final String name;
  final String by;
  final DocKind kind;
  final String kindLabel;
  final String issued;
  final String validTill;
  final String status;
  final bool clientsSee;
  final String uploaded;
  final String size;
  final String file;
  final bool expiring;

  bool get verified => status == 'Verified';
  bool get unchecked => status == 'Not checked';

  TrainerDoc verify() => TrainerDoc(
        name: name,
        by: by,
        kind: kind,
        kindLabel: kindLabel,
        issued: issued,
        validTill: validTill,
        status: 'Verified',
        clientsSee: true,
        uploaded: uploaded,
        size: size,
        file: file,
      );
}

class AssignCandidate {
  const AssignCandidate(this.name, this.initials, this.color, this.sub, this.badge, this.hasTrainer);
  final String name;
  final String initials;
  final AvatarColor color;
  final String sub;
  final String badge;
  final bool hasTrainer;
}

class AttentionClient {
  const AttentionClient(this.name, this.initials, this.color, this.why, this.badge);
  final String name;
  final String initials;
  final AvatarColor color;
  final String why;
  final String badge;
}

class ClientViewRow {
  const ClientViewRow(this.key, this.title, this.sub, this.defaultOn, {this.locked = false});
  final String key;
  final String title;
  final String sub;
  final bool defaultOn;
  final bool locked;
}
