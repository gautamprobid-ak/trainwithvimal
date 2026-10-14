import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import 'engage_ui.dart';

/// Opens the client preview of a form (the design's preview drawer).
Future<void> showFormPreview(BuildContext context, {required String name, required List<FormQuestion> questions}) {
  return showAppSheet(
    context,
    title: name,
    subtitle: 'Client preview · ${questionCount(questions.length)}',
    builder: (_) => FormPreview(questions: questions),
    actions: (ctx) => [AppButton('Close', onPressed: () => Navigator.of(ctx).pop())],
  );
}

/// What the client sees. Choices can be tapped; nothing is saved.
class FormPreview extends StatefulWidget {
  const FormPreview({super.key, required this.questions});
  final List<FormQuestion> questions;

  @override
  State<FormPreview> createState() => _FormPreviewState();
}

class _FormPreviewState extends State<FormPreview> {
  /// Picked answers per question index.
  final Map<int, List<String>> _sel = {};

  void _pick(int i, FormQuestion q, String o) {
    final got = _sel[i] ?? const [];
    setState(() {
      if (q.type == QuestionType.multiChoice) {
        _sel[i] = got.contains(o) ? got.where((x) => x != o).toList() : [...got, o];
      } else {
        _sel[i] = [o];
      }
    });
  }

  Future<void> _openDropdown(int i, FormQuestion q) async {
    final opts = [...q.options, if (q.other) 'Other'];
    final v = await pickFromSheet<String>(context, title: q.text, items: [for (final o in opts) (o, o)], selected: _sel[i]?.firstOrNull);
    if (v != null) setState(() => _sel[i] = [v]);
  }

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    return Spaced(
      gap: 18,
      children: [
        for (var i = 0; i < qs.length; i++) _question(i, qs[i]),
        if (qs.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(12)),
            child: Text('This form has no questions yet.', textAlign: TextAlign.center, style: AppText.secondary),
          ),
        const NoteBox('This is a preview. Answers typed here are not saved.', icon: Icons.visibility_rounded),
      ],
    );
  }

  Widget _question(int i, FormQuestion q) {
    final got = _sel[i] ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(6)),
              child: Text(
                '${i + 1}',
                style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(q.text, style: AppText.bodyBold.copyWith(height: 1.35))),
            if (q.required) ...[
              const SizedBox(width: 6),
              Text(
                'Required',
                style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.badText),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (q.help.isNotEmpty) ...[Text(q.help, style: AppText.caption), const SizedBox(height: 8)],
              _answer(i, q, got),
              if (got.contains('Other')) ...[const SizedBox(height: 8), const _FakeInput('Type your answer')],
            ],
          ),
        ),
      ],
    );
  }

  Widget _answer(int i, FormQuestion q, List<String> got) {
    switch (q.type) {
      case QuestionType.shortText:
        return const _FakeInput('Your answer');
      case QuestionType.number:
        return const _FakeInput('0');
      case QuestionType.longText:
        return const _FakeInput('Your answer', minHeight: 64);
      case QuestionType.scale:
        return _Boxes(labels: const ['1', '2', '3', '4', '5'], selected: got, onTap: (o) => _pick(i, q, o));
      case QuestionType.yesNo:
        return _Boxes(labels: const ['Yes', 'No'], selected: got, onTap: (o) => _pick(i, q, o));
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        final multi = q.type == QuestionType.multiChoice;
        return Column(
          children: [
            for (final o in [...q.options, if (q.other) 'Other'])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ChoiceRow(label: o, on: got.contains(o), square: multi, onTap: () => _pick(i, q, o)),
              ),
          ],
        );
      case QuestionType.dropdown:
        return SelectBox(value: got.isEmpty ? 'Choose one' : got.first, placeholder: got.isEmpty, onTap: () => _openDropdown(i, q));
      case QuestionType.photo:
        return InkWell(
          onTap: () => showToast(context, 'Preview only', subtitle: 'Clients add photos from the camera or gallery'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line2),
              color: AppColors.bg,
            ),
            child: Column(
              children: [
                const Icon(Icons.add_a_photo_rounded, color: AppColors.muted, size: 22),
                const SizedBox(height: 4),
                Text('Add photos', style: AppText.bodyBold.copyWith(fontSize: 13)),
                Text('Camera or gallery · up to 3', style: AppText.caption),
              ],
            ),
          ),
        );
    }
  }
}

class _FakeInput extends StatelessWidget {
  const _FakeInput(this.hint, {this.minHeight = 40});
  final String hint;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return TextField(
      minLines: minHeight > 40 ? 3 : 1,
      maxLines: minHeight > 40 ? 5 : 1,
      style: AppText.body,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _Boxes extends StatelessWidget {
  const _Boxes({required this.labels, required this.selected, required this.onTap});
  final List<String> labels;
  final List<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(labels[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(labels[i]) ? AppColors.accentSoft : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected.contains(labels[i]) ? AppColors.accent : AppColors.line2),
                ),
                child: Text(
                  labels[i],
                  style: AppText.bodyBold.copyWith(
                    fontSize: 13,
                    color: selected.contains(labels[i]) ? AppColors.accentText : AppColors.text2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.label, required this.on, required this.square, required this.onTap});
  final String label;
  final bool on;
  final bool square;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.accentSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: on ? AppColors.accent : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            children: [
              PickCheck(on: on, square: square),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: AppText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
