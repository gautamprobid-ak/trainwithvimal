import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/programs_mock.dart';
import 'package:train_with_vimal/data/models/programs.dart';

import '../programs/widgets/build_widgets.dart';
import '../programs/widgets/builder_sheets.dart';
import 'exercises_state.dart';

/// Content library videos to pick from: name, length, tone, added.
const _libVideos = [
  ('Landmine press · side view', '0:38', 0, '2 Oct'),
  ('Landmine press · front view', '0:41', 1, '2 Oct'),
  ('Half-kneeling press · coaching', '1:12', 2, '28 Sep'),
  ('Shoulder warm-up', '2:05', 3, '21 Sep'),
  ('Bench press · setup', '0:42', 0, '14 Sep'),
  ('Push-up progressions', '1:48', 1, '9 Sep'),
];

const _what = {
  'Chest': 'push the arms forward',
  'Back': 'pull the shoulder blades back',
  'Shoulders': 'lift the arm',
  'Triceps': 'straighten the arm at the top',
  'Biceps': 'bend the elbow',
  'Forearms': 'hold the grip',
  'Core': 'keep the body still',
  'Glutes': 'drive the hips forward',
  'Hamstrings': 'bend the knee',
  'Quads': 'straighten the knee',
  'Calves': 'push through the toes',
};

const _primaryOpts = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Glutes'];
const _alsoOpts = ['Chest', 'Back', 'Shoulders', 'Triceps', 'Biceps', 'Forearms', 'Core', 'Glutes', 'Hamstrings', 'Quads', 'Calves'];

/// Design: ExerciseAddMobile.dc.html — everything the exercise page shows.
class ExerciseAddScreen extends ConsumerStatefulWidget {
  const ExerciseAddScreen({super.key});

  @override
  ConsumerState<ExerciseAddScreen> createState() => _ExerciseAddScreenState();
}

class _ExerciseAddScreenState extends ConsumerState<ExerciseAddScreen> {
  final _name = TextEditingController();
  final _reps = TextEditingController(text: '8–12');
  final _tempo = TextEditingController();
  String? _nameError;
  String _equipment = 'Barbell';
  String _level = 'Intermediate';
  LogType _log = LogType.weightReps;
  int _sets = 3;
  int _rest = 90;
  int _rpe = 0;
  List<String> _steps = ['Set up half-kneeling, bar at the shoulder.', 'Press up and slightly forward until the arm is straight.'];
  List<String> _cues = ['Ribs down, glute squeezed.', 'Elbow under the bar, not flared.'];
  bool _fromLib = true;
  int _vid = 1;
  bool _yt = true;
  bool _coverFrame = true;
  int _frame = 1;
  String _primary = 'Shoulders';
  List<String> _also = ['Triceps', 'Core'];
  Map<String, bool> _strong = {'Triceps': true, 'Core': false};

  @override
  void dispose() {
    _name.dispose();
    _reps.dispose();
    _tempo.dispose();
    super.dispose();
  }

  void _setLog(LogType t) => setState(() {
        _log = t;
        _reps.text = switch (t) { LogType.weightReps => '8–12', LogType.time => '30 s', LogType.cardio => '20 min' };
      });

