import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';
import 'package:train_with_vimal/data/state/session.dart';

import 'client_ui.dart';

part 'client_more_sheets.dart';

/// Design: ClientMore.dc.html — More tab / My account: profile, coach, your plan,
/// notifications, reminders, units, privacy, help, about, log out.
class ClientMoreScreen extends ConsumerStatefulWidget {
  const ClientMoreScreen({super.key});

  @override
  ConsumerState<ClientMoreScreen> createState() => _ClientMoreScreenState();
}

enum _Tab { overview, notifications, activity }

class _ClientMoreScreenState extends ConsumerState<ClientMoreScreen> {
  _Tab _tab = _Tab.overview;
  bool _profile = false;

  // profile
  Map<String, String> _pf = {...ClientMock.profile0};
  String? _pendingEmail;
  List<ActivityItem> _extra = [];

  // units
  Map<String, String> _units = {..._units0};
  static const _units0 = {'w': 'kg', 'l': 'cm', 'wa': 'L', 'ws': 'Monday', 'th': 'Light'};

  // notifications
  Set<String> _read = {...ClientMock.notificationsRead0};
  Set<String> _gone = {};
  bool _unreadOnly = false;

  // reminders
  Map<String, bool> _rem = {...ClientMock.reminders0};
  bool _quietOn = true;
  int _quietFrom = 1320, _quietTo = 420;

  // privacy
  bool _photos = true, _improve = false;
  String _dl = 'idle';
  bool _deletion = false;

  // activity
  String _actFilter = 'All';

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  // ------------------------------------------------------------ helpers

  String _wt(double kg, [Map<String, String>? u]) => (u ?? _units)['w'] == 'kg' ? '${kg.toStringAsFixed(1)} kg' : '${(kg * 2.20462).toStringAsFixed(1)} lb';
  String _ht([Map<String, String>? u]) => (u ?? _units)['l'] == 'cm' ? '162 cm' : '5 ft 4 in';
  String _wat([Map<String, String>? u]) => (u ?? _units)['wa'] == 'L' ? '3 L a day' : '101 fl oz a day';

  String get _initials => _pf['name']!.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();

  List<ClientNotification> get _live => [for (final n in ClientMock.notifications) if (!_gone.contains(n.id)) n];
  int get _unread => _live.where((n) => !_read.contains(n.id)).length;

  /// Routes inside More are pushed; other tabs are opened with go.
  void _openRoute(String route) => route.startsWith(Routes.cMore) ? context.push(route) : context.go(route);

