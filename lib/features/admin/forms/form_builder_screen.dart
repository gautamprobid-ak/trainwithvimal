import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import 'forms_state.dart';
import 'widgets/engage_ui.dart';
import 'widgets/form_preview.dart';
import 'widgets/question_editor.dart';

/// Design: FormBuilderMobile.dc.html — add, reorder and edit the questions of
/// one form. Opens the form given by `?id=` (the weekly check-in by default).
class FormBuilderScreen extends ConsumerStatefulWidget {
  const FormBuilderScreen({super.key});

  @override
  ConsumerState<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends ConsumerState<FormBuilderScreen> {
  String? _id;

  FormsNotifier get _forms => ref.read(formsProvider.notifier);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _id ??= GoRouterState.of(context).uri.queryParameters['id'] ?? 'f-weekly';
  }

  List<FormQuestion> get _qs => _forms.byId(_id!)!.questions;

  void _setQs(List<FormQuestion> qs, {bool toDraft = false}) => _forms.setQuestions(_id!, qs, toDraft: toDraft);

  // --- question actions ----------------------------------------------------

  Future<void> _edit(int i) async {
    final qs = _qs;
    final q = await showQuestionEditor(context, initial: qs[i], isNew: false, index: i, total: qs.length);
    if (q == null || !mounted) return;
    _setQs([...qs]..[i] = q, toDraft: true);
    showToast(context, 'Question saved', kind: ToastKind.ok);
  }

  Future<void> _add(QuestionType type) async {
    final q = await showQuestionEditor(context, initial: FormQuestion(text: '', type: type, required: true), isNew: true);
    if (q == null || !mounted) return;
    _setQs([..._qs, q], toDraft: true);
    showToast(context, 'Question added', subtitle: 'Placed at the end of the form', kind: ToastKind.ok);
  }

  Future<void> _openPalette() async {
    final t = await showQuestionPalette(context);
    if (t != null && mounted) _add(t);
  }

  void _duplicateQ(int i) {
    final qs = [..._qs]..insert(i + 1, _qs[i]);
    _setQs(qs);
    showToast(context, 'Question duplicated', kind: ToastKind.ok);
  }

  void _move(int from, int to) {
    final qs = [..._qs];
    if (to < 0 || to >= qs.length) return;
    final q = qs.removeAt(from);
    qs.insert(to, q);
    _setQs(qs);
  }

  void _deleteQ(int i) {
    final prev = _qs;
    _setQs([...prev]..removeAt(i));
    showToast(context, 'Question deleted', subtitle: prev[i].text, kind: ToastKind.del, onUndo: () => _setQs(prev));
  }

  void _questionMenu(int i) {
    final n = _qs.length;
    showActionSheet(context, title: 'Question ${i + 1}', actions: [
      SheetAction('Edit question', Icons.edit_rounded, () => _edit(i)),
      SheetAction('Duplicate', Icons.content_copy_rounded, () => _duplicateQ(i)),
      if (i > 0) SheetAction('Move up', Icons.arrow_upward_rounded, () => _move(i, i - 1)),
      if (i < n - 1) SheetAction('Move down', Icons.arrow_downward_rounded, () => _move(i, i + 1)),
      SheetAction('Delete question', Icons.delete_rounded, () => _deleteQ(i), destructive: true),
    ]);
  }

  // --- form actions --------------------------------------------------------

  void _formMenu(FormDef f) {
    showActionSheet(context, title: f.name, actions: [
      SheetAction('Duplicate form', Icons.content_copy_rounded, () {
        final id = _forms.duplicate(f.id);
        setState(() => _id = id);
        showToast(context, 'Form duplicated', subtitle: 'You are editing the copy now', kind: ToastKind.ok);
      }),
      if (f.published && !f.archived)
        SheetAction('Move back to draft', Icons.edit_note_rounded, () {
          _forms.setPublished(f.id, false);
          showToast(context, 'Moved back to draft', subtitle: 'Clients get the old version until you publish', kind: ToastKind.info);
        }),
      if (!f.archived)
        SheetAction('Archive form', Icons.archive_rounded, () {
          _forms.setArchived(f.id, true);
          showToast(context, 'Form archived', subtitle: 'It is no longer sent to clients', kind: ToastKind.ok, onUndo: () => _forms.setArchived(f.id, false));
        }),
      if (f.archived)
        SheetAction('Restore form', Icons.unarchive_rounded, () {
          _forms.setArchived(f.id, false);
          showToast(context, 'Form restored', subtitle: f.name, kind: ToastKind.ok);
        }),
    ]);
  }

