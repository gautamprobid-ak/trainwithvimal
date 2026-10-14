import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';
import '../sheets/profile_sheets.dart';

typedef _M = ClientProfileMock;

class FormsTab extends StatelessWidget {
  const FormsTab({super.key});
  static const _icons = {
    'onb': Icons.assignment_outlined,
    'parq': Icons.health_and_safety_outlined,
    'fb': Icons.rate_review_outlined,
    'wk': Icons.event_repeat_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final f = _M.forms.firstWhere((x) => x.id == c.form);
    return Spaced(
      children: [
        CpCard(
          title: 'Forms',
          cap: '4 forms for ${c.first} · copies of the master forms',
          trailing: AppButton.outline('Send a form', icon: Icons.send_rounded, small: true, onPressed: () => showSendFormSheet(context, c)),
          child: CpRows([
            for (final x in _M.forms)
              CpRow(
                icon: _icons[x.id],
                selected: x.id == c.form,
                title: x.name,
                sub: c.r(x.sub),
                trailing: AppBadge.status(x.badge, tone: x.tone),
                onTap: () => c.setForm(x.id),
              ),
          ]),
        ),
        if (!f.editable) _Answers(f) else if (c.formEdit) _FormEditor(f) else _FormView(f),
      ],
    );
  }
}

class _Answers extends StatelessWidget {
  const _Answers(this.f);
  final ClientForm f;
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return CpCard(
      title: f.name,
      cap: c.r(f.cap),
      action: f.id == 'onb' ? 'Print' : null,
      onAction: () => showToast(context, 'Sent to the printer', subtitle: f.name, kind: ToastKind.ok),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final s in f.answers) ...[
            SubLabel(s.title),
            QaList([for (final (q, a) in s.items) (q, c.r(a))]),
          ],
        ]),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView(this.f);
  final ClientForm f;
  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(f.name, style: AppText.cardTitle),
                AppBadge.status(f.badge, tone: f.tone),
                if (f.edited) AppBadge(c.r('Edited for Riya'), tone: BadgeTone.info),
              ]),
              const SizedBox(height: 3),
              Text(f.cap, style: AppText.caption),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: AppButton.outline('Edit for ${c.first}', icon: Icons.edit_outlined, small: true, onPressed: c.openFormEdit)),
                const SizedBox(width: 8),
                AppIconButton(Icons.more_horiz_rounded, small: true, tooltip: 'More actions', onPressed: () => _menu(context, c)),
              ]),
            ]),
          ),
          if (f.id == 'fb')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                Expanded(child: Text('${c.first} has not answered yet. A reminder went out on 5 Oct.', style: AppText.secondary)),
                const SizedBox(width: 8),
                AppButton.outline('Remind again', icon: Icons.notifications_active_outlined, small: true, onPressed: () => showToast(context, 'Reminder sent to ${c.first}', subtitle: f.name, kind: ToastKind.ok)),
              ]),
            ),
          CpRows([
            for (final q in f.questions)
              CpRow(
                leading: ChangeDot(on: q.changed),
                title: q.text,
                sub: q.note == null ? null : c.r(q.note!),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(q.type, style: AppText.caption),
                  if (q.required) ...[const SizedBox(width: 6), const AppBadge('Required')],
                ]),
              ),
          ]),
        ],
      ),
    );
  }

  void _menu(BuildContext context, ClientProfileController c) {
    showActionSheet(context, title: f.name, actions: [
      SheetAction('Duplicate and edit', Icons.copy_rounded, () => c.openFormEdit(duplicate: true)),
      SheetAction('Send now', Icons.send_rounded, () => showToast(context, '${f.name} sent to ${c.first}', subtitle: 'She answers in her app', kind: ToastKind.ok)),
      SheetAction('Reset to master', Icons.restart_alt_rounded, () => showToast(context, 'Reset to master', subtitle: f.name, kind: ToastKind.ok)),
      SheetAction('Stop sending', Icons.stop_circle_outlined, destructive: true, () async {
        final ok = await showConfirmDialog(context,
            title: 'Stop sending ${f.name}?', message: '${c.first} stops getting this form. Answers she already sent are kept.', confirmLabel: 'Stop sending', destructive: true);
        if (ok && context.mounted) showToast(context, 'Stopped sending', subtitle: f.name, kind: ToastKind.del);
      }),
    ]);
  }
}