  String _clock(int m) => clock(m % 1440);

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_profile && _tab == _Tab.overview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            if (_profile) {
              _profile = false;
            } else {
              _tab = _Tab.overview;
            }
          });
        }
      },
      child: PageScroll(
        children: _profile
            ? _profileView()
            : [
                ClientTop(
                  title: 'More',
                  subtitle: 'Your account, coach and settings',
                  actions: [
                    AppIconButton(Icons.notifications_none_rounded, dot: _unread > 0, tooltip: 'Notifications', onPressed: () => setState(() => _tab = _Tab.notifications)),
                  ],
                ),
                SegmentedTabs<_Tab>(
                  items: [
                    (_Tab.overview, 'Overview'),
                    (_Tab.notifications, _unread > 0 ? 'Notifications · $_unread' : 'Notifications'),
                    (_Tab.activity, 'My activity'),
                  ],
                  value: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                ...switch (_tab) {
                  _Tab.overview => _overview(),
                  _Tab.notifications => _notificationsView(),
                  _Tab.activity => _activityView(),
                },
              ],
      ),
    );
  }

  List<Widget> _overview() {
    final onN = ClientMock.reminderSettings.where((r) => _rem[r.key]!).length;
    final remSum = '$onN of ${ClientMock.reminderSettings.length} on${_quietOn ? ' · quiet ${_clock(_quietFrom)} – ${_clock(_quietTo)}' : ''}';
    final unitSum =
        '${_units['w']}, ${_units['l']}, ${_units['wa'] == 'L' ? 'litres' : 'fl oz'} · week starts ${_units['ws']!.substring(0, 3)}';
    return [
      if (_deletion)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Row(
            children: [
              const TintIcon(Icons.warning_amber_rounded, tint: Tint.amber, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account deletion on Fri, 23 Oct', style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                    Text('Everything is erased on that day. You can still cancel.', style: AppText.caption),
                  ],
                ),
              ),
              AppButton.outline('Cancel deletion', small: true, onPressed: () {
                setState(() => _deletion = false);
                showToast(context, 'Deletion cancelled', subtitle: 'Your account stays as it is', kind: ToastKind.ok);
              }),
            ],
          ),
        ),
      AppCard(
        onTap: () => setState(() => _profile = true),
        child: Row(
          children: [
            _BigAvatar(_initials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_pf['name']!, style: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Coach Aman · Profile & activity', style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
      AppCard(
        child: Column(
          children: [
            Row(
              children: [
                const Avatar('AV', size: 40, color: AvatarColor.c2),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aman Verma', style: AppText.bodyBold.copyWith(fontSize: 14.5)),
                      Text('Your trainer since 12 Jan 2026', style: AppText.caption),
                    ],
                  ),
                ),
                AppButton.outline('Details', small: true, onPressed: _openCoach),
              ],
            ),
            const SizedBox(height: 10),
            const _CoachLine(icon: Icons.event_rounded, tint: Tint.blue, label: 'Next session', value: 'Today, 6:30 pm · Gym floor'),
            const SizedBox(height: 8),
            const _CoachLine(icon: Icons.assignment_rounded, tint: Tint.amber, label: 'Weekly check-in', value: 'Every Sunday, 6:00 pm · next Sun, 11 Oct'),
          ],
        ),
      ),
      const Overline('Your plan'),
      MenuList(children: [
        MenuRow(
          icon: Icons.check_circle_outline_rounded,
          title: 'Habits & supplements',
          subtitle: 'Steps, water, sleep · whey, D3, magnesium',
          onTap: () => context.push(Routes.cHabits),
        ),
        MenuRow(
          icon: Icons.assignment_rounded,
          title: 'Check-ins',
          subtitle: 'Week 7 due Sun, 11 Oct',
          trailing: const Pill('Due Sun', tone: PillTone.amber),
          onTap: () => context.push(Routes.cCheckins),
        ),
        MenuRow(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Nutrition overview',
          subtitle: '1,650 kcal · vegetarian · weekly averages',
          onTap: () => context.go(Routes.cNutrition),
        ),
        MenuRow(icon: Icons.menu_book_rounded, title: 'Library', subtitle: 'Guides and videos from Aman', onTap: () => context.push(Routes.cLibrary)),
      ]),
      const Overline('Account'),
      MenuList(children: [
        MenuRow(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: _unread > 0 ? '$_unread unread' : 'All caught up',
          trailing: _unread > 0 ? Pill('$_unread new', tone: PillTone.blue) : null,
          onTap: () => setState(() => _tab = _Tab.notifications),
        ),
        MenuRow(icon: Icons.tune_rounded, title: 'Notification settings', subtitle: remSum, onTap: _openReminders),
        MenuRow(icon: Icons.straighten_rounded, title: 'Units & preferences', subtitle: unitSum, onTap: _openUnits),
        MenuRow(icon: Icons.lock_outline_rounded, title: 'Privacy & data', subtitle: 'Who sees your data · download · delete', onTap: _openPrivacy),
        MenuRow(icon: Icons.history_rounded, title: 'My activity', subtitle: 'Everything you logged, newest first', onTap: () => setState(() => _tab = _Tab.activity)),
        MenuRow(icon: Icons.help_outline_rounded, title: 'Help & about', subtitle: 'Questions, report a problem, version', onTap: _openHelp),
        MenuRow(icon: Icons.info_outline_rounded, title: 'About', subtitle: 'Train With Vimal · contact and app info', onTap: () => context.push(Routes.cAbout)),
      ]),
      AppButton.outline('Log out', icon: Icons.logout_rounded, expand: true, onPressed: _openLogout),
      Center(child: Text('Train With Vimal · Version 1.0.0', style: AppText.caption)),
    ];
  }

  List<Widget> _profileView() {
    return [
      ClientTop(title: 'Profile', subtitle: 'What Aman sees about you', onBack: () => setState(() => _profile = false)),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _BigAvatar(_initials, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_pf['name']!, style: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('Client since 12 Jan 2026', style: AppText.caption),
                    ],
                  ),
                ),
                AppButton.outline('Edit', small: true, icon: Icons.edit_rounded, onPressed: _openEditProfile),
              ],
            ),
            if (_pendingEmail != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Verify your new email', style: AppText.bodyBold.copyWith(fontSize: 13.5, color: AppColors.infoText)),
                    Text('We sent a link to $_pendingEmail. Until then we use ${_pf['email']}.', style: AppText.caption.copyWith(color: AppColors.text2)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      AppButton.outline('Resend link',
                          small: true, onPressed: () => showToast(context, 'Verification link sent again', subtitle: 'To $_pendingEmail', kind: ToastKind.info)),
                      AppButton.outline('Cancel change', small: true, onPressed: () {
                        final p = _pendingEmail;
                        setState(() => _pendingEmail = null);
                        showToast(context, 'Email change cancelled',
                            subtitle: 'We keep using ${_pf['email']}', kind: ToastKind.info, onUndo: () => _set(() => _pendingEmail = p));
                      }),
                      AppButton.dark('Verify now (demo)', small: true, onPressed: () {
                        final p = _pendingEmail!;
                        setState(() {
                          _pf = {..._pf, 'email': p};
                          _pendingEmail = null;
                        });
                        showToast(context, 'Email verified', subtitle: '$p is now your login email', kind: ToastKind.ok);
                      }),
                    ]),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            KvList([
              ('Email', _pf['email']!),
              ('Mobile', '+91 ${_pf['phone']}'),
              ('City', _pf['city']!),
              ('Date of birth', '${_pf['dob']} · 29 years'),
              ('Height', _ht()),
              ('Coach', 'Aman Verma'),
              ('Program', 'Fat Loss Phase 1 · week 6 of 12'),
              ('Plan dates', '1 Sep – 23 Nov 2026'),
            ]),
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHead(
              icon: Icons.flag_rounded,
              tint: Tint.green,
              title: 'Goal: lose fat',
              subtitle: 'By Feb 2027 · ${_wt(3.2)} to go',
              trailing: const Pill('68% there', tone: PillTone.green),
            ),
            const SizedBox(height: 12),
            const ProgressBar(.68, height: 8, color: Color(0xFF22C55E)),
            const SizedBox(height: 6),
            Row(children: [
              Text('Start ${_wt(78)}', style: AppText.caption),
              const Spacer(),
              Text('Now ${_wt(71.2)}', style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.text)),
              const Spacer(),
              Text('Goal ${_wt(68)}', style: AppText.caption),
            ]),
            const SizedBox(height: 12),
            StatCells([('−${_wt(6.8)}', 'since Jan'), ('6 of 12', 'weeks done'), ('6', 'check-ins sent')]),
          ],
        ),
      ),
      MenuList(children: [
        MenuRow(
          icon: Icons.history_rounded,
          title: 'My activity',
          subtitle: 'Everything you logged, newest first',
          onTap: () => setState(() {
            _profile = false;
            _tab = _Tab.activity;
          }),
        ),
      ]),
    ];
  }

  List<Widget> _notificationsView() {
    final unread = _unread;
    final shown = _unreadOnly ? _live.where((n) => !_read.contains(n.id)).toList() : _live;
    return [
      Row(
        children: [
          Expanded(child: Text(unread > 0 ? '$unread unread · ${_live.length} in all' : 'All caught up', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600))),
          AppButton.outline('Mark all read', small: true, icon: Icons.done_all_rounded, onPressed: unread == 0 ? null : () {
            final prev = {..._read};
            setState(() => _read = {for (final n in ClientMock.notifications) n.id});
            showToast(context, 'All marked as read', subtitle: '$unread notifications', kind: ToastKind.ok, onUndo: () => _set(() => _read = prev));
          }),
          const SizedBox(width: 6),
          AppIconButton(Icons.settings_outlined, small: true, tooltip: 'Notification settings', onPressed: _openReminders),
        ],
      ),
      Row(children: [
        ChoicePill('All', selected: !_unreadOnly, onTap: () => setState(() => _unreadOnly = false)),
        const SizedBox(width: 6),
        ChoicePill(unread > 0 ? 'Unread · $unread' : 'Unread', selected: _unreadOnly, onTap: () => setState(() => _unreadOnly = true)),
      ]),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: shown.isEmpty
            ? EmptyState(
                icon: Icons.notifications_off_outlined,
                title: _unreadOnly ? 'All caught up' : 'No notifications',
                message: _unreadOnly ? 'You have read everything. New notifications show up here.' : 'Reminders and updates from Aman show up here.',
              )
            : Column(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _IconRow(
                      icon: _iconFor(shown[i].icon),
                      tint: _tintFor(shown[i].tone),
                      title: shown[i].title,
                      subtitle: shown[i].body,
                      meta: shown[i].when,
                      unread: !_read.contains(shown[i].id),
                      onTap: () => _openNotification(shown[i]),
                    ),
                  ],
                ],
              ),
      ),
    ];
  }

  List<Widget> _activityView() {
    final all = [..._extra, ...ClientMock.activity];
    final fl = [for (final a in all) if (_actFilter == 'All' || a.kind == _actFilter) a];
    return [
      Text('Only you can see this · last 7 days', style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final f in ClientMock.activityFilters) ...[
            ChoicePill(f, selected: _actFilter == f, onTap: () => setState(() => _actFilter = f)),
            const SizedBox(width: 6),
          ],
        ]),
      ),
      if (fl.isEmpty)
        AppCard(
          child: EmptyState(
            icon: Icons.history_rounded,
            title: 'Nothing here yet',
            message: _actFilter == 'Account' ? 'Changes to your profile and settings show up here.' : 'Nothing logged in this filter in the last 7 days.',
          ),
        ),
      for (var d = 0; d < ClientMock.activityDays.length; d++)
        if (fl.any((a) => a.day == d)) ...[
          Overline(ClientMock.activityDays[d],
              trailing: Builder(builder: (_) {
                final n = fl.where((a) => a.day == d).length;
                return Text('$n${n == 1 ? ' item' : ' items'}', style: AppText.caption);
              })),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final (i, a) in fl.where((a) => a.day == d).indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _IconRow(icon: _iconFor(a.icon), tint: _tintFor(a.tone), title: a.title, subtitle: a.subtitle, meta: a.time, onTap: () => _openActivity(a)),
                ],
              ],
            ),
          ),
        ],
    ];
  }
}

