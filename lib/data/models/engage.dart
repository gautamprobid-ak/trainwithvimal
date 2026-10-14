import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Forms & check-ins
// ---------------------------------------------------------------------------

/// What a form is for (KINDS in the design).
enum FormKind {
  onboarding(
    'Onboarding questionnaire',
    'Onboarding',
    'Goal, history, diet and schedule. Filled in once after registration.',
    Icons.assignment_ind_rounded,
    Tint.blue,
  ),
  weekly(
    'Weekly check-in',
    'Weekly check-ins',
    'Weight, measurements and how the week went. Sent on a schedule.',
    Icons.event_repeat_rounded,
    Tint.green,
  ),
  daily('Daily check-in', 'Daily check-ins', 'A 30-second morning pulse: weight, sleep and energy.', Icons.wb_sunny_rounded, Tint.amber),
  survey('Survey / feedback', 'Surveys', 'Program feedback, ratings and quick polls.', Icons.poll_rounded, Tint.purple),
  waiver('Waiver / consent', 'Waivers', 'Statements the client agrees to before starting.', Icons.verified_user_rounded, Tint.blue);

  const FormKind(this.label, this.filterLabel, this.description, this.icon, this.tint);
  final String label;
  final String filterLabel;
  final String description;
  final IconData icon;
  final Tint tint;
}

/// Answer types (QT in the design).
enum QuestionType {
  shortText('Short answer', Icons.short_text_rounded, 'How did the week feel?'),
  longText('Long answer', Icons.notes_rounded, 'What was hard this week?'),
  number('Number', Icons.pin_rounded, 'Steps per day (average)'),
  singleChoice('Single choice', Icons.radio_button_checked_rounded, 'Which day was hardest?'),
  multiChoice('Multiple choice', Icons.check_box_rounded, 'What got in the way?'),
  dropdown('Dropdown', Icons.arrow_drop_down_circle_rounded, 'Which city do you live in?'),
  scale('Scale 1–5', Icons.linear_scale_rounded, 'Hunger this week'),
  yesNo('Yes / No', Icons.toggle_on_rounded, 'Did you hit your protein target most days?'),
  photo('Photo upload', Icons.photo_camera_rounded, 'Photo of your plate at lunch');

  const QuestionType(this.label, this.icon, this.sample);
  final String label;
  final IconData icon;

  /// Question text used when the editor is saved with an empty question.
  final String sample;

  bool get hasOptions => this == singleChoice || this == multiChoice || this == dropdown;
}

@immutable
class FormQuestion {
  const FormQuestion({
    required this.text,
    required this.type,
    this.help = '',
    this.required = false,
    this.options = const [],
    this.other = false,
  });

  final String text;
  final QuestionType type;
  final String help;
  final bool required;
  final List<String> options;

  /// Adds an "Other" option the client can type into.
  final bool other;

  String get optionsSummary => '${options.length} options${other ? ' + Other' : ''}';

  FormQuestion copyWith({String? text, QuestionType? type, String? help, bool? required, List<String>? options, bool? other}) =>
      FormQuestion(
        text: text ?? this.text,
        type: type ?? this.type,
        help: help ?? this.help,
        required: required ?? this.required,
        options: options ?? this.options,
        other: other ?? this.other,
      );
}

@immutable
class FormDef {
  const FormDef({
    required this.id,
    required this.name,
    required this.kind,
    this.automations = const [],
    this.published = false,
    required this.updated,
    this.questions = const [],
    this.archived = false,
  });

  final String id;
  final String name;
  final FormKind kind;

  /// Automations that send this form ("How it is sent").
  final List<String> automations;
  final bool published;
  final String updated;
  final List<FormQuestion> questions;
  final bool archived;

  String get statusLabel => archived ? 'Archived' : (published ? 'Published' : 'Draft');

  FormDef copyWith({
    String? id,
    String? name,
    FormKind? kind,
    List<String>? automations,
    bool? published,
    String? updated,
    List<FormQuestion>? questions,
    bool? archived,
  }) => FormDef(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    automations: automations ?? this.automations,
    published: published ?? this.published,
    updated: updated ?? this.updated,
    questions: questions ?? this.questions,
    archived: archived ?? this.archived,
  );
}

/// "1 question" / "5 questions".
String questionCount(int n) => '$n ${n == 1 ? 'question' : 'questions'}';

// ---------------------------------------------------------------------------
// Automations
// ---------------------------------------------------------------------------

enum TriggerGroup {
  client('Client', Tint.blue),
  schedule('Schedule', Tint.green),
  activity('Activity', Tint.amber),
  progress('Progress', Tint.purple);