  void _toggleAlso(String m) {
    if (m == _primary) return;
    setState(() {
      if (_also.contains(m)) {
        _also = _also.where((x) => x != m).toList();
      } else {
        _also = [..._also, m];
        _strong = {..._strong, m: _strong[m] ?? false};
      }
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the exercise a name');
      return;
    }
    final store = ref.read(exercisesProvider.notifier);
    var id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (ref.read(exercisesProvider).byId(id) != null) id = '$id-${DateTime.now().millisecondsSinceEpoch}';
    final also = [for (final m in _also) MuscleWork(m, note: _what[m] == null ? '' : '${_what[m]![0].toUpperCase()}${_what[m]!.substring(1)}', strong: _strong[m] ?? false)];
    final v = _libVideos[_vid];
    store.add(Exercise(
      id: id,
      name: name,
      muscle: _primary,
      works: _also.isEmpty ? _primary : '$_primary · also ${_also.join(', ')}',
      equipment: _equipment,
      level: _level,
      custom: true,
      hasVideo: _fromLib || _yt,
      videoDur: _fromLib ? v.$2 : '4:12',
      videoTitle: _fromLib ? v.$1 : 'How to do the $name',
      tone: _fromLib ? v.$3 : 2,
      sets: _sets,
      reps: _reps.text.trim().isEmpty ? '8–12' : _reps.text.trim(),
      rest: _rest,
      rpe: _rpe,
      tempo: _tempo.text.trim(),
      logType: _log,
      howTo: _steps.where((s) => s.trim().isNotEmpty).toList(),
      cues: _cues.where((s) => s.trim().isNotEmpty).toList(),
      primaryNote: _primary,
      also: also,
    ));
    showToast(context, 'Exercise saved', subtitle: '$name is in the library', kind: ToastKind.ok);
    context.pushReplacement(context.rolePath(Routes.exercise(id)));
  }

  void _pickVideo() {
    showAppSheet<void>(
      context,
      title: 'Pick a video',
      subtitle: 'From your Content library',
      builder: (ctx) => _VideoPicker(
        current: _vid,
        onUse: (i) {
          Navigator.of(ctx).pop();
          setState(() => _vid = i);
        },
        onUpload: () {
          Navigator.of(ctx).pop();
          context.push(context.rolePath(Routes.content));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      children: [
        SubPageHeader(title: 'New exercise', subtitle: 'Everything the exercise page shows is filled in here.'),
        _basics(),
        _defaults(),
        _card('How to', 'Shows on the How to tab', EditableList(
          placeholder: 'Add a step',
          addLabel: 'Add step',
          items: _steps,
          onChanged: (l) => setState(() => _steps = l),
        )),
        _card('Form cues (optional)', 'Shows on the Form cues tab', EditableList(
          placeholder: 'Add a cue',
          addLabel: 'Add cue',
          numbered: false,
          items: _cues,
          onChanged: (l) => setState(() => _cues = l),
        )),
        _video(),
        _muscles(),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', expand: true, onPressed: () => context.canPop() ? context.pop() : context.go(context.rolePath(Routes.exercises)))),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: AppButton('Save exercise', icon: Icons.check_rounded, expand: true, onPressed: _save)),
          ],
        ),
      ],
    );
  }

  Widget _card(String title, String caption, Widget child) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SectionHead(title, caption: caption), const SizedBox(height: 12), child],
        ),
      );

  Widget _basics() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Basics', style: AppText.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const FieldLabel('Name', required: true),
          TextField(
            controller: _name,
            style: AppText.body,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _nameError == null ? null : setState(() => _nameError = null),
            decoration: InputDecoration(hintText: 'e.g. Landmine Press (half-kneeling)', errorText: _nameError),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Equipment'),
          DropdownButtonFormField<String>(
            initialValue: _equipment,
            style: AppText.body,
            icon: const Icon(Icons.expand_more_rounded),
            items: [for (final e in ProgramsMock.equipment) DropdownMenuItem(value: e, child: Text(e))],
            onChanged: (v) => setState(() => _equipment = v ?? _equipment),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Level'),
          MiniTabs(
            labels: const ['Beginner', 'Intermediate', 'Advanced'],
            index: const ['Beginner', 'Intermediate', 'Advanced'].indexOf(_level),
            expand: true,
            onChanged: (i) => setState(() => _level = const ['Beginner', 'Intermediate', 'Advanced'][i]),
          ),
        ],
      ),
    );
  }

  Widget _defaults() {
    final (lbl, cap) = switch (_log) {
      LogType.weightReps => ('Reps', 'Client logs kg × reps per set, or Bodyweight (BW, BW+5, BW−10 for assistance).'),
      LogType.time => ('Time per set', 'Client logs seconds per set, for holds like plank or wall sit.'),
      LogType.cardio => ('Minutes', 'Client logs minutes and distance (km). Speed, incline or level go in the program note.'),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead('Default sets and reps', caption: 'Filled in when added to a program'),
          const SizedBox(height: 12),
          const FieldLabel('Client logs'),
          MiniTabs(
            labels: const ['Weight & reps', 'Time', 'Cardio'],
            index: _log.index,
            expand: true,
            onChanged: (i) => _setLog(LogType.values[i]),
          ),
          HintText(cap),
          const SizedBox(height: 14),
          Row(
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
                  children: [FieldLabel(lbl), SizedBox(height: 40, child: TextField(controller: _reps, style: AppText.body))],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StepperField(
                  label: 'Rest',
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
          TextField(controller: _tempo, style: AppText.body, decoration: const InputDecoration(hintText: 'e.g. 3-1-1')),
          const HintText('Every program day can change these. The client sees what the program day says.', top: 10),
        ],
      ),
    );
  }

  Widget _video() {
    final v = _libVideos[_vid];
    final tone = _fromLib ? v.$3 : 2;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead('Video and image', caption: 'Shows at the top of the exercise page'),
          const SizedBox(height: 12),
          const FieldLabel('Video'),
          MiniTabs(
            labels: const ['From content library', 'YouTube link'],
            index: _fromLib ? 0 : 1,
            expand: true,
            onChanged: (i) => setState(() => _fromLib = i == 0),
          ),
          const SizedBox(height: 12),
          if (_fromLib) ...[
            _VideoRow(
              tone: v.$3,
              dur: v.$2,
              title: v.$1,
              sub: 'Content library · ${v.$2} · added ${v.$4}',
              trailing: AppButton.outline('Change', small: true, onPressed: _pickVideo),
            ),
            const HintText('Videos you upload in the Content library show up here.', top: 8),
          ] else ...[
            if (_yt) ...[
              TextFormField(
                initialValue: 'https://youtu.be/7rG2bq1b0Zc',
                style: AppText.body,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.link_rounded, size: 18)),
              ),
              const SizedBox(height: 10),
              _VideoRow(
                tone: 2,
                dur: '4:12',
                youtube: true,
                title: 'How to do the Landmine Press',
                sub: 'YouTube · 4:12 · Coach Ravi Fitness',
                trailing: IconButton(
                  tooltip: 'Remove video',
                  onPressed: () => setState(() => _yt = false),
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                ),
              ),
            ] else
              TextField(
                style: AppText.body,
                onTap: () => setState(() => _yt = true),
                readOnly: true,
                decoration: const InputDecoration(hintText: 'Paste a YouTube link', prefixIcon: Icon(Icons.link_rounded, size: 18)),
              ),
            const HintText('Plays inside the app. Public or unlisted videos only.', top: 8),
          ],
          const SizedBox(height: 14),
          const FieldLabel('Cover image'),
          MiniTabs(
            labels: const ['Frame from the video', 'Upload image'],
            index: _coverFrame ? 0 : 1,
            expand: true,
            onChanged: (i) => setState(() => _coverFrame = i == 0),
          ),
          const SizedBox(height: 12),
          if (_coverFrame)
            Row(
              children: [
                for (final (i, t) in const ['0:04', '0:12', '0:21', '0:33'].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _Frame(time: t, tone: i == 1 ? tone : (tone + i) % 4, on: _frame == i, onTap: () => setState(() => _frame = i))),
                ],
              ],
            )
          else
            InkWell(
              onTap: () => showToast(context, 'Image picker opened', subtitle: 'JPG or PNG, up to 5 MB', kind: ToastKind.info),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line2, width: 1.5),
                ),
                child: Row(
                  children: [
                    const TintIcon(Icons.upload_rounded, tint: Tint.blue, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            const TextSpan(children: [
                              TextSpan(text: 'Drop an image here or '),
                              TextSpan(text: 'browse', style: TextStyle(color: AppColors.accentText)),
                            ]),
                            style: AppText.bodyBold.copyWith(fontSize: 13.5),
                          ),
                          Text('JPG or PNG, up to 5 MB. Square or 4:3 looks best.', style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const HintText('The cover shows in the exercise library, the program builder and the client app.', top: 8),
        ],
      ),
    );
  }

  Widget _muscles() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead('Muscles', caption: 'Shows on the Muscles tab'),
          const SizedBox(height: 12),
          const FieldLabel('Primary muscle'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _primaryOpts)
                ChoicePill(m, selected: _primary == m, accent: false, onTap: () => setState(() {
                      _primary = m;
                      _also = _also.where((x) => x != m).toList();
                    })),
            ],
          ),
          const HintText('Decides where the exercise shows in the library filter.'),
          const SizedBox(height: 14),
          const FieldLabel('Also works (optional)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _alsoOpts.where((x) => x != _primary))
                ChoicePill(m, selected: _also.contains(m), accent: true, icon: _also.contains(m) ? Icons.check_rounded : null, onTap: () => _toggleAlso(m)),
            ],
          ),
          const SizedBox(height: 16),
          Overline('How much it works them', padding: const EdgeInsets.only(left: 2, bottom: 8)),
          if (_also.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
              child: Text('Pick muscles above.', style: AppText.secondary, textAlign: TextAlign.center),
            ),
          for (final m in _also) _AlsoRow(
            name: m,
            strong: _strong[m] ?? false,
            hint: 'e.g. ${_what[m] ?? 'helps keep the position'}',
            onLevel: (s) => setState(() => _strong = {..._strong, m: s}),
            onRemove: () => _toggleAlso(m),
          ),
        ],
      ),
    );
  }
}

