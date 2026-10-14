import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/programs_mock.dart';
import 'package:train_with_vimal/data/models/programs.dart';

import 'build_widgets.dart';

// Sheet bodies used by the program builder. Each is stateful and ends with its
// own Cancel / main buttons so the button label can follow the state.

/// "Edit sets and rest" (prescription modal).
class PrescriptionForm extends StatefulWidget {
  const PrescriptionForm({super.key, required this.exercise, required this.onSave});
  final ProgramExercise exercise;
  final ValueChanged<ProgramExercise> onSave;

  @override
  State<PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  late int _sets = widget.exercise.sets;
  late int _rest = widget.exercise.rest;
  late int _rpe = widget.exercise.rpe;
  late final _reps = TextEditingController(text: widget.exercise.reps);
  late final _tempo = TextEditingController(text: widget.exercise.tempo);
  late final _note = TextEditingController(text: widget.exercise.note);

  @override
  void dispose() {
    _reps.dispose();
    _tempo.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _line =>
      '$_sets × ${_reps.text}${_rpe > 0 ? ' · RPE $_rpe' : ''}${_tempo.text.isNotEmpty ? ' · Tempo ${_tempo.text}' : ''} · Rest ${restLabel(_rest)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_line, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.accentText)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StepperField(
                label: 'Sets',
                value: '$_sets',
                onMinus: () => setState(() => _sets = (_sets - 1).clamp(1, 12)),
                onPlus: () => setState(() => _sets = (_sets + 1).clamp(1, 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Reps'),
                  SizedBox(height: 40, child: TextField(controller: _reps, style: AppText.body, onChanged: (_) => setState(() {}))),
                  const HintText('e.g. 8–10, AMRAP, 45 s'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StepperField(
                label: 'Rest after each set',
                value: '$_rest',
                unit: 's',
                onMinus: () => setState(() => _rest = (_rest - 15).clamp(0, 300)),
                onPlus: () => setState(() => _rest = (_rest + 15).clamp(0, 300)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StepperField(
                label: 'RPE (0 = not set)',
                value: '$_rpe',
                onMinus: () => setState(() => _rpe = (_rpe - 1).clamp(0, 10)),
                onPlus: () => setState(() => _rpe = (_rpe + 1).clamp(0, 10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const FieldLabel('Tempo (optional)'),
        TextField(controller: _tempo, style: AppText.body, decoration: const InputDecoration(hintText: 'e.g. 3-1-1'), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        const FieldLabel('Note for the client (optional)'),
        TextField(controller: _note, style: AppText.body, maxLines: 2, decoration: const InputDecoration(hintText: 'e.g. 30° incline only')),
        SheetButtons(
          label: 'Update',
          icon: Icons.check_rounded,
          onPressed: () => widget.onSave(widget.exercise.copyWith(
            sets: _sets,
            reps: _reps.text.trim().isEmpty ? widget.exercise.reps : _reps.text.trim(),
            rest: _rest,
            rpe: _rpe,
            tempo: _tempo.text.trim(),
            note: _note.text.trim(),
          )),
        ),
      ],
    );
  }
}

/// "Add exercises" drawer: search, muscle tabs, multi-select list from the library.
class ExercisePicker extends StatefulWidget {
  const ExercisePicker({super.key, required this.library, required this.onDay, required this.onAdd});
  final List<Exercise> library;

  /// Names already on the selected day (shown as "On this day", not pickable).
  final List<String> onDay;
  final ValueChanged<List<Exercise>> onAdd;

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  static const _tabs = ['All', ...ProgramsMock.muscles];
  int _tab = 0;
  String _q = '';
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    final lib = widget.library;
    final q = _q.trim().toLowerCase();
    final list = lib.where((e) => (_tab == 0 || e.muscle == _tabs[_tab]) && (q.isEmpty || e.name.toLowerCase().contains(q))).toList();
    final n = _picked.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(hint: 'Search exercises', onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 6),
        UnderlineTabs(
          labels: [for (final t in _tabs) '$t ${t == 'All' ? lib.length : lib.where((e) => e.muscle == t).length}'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Text('No exercise matches. Create it in the exercise library.', style: AppText.secondary, textAlign: TextAlign.center),
          )
        else
          JoinedList(children: [for (final e in list) _row(e)]),
        SheetButtons(
          note: n > 0 ? '$n selected' : 'Tick the exercises to add',
          label: n > 1 ? 'Add $n exercises' : 'Add exercise',
          icon: Icons.add_rounded,
          onPressed: n == 0 ? null : () => widget.onAdd([for (final name in _picked) lib.firstWhere((e) => e.name == name)]),
        ),
      ],
    );
  }

  Widget _row(Exercise e) {
    final on = _picked.contains(e.name);
    final there = widget.onDay.contains(e.name);
    return PickRow(
      selected: on,
      disabled: there,
      onTap: () => setState(() => on ? _picked.remove(e.name) : _picked.add(e.name)),
      child: Row(
        children: [
          MediaThumb(tone: e.tone, width: 52, height: 52, radius: 8, iconSize: 18, duration: e.hasVideo ? e.videoDur : null),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text(e.works, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (there) ...[const AppBadge('On this day', tone: BadgeTone.info), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        '${e.equipment} · ${e.muscle == 'Cardio' ? '20 min' : '${e.sets} × ${e.reps}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Assign to clients" modal.
class AssignForm extends StatefulWidget {
  const AssignForm({super.key, required this.assigned, required this.otherProgramOf, required this.onSave});
  final List<String> assigned;

  /// Short name of another program the client follows, if any.
  final String? Function(String client) otherProgramOf;
  final ValueChanged<List<String>> onSave;

  @override
  State<AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<AssignForm> {
  late final List<String> _sel = [...widget.assigned];
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = ProgramsMock.clients.where((c) => q.isEmpty || c.name.toLowerCase().contains(q)).toList();
    final n = _sel.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(hint: 'Search clients', onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 10),
        JoinedList(children: [
          for (final c in list)
            PickRow(
              selected: _sel.contains(c.name),
              onTap: () => setState(() => _sel.contains(c.name) ? _sel.remove(c.name) : _sel.add(c.name)),
              child: _ClientLine(client: c, trailing: _sel.contains(c.name) ? null : widget.otherProgramOf(c.name)),
            ),
        ]),
        const HintText('Clients follow this master plan as it is. A trainer can make a custom version for one client from the client page.', top: 10),
        SheetButtons(
          label: n > 0 ? 'Save · ${plural(n, 'client')}' : 'Save · no clients',
          icon: Icons.check_rounded,
          onPressed: () => widget.onSave([
            for (final c in ProgramsMock.clients)
              if (_sel.contains(c.name)) c.name,
          ]),
        ),
      ],
    );
  }
}

class _ClientLine extends StatelessWidget {
  const _ClientLine({required this.client, this.trailing});
  final ProgramClient client;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Avatar(client.initials, size: 30, color: AvatarColor.values[client.colorIndex]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
              Text('${client.goal} · ${client.trainer}', style: AppText.caption),
            ],
          ),
        ),
        if (trailing != null) Text(trailing!, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// "Assigned clients" drawer.
class AssignedList extends StatelessWidget {
  const AssignedList({super.key, required this.clients, required this.onOpen, required this.onChange});
  final List<ProgramClient> clients;
  final ValueChanged<ProgramClient> onOpen;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in clients)
          InkWell(
            onTap: () => onOpen(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  Avatar(c.initials, size: 36, color: AvatarColor.values[c.colorIndex]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                        Text('${c.goal} · ${c.trainer}', style: AppText.caption),
                      ],
                    ),
                  ),
                  AppBadge(c.custom ? 'Custom' : 'Master', tone: c.custom ? BadgeTone.warn : BadgeTone.info),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
                ],
              ),
            ),
          ),
        if (clients.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text('Nobody follows this program yet.', style: AppText.secondary, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 14),
        const NoteBox(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'Master', style: TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: ' follows this plan as it is. '),
            TextSpan(text: 'Custom', style: TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: ' has changes made only for that client, which stay when the master plan is updated.'),
          ])),
        ),
        SheetButtons(
          cancelLabel: 'Close',
          label: clients.isEmpty ? 'Assign clients' : 'Change clients',
          icon: Icons.group_add_rounded,
          onPressed: onChange,
        ),
      ],
    );
  }
}