  const TriggerGroup(this.label, this.tint);
  final String label;
  final Tint tint;
}

/// What starts an automation (TRIG in the design).
enum TriggerKind {
  clientApproved('New client approved', 'As soon as they are approved.', TriggerGroup.client, Icons.how_to_reg_rounded),
  planStarts('Plan starts', 'A program or meal plan starts.', TriggerGroup.client, Icons.play_circle_rounded),
  planEnds('Plan ends', 'Before a plan ends.', TriggerGroup.client, Icons.flag_rounded),
  renewalDue('Package ending', 'Before a package ends.', TriggerGroup.client, Icons.autorenew_rounded),
  birthday('Client birthday', 'On the client’s birthday.', TriggerGroup.client, Icons.cake_rounded),
  weeklyCheckInDay('Every week', 'Same day and time each week.', TriggerGroup.schedule, Icons.event_repeat_rounded),
  daily('Every day', 'Same time every day.', TriggerGroup.schedule, Icons.today_rounded),
  onDate('On a date', 'Once, on a date you pick.', TriggerGroup.schedule, Icons.event_rounded),
  checkInMissed('Missed check-in', 'A check-in is late.', TriggerGroup.activity, Icons.assignment_late_rounded),
  workoutsMissed('Missed workouts', 'Workouts missed in a row.', TriggerGroup.activity, Icons.fitness_center_rounded),
  inactive('No app activity', 'The app is not opened.', TriggerGroup.activity, Icons.phonelink_off_rounded),
  formSubmitted('Form sent in', 'A client sends a form.', TriggerGroup.activity, Icons.assignment_turned_in_rounded),
  streak('Workout streak', 'Workouts done days in a row.', TriggerGroup.activity, Icons.local_fire_department_rounded),
  goalReached('Goal weight reached', 'Weight reaches the goal.', TriggerGroup.progress, Icons.emoji_events_rounded),
  weightStuck('Weight not changing', 'Weight stays the same.', TriggerGroup.progress, Icons.trending_flat_rounded);

  const TriggerKind(this.label, this.description, this.group, this.icon);
  final String label;
  final String description;
  final TriggerGroup group;
  final IconData icon;
}

/// Send channels.
enum Channel {
  email('Email', Icons.mail_rounded),
  push('Push', Icons.notifications_rounded),
  whatsapp('WhatsApp', Icons.chat_rounded),
  inApp('In-app', Icons.phone_iphone_rounded);

