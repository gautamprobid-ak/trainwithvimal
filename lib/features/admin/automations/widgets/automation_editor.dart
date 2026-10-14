import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import '../../forms/form_builder_screen.dart' show DashedAddButton;
import '../../forms/widgets/engage_ui.dart';
import '../automations_state.dart';

/// Values picked for a trigger (TD in the design): plan, day, number, time
/// (half-hour slots), date (day of Oct 2026) and form.
@immutable
class _Cfg {
  const _Cfg({this.p = 'any', this.d = 7, this.n = 0, this.t = 18, this.dt = 15, this.f = 'f-parq'});
  final String p;
  final int d;
  final int n;
  final int t;
  final int dt;
  final String f;

  _Cfg copyWith({String? p, int? d, int? n, int? t, int? dt, String? f}) =>
      _Cfg(p: p ?? this.p, d: d ?? this.d, n: n ?? this.n, t: t ?? this.t, dt: dt ?? this.dt, f: f ?? this.f);
}

/// Fields each trigger shows, and its defaults.
const _fields = <TriggerKind, (List<String>, _Cfg)>{
  TriggerKind.clientApproved: ([], _Cfg()),
  TriggerKind.planStarts: (['p'], _Cfg()),
  TriggerKind.planEnds: (['num', 'time'], _Cfg(n: 3, t: 18)),
  TriggerKind.renewalDue: (['num', 'time'], _Cfg(n: 7, t: 18)),
  TriggerKind.birthday: (['time'], _Cfg(t: 16)),
  TriggerKind.weeklyCheckInDay: (['day', 'time'], _Cfg(d: 7, t: 18)),
  TriggerKind.daily: (['time'], _Cfg(t: 14)),
  TriggerKind.onDate: (['date', 'time'], _Cfg(dt: 15, t: 20)),
  TriggerKind.checkInMissed: (['num'], _Cfg(n: 24)),
  TriggerKind.workoutsMissed: (['num'], _Cfg(n: 3)),
  TriggerKind.inactive: (['num'], _Cfg(n: 5)),
  TriggerKind.formSubmitted: (['form'], _Cfg(f: 'f-parq')),
  TriggerKind.streak: (['num'], _Cfg(n: 7)),
  TriggerKind.goalReached: ([], _Cfg()),
  TriggerKind.weightStuck: (['num'], _Cfg(n: 3)),
};

/// Number field of a trigger: label, unit, min, max, step.
const _num = <TriggerKind, (String, String, int, int, int)>{
  TriggerKind.planEnds: ('Days before the end', 'days', 0, 14, 1),
  TriggerKind.renewalDue: ('Days before the end', 'days', 1, 30, 1),
  TriggerKind.checkInMissed: ('Not sent within', 'hours', 6, 72, 6),
  TriggerKind.workoutsMissed: ('Missed in a row', 'workouts', 1, 10, 1),
  TriggerKind.inactive: ('No activity for', 'days', 2, 30, 1),
  TriggerKind.streak: ('Days in a row', 'days', 3, 60, 1),
  TriggerKind.weightStuck: ('Same weight for', 'weeks', 1, 8, 1),
};

const _plans = {'any': 'program or meal plan', 'prog': 'program', 'meal': 'meal plan'};

String _fmtT(int h) {
  final hh = h ~/ 2;
  return '${hh % 12 == 0 ? 12 : hh % 12}:${h.isOdd ? '30' : '00'}${hh < 12 ? ' am' : ' pm'}';
}