  Future<void> _publish(FormDef f) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Publish this form?',
      message: 'The next check-in goes out with ${questionCount(f.questions.length)}. Answers already sent stay as they are.',
      confirmLabel: 'Publish',
      icon: Icons.publish_rounded,
    );
    if (!ok || !mounted) return;
    if (f.questions.isEmpty) {
      showToast(context, 'Add a question first', subtitle: 'An empty form cannot be published', kind: ToastKind.warn);
      return;
    }
    _forms.setPublished(f.id, true);
    showToast(context, 'Form published', subtitle: 'Clients get it on the next send', kind: ToastKind.ok);
  }

  @override
  Widget build(BuildContext context) {
    final forms = ref.watch(formsProvider);
    final f = forms.where((x) => x.id == _id).firstOrNull;
    if (f == null) {
      return PageScroll(children: [
        const SubPageHeader(title: 'Form builder'),
        EmptyState(
          icon: Icons.assignment_rounded,
          title: 'This form was deleted',
          action: AppButton.outline('Back to forms', onPressed: () => context.pop()),
        ),
      ]);
    }
    final draft = !f.published;
    return PageScroll(
      children: [
        SubPageHeader(
          title: f.name,
          actions: [AppIconButton(Icons.more_horiz_rounded, tooltip: 'More', onPressed: () => _formMenu(f))],
        ),
        _TitleMeta(form: f),
        Row(
          children: [
            Expanded(
              child: AppButton.outline('Preview',
                  icon: Icons.visibility_rounded, onPressed: () => showFormPreview(context, name: f.name, questions: f.questions)),
            ),
            if (draft) ...[
              const SizedBox(width: 10),
              Expanded(child: AppButton('Publish', icon: Icons.publish_rounded, onPressed: () => _publish(f))),
            ],
          ],
        ),
        _QuestionList(
          questions: f.questions,
          onEdit: _edit,
          onMenu: _questionMenu,
          onReorder: _move,
        ),
        _AddQuestionButton(onTap: _openPalette),
        _DetailsCard(
          key: ValueKey(f.id),
          form: f,
          onRename: (v) => _forms.rename(f.id, v),
          onKind: () async {
            final k = await pickFromSheet<FormKind>(context,
                title: 'Type', items: [for (final k in FormKind.values) (k, k.label)], selected: f.kind, iconOf: (k) => k.icon);
            if (k != null) _forms.setKind(f.id, k);
          },
          onAutomations: () => context.push(Routes.aAutomations),
        ),
        SideCard(
          title: 'Answers so far',
          children: [
            const StatTriple(EngageMock.formStats),
            const FieldHint('Each answer shows in the client profile under Check-ins.'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextLink('See Riya\'s answers', icon: Icons.person_rounded, onTap: () => context.push(Routes.aClient('riya'))),
            ),
          ],
        ),
      ],
    );
  }
}

class _TitleMeta extends StatelessWidget {
  const _TitleMeta({required this.form});
  final FormDef form;

