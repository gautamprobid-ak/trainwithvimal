import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import '../../forms/widgets/engage_ui.dart';

enum IntegrationAction { confirm, disconnect }

/// Connect / manage sheet for an integration. Returns what the admin chose.
Future<IntegrationAction?> showIntegrationSheet(
  BuildContext context, {
  required Integration integration,
  required IntegrationState state,
  required Map<String, bool> health,
  required ValueChanged<Map<String, bool>> onHealth,
}) {
  final x = integration;
  final go = state == IntegrationState.off ? 'Connect' : (x.id == 'email' ? 'Check records again' : 'Save');
  return showAppSheet<IntegrationAction>(
    context,
    title: x.name,
    subtitle: state == IntegrationState.off ? 'Set it up once. It works for every client.' : state.label,
    builder: (ctx) => _Body(integration: x, state: state, health: health, onHealth: onHealth, goLabel: go),
  );
}

class _Body extends StatefulWidget {
  const _Body({required this.integration, required this.state, required this.health, required this.onHealth, required this.goLabel});
  final Integration integration;
  final IntegrationState state;
  final Map<String, bool> health;
  final ValueChanged<Map<String, bool>> onHealth;
  final String goLabel;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late Map<String, bool> _hc = {...widget.health};

  Future<void> _disconnect() async {
    final x = widget.integration;
    final msg = switch (x.id) {
      'whatsapp' => 'Automations and messages stop sending on WhatsApp. Email and push keep working.',
      'email' => 'Emails go back to the platform address.',
      _ => 'Client health data stops syncing. Past data stays.',
    };
    final ok = await showConfirmDialog(
      context,
      title: 'Disconnect ${x.name}?',
      message: msg,
      confirmLabel: 'Disconnect',
      destructive: true,
      icon: Icons.link_off_rounded,
    );
    if (ok && mounted) Navigator.of(context).pop(IntegrationAction.disconnect);
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.integration;
    final s = widget.state;
    return Spaced(
      gap: 14,
      children: [
        if (x.steps.isNotEmpty)
          Column(
            children: [
              for (var i = 0; i < x.steps.length; i++)
                _StepRow(
                  n: i + 1,
                  title: x.steps[i].$1,
                  help: x.steps[i].$2,
                  done: s == IntegrationState.on || (s == IntegrationState.dns && i < 2),
                ),
            ],
          ),
        if (x.id == 'whatsapp')
          FieldBlock(
            label: 'Business number',
            hint: 'Registered with the WhatsApp Business API',
            child: TextFormField(initialValue: EngageMock.gymPhone, style: AppText.body, keyboardType: TextInputType.phone),
          ),
        if (x.id == 'email') ...[
          FieldBlock(
            label: 'Sending domain',
            hint: 'Emails come from hello@trainwithvimal.com once verified',
            child: TextFormField(initialValue: 'trainwithvimal.com', style: AppText.body),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (t, h, st, ok) in EngageMock.dnsRecords)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 56, child: Text(t, style: AppText.bodyBold.copyWith(fontSize: 13))),
                        Expanded(child: Text(h, style: AppText.caption)),
                        AppBadge(st, tone: ok ? BadgeTone.ok : BadgeTone.warn),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (x.id == 'health') ...[
          for (final (k, t, h) in EngageMock.healthData)
            SwitchRow(
              title: t,
              subtitle: h,
              value: _hc[k] ?? false,
              onChanged: (v) {
                setState(() => _hc = {..._hc, k: v});
                widget.onHealth(_hc);
              },
            ),
          const NoteBox('Each client turns it on in their own app. Nothing is read without their permission.', icon: Icons.lock_rounded),
        ],
        Row(
          children: [
            if (s != IntegrationState.off) TextLink('Disconnect', danger: true, onTap: _disconnect),
            const Spacer(),
            AppButton.outline('Cancel', small: true, onPressed: () => Navigator.of(context).pop()),
            const SizedBox(width: 8),
            AppButton(
              widget.goLabel,
              small: true,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(IntegrationAction.confirm),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.n, required this.title, required this.help, required this.done});
  final int n;
  final String title;
  final String help;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: done ? AppColors.okBg : AppColors.sub, shape: BoxShape.circle),
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: AppColors.okText)
                : Text(
                    '$n',
                    style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text2),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                Text(help, style: AppText.caption.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