String _trigSummary(TriggerKind? t, _Cfg c) => switch (t) {
  null => 'Pick what starts it',
  TriggerKind.clientApproved => 'Right after a client is approved',
  TriggerKind.planStarts => 'When a client’s ${_plans[c.p]} starts',
  TriggerKind.planEnds => '${c.n > 0 ? '${c.n} ${c.n == 1 ? 'day' : 'days'} before' : 'On the day'} a client’s plan ends, at ${_fmtT(c.t)}',
  TriggerKind.renewalDue => '${c.n} days before a package ends, at ${_fmtT(c.t)}',
  TriggerKind.birthday => 'On the client’s birthday at ${_fmtT(c.t)}',
  TriggerKind.weeklyCheckInDay => 'Every ${EngageMock.days[c.d]} at ${_fmtT(c.t)}',
  TriggerKind.daily => 'Every day at ${_fmtT(c.t)}',
  TriggerKind.onDate => 'Once, on ${c.dt} Oct 2026 at ${_fmtT(c.t)}',
  TriggerKind.checkInMissed => 'When a check-in is not sent within ${c.n} hours',
  TriggerKind.workoutsMissed => 'When ${c.n} workouts in a row are missed',
  TriggerKind.inactive => 'When a client has not opened the app for ${c.n} days',
  TriggerKind.formSubmitted => 'When a client sends “${EngageMock.formNames[c.f]}”',
  TriggerKind.streak => 'When a client finishes workouts ${c.n} days in a row',
  TriggerKind.goalReached => 'When a client’s weight reaches their goal',
  TriggerKind.weightStuck => 'When weight stays within 0.5 kg for ${c.n} ${c.n == 1 ? 'week' : 'weeks'}',
};

/// Steps that can be added (kind, label, help, default step).
const _addable = <(StepKind, String, AutoStep)>[
  (StepKind.wait, 'Pause before the next step', AutoStep.wait(1, 'days')),
  (StepKind.message, 'A template by email, push, WhatsApp or in-app', AutoStep.message('checkin-reminder', [Channel.push])),
  (StepKind.form, 'A form or check-in from Forms & check-ins', AutoStep.form('f-parq', [Channel.push])),
  (StepKind.assign, 'A to-do for the trainer or the owner', AutoStep.task('Welcome call with the client')),
];

/// Automation editor shared by "New automation" (blank) and the builder
/// (an existing automation by [id], or a ready-made [starterId]).
class AutomationEditor extends ConsumerStatefulWidget {
  const AutomationEditor({super.key, this.id, this.starterId});
  final String? id;
  final String? starterId;

  @override
  ConsumerState<AutomationEditor> createState() => _AutomationEditorState();
}

class _AutomationEditorState extends ConsumerState<AutomationEditor> {
  late Automation _base;
  late bool _blank;
  late final TextEditingController _name;
  TriggerKind? _trig;
  final Map<TriggerKind, _Cfg> _cfg = {};
  TriggerGroup? _group;
  late List<AutoStep> _steps;
  late bool _stop;
  late AutoStatus _status;
  late String _package;
  late String _trainer;