  @override
  Widget build(BuildContext context) {
    final f = form;
    final tone = f.archived ? BadgeTone.neutral : (f.published ? BadgeTone.ok : BadgeTone.warn);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBadge(f.statusLabel, tone: tone),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${f.kind.label} · ${questionCount(f.questions.length)} · ${f.automations.isNotEmpty ? 'Sent by automation' : 'Sent by hand'}',
            style: AppText.secondary,
          ),
        ),
      ],
    );
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({required this.questions, required this.onEdit, required this.onMenu, required this.onReorder});
  final List<FormQuestion> questions;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onMenu;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.quiz_rounded,
          title: 'No questions yet',
          message: 'Pick an answer type to write the first question.',
        ),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: questions.length,
      onReorderItem: onReorder,
      proxyDecorator: (child, _, _) => Material(color: Colors.transparent, elevation: 6, borderRadius: BorderRadius.circular(14), child: child),
      itemBuilder: (_, i) => Padding(
        key: ValueKey('q$i-${questions[i].text}'),
        padding: EdgeInsets.only(bottom: i == questions.length - 1 ? 0 : 8),
        child: _QuestionCard(index: i, q: questions[i], onTap: () => onEdit(i), onMenu: () => onMenu(i)),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.q, required this.onTap, required this.onMenu});
  final int index;
  final FormQuestion q;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final meta = [
      q.type.label,
      if (q.type.hasOptions) q.optionsSummary,
      if (q.help.isNotEmpty) q.help,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(4, 10, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Tooltip(
              message: 'Drag to reorder',
              child: Padding(padding: EdgeInsets.fromLTRB(4, 2, 2, 2), child: Icon(Icons.drag_indicator_rounded, size: 18, color: AppColors.line2)),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 9, top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(6)),
            child: Text('${index + 1}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text2)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text, style: AppText.bodyBold.copyWith(fontSize: 13.5, height: 1.35)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypeIcon(q.type, small: true),
                    const SizedBox(width: 5),
                    Expanded(child: Text(meta, style: AppText.caption.copyWith(height: 1.5))),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 6),
            child: Text(q.required ? 'Required' : 'Optional',
                style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: q.required ? AppColors.badText : AppColors.muted)),
          ),
          SizedBox(
            width: 36,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Question options',
              onPressed: onMenu,
              icon: const Icon(Icons.more_vert_rounded, size: 19, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed "Add question" button (mb-addm).
class _AddQuestionButton extends StatelessWidget {
  const _AddQuestionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedAddButton(label: 'Add question', onTap: onTap);
  }
}

/// Full-width dashed button with a plus.
class DashedAddButton extends StatelessWidget {
  const DashedAddButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashPainter(),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: AppColors.accentText),
              const SizedBox(width: 6),
              Text(label, style: AppText.bodyBold.copyWith(color: AppColors.accentText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    final path = Path()..addRRect(rr);
    final paint = Paint()
      ..color = AppColors.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetailsCard extends StatefulWidget {
  const _DetailsCard({super.key, required this.form, required this.onRename, required this.onKind, required this.onAutomations});
  final FormDef form;
  final ValueChanged<String> onRename;
  final VoidCallback onKind;
  final VoidCallback onAutomations;

  @override
  State<_DetailsCard> createState() => _DetailsCardState();
}

class _DetailsCardState extends State<_DetailsCard> {
  late final _name = TextEditingController(text: widget.form.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;
    final tone = f.archived ? BadgeTone.neutral : (f.published ? BadgeTone.ok : BadgeTone.warn);
    return SideCard(
      title: 'Form details',
      trailing: AppBadge(f.statusLabel, tone: tone),
      children: [
        FieldBlock(
          label: 'Name',
          child: TextField(
            controller: _name,
            style: AppText.body,
            onChanged: (v) {
              if (v.trim().isNotEmpty) widget.onRename(v.trim());
            },
          ),
        ),
        const SizedBox(height: 12),
        FieldBlock(label: 'Type', child: SelectBox(value: f.kind.label, onTap: widget.onKind)),
        const SizedBox(height: 12),
        FieldBlock(
          label: 'How it is sent',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in f.automations) LinkRow(icon: Icons.bolt_rounded, title: a, onTap: widget.onAutomations),
              if (f.automations.isEmpty) const FieldHint('No automation sends this form yet.'),
              const FieldHint('Schedule and reminders are set in the automation.'),
              const SizedBox(height: 8),
              AppButton.outline('Open automations', small: true, icon: Icons.bolt_rounded, onPressed: widget.onAutomations),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NoteBox('Changes are saved automatically. Last change: ${f.updated}', icon: Icons.cloud_done_rounded),
      ],
    );
  }
}
