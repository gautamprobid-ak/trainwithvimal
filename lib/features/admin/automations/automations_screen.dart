import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import '../forms/widgets/engage_ui.dart';
import 'automations_state.dart';

/// Design: AutomationsMobile.dc.html — forms, messages and tasks that go out
/// by themselves.
class AutomationsScreen extends ConsumerWidget {
  const AutomationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(automationsProvider);
    final n = ref.read(automationsProvider.notifier);

    void toggle(Automation a) {
      if (a.status == AutoStatus.draft) {
        showToast(context, 'Finish it before turning it on', subtitle: 'Open it and add what is missing', kind: ToastKind.warn);
        return;
      }
      final prev = ref.read(automationsProvider);
      final on = a.status == AutoStatus.on;
      n.setStatus(a.id, on ? AutoStatus.off : AutoStatus.on);
      showToast(context, '${a.name}${on ? ' is off' : ' is on'}',
          subtitle: on ? 'No new runs will start' : 'It starts with the next trigger', kind: ToastKind.ok, onUndo: () => n.restore(prev));
    }

    Future<void> delete(Automation a) async {
      final ok = await showConfirmDialog(
        context,
        title: 'Delete this automation?',
        message: '${a.name} stops for everyone in it now. Messages already sent stay sent.',
        confirmLabel: 'Delete',
        destructive: true,
        icon: Icons.delete_rounded,
      );
      if (!ok || !context.mounted) return;
      final prev = ref.read(automationsProvider);
      n.delete(a.id);
      showToast(context, 'Automation deleted', subtitle: a.name, kind: ToastKind.del, onUndo: () => n.restore(prev));
    }

    void open(Automation a) => context.push('${Routes.aAutomationBuilder}?id=${a.id}');

    void menu(Automation a) {
      showActionSheet(context, title: a.name, actions: [
        SheetAction('Edit', Icons.edit_rounded, () => open(a)),
        SheetAction('Duplicate', Icons.content_copy_rounded, () {
          final prev = ref.read(automationsProvider);
          n.duplicate(a.id);
          showToast(context, 'Automation duplicated', subtitle: 'Saved as a draft', kind: ToastKind.ok, onUndo: () => n.restore(prev));
        }),
        SheetAction('Delete', Icons.delete_rounded, () => delete(a), destructive: true),
      ]);
    }

    final onCount = list.where((a) => a.status == AutoStatus.on).length;
    final offCount = list.length - onCount;

    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Automations',
          actions: [AppButton('New automation', icon: Icons.add_rounded, small: true, onPressed: () => _openNew(context))],
        ),
        Text('Forms, messages and tasks that go out by themselves when something happens.', style: AppText.secondary),
        AppButton.outline('Message templates', icon: Icons.mail_rounded, expand: true, onPressed: () => context.push(Routes.aEmails)),
        _Stats(items: [
          (Icons.bolt_rounded, Tint.green, 'Automations on', '$onCount of ${list.length}', offCount > 0 ? '$offCount off or draft' : 'All of them are on'),
          (Icons.group_rounded, Tint.blue, 'Clients in a flow', '${list.fold<int>(0, (s, a) => s + a.running)}', 'Waiting for their next step'),
          (Icons.send_rounded, Tint.amber, 'Messages this month', EngageMock.messagesThisMonth.$1, EngageMock.messagesThisMonth.$2),
          (Icons.task_alt_rounded, Tint.purple, 'Tasks for trainers', EngageMock.trainerTasks.$1, EngageMock.trainerTasks.$2),
        ]),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _AutomationRow(a: list[i], onOpen: () => open(list[i]), onToggle: () => toggle(list[i]), onMenu: () => menu(list[i])),
              ],
              if (list.isEmpty)
                const EmptyState(icon: Icons.bolt_rounded, title: 'No automations yet', message: 'Start from a ready-made one or from scratch.'),
            ],
          ),
        ),
        NoteBox(
          'Emails and WhatsApp go out from Train With Vimal until you set your own sender.',
          icon: Icons.outgoing_mail,
          action: TextLink('Sender settings', onTap: () => context.push(Routes.aSettings)),
        ),
      ],
    );
  }

  static void _openNew(BuildContext context) {
    showAppSheet(
      context,
      title: 'New automation',
      subtitle: 'Start from a ready-made automation or from scratch.',
      builder: (ctx) => _StarterPicker(
        onUse: (id) {
          Navigator.of(ctx).pop();
          context.push(id == null ? Routes.aAutomationNew : '${Routes.aAutomationBuilder}?starter=$id');
        },
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.items});
  final List<(IconData, Tint, String, String, String)> items;

  @override
  Widget build(BuildContext context) {
    Widget card((IconData, Tint, String, String, String) s) => AppCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(s.$1, size: 15, color: s.$2.fg),
                  const SizedBox(width: 6),
                  Expanded(child: Text(s.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 6),
              Text(s.$4, style: AppText.bigNumber.copyWith(fontSize: 22)),
              const SizedBox(height: 3),
              Text(s.$5, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5)),
            ],
          ),
        );
    return Column(
      children: [
        for (var r = 0; r < items.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 10),
          Row(children: [Expanded(child: card(items[r])), const SizedBox(width: 10), Expanded(child: card(items[r + 1]))]),
        ],
      ],
    );
  }
}

