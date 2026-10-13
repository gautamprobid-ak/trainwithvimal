import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import 'forms_state.dart';
import 'widgets/engage_ui.dart';
import 'widgets/form_preview.dart';

/// Design: FormsMobile.dc.html — onboarding questionnaires, check-ins,
/// surveys and waivers.
class FormsScreen extends ConsumerStatefulWidget {
  const FormsScreen({super.key});

  @override
  ConsumerState<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends ConsumerState<FormsScreen> {
  bool _archived = false;
  FormKind? _kind;
  String _query = '';

  FormsNotifier get _forms => ref.read(formsProvider.notifier);

  void _openBuilder(String id) => context.push('${Routes.aFormBuilder}?id=$id');

  Future<void> _pickKind(List<FormDef> live) async {
    final picked = await showAppSheet<(FormKind?,)>(
      context,
      title: 'Form type',
      builder: (ctx) => Column(
        children: [
          _KindRow(icon: Icons.apps_rounded, tint: Tint.green, label: 'All forms', count: live.length, on: _kind == null, onTap: () => Navigator.of(ctx).pop(const (null,))),
          for (final k in FormKind.values)
            _KindRow(
              icon: k.icon,
              tint: k.tint,
              label: k.filterLabel,
              count: live.where((f) => f.kind == k).length,
              on: _kind == k,
              onTap: () => Navigator.of(ctx).pop((k,)),
            ),
        ],
      ),
    );
    // Closing the sheet returns null: keep the current filter.
    if (picked == null || !mounted) return;
    setState(() => _kind = picked.$1);
  }

  void _openMenu(FormDef f) {
    showActionSheet(context, title: f.name, actions: [
      SheetAction('Edit questions', Icons.edit_rounded, () => _openBuilder(f.id)),
      SheetAction('Preview', Icons.visibility_rounded, () => showFormPreview(context, name: f.name, questions: f.questions)),
      SheetAction('Duplicate', Icons.content_copy_rounded, () => _duplicate(f)),
      if (!f.archived) SheetAction('Archive', Icons.archive_rounded, () => _archive(f)),
      if (f.archived) SheetAction('Restore', Icons.unarchive_rounded, () => _archive(f)),
      SheetAction('Delete form', Icons.delete_rounded, () => _delete(f), destructive: true),
    ]);
  }

  void _duplicate(FormDef f) {
    final prev = ref.read(formsProvider);
    _forms.duplicate(f.id);
    showToast(context, 'Form duplicated', subtitle: 'Saved as a draft', kind: ToastKind.ok, onUndo: () => _forms.restore(prev));
  }

  void _archive(FormDef f) {
    final prev = ref.read(formsProvider);
    _forms.setArchived(f.id, !f.archived);
    showToast(
      context,
      f.archived ? 'Form restored' : 'Form archived',
      subtitle: f.archived ? f.name : 'It is no longer sent to clients',
      kind: ToastKind.ok,
      onUndo: () => _forms.restore(prev),
    );
  }

  Future<void> _delete(FormDef f) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this form?',
      message: '${f.name} is removed for good. Answers clients already sent stay in their profiles.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_rounded,
    );
    if (!ok || !mounted) return;
    final prev = ref.read(formsProvider);
    _forms.delete(f.id);
    showToast(context, 'Form deleted', subtitle: f.name, kind: ToastKind.del, onUndo: () => _forms.restore(prev));
  }

  void _openNew() {
    showAppSheet(
      context,
      title: 'Create form',
      subtitle: 'Pick what it is for, then add the questions',
      builder: (ctx) => _NewFormSheet(
        onContinue: (kind, name, tpl) {
          final id = _forms.create(kind: kind, name: name, fromTemplate: tpl);
          Navigator.of(ctx).pop();
          _openBuilder(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(formsProvider);
    final live = all.where((f) => !f.archived).toList();
    final arch = all.where((f) => f.archived).toList();
    final q = _query.trim().toLowerCase();
    final rows = (_archived ? arch : live)
        .where((f) => _kind == null || f.kind == _kind)
        .where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
        .toList();

    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Forms & check-ins',
          actions: [AppButton('Create form', icon: Icons.add_rounded, small: true, onPressed: _openNew)],
        ),
        Text('Onboarding questionnaires, weekly and daily check-ins, surveys and waivers.', style: AppText.secondary),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Tools(
                kind: _kind,
                liveCount: _kind == null ? live.length : live.where((f) => f.kind == _kind).length,
                archived: _archived,
                counts: (live.length, arch.length),
                onQuery: (v) => setState(() => _query = v),
                onKind: () => _pickKind(live),
                onTab: (v) => setState(() => _archived = v),
              ),
              const Divider(height: 1),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _FormRow(
                  form: rows[i],
                  onOpen: () => _openBuilder(rows[i].id),
                  onMenu: () => _openMenu(rows[i]),
                  onAutomation: () => context.push(Routes.aAutomations),
                ),
              ],
              if (rows.isEmpty)
                EmptyState(
                  icon: _archived ? Icons.archive_rounded : Icons.assignment_rounded,
                  title: _archived ? 'Nothing archived' : 'No forms here yet',
                  message: _archived ? 'Forms you archive show up here.' : 'There is no form of this type. Create one to start.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tools extends StatelessWidget {
  const _Tools({
    required this.kind,
    required this.liveCount,
    required this.archived,
    required this.counts,
    required this.onQuery,
    required this.onKind,
    required this.onTab,
  });
  final FormKind? kind;
  final int liveCount;
  final bool archived;
  final (int, int) counts;
  final ValueChanged<String> onQuery;
  final VoidCallback onKind;
  final ValueChanged<bool> onTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          SearchField(hint: 'Search forms', onChanged: onQuery),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.line)),
                  child: InkWell(
                    onTap: onKind,
                    customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(kind?.icon ?? Icons.apps_rounded, size: 16, color: (kind?.tint ?? Tint.green).fg),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(kind?.filterLabel ?? 'All forms',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13)),
                          ),
                          const SizedBox(width: 6),
                          Text('$liveCount', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedTabs<bool>(
                expand: false,
                items: [(false, 'All ${counts.$1}'), (true, 'Archived ${counts.$2}')],
                value: archived,
                onChanged: onTab,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.form, required this.onOpen, required this.onMenu, required this.onAutomation});
  final FormDef form;
  final VoidCallback onOpen;
  final VoidCallback onMenu;
  final VoidCallback onAutomation;

  @override
  Widget build(BuildContext context) {
    final f = form;
    final tone = f.archived ? BadgeTone.neutral : (f.published ? BadgeTone.ok : BadgeTone.warn);
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 4, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintIcon(f.kind.icon, tint: f.kind.tint, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: AppText.bodyBold),
                  Text('${f.kind.label} · ${questionCount(f.questions.length)}', style: AppText.caption),
                  const SizedBox(height: 6),
                  _SendLine(form: f, onAutomation: onAutomation),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AppBadge(f.statusLabel, tone: tone),
                      const SizedBox(width: 8),
                      Text('Updated ${f.updated}', style: AppText.caption),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMenu,
              tooltip: 'Form options',
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// "How it is sent": the automation, or "Sent by hand · Set up automation".
class _SendLine extends StatelessWidget {
  const _SendLine({required this.form, required this.onAutomation});
  final FormDef form;
  final VoidCallback onAutomation;

  @override
  Widget build(BuildContext context) {
    final au = form.automations;
    if (au.isEmpty) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text('Sent by hand', style: AppText.caption),
          GestureDetector(
            onTap: onAutomation,
            child: Text('Set up automation', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentText)),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.bolt_rounded, size: 15, color: AppColors.accent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(au.first, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.text2, fontWeight: FontWeight.w600)),
        ),
        if (au.length > 1) ...[
          const SizedBox(width: 6),
          Text('+${au.length - 1} more', style: AppText.caption.copyWith(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({required this.icon, required this.tint, required this.label, required this.count, required this.on, required this.onTap});
  final IconData icon;
  final Tint tint;
  final String label;
  final int count;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: on ? AppColors.accentSoft : null,
      leading: TintIcon(icon, tint: tint, size: 30),
      title: Text(label, style: AppText.bodyBold.copyWith(fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
      trailing: Text('$count', style: AppText.secondary.copyWith(fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}

/// "Create form" sheet body: kind, name and where to start from.
class _NewFormSheet extends StatefulWidget {
  const _NewFormSheet({required this.onContinue});
  final void Function(FormKind kind, String name, bool fromTemplate) onContinue;

  @override
  State<_NewFormSheet> createState() => _NewFormSheetState();
}

class _NewFormSheetState extends State<_NewFormSheet> {
  FormKind _kind = FormKind.weekly;
  bool _tpl = true;
  late final _name = TextEditingController(text: _kind.label);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(FormKind k) {
    setState(() {
      if (_name.text.trim().isEmpty || _name.text == _kind.label) _name.text = k.label;
      _kind = k;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 16,
      children: [
        FieldBlock(
          label: 'What kind of form?',
          child: Spaced(
            gap: 8,
            children: [
              for (final k in FormKind.values)
                OptionCard(
                  selected: _kind == k,
                  title: k.label,
                  subtitle: k.description,
                  icon: k.icon,
                  tint: k.tint,
                  onTap: () => _pick(k),
                ),
            ],
          ),
        ),
        FieldBlock(label: 'Name', child: TextField(controller: _name, style: AppText.body)),
        FieldBlock(
          label: 'Start from',
          hint: _tpl ? 'Starts with our standard questions. You can change every one of them.' : 'Starts empty. You add every question yourself.',
          child: SegmentedTabs<bool>(
            items: const [(true, 'Template'), (false, 'Blank form')],
            value: _tpl,
            onChanged: (v) => setState(() => _tpl = v),
          ),
        ),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: AppButton('Continue to builder', icon: Icons.arrow_forward_rounded, onPressed: () => widget.onContinue(_kind, _name.text, _tpl)),
            ),
          ],
        ),
      ],
    );
  }
}
