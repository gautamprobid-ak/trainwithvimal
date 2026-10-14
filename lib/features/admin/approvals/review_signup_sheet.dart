import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';
import 'package:train_with_vimal/data/models/people.dart';

import '../clients/admin_ui.dart';
import 'approvals_screen.dart';

/// Sign-up details drawer: review, pick a trainer, approve / ask / reject.
Future<void> showReviewSignupSheet(BuildContext context, {required List<SignupRequest> list, required String start}) =>
    showFormSheet(context, title: 'Sign-up details', builder: (_) => _ReviewBody(list: list, start: start));

class _ReviewBody extends ConsumerStatefulWidget {
  const _ReviewBody({required this.list, required this.start});
  final List<SignupRequest> list;
  final String start;

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
  late int _i = widget.list.indexWhere((r) => r.id == widget.start).clamp(0, widget.list.length - 1);
  final _picked = <String, String>{};

  SignupRequest get _r => widget.list[_i];
  String get _trainer => _picked[_r.id] ?? _r.invitedBy;

  void _step(int d) => setState(() => _i = (_i + d + widget.list.length) % widget.list.length);

  void _approve() {
    final r = _r;
    final tr = _trainer;
    final waitingIndex = ref.read(approvalsProvider).waiting.indexWhere((x) => x.id == r.id);
    ref.read(approvalsProvider.notifier).decide(r, Decision.approved, 'Trainer $tr');
    final clients = ref.read(adminClientsProvider.notifier);
    final goal = r.answers.where((a) => a.$1 == 'Goal').map((a) => a.$2).firstOrNull ?? 'General fitness';
    clients.add(ClientSummary(
      id: 'signup-${r.id}',
      name: r.name,
      email: r.email,
      trainer: tr,
      goal: goal == 'Lose fat' ? 'Fat loss' : goal == 'Build muscle' ? 'Muscle gain' : goal,
      status: ClientStatus.active,
      thisWeek: r.steps == 5 ? 'Done' : '${r.steps * 20}%',
      phone: '+91 ${r.phone}',
      joined: '9 Oct 2026',
      nextCheckin: 'Sun, 11 Oct',
      lastActive: r.wait,
    ));
    final approvals = ref.read(approvalsProvider.notifier);
    showToast(context, '${r.first} approved', subtitle: '$tr is her trainer · she can log in now', kind: ToastKind.ok, onUndo: () {
      approvals.undo(r, waitingIndex);
      clients.remove('signup-${r.id}');
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return SheetBody(
      actions: [
        AppButton.ghost('Reject', onPressed: () => _openReject(context, r)),
        AppButton.outline('Ask for info', onPressed: () => _openAsk(context, r)),
        AppButton(r.steps < 5 ? 'Approve anyway' : 'Approve and assign', onPressed: _approve),
      ],
      gap: 18,
      children: [
        _Head(request: r, onPrev: () => _step(-1), onNext: () => _step(1), canStep: widget.list.length > 1),
        _Kpis(request: r),
        if (r.healthNote.isNotEmpty)
          InfoBanner(
            text: 'Health note. ${r.healthNote}',
            icon: Icons.warning_amber_rounded,
            bg: AppColors.warnBg,
            fg: AppColors.warnText,
          ),
        KvGrid(KvGrid.text([
          ('Mobile', '+91 ${r.phone}'),
          ('Email', r.email),
          ('Invite code', r.code),
          ('Signed up from', r.device),
        ])),
        SheetSection(title: 'Profile setup', subtitle: '${r.steps} of 5 done', children: [_Checklist(done: r.steps)]),
        SheetSection(
          title: 'From her onboarding',
          children: [
            if (r.answers.isEmpty)
              Text('She has not filled her goal and body details yet. Ask for info to remind her.', style: AppText.secondary)
            else
              KvGrid(KvGrid.text(r.answers)),
          ],
        ),
        SheetSection(
          title: 'Trainer',
          subtitle: '${AdminMock.trainerChoices.where((t) => !t.full).length} of ${AdminMock.trainerChoices.length} have space',
          children: [_TrainerPicker(request: r, value: _trainer, onPick: (v) => setState(() => _picked[r.id] = v))],
        ),
        const SheetSection(
          title: 'When you approve',
          children: [
            SwitchRow(title: 'Tell her on WhatsApp and email', subtitle: 'She can log in right away', initial: true),
            SwitchRow(title: 'Ask her to finish setup', subtitle: 'Only if some steps are not done'),
          ],
        ),
      ],
    );
  }

  void _openReject(BuildContext context, SignupRequest r) {
    var reason = 'fit';
    showAppSheet(
      context,
      title: 'Reject ${r.first}?',
      subtitle: '${r.first} will not be able to log in. You can move her back to Waiting later from History.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Spaced(
          gap: 14,
          children: [
            const FieldLabel('Reason'),
            OptionList(children: [
              for (final o in AdminMock.rejectReasons)
                OptionRow(title: o.title, subtitle: o.sub, selected: reason == o.id, onTap: () => set(() => reason = o.id)),
            ]),
            const LabeledField(label: 'Message to her (optional)', hint: 'Thanks for signing up. Right now we…', maxLines: 3),
            const SwitchRow(title: 'Tell her by email', subtitle: 'She sees the reason and your message', initial: true),
          ],
        ),
      ),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton.danger('Reject', onPressed: () {
          final why = AdminMock.rejectReasons.firstWhere((o) => o.id == reason).title;
          final idx = ref.read(approvalsProvider).waiting.indexWhere((x) => x.id == r.id);
          final n = ref.read(approvalsProvider.notifier);
          n.decide(r, Decision.rejected, why);
          showToast(ctx, '${r.first} rejected', subtitle: why, kind: ToastKind.del, onUndo: () => n.undo(r, idx));
          Navigator.of(ctx).pop();
          if (mounted) Navigator.of(this.context).pop();
        }),
      ],
    );
  }

  void _openAsk(BuildContext context, SignupRequest r) {
    final items = AdminMock.askItems(r.steps);
    final picked = <String>{r.steps < 5 ? 'setup' : r.healthNote.isNotEmpty ? 'doc' : 'photo'};
    final via = <String>{'WhatsApp', 'Email'};
    showAppSheet(
      context,
      title: 'Ask ${r.first} for more info',
      subtitle: 'She stays in Waiting. You get a notice when she updates her profile.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Spaced(
          gap: 14,
          children: [
            const FieldLabel('What does she need to do?'),
            OptionList(children: [
              for (final o in items)
                OptionRow(
                  title: o.title,
                  subtitle: o.sub,
                  multi: true,
                  selected: picked.contains(o.id),
                  onTap: () => set(() => picked.contains(o.id) ? picked.remove(o.id) : picked.add(o.id)),
                ),
            ]),
            LabeledField(
              label: 'Message',
              maxLines: 3,
              initialValue: 'Hi ${r.first}, before we start please finish the steps below in the app. It takes about 5 minutes.',
            ),
            Row(
              children: [
                Text('Send by', style: AppText.caption),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in const ['WhatsApp', 'Email', 'App notice'])
                        ChoicePill(v, selected: via.contains(v), onTap: () => set(() => via.contains(v) ? via.remove(v) : via.add(v))),
                    ],
                  ),
                ),
              ],
            ),
            Text('${picked.length} ${picked.length == 1 ? 'thing' : 'things'} asked', style: AppText.caption),
          ],
        ),
      ),
      actions: (ctx) => [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(ctx).pop()),
        AppButton('Send request', onPressed: () {
          showToast(ctx, 'Request sent to ${r.first}', subtitle: 'She stays in Waiting', kind: ToastKind.ok);
          Navigator.of(ctx).pop();
        }),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.request, required this.onPrev, required this.onNext, required this.canStep});
  final SignupRequest request;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canStep;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Row(
      children: [
        Avatar(r.initials, size: 44, color: r.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: AppText.cardTitle.copyWith(fontSize: 17)),
              Text('${r.when} · waiting ${r.wait}', style: AppText.caption),
            ],
          ),
        ),
        if (canStep) ...[
          AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Previous', onPressed: onPrev),
          const SizedBox(width: 6),
          AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Next', onPressed: onNext),
        ],
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.request});
  final SignupRequest request;

  @override
  Widget build(BuildContext context) {
    Widget kpi(String l, String v, [Color? c]) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: AppText.caption.copyWith(fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold.copyWith(fontSize: 13.5, color: c)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          kpi('Profile setup', '${request.steps} of 5 done'),
          kpi('Invited by', request.invitedBy),
          kpi('Waiting', request.wait, waitColor(request.waitLevel)),
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.done});
  final int done;

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 8,
      children: [
        for (var i = 0; i < AdminMock.setupSteps.length; i++)
          Row(
            children: [
              Icon(i < done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: i < done ? AppColors.ok : AppColors.line2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AdminMock.setupSteps[i].$1,
                    style: AppText.body.copyWith(fontSize: 13.5, color: i < done ? AppColors.text : AppColors.muted)),
              ),
              Text(i < done ? AdminMock.setupSteps[i].$2 : 'Not done', style: AppText.caption),
            ],
          ),
      ],
    );
  }
}

