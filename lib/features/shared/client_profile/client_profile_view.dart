import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/people.dart';

import 'client_profile_controller.dart';
import 'sheets/profile_sheets.dart';
import 'tabs/activity_tab.dart';
import 'tabs/content_tab.dart';
import 'tabs/forms_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/plans_tab.dart';
import 'tabs/progress_tab.dart';

/// Client profile used by the admin (Clients → profile) and the trainer (My clients → profile).
/// Design: ClientProfileMobile / TrainerClientProfileMobile.
class ClientProfileView extends StatefulWidget {
  const ClientProfileView({super.key, required this.clientId, required this.role});
  final String clientId;
  final ProfileRole role;

  @override
  State<ClientProfileView> createState() => _ClientProfileViewState();
}

class _ClientProfileViewState extends State<ClientProfileView> {
  late final ClientProfileController _c = ClientProfileController(clientId: widget.clientId, role: widget.role);
  final _scroll = ScrollController();

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScope(
      controller: _c,
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => PageScroll(
          controller: _scroll,
          children: [
            const _Crumbs(),
            const _Header(),
            const _Actions(),
            const _Stats(),
            const _Tabs(),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _body() => switch (_c.tab) {
        'plans' => const PlansTab(),
        'logs' => const LogsTab(),
        'progress' => const ProgressTab(),
        'history' => const HistoryTab(),
        'content' => const ContentTab(),
        'forms' => const FormsTab(),
        'activity' => const ActivityTab(),
        'notes' => const NotesTab(),
        _ => const OverviewTab(),
      };
}

class _Crumbs extends StatelessWidget {
  const _Crumbs();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final list = c.isAdmin ? 'Clients' : 'My clients';
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(c.isAdmin ? Routes.aClients : Routes.tClients);
      }
    }

    return Row(
      children: [
        AppIconButton(Icons.arrow_back_rounded, small: true, onPressed: back),
        const SizedBox(width: 10),
        InkWell(
          onTap: back,
          child: Text(list, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: AppColors.accentText)),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
        Flexible(
          child: Text(c.name, overflow: TextOverflow.ellipsis, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    final tone = switch (c.status) {
      ClientStatus.active => BadgeTone.ok,
      ClientStatus.pending => BadgeTone.warn,
      ClientStatus.atRisk => BadgeTone.bad,
      ClientStatus.paused => BadgeTone.neutral,
    };
    final meta = AppText.secondary.copyWith(fontSize: 12.5, height: 1.55);
    const sep = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7),
        child: CircleAvatar(radius: 1.5, backgroundColor: AppColors.muted),
      ),
    );
    final since = c.client.joined.split(' ').take(2).join(' ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(c.initials, size: 48, color: AvatarColor.c1),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(c.name, style: AppText.sectionTitle.copyWith(fontSize: 20, height: 1.2)),
                  AppBadge.status(c.status.label, tone: tone),
                ],
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: meta,
                  children: [
                    TextSpan(text: '${c.client.goal} · 68 kg goal'),
                    sep,
                    if (c.isAdmin) ...[
                      const TextSpan(text: 'Trainer '),
                      TextSpan(text: c.trainer, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                    ] else
                      TextSpan(text: 'Your client since $since'),
                    sep,
                    TextSpan(text: 'Active ${c.client.lastActive}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    return Row(
      children: [
        Expanded(
          child: AppButton.outline('Edit profile', icon: Icons.edit_outlined, small: true, onPressed: () => showEditProfileSheet(context, c)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton('Assign plan', icon: Icons.add_rounded, small: true, onPressed: () => showAssignMenu(context, c)),
        ),
        const SizedBox(width: 8),
        AppIconButton(Icons.more_horiz_rounded, tooltip: 'More actions', onPressed: () => _more(context, c)),
      ],
    );
  }

  void _more(BuildContext context, ClientProfileController c) {
    showActionSheet(
      context,
      title: c.name,
      actions: [
        SheetAction('Edit profile details', Icons.edit_outlined, () => showEditProfileSheet(context, c)),
        if (c.isAdmin) SheetAction('Change trainer', Icons.swap_horiz_rounded, () => showChangeTrainerSheet(context, c)),
        SheetAction('Assign a plan', Icons.add_box_outlined, () => showAssignMenu(context, c)),
        SheetAction(
          'Send check-in reminder',
          Icons.notifications_active_outlined,
          () => showToast(context, 'Reminder sent to ${c.first}', subtitle: 'Push notice: "Time for your check-in"', kind: ToastKind.ok),
        ),
        SheetAction('Full history', Icons.history_rounded, () => c.goTab('history')),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  static const _icons = [Icons.track_changes_rounded, Icons.monitor_weight_outlined, Icons.fitness_center_rounded, Icons.fact_check_outlined];

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    const s = ClientProfileMock.stats;
    final taps = [() => c.goTab('logs'), () => c.goTab('progress'), () => c.goTab('logs'), () => c.goTab('logs')];
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < s.length; i++)
              SizedBox(
                width: w,
                child: _Stat(icon: _icons[i], label: s[i].$1, value: s[i].$2, delta: s[i].$3, good: s[i].$4, onTap: taps[i]),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value, required this.delta, this.good, this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool? good;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TintIcon(icon, tint: Tint.blue, size: 24),
              const SizedBox(width: 6),
              Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppText.bigNumber.copyWith(fontSize: 21)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (good == true) ...[const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.okText), const SizedBox(width: 3)],
              Expanded(
                child: Text(
                  delta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: good == true ? AppColors.okText : AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final c = ProfileScope.of(context);
    const t = ClientProfileMock.tabs;
    final idx = t.indexWhere((x) => x.$1 == c.tab);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: UnderlineTabs(
        labels: [for (final x in t) x.$3 == null ? x.$2 : '${x.$2}  ${x.$3}'],
        index: idx < 0 ? 0 : idx,
        onChanged: (i) => c.goTab(t[i].$1),
      ),
    );
  }
}