class _FormEditor extends StatefulWidget {
  const _FormEditor(this.f);
  final ClientForm f;
  @override
  State<_FormEditor> createState() => _FormEditorState();
}

class _FormEditorState extends State<_FormEditor> {
  late List<FormQuestion> qs = [...widget.f.questions];
  late List<String> sched = [...widget.f.schedule];

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final f = widget.f;
    final dup = c.formDup;
    return Spaced(
      children: [
        Align(alignment: Alignment.centerLeft, child: AppButton.outline('Back to form', icon: Icons.arrow_back_rounded, small: true, onPressed: c.closeFormEdit)),
        Row(children: [
          if (!dup) CpTextButton('Reset to master', icon: Icons.restart_alt_rounded, size: 13, onTap: () => setState(() => qs = [...f.questions])),
          const Spacer(),
          AppButton.outline('Cancel', small: true, onPressed: c.closeFormEdit),
          const SizedBox(width: 8),
          AppButton(dup ? 'Send copy' : 'Save for ${c.first}', icon: Icons.check_rounded, small: true, onPressed: () {
            c.closeFormEdit();
            showToast(context, dup ? 'Copy sent to ${c.first}' : 'Saved for ${c.first}', subtitle: f.name, kind: ToastKind.ok);
          }),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(dup ? 'New form for ${c.first}: copy of ${f.name}' : 'Edit ${f.name} for ${c.first}', style: AppText.cardTitle.copyWith(fontSize: 16))),
            InfoTip(dup
                ? 'A new form only for ${c.first}. The form she has now keeps going until you stop it. The master stays the same.'
                : "Only ${c.first}'s copy changes. The master form and other clients stay the same. Answers she already sent are kept."),
          ]),
          Text(dup ? 'Change the questions and schedule, then send.' : f.editCap, style: AppText.caption),
        ]),
        if (dup)
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              LabeledField(label: 'Form name', initialValue: '${f.name} · ${c.first}'),
              const SizedBox(height: 10),
              const SelectField(label: 'First send', value: 'Sun, 11 Oct', options: ['Sun, 11 Oct', 'Sun, 18 Oct', 'Sun, 25 Oct']),
              const SizedBox(height: 10),
              SelectField(label: 'Instead of', value: f.name, options: [f.name, 'Nothing, send both']),
            ]),
          ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('Send', style: AppText.bodyBold.copyWith(fontSize: 13)),
                EditCell(sched[0], select: true, width: 140, onTap: () => _pick(0, ['Every day', 'Every Sunday', 'Every month'])),
                EditCell(sched[1], width: 110),
                EditCell(sched[2], select: true, width: 150, onTap: () => _pick(2, ['Push', 'Push + email', 'Push + WhatsApp'])),
              ]),
            ),
            PfCards(columns: 2, [
              for (var i = 0; i < qs.length; i++)
                PfItem(
                  head: Row(children: [ChangeDot(on: qs[i].changed), Expanded(child: EditCell(qs[i].text, changed: qs[i].changed))]),
                  action: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.text2),
                    onPressed: () {
                      final x = qs[i];
                      setState(() => qs.removeAt(i));
                      showToast(context, 'Question removed', subtitle: x.text, kind: ToastKind.del, onUndo: () {
                        if (mounted) setState(() => qs.insert(i, x));
                      });
                    },
                  ),
                  fields: [
                    ('Answer type', EditCell(qs[i].type, select: true)),
                    (
                      'Required',
                      Row(children: [
                        Transform.scale(
                          scale: .75,
                          child: Switch(
                            value: qs[i].required,
                            activeTrackColor: AppColors.accent,
                            onChanged: (v) => setState(() => qs[i] = FormQuestion(qs[i].text, qs[i].type, required: v, changed: true, note: qs[i].note)),
                          ),
                        ),
                        Text('Required', style: AppText.caption),
                      ]),
                    ),
                  ],
                ),
            ]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: AddButton('Add question', onTap: () async {
                    final t = await editText(context, title: 'New question', value: '', hint: 'Ask something…');
                    if (t != null && t.trim().isNotEmpty) setState(() => qs.add(FormQuestion(t, 'Text', changed: true, note: 'Added for ${c.first}')));
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(child: AddButton('Add section', onTap: () => showToast(context, 'Section added', subtitle: f.name, kind: ToastKind.ok))),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _pick(int i, List<String> opts) async {
    final v = await pickOption(context, title: 'Send', options: opts, current: sched[i]);
    if (v != null) setState(() => sched[i] = v);
  }
}