  @override
  void initState() {
    super.initState();
    final n = ref.read(automationsProvider.notifier);
    final existing = widget.id == null ? null : n.byId(widget.id!);
    final starter = EngageMock.starters.where((s) => s.id == widget.starterId).firstOrNull;
    _blank = existing == null;
    _base =
        existing ??
        (starter != null
            ? Automation(id: n.newId(), name: starter.name, trigger: starter.trigger, value: starter.value, steps: starter.steps)
            : Automation(id: n.newId(), name: '', trigger: null));
    _name = TextEditingController(text: _base.name);
    _trig = _base.trigger;
    final t = _base.trigger;
    if (t != null) {
      final def = _fields[t]!.$2;
      _cfg[t] = t == TriggerKind.weeklyCheckInDay
          ? def.copyWith(d: _base.value == 0 ? 7 : _base.value)
          : _num.containsKey(t)
          ? def.copyWith(n: _base.value)
          : def;
    }
    _steps = [..._base.steps];
    _stop = _base.stopOnReply;
    _status = _base.status;
    _package = _base.package;
    _trainer = _base.trainer;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  _Cfg get _c => _trig == null ? const _Cfg() : (_cfg[_trig!] ?? _fields[_trig!]!.$2);

  void _setC(_Cfg Function(_Cfg) fn) => setState(() => _cfg[_trig!] = fn(_c));

  void _setStep(int i, AutoStep s) => setState(() => _steps[i] = s);

  List<String> get _problems => [
    if (_trig == null) 'Pick what starts it',
    if (_steps.isEmpty) 'Add at least one step',
    if (_steps.isNotEmpty && _steps.last.kind == StepKind.wait) 'Add a step that does something after the wait',
    for (var i = 0; i < _steps.length; i++)
      if ((_steps[i].kind == StepKind.message || _steps[i].kind == StepKind.form) && _steps[i].channels.isEmpty)
        'Step ${i + 1}: pick at least one channel',
  ];

  String get _displayName => _name.text.trim().isEmpty ? 'New automation' : _name.text.trim();

  void _persist(AutoStatus status) {
    final t = _trig;
    final value = t == null ? 0 : (t == TriggerKind.weeklyCheckInDay ? _c.d : (_num.containsKey(t) ? _c.n : 0));
    final a = Automation(
      id: _base.id,
      name: _displayName,
      trigger: t,
      value: value,
      steps: _steps,
      status: status,
      package: _package,
      trainer: _trainer,
      stopOnReply: _stop,
      changed: 'just now',
      running: _base.running,
      finished: _base.finished,
    );
    ref.read(automationsProvider.notifier).save(a);
    setState(() => _status = status);
  }

  void _saveDraft() {
    _persist(AutoStatus.draft);
    showToast(context, 'Saved as a draft', subtitle: 'Turn it on when it is ready', kind: ToastKind.ok);
  }

  void _turnOn() {
    final p = _problems;
    if (p.isNotEmpty) {
      showToast(context, 'Not ready to turn on', subtitle: p.first, kind: ToastKind.warn);
      return;
    }
    _persist(AutoStatus.on);
    showToast(context, '$_displayName is on', subtitle: 'It starts with the next trigger', kind: ToastKind.ok);
  }

  Future<void> _addStep() async {
    final picked = await showAppSheet<AutoStep>(
      context,
      title: 'Add a step',
      subtitle: 'It is added after the last step',
      builder: (ctx) => Column(
        children: [
          for (final (k, help, def) in _addable)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: TintIcon(k.icon, tint: k.tint, size: 32),
              title: Text(k.label, style: AppText.bodyBold),
              subtitle: Text(help, style: AppText.caption),
              onTap: () => Navigator.of(ctx).pop(def),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _steps.add(picked));
    showToast(context, 'Step added', subtitle: picked.kind.label, kind: ToastKind.ok);
  }

  void _stepMenu(int i) {
    showActionSheet(
      context,
      title: 'Step ${i + 1}',
      actions: [
        if (i > 0) SheetAction('Move up', Icons.arrow_upward_rounded, () => setState(() => _steps.insert(i - 1, _steps.removeAt(i)))),
        if (i < _steps.length - 1)
          SheetAction('Move down', Icons.arrow_downward_rounded, () => setState(() => _steps.insert(i + 1, _steps.removeAt(i)))),
        SheetAction('Remove', Icons.delete_rounded, () {
          final prev = [..._steps];
          final s = _steps[i];
          setState(() => _steps.removeAt(i));
          showToast(
            context,
            'Step removed',
            subtitle: EngageMock.stepLine(s),
            kind: ToastKind.del,
            onUndo: () => setState(() => _steps = prev),
          );
        }, destructive: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final (stL, stTone) = switch (_status) {
      AutoStatus.on => ('On', BadgeTone.ok),
      AutoStatus.draft => ('Draft', BadgeTone.warn),
      AutoStatus.off => ('Off', BadgeTone.neutral),
    };
    final probs = _problems;
    return PageScroll(
      children: [
        SubPageHeader(
          title: _blank ? 'New automation' : _base.name,
          subtitle: _blank ? 'Automations · New automation' : 'Automations · Edit automation',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge(stL, tone: stTone),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Trigger, conditions and steps. Nothing is saved until you turn it on or save it.', style: AppText.secondary),
            ),
          ],
        ),
        _Actions(
          onLabel: _status == AutoStatus.on ? 'Save and keep on' : 'Turn on',
          onTurnOn: _turnOn,
          onDraft: _saveDraft,
          onCancel: () => context.pop(),
        ),
        _section(1, 'When does it start?', _triggerSection()),
        _section(2, 'Who is it for?', _whoSection()),
        _section(3, 'What happens next?', _stepsSection()),
        _PlainWords(
          trigger: _trigSummary(_trig, _c),
          applies: _package.isNotEmpty ? 'Clients on $_package' : 'All clients',
          steps: _steps,
          stop: _stop,
          problems: probs,
        ),
        SideCard(
          title: 'Last 30 days',
          children: _blank
              ? [const FieldHint('No runs yet. Clients show up here once it is on.')]
              : [
                  const StatTriple(EngageMock.runStats),
                  const SizedBox(height: 10),
                  for (final r in EngageMock.runLog)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () {
                          final c = PeopleMock.clients.where((c) => c.name == r.name).firstOrNull;
                          if (c != null) context.push(Routes.aClient(c.id));
                        },
                        child: Row(
                          children: [
                            Avatar(Avatar.initialsOf(r.name), size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: AppText.bodyBold.copyWith(fontSize: 13)),
                                  Text(r.status, style: AppText.caption),
                                ],
                              ),
                            ),
                            Text(r.when, style: AppText.caption.copyWith(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                ],
        ),
      ],
    );
  }

  Widget _section(int n, String title, Widget body) {
    return AppCard(
      clip: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
                child: Text(
                  '$n',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  // --- 1. trigger ------------------------------------------------------------

  Widget _triggerSection() {
    final groups = <(TriggerGroup?, String, int?)>[
      (null, 'All', TriggerKind.values.length),
      for (final g in TriggerGroup.values) (g, g.label, TriggerKind.values.where((t) => t.group == g).length),
    ];
    final shown = TriggerKind.values.where((t) => _group == null || t.group == _group);
    return Spaced(
      gap: 12,
      children: [
        FieldBlock(
          label: 'Automation name',
          child: TextField(
            controller: _name,
            style: AppText.body,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. Welcome series'),
          ),
        ),
        FieldBlock(
          label: 'Start it when',
          child: CountTabs<TriggerGroup?>(items: groups, value: _group, onChanged: (g) => setState(() => _group = g)),
        ),
        Spaced(
          gap: 6,
          children: [
            for (final t in shown)
              OptionCard(
                selected: _trig == t,
                showCheck: false,
                title: t.label,
                subtitle: t.description,
                icon: t.icon,
                tint: t.group.tint,
                onTap: () => setState(() => _trig = t),
              ),
          ],
        ),
        if (_trig == null)
          const NoteBox('Pick what starts this automation. You can change it later.', icon: Icons.touch_app_rounded)
        else
          _triggerDetail(_trig!),
      ],
    );
  }

  Widget _triggerDetail(TriggerKind t) {
    final f = _fields[t]!.$1;
    final c = _c;
    final num = _num[t];
    final note = EngageMock.triggerNotes[t];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Spaced(
        gap: 12,
        children: [
          Row(
            children: [
              TintIcon(t.icon, tint: t.group.tint, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.label, style: AppText.bodyBold),
                    Text('${t.group.label} trigger', style: AppText.caption),
                  ],
                ),
              ),
              TextLink(
                'Change',
                onTap: () => setState(() {
                  _trig = null;
                  _group = null;
                }),
              ),
            ],
          ),
          if (f.contains('p'))
            FieldBlock(
              label: 'Which plan',
              child: SegmentedTabs<String>(
                items: const [('any', 'Any plan'), ('prog', 'Program'), ('meal', 'Meal plan')],
                value: c.p,
                onChanged: (v) => _setC((c) => c.copyWith(p: v)),
              ),
            ),
          if (f.contains('day'))
            FieldBlock(
              label: 'Day',
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: _DayPill(
                        label: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                        on: c.d == i + 1,
                        onTap: () => _setC((c) => c.copyWith(d: i + 1)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (f.contains('num') && num != null)
            FieldBlock(
              label: num.$1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StepperBox(
                  value: c.n == 0 && t == TriggerKind.planEnds ? 'On the day' : '${c.n}',
                  unit: c.n == 0 && t == TriggerKind.planEnds ? '' : num.$2,
                  onMinus: () => _setC((c) => c.copyWith(n: (c.n - num.$5).clamp(num.$3, num.$4))),
                  onPlus: () => _setC((c) => c.copyWith(n: (c.n + num.$5).clamp(num.$3, num.$4))),
                ),
              ),
            ),
          if (f.contains('date'))
            FieldBlock(
              label: 'Date',
              child: Align(
                alignment: Alignment.centerLeft,
                child: StepperBox(
                  value: '${c.dt} Oct 2026',
                  onMinus: () => _setC((c) => c.copyWith(dt: (c.dt - 1).clamp(11, 31))),
                  onPlus: () => _setC((c) => c.copyWith(dt: (c.dt + 1).clamp(11, 31))),
                ),
              ),
            ),
          if (f.contains('form'))
            FieldBlock(
              label: 'Form',
              child: SelectBox(
                value: EngageMock.formNames[c.f] ?? 'Choose a form',
                onTap: () async {
                  final v = await pickFromSheet<String>(
                    context,
                    title: 'Form',
                    items: [for (final e in EngageMock.formNames.entries) (e.key, e.value)],
                    selected: c.f,
                    iconOf: (_) => Icons.assignment_rounded,
                  );
                  if (v != null) _setC((c) => c.copyWith(f: v));
                },
              ),
            ),
          if (f.contains('time'))
            FieldBlock(
              label: 'Time',
              child: Align(
                alignment: Alignment.centerLeft,
                child: StepperBox(
                  value: _fmtT(c.t),
                  onMinus: () => _setC((c) => c.copyWith(t: (c.t - 1).clamp(0, 47))),
                  onPlus: () => _setC((c) => c.copyWith(t: (c.t + 1).clamp(0, 47))),
                ),
              ),
            ),
          if (note != null) Text(note, style: AppText.caption.copyWith(height: 1.4)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(9)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Starts: ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: _trigSummary(t, c)),
                      ],
                    ),
                    style: AppText.caption.copyWith(color: AppColors.accentText, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. who ----------------------------------------------------------------

  Widget _whoSection() {
    return Spaced(
      gap: 12,
      children: [
        FieldBlock(
          label: 'Package',
          child: SelectBox(
            value: _package.isEmpty ? 'Any package' : _package,
            onTap: () async {
              final v = await pickFromSheet<String>(
                context,
                title: 'Package',
                items: const [
                  ('', 'Any package'),
                  ('Quarterly Transformation', 'Quarterly Transformation'),
                  ('Monthly plan', 'Monthly plan'),
                  ('Quarterly plan', 'Quarterly plan'),
                ],
                selected: _package,
              );
              if (v != null) setState(() => _package = v);
            },
          ),
        ),
        FieldBlock(
          label: 'Trainer',
          child: SelectBox(
            value: _trainer.isEmpty ? 'Any trainer' : _trainer,
            onTap: () async {
              final v = await pickFromSheet<String>(
                context,
                title: 'Trainer',
                items: [('', 'Any trainer'), for (final t in PeopleMock.trainers.where((t) => t.active)) (t.name, t.name)],
                selected: _trainer,
              );
              if (v != null) setState(() => _trainer = v);
            },
          ),
        ),
        SwitchRow(
          title: 'Stop when the client responds',
          subtitle: 'The remaining steps are skipped once the client sends the form or replies.',
          value: _stop,
          onChanged: (v) => setState(() => _stop = v),
        ),
      ],
    );
  }

  // --- 3. steps --------------------------------------------------------------

  Widget _stepsSection() {
    return Spaced(
      gap: 10,
      children: [
        for (var i = 0; i < _steps.length; i++)
          _StepCard(
            no: i + 1,
            step: _steps[i],
            last: i == _steps.length - 1,
            onChanged: (s) => _setStep(i, s),
            onMenu: () => _stepMenu(i),
            onPickForm: () async {
              final v = await pickFromSheet<String>(
                context,
                title: 'Form',
                items: [for (final e in EngageMock.formNames.entries) (e.key, e.value)],
                selected: _steps[i].ref,
              );
              if (v != null) _setStep(i, _steps[i].copyWith(ref: v));
            },
            onPickTemplate: () async {
              final v = await pickFromSheet<String>(
                context,
                title: 'Message template',
                items: [for (final e in EngageMock.templateNames.entries) (e.key, e.value)],
                selected: _steps[i].ref,
              );
              if (v != null) _setStep(i, _steps[i].copyWith(ref: v));
            },
            onLink: (r) => context.push(r),
          ),
        if (_steps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
            child: Text('No steps yet. Add what should happen after the trigger.', textAlign: TextAlign.center, style: AppText.secondary),
          ),
        DashedAddButton(label: 'Add a step', onTap: _addStep),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onLabel, required this.onTurnOn, required this.onDraft, required this.onCancel});
  final String onLabel;
  final VoidCallback onTurnOn;
  final VoidCallback onDraft;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(onLabel, icon: Icons.bolt_rounded, expand: true, onPressed: onTurnOn),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', small: true, expand: true, onPressed: onCancel)),
            const SizedBox(width: 8),
            Expanded(child: AppButton.outline('Save as draft', small: true, expand: true, onPressed: onDraft)),
          ],
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? AppColors.accent : AppColors.line2),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.text2),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.no,
    required this.step,
    required this.last,
    required this.onChanged,
    required this.onMenu,
    required this.onPickForm,
    required this.onPickTemplate,
    required this.onLink,
  });
  final int no;
  final AutoStep step;
  final bool last;
  final ValueChanged<AutoStep> onChanged;
  final VoidCallback onMenu;
  final VoidCallback onPickForm;
  final VoidCallback onPickTemplate;
  final ValueChanged<String> onLink;

  @override
  Widget build(BuildContext context) {
    final s = step;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: s.kind.tint.bg, shape: BoxShape.circle),
                child: Icon(s.kind.icon, size: 14, color: s.kind.tint.fg),
              ),
              if (!last) Expanded(child: Container(width: 2, color: AppColors.line)),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppCard(
              clip: false,
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Step $no · ${s.kind.label}', style: AppText.bodyBold.copyWith(fontSize: 13)),
                              Text(EngageMock.stepLine(s), style: AppText.caption.copyWith(height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Step options',
                        onPressed: onMenu,
                        icon: const Icon(Icons.more_vert_rounded, size: 19, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(padding: const EdgeInsets.only(right: 8), child: _body(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channels() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in Channel.values)
          _ChannelChip(
            channel: c,
            on: step.channels.contains(c),
            onTap: () => onChanged(
              step.copyWith(channels: step.channels.contains(c) ? step.channels.where((x) => x != c).toList() : [...step.channels, c]),
            ),
          ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final s = step;
    switch (s.kind) {
      case StepKind.wait:
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StepperBox(
              value: '${s.amount}',
              onMinus: () => onChanged(s.copyWith(amount: (s.amount - 1).clamp(1, 72))),
              onPlus: () => onChanged(s.copyWith(amount: (s.amount + 1).clamp(1, 72))),
            ),
            SegmentedTabs<String>(
              expand: false,
              items: const [('hours', 'Hours'), ('days', 'Days')],
              value: s.unit,
              onChanged: (v) => onChanged(s.copyWith(unit: v)),
            ),
            Text('Pause before the next step', style: AppText.caption),
          ],
        );
      case StepKind.form:
        return Spaced(
          gap: 10,
          children: [
            FieldBlock(
              label: 'Form',
              child: SelectBox(value: EngageMock.formNames[s.ref] ?? 'Choose a form', onTap: onPickForm),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextLink('Open forms & check-ins', onTap: () => onLink(Routes.aForms)),
            ),
            FieldBlock(label: 'Send by', child: _channels()),
          ],
        );
      case StepKind.message:
        final prev = s.channels.isEmpty ? '' : (EngageMock.messagePreview[s.ref] ?? '');
        return Spaced(
          gap: 10,
          children: [
            FieldBlock(
              label: 'Message template',
              child: SelectBox(value: EngageMock.templateNames[s.ref] ?? 'Choose a template', onTap: onPickTemplate),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextLink('Edit message templates', onTap: () => onLink(Routes.aEmails)),
            ),
            FieldBlock(label: 'Send by', child: _channels()),
            if (prev.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.channels.first.label} preview'.toUpperCase(), style: AppText.overline.copyWith(fontSize: 10.5)),
                    const SizedBox(height: 4),
                    Text(prev, style: AppText.secondary.copyWith(color: AppColors.text2, height: 1.45)),
                  ],
                ),
              ),
          ],
        );
      case StepKind.assign:
        return Spaced(
          gap: 10,
          children: [
            FieldBlock(
              label: 'Task',
              child: TextFormField(
                initialValue: s.ref,
                style: AppText.body,
                onChanged: (v) => onChanged(s.copyWith(ref: v)),
              ),
            ),
            FieldBlock(
              label: 'For',
              child: SegmentedTabs<String>(
                items: const [('trainer', 'Assigned trainer'), ('owner', 'Owner')],
                value: s.unit,
                onChanged: (v) => onChanged(s.copyWith(unit: v)),
              ),
            ),
          ],
        );
    }
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.channel, required this.on, required this.onTap});
  final Channel channel;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.accentSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: on ? AppColors.accent : AppColors.line2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (on) ...[const Icon(Icons.check_rounded, size: 13, color: AppColors.accentText), const SizedBox(width: 5)],
              Text(
                channel.label,
                style: AppText.secondary.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: on ? AppColors.accentText : AppColors.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "In plain words" summary with what is still missing.
class _PlainWords extends StatelessWidget {
  const _PlainWords({required this.trigger, required this.applies, required this.steps, required this.stop, required this.problems});
  final String trigger;
  final String applies;
  final List<AutoStep> steps;
  final bool stop;
  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    Widget item(int n, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text('$n.', style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.muted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
    return SideCard(
      title: 'In plain words',
      children: [
        Text('This is what will happen for each client it applies to.', style: AppText.caption),
        const SizedBox(height: 10),
        item(
          1,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trigger, style: AppText.bodyBold.copyWith(fontSize: 13)),
              Text(applies, style: AppText.caption),
            ],
          ),
        ),
        for (var i = 0; i < steps.length; i++) item(i + 2, Text(EngageMock.stepLine(steps[i]), style: AppText.body.copyWith(fontSize: 13))),
        if (stop) const NoteBox('Stops when the client responds.', icon: Icons.front_hand_rounded),
        if (problems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 17, color: AppColors.warnText),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Not ready to turn on', style: AppText.bodyBold.copyWith(fontSize: 13, color: AppColors.warnText)),
                      for (final p in problems) Text(p, style: AppText.caption.copyWith(color: AppColors.warnText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