/// One-field name modal (Rename program, Rename day, Add day).
class NameForm extends StatefulWidget {
  const NameForm({super.key, required this.label, required this.initial, required this.button, required this.onSave, this.hint});
  final String label;
  final String initial;
  final String button;
  final String? hint;
  final ValueChanged<String> onSave;

  @override
  State<NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<NameForm> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    final v = _c.text.trim();
    if (v.isNotEmpty) widget.onSave(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(widget.label, required: true),
        TextField(
          controller: _c,
          autofocus: true,
          style: AppText.body,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _save(),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: widget.hint),
        ),
        if (widget.hint != null) HintText(widget.hint!),
        SheetButtons(label: widget.button, icon: Icons.check_rounded, onPressed: _c.text.trim().isEmpty ? null : _save),
      ],
    );
  }
}

/// "Edit for this program": a per-program copy of a library exercise.
class CustomizeForm extends StatefulWidget {
  const CustomizeForm({
    super.key,
    required this.exercise,
    required this.library,
    required this.programName,
    required this.onSave,
    required this.onReset,
  });
  final ProgramExercise exercise;
  final Exercise? library;
  final String programName;
  final ValueChanged<ExerciseOverride> onSave;
  final VoidCallback onReset;

  @override
  State<CustomizeForm> createState() => _CustomizeFormState();
}

