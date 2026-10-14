import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import 'engage_ui.dart';

/// Opens the question editor. Returns the edited question, or null on cancel.
Future<FormQuestion?> showQuestionEditor(
  BuildContext context, {
  required FormQuestion initial,
  required bool isNew,
  int index = 0,
  int total = 0,
}) {
  return showAppSheet<FormQuestion>(
    context,
    title: isNew ? 'New question' : 'Edit question',
    subtitle: isNew ? 'Placed at the end of the form' : 'Question ${index + 1} of $total',
    builder: (_) => _QuestionEditor(initial: initial, isNew: isNew),
  );
}

/// "Add question" palette: one row per answer type.
Future<QuestionType?> showQuestionPalette(BuildContext context) {
  return showAppSheet<QuestionType>(
    context,
    title: 'Add question',
    builder: (ctx) => AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < QuestionType.values.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => Navigator.of(ctx).pop(QuestionType.values[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    TypeIcon(QuestionType.values[i]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(QuestionType.values[i].label, style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.add_rounded, size: 18, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Small grey square with the answer-type icon (fm-qi).
class TypeIcon extends StatelessWidget {
  const TypeIcon(this.type, {super.key, this.small = false, this.on = false});
  final QuestionType type;
  final bool small;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final s = small ? 20.0 : 28.0;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: on ? Colors.transparent : AppColors.sub, borderRadius: BorderRadius.circular(small ? 5 : 8)),
      child: Icon(type.icon, size: small ? 13 : 16, color: on ? AppColors.accentText : AppColors.text2),
    );
  }
}

class _QuestionEditor extends StatefulWidget {
  const _QuestionEditor({required this.initial, required this.isNew});
  final FormQuestion initial;
  final bool isNew;

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late FormQuestion _q = widget.initial;
  late final _text = TextEditingController(text: widget.initial.text);
  late final _help = TextEditingController(text: widget.initial.help);
  late final _opts = TextEditingController(
    text: (widget.initial.options.isEmpty ? const ['Gym', 'Home'] : widget.initial.options).join('\n'),
  );

  @override
  void dispose() {
    _text.dispose();
    _help.dispose();
    _opts.dispose();
    super.dispose();
  }

  void _pickType(QuestionType t) {
    setState(() {
      _q = _q.copyWith(type: t);
      if (t.hasOptions && _q.options.isEmpty) {
        _q = _q.copyWith(options: const ['Work', 'Travel', 'Low energy']);
        _opts.text = _q.options.join('\n');
      }
    });
  }

  void _save() {
    final opts = _opts.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (_q.type.hasOptions && opts.length < 2) {
      showToast(context, 'Add at least two options', subtitle: 'One option per line', kind: ToastKind.warn);
      return;
    }
    final text = _text.text.trim().isEmpty ? _q.type.sample : _text.text.trim();
    Navigator.of(context).pop(_q.copyWith(text: text, help: _help.text.trim(), options: _q.type.hasOptions ? opts : _q.options));
  }

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 14,
      children: [
        FieldBlock(
          label: 'Question',
          required: true,
          child: TextField(
            controller: _text,
            style: AppText.body,
            maxLines: null,
            decoration: InputDecoration(hintText: widget.isNew ? _q.type.sample : 'Enter the question'),
          ),
        ),
        FieldBlock(
          label: 'Answer type',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final t in QuestionType.values) _TypeChip(type: t, on: _q.type == t, onTap: () => _pickType(t))],
          ),
        ),
        if (_q.type.hasOptions) ...[
          FieldBlock(
            label: 'Options, one per line',
            hint: 'Add at least two options.',
            child: TextField(controller: _opts, style: AppText.body, minLines: 3, maxLines: 8),
          ),
          SwitchRow(
            title: 'Add an "Other" option',
            subtitle: 'The client can pick Other and type their own answer',
            value: _q.other,
            onChanged: (v) => setState(() => _q = _q.copyWith(other: v)),
          ),
        ],
        if (_q.type == QuestionType.photo)
          const NoteBox(
            'The client takes up to 3 photos or picks them from the gallery. They show in the client profile under Progress.',
            icon: Icons.photo_camera_rounded,
          ),
        if (_q.type == QuestionType.scale)
          const NoteBox('Clients rate from 1 to 5. Use the help text to say what 1 and 5 mean.', icon: Icons.linear_scale_rounded),
        FieldBlock(
          label: 'Help text (optional)',
          child: TextField(
            controller: _help,
            style: AppText.body,
            decoration: const InputDecoration(hintText: 'e.g. Empty stomach, same scale'),
          ),
        ),
        SwitchRow(
          title: 'Required',
          subtitle: 'The client must answer it',
          value: _q.required,
          onChanged: (v) => setState(() => _q = _q.copyWith(required: v)),
        ),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(widget.isNew ? 'Add question' : 'Save question', icon: Icons.check_rounded, onPressed: _save),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.on, required this.onTap});
  final QuestionType type;
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
          padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TypeIcon(type, small: true, on: on),
              const SizedBox(width: 4),
              Text(
                type.label,
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