// ---------------------------------------------------------------- widgets

IconData _iconFor(String k) => switch (k) {
      'form' => Icons.assignment_rounded,
      'dumb' => Icons.fitness_center_rounded,
      'cal' => Icons.event_rounded,
      'water' => Icons.water_drop_rounded,
      'food' => Icons.restaurant_rounded,
      'pill' => Icons.medication_rounded,
      'steps' => Icons.directions_walk_rounded,
      'moon' => Icons.bedtime_rounded,
      'user' => Icons.person_rounded,
      'scale' => Icons.monitor_weight_rounded,
      'star' => Icons.star_rounded,
      'target' => Icons.flag_rounded,
      'book' => Icons.menu_book_rounded,
      _ => Icons.notifications_rounded,
    };

Tint _tintFor(String t) => switch (t) {
      'blue' => Tint.blue,
      'green' => Tint.green,
      'amber' => Tint.amber,
      'purple' => Tint.purple,
      _ => Tint.gray,
    };

class _BigAvatar extends StatelessWidget {
  const _BigAvatar(this.initials, {this.size = 48});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFFFE4D6), shape: BoxShape.circle),
      child: Text(initials, style: AppText.bodyBold.copyWith(fontSize: size / 3, fontWeight: FontWeight.w800, color: const Color(0xFF9A3412))),
    );
  }
}

class _CoachLine extends StatelessWidget {
  const _CoachLine({required this.icon, required this.tint, required this.label, required this.value});
  final IconData icon;
  final Tint tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TintIcon(icon, tint: tint, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption),
              Text(value, style: AppText.bodyBold.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Notification / activity row (mo-nr / mo-ar).
class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.tint, required this.title, required this.subtitle, required this.meta, required this.onTap, this.unread = false});
  final IconData icon;
  final Tint tint;
  final String title;
  final String subtitle;
  final String meta;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintIcon(icon, tint: tint, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5, fontWeight: unread ? FontWeight.w800 : FontWeight.w700)),
                  Text(subtitle, style: AppText.caption.copyWith(color: AppColors.text2)),
                  const SizedBox(height: 2),
                  Text(meta, style: AppText.caption.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            if (unread)
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6, left: 6), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