  const Channel(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum StepKind {
  wait('Wait', Icons.hourglass_bottom_rounded, Tint.gray),
  message('Send message', Icons.send_rounded, Tint.blue),
  form('Send form', Icons.assignment_rounded, Tint.green),
  assign('Assign task', Icons.task_alt_rounded, Tint.purple);

  const StepKind(this.label, this.icon, this.tint);
  final String label;
  final IconData icon;
  final Tint tint;
}

enum AutoStatus { on, off, draft }

/// One step of an automation.
@immutable
class AutoStep {
  const AutoStep({required this.kind, this.amount = 0, this.unit = '', this.ref = '', this.channels = const []});

  const AutoStep.wait(this.amount, this.unit) : kind = StepKind.wait, ref = '', channels = const [];
  const AutoStep.message(this.ref, this.channels) : kind = StepKind.message, amount = 0, unit = '';
  const AutoStep.form(this.ref, this.channels) : kind = StepKind.form, amount = 0, unit = '';

  /// [unit] holds who the task is for: `trainer` or `owner`.
  const AutoStep.task(this.ref, {this.unit = 'trainer'}) : kind = StepKind.assign, amount = 0, channels = const [];

  final StepKind kind;

  /// Wait amount.
  final int amount;

  /// `hours` / `days` for waits, `trainer` / `owner` for tasks.
  final String unit;

  /// Form id, template id or task text.
  final String ref;
  final List<Channel> channels;

  AutoStep copyWith({int? amount, String? unit, String? ref, List<Channel>? channels}) => AutoStep(
    kind: kind,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    ref: ref ?? this.ref,
    channels: channels ?? this.channels,
  );
}

@immutable
class Automation {
  const Automation({
    required this.id,
    required this.name,
    required this.trigger,
    this.value = 0,
    this.steps = const [],
    this.status = AutoStatus.draft,
    this.package = '',
    this.trainer = '',
    this.stopOnReply = true,
    this.changed = '',
    this.running = 0,
    this.finished = 0,
  });

  final String id;
  final String name;

  /// Null while a new automation has no trigger yet.
  final TriggerKind? trigger;

  /// Day of week (1–7) for weekly, hours / days / workouts for others.
  final int value;
  final List<AutoStep> steps;
  final AutoStatus status;
  final String package;
  final String trainer;
  final bool stopOnReply;
  final String changed;
  final int running;
  final int finished;

  Automation copyWith({
    String? id,
    String? name,
    TriggerKind? trigger,
    bool clearTrigger = false,
    int? value,
    List<AutoStep>? steps,
    AutoStatus? status,
    String? package,
    String? trainer,
    bool? stopOnReply,
    String? changed,
    int? running,
    int? finished,
  }) => Automation(
    id: id ?? this.id,
    name: name ?? this.name,
    trigger: clearTrigger ? null : (trigger ?? this.trigger),
    value: value ?? this.value,
    steps: steps ?? this.steps,
    status: status ?? this.status,
    package: package ?? this.package,
    trainer: trainer ?? this.trainer,
    stopOnReply: stopOnReply ?? this.stopOnReply,
    changed: changed ?? this.changed,
    running: running ?? this.running,
    finished: finished ?? this.finished,
  );
}

/// Ready-made automation offered in "New automation".
@immutable
class AutomationStarter {
  const AutomationStarter({
    required this.id,
    required this.name,
    required this.trigger,
    required this.value,
    required this.steps,
    required this.note,
  });
  final String id;
  final String name;
  final TriggerKind trigger;
  final int value;
  final List<AutoStep> steps;
  final String note;
}

/// One row of the "Last 30 days" log in the automation builder.
@immutable
class AutomationRun {
  const AutomationRun(this.name, this.status, this.when);
  final String name;
  final String status;
  final String when;
}

// ---------------------------------------------------------------------------
// Emails & alerts
// ---------------------------------------------------------------------------

/// Title / subject and body for one channel of a template.
@immutable
class MsgText {
  const MsgText(this.subject, this.body);
  final String subject;
  final String body;
}

@immutable
class MsgTemplate {
  const MsgTemplate({
    required this.id,
    required this.name,
    required this.group,
    required this.when,
    required this.texts,
    this.custom = false,
  });

  final String id;
  final String name;

  /// Access, Coaching, Packages or Team.
  final String group;

  /// "Sent: …" line.
  final String when;
  final Map<Channel, MsgText> texts;
  final bool custom;

  MsgTemplate copyWith({Map<Channel, MsgText>? texts}) =>
      MsgTemplate(id: id, name: name, group: group, when: when, texts: texts ?? this.texts, custom: custom);
}

/// Automation that uses a template ("Where it is used").
@immutable
class TemplateUse {
  const TemplateUse(this.automation, this.where);
  final String automation;
  final String where;
}

/// Team alert row: an event and which channels notify the team.
@immutable
class TeamAlert {
  const TeamAlert({required this.id, required this.name, required this.description, required this.channels});
  final String id;
  final String name;
  final String description;
  final Set<Channel> channels;

  TeamAlert copyWith({Set<Channel>? channels}) =>
      TeamAlert(id: id, name: name, description: description, channels: channels ?? this.channels);
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

@immutable
class RolePermission {
  const RolePermission(this.name, {required this.trainer, required this.client});
  final String name;
  final bool trainer;
  final bool client;

  RolePermission copyWith({bool? trainer, bool? client}) =>
      RolePermission(name, trainer: trainer ?? this.trainer, client: client ?? this.client);
}

@immutable
class RoleInfo {
  const RoleInfo({
    required this.name,
    required this.count,
    required this.scope,
    required this.note,
    required this.tint,
    required this.icon,
    this.link,
    this.linkLabel,
  });
  final String name;
  final String count;
  final String scope;
  final String note;
  final Tint tint;
  final IconData icon;
  final String? link;
  final String? linkLabel;
}

enum IntegrationState {
  on('Connected'),
  dns('Checking DNS'),
  off('Not connected');

  const IntegrationState(this.label);
  final String label;
}

@immutable
class IntegrationUse {
  const IntegrationUse(this.label, this.target);
  final String label;

  /// Page key: automations, emails, approvals, forms, clientProfile, habits.
  final String target;
}

@immutable
class Integration {
  const Integration({
    required this.id,
    required this.short,
    required this.name,
    required this.description,
    required this.used,
    required this.bg,
    required this.fg,
    this.steps = const [],
  });

  final String id;
  final String short;
  final String name;
  final String description;
  final List<IntegrationUse> used;
  final Color bg;
  final Color fg;

  /// Set-up steps shown in the manage sheet (title, help).
  final List<(String, String)> steps;
}