class _TrainerPicker extends StatelessWidget {
  const _TrainerPicker({required this.request, required this.value, required this.onPick});
  final SignupRequest request;
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final fit = AdminMock.goodFit[request.id];
    final order = <String>{request.invitedBy, ?fit, ...AdminMock.trainerChoices.map((t) => t.name)};
    final trs = [for (final n in order) ...AdminMock.trainerChoices.where((t) => t.name == n)];
    return OptionList(
      children: [
        for (final t in trs)
          OptionRow(
            title: t.name,
            subtitle: t.focus,
            selected: t.name == value,
            disabled: t.full,
            leading: Avatar(t.initials, size: 30, color: t.color),
            badge: t.full
                ? const PlainBadge('Full', tone: BadgeTone.warn)
                : t.name == request.invitedBy
                    ? const PlainBadge('Invited her')
                    : t.name == fit
                        ? const PlainBadge('Good fit', tone: BadgeTone.ok)
                        : null,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(TextSpan(
                  style: AppText.caption.copyWith(fontSize: 11.5),
                  children: [
                    TextSpan(text: '${t.clients} / ${t.capacity}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                    const TextSpan(text: ' clients'),
                  ],
                )),
                const SizedBox(height: 4),
                MiniBar(t.clients / t.capacity, width: 44, color: t.full ? const Color(0xFFB91C1C) : t.clients / t.capacity >= .8 ? const Color(0xFFD97706) : const Color(0xFFC9C9C4)),
              ],
            ),
            onTap: () => onPick(t.name),
          ),
      ],
    );
  }
}