class _AlsoRow extends StatelessWidget {
  const _AlsoRow({required this.name, required this.strong, required this.hint, required this.onLevel, required this.onRemove});
  final String name;
  final bool strong;
  final String hint;
  final ValueChanged<bool> onLevel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
              MiniTabs(labels: const ['Light', 'Strong'], index: strong ? 1 : 0, onChanged: (i) => onLevel(i == 1)),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(style: AppText.body.copyWith(fontSize: 13), decoration: InputDecoration(hintText: hint, isDense: true)),
        ],
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.tone, required this.dur, required this.title, required this.sub, required this.trailing, this.youtube = false});
  final int tone;
  final String dur;
  final String title;
  final String sub;
  final Widget trailing;
  final bool youtube;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          MediaThumb(tone: tone, width: 84, height: 54, radius: 8, iconSize: 18, duration: dur, youtube: youtube),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: 6),
          trailing,
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.time, required this.tone, required this.on, required this.onTap});
  final String time;
  final int tone;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? AppColors.accent : Colors.transparent, width: 2),
            ),
            child: AspectRatio(aspectRatio: 16 / 10, child: MediaThumb(tone: tone, radius: 8, iconSize: 16)),
          ),
          const SizedBox(height: 4),
          Text(time, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600, color: on ? AppColors.accentText : AppColors.muted)),
        ],
      ),
    );
  }
}

class _VideoPicker extends StatefulWidget {
  const _VideoPicker({required this.current, required this.onUse, required this.onUpload});
  final int current;
  final ValueChanged<int> onUse;
  final VoidCallback onUpload;

  @override
  State<_VideoPicker> createState() => _VideoPickerState();
}

class _VideoPickerState extends State<_VideoPicker> {
  late int _pick = widget.current;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(hint: 'Search videos', onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 10),
        JoinedList(children: [
          for (final (i, v) in _libVideos.indexed)
            if (q.isEmpty || v.$1.toLowerCase().contains(q))
              PickRow(
                square: false,
                selected: _pick == i,
                onTap: () => setState(() => _pick = i),
                child: Row(
                  children: [
                    MediaThumb(tone: v.$3, width: 64, height: 42, radius: 6, iconSize: 14, duration: v.$2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.$1, style: AppText.bodyBold.copyWith(fontSize: 13)),
                          Text('Video · added ${v.$4}', style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ]),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: widget.onUpload, icon: const Icon(Icons.upload_rounded, size: 18), label: const Text('Upload to library')),
        ),
        SheetButtons(label: 'Use video', icon: Icons.check_rounded, onPressed: () => widget.onUse(_pick)),
      ],
    );
  }
}