class _CustomizeFormState extends State<CustomizeForm> {
  late ExerciseOverride _d = widget.exercise.custom ??
      ExerciseOverride(
        name: widget.exercise.name,
        video: 'lib',
        steps: widget.library?.howTo ?? const [],
        cues: widget.library?.cues ?? const [],
      );
  late final _name = TextEditingController(text: _d.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _ln => widget.exercise.name;

  @override
  Widget build(BuildContext context) {
    final videos = [
      ('lib', 'Same as library', '$_ln · demo · 0:38', 0, '0:38'),
      ('cl', 'Another video from Content library', '$_ln · easier version · 0:52', 1, '0:52'),
      ('yt', 'YouTube link', '${_ln == 'Dips' ? 'Bench dips for beginners' : '$_ln tutorial'} · 4:05', 2, '4:05'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteBox(
          child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'Changes stay inside '),
            TextSpan(text: widget.programName, style: const TextStyle(fontWeight: FontWeight.w800)),
            const TextSpan(text: '. The exercise library and other programs keep the original. While it is edited here, library updates skip it in this program.'),
          ])),
        ),
        const SizedBox(height: 14),
        const FieldLabel('Name in this program'),
        TextField(controller: _name, style: AppText.body),
        HintText('Library name: $_ln'),
        const SizedBox(height: 14),
        const FieldLabel('Video'),
        JoinedList(children: [
          for (final v in videos)
            PickRow(
              square: false,
              selected: _d.video == v.$1,
              onTap: () => setState(() => _d = _d.copyWith(video: v.$1)),
              child: Row(
                children: [
                  MediaThumb(tone: v.$4, width: 56, height: 40, radius: 6, iconSize: 14, duration: v.$5, youtube: v.$1 == 'yt'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.$2, style: AppText.bodyBold.copyWith(fontSize: 13)),
                        Text(v.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ]),
        if (_d.video == 'yt') ...[
          const SizedBox(height: 14),
          const FieldLabel('YouTube link'),
          TextFormField(initialValue: 'https://youtu.be/0326dy_-CzM', style: AppText.body),
          const HintText('Plays inside the app.'),
        ],
        const SizedBox(height: 14),
        EditableList(
          label: 'How to',
          placeholder: 'Write the step',
          addLabel: 'Add step',
          items: _d.steps,
          onChanged: (l) => setState(() => _d = _d.copyWith(steps: l)),
        ),
        const SizedBox(height: 14),
        EditableList(
          label: 'Form cues',
          placeholder: 'Write the cue',
          addLabel: 'Add cue',
          items: _d.cues,
          onChanged: (l) => setState(() => _d = _d.copyWith(cues: l)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Text('Muscles', style: AppText.caption),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.library?.works ?? '', style: AppText.bodyBold.copyWith(fontSize: 13))),
              Text('From the library', style: AppText.caption.copyWith(fontSize: 11.5)),
            ],
          ),
        ),
        if (widget.exercise.custom != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onReset,
              style: TextButton.styleFrom(foregroundColor: AppColors.bad),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset to library'),
            ),
          ),
        ],
        SheetButtons(
          label: 'Save for this program',
          icon: Icons.check_rounded,
          onPressed: () {
            final n = _name.text.trim();
            widget.onSave(_d.copyWith(
              name: n.isEmpty ? _ln : n,
              steps: _d.steps.where((s) => s.trim().isNotEmpty).toList(),
              cues: _d.cues.where((s) => s.trim().isNotEmpty).toList(),
            ));
          },
        ),
      ],
    );
  }
}

/// Numbered list of text rows with remove buttons and an "Add" text button.
class EditableList extends StatelessWidget {
  const EditableList({super.key, this.label = '', required this.placeholder, required this.addLabel, required this.items, required this.onChanged, this.numbered = true});
  final String label;
  final bool numbered;
  final String placeholder;
  final String addLabel;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) FieldLabel(label),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                numbered ? CountBubble(i + 1) : const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$label-$i-${items.length}'),
                    initialValue: items[i],
                    autofocus: items[i].isEmpty,
                    style: AppText.body.copyWith(fontSize: 13.5),
                    decoration: InputDecoration(hintText: placeholder, isDense: true),
                    onChanged: (v) => onChanged([for (var j = 0; j < items.length; j++) j == i ? v : items[j]]),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onChanged([...items]..removeAt(i)),
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onChanged([...items, '']),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

/// Small numbered square (count / sq).
class CountBubble extends StatelessWidget {
  const CountBubble(this.n, {super.key, this.active = true});
  final int n;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? AppColors.accentSoft : AppColors.sub, borderRadius: BorderRadius.circular(6)),
      child: Text('$n', style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: active ? AppColors.accentText : AppColors.muted)),
    );
  }
}