class _AutomationRow extends StatelessWidget {
  const _AutomationRow({required this.a, required this.onOpen, required this.onToggle, required this.onMenu});
  final Automation a;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (a.status) {
      AutoStatus.on => ('On', BadgeTone.ok),
      AutoStatus.draft => ('Draft', BadgeTone.warn),
      AutoStatus.off => ('Off', BadgeTone.neutral),
    };
    final applies = a.package.isNotEmpty ? 'Package: ${a.package}' : (a.trainer.isNotEmpty ? 'Trainer: ${a.trainer}' : 'All clients');
    final trig = a.trigger;
    return InkWell(
      onTap: onOpen,
      child: Opacity(
        opacity: a.status == AutoStatus.on ? 1 : .75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: TintIcon(trig?.icon ?? Icons.bolt_rounded, tint: trig?.group.tint ?? Tint.gray, size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [Text(a.name, style: AppText.bodyBold.copyWith(height: 1.3)), AppBadge(label, tone: tone)],
                    ),
                    const SizedBox(height: 2),
                    Text('${EngageMock.triggerLine(trig, a.value)} · $applies', style: AppText.caption.copyWith(height: 1.4)),
                    const SizedBox(height: 8),
                    StepFlow(steps: a.steps),
                  ],
                ),
              ),
              Tooltip(
                message: a.status == AutoStatus.draft ? 'Finish it before turning it on' : 'Turn ${a.name} on or off',
                child: MiniToggle(value: a.status == AutoStatus.on, dim: a.status == AutoStatus.draft, onChanged: (_) => onToggle()),
              ),
              SizedBox(
                width: 34,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'More options',
                  onPressed: onMenu,
                  icon: const Icon(Icons.more_vert_rounded, size: 19, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step chips joined by arrows; the steps that do not fit go into "+N more".
class StepFlow extends StatelessWidget {
  const StepFlow({super.key, required this.steps});
  final List<AutoStep> steps;

  @override
  Widget build(BuildContext context) {
    // Same rule as the design: as many chips as fit on about 46 characters.
    var fit = 0, w = 0;
    for (var i = 0; i < steps.length; i++) {
      final l = EngageMock.stepChip(steps[i]).length + 6;
      if (w + l <= (steps.length - fit > 1 ? 46 : 54) && fit == i) {
        w += l;
        fit++;
      }
    }
    final more = steps.length - fit;
    Widget arrow() => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.muted),
        );
    return Wrap(
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < fit; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [if (i > 0) arrow(), _Chip(step: steps[i])],
          ),
        if (more > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fit > 0) arrow(),
              Tooltip(
                message: steps.skip(fit).map(EngageMock.stepLine).join('  ·  '),
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Text('+$more more', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.step});
  final AutoStep step;

  @override
  Widget build(BuildContext context) {
    final t = step.kind.tint;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(step.kind.icon, size: 12, color: t.fg),
          const SizedBox(width: 4),
          Text(EngageMock.stepChip(step), style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: t.fg)),
        ],
      ),
    );
  }
}

/// "New automation" sheet: ready-made starters or start blank.
class _StarterPicker extends StatefulWidget {
  const _StarterPicker({required this.onUse});

  /// Starter id, or null for "Start blank".
  final ValueChanged<String?> onUse;

  @override
  State<_StarterPicker> createState() => _StarterPickerState();
}

class _StarterPickerState extends State<_StarterPicker> {
  String? _sel = 'st-onboarding';

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 8,
      children: [
        for (final s in EngageMock.starters)
          OptionCard(
            selected: _sel == s.id,
            title: s.name,
            subtitle: s.note,
            extra: '${EngageMock.triggerLine(s.trigger, s.value)} · ${s.steps.length} steps',
            icon: s.trigger.icon,
            tint: Tint.blue,
            onTap: () => setState(() => _sel = s.id),
          ),
        OptionCard(
          selected: _sel == null,
          title: 'Start blank',
          subtitle: 'Choose the trigger and add the steps yourself.',
          icon: Icons.add_rounded,
          tint: Tint.green,
          onTap: () => setState(() => _sel = null),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(child: AppButton('Use this', icon: Icons.arrow_forward_rounded, onPressed: () => widget.onUse(_sel))),
          ],
        ),
      ],
    );
  }
}
