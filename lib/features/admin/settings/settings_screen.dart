import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import '../forms/widgets/engage_ui.dart';
import 'widgets/brand_preview.dart';
import 'widgets/integration_sheet.dart';

enum _Tab { general, branding, roles, integrations }

/// Design: SettingsMobile.dc.html — gym profile and defaults, branding, roles
/// & access, and integrations.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Tab _tab = _Tab.general;
  bool _genSaved = false;
  bool _metric = true;
  bool _mondayFirst = true;
  String _timezone = 'Asia/Kolkata (IST)';
  String _language = 'English';
  Color _col = EngageMock.brandSwatches.first;
  String _theme = 'light';
  bool _brDirty = false;
  bool _hasLogo = true;
  List<RolePermission> _perms = EngageMock.permissions;
  bool _pmDirty = false;
  Map<String, IntegrationState> _int = EngageMock.integrationStates;
  Map<String, bool> _health = {'steps': true, 'sleep': true, 'hr': false, 'wo': true};

  /// Opens the page a "used in" / "where it shows" link points at.
  void _go(String target) {
    switch (target) {
      case 'automations':
        context.push(Routes.aAutomations);
      case 'emails':
        context.push(Routes.aEmails);
      case 'forms':
        context.push(Routes.aForms);
      case 'approvals':
        context.go(Routes.aApprovals);
      case 'clients':
        context.go(Routes.aClients);
      case 'trainers':
        context.push(Routes.aTrainers);
      case 'clientProfile':
        context.push(Routes.aClient('riya'));
      case 'habits':
        context.push(context.rolePath(Routes.habits));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = switch (_tab) {
      _Tab.general => 'Your gym details and the defaults every new client starts with.',
      _Tab.branding => 'How your app, emails and invite links look to clients.',
      _Tab.roles => 'Who can see and change what. Trainer access is fine-tuned on each trainer profile.',
      _Tab.integrations => 'Outside services the app sends through or reads from.',
    };
    return PageScroll(
      children: [
        const SubPageHeader(title: 'Settings'),
        Text(sub, style: AppText.secondary),
        CountTabs<_Tab>(
          items: const [
            (_Tab.general, 'General', null),
            (_Tab.branding, 'Branding', null),
            (_Tab.roles, 'Roles & access', null),
            (_Tab.integrations, 'Integrations', null),
          ],
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        ...switch (_tab) {
          _Tab.general => _general(),
          _Tab.branding => _branding(),
          _Tab.roles => _roles(),
          _Tab.integrations => _integrations(),
        },
      ],
    );
  }

  // --- general ---------------------------------------------------------------

  List<Widget> _general() {
    Widget field(String label, String value, {bool required = false, TextInputType? type}) => FieldBlock(
          label: label,
          required: required,
          child: TextFormField(initialValue: value, style: AppText.body, keyboardType: type, maxLines: null),
        );
    return [
      AppCard(
        clip: false,
        child: Spaced(
          gap: 12,
          children: [
            const EditorHead(icon: Icons.store_rounded, tint: Tint.blue, title: 'Gym profile', subtitle: 'Clients see this on emails and in their app'),
            field('Gym / business name', EngageMock.gymName, required: true),
            field('Contact email', EngageMock.gymEmail, type: TextInputType.emailAddress),
            field('Phone / WhatsApp', EngageMock.gymPhone, type: TextInputType.phone),
            field('Address', EngageMock.gymAddress),
            field('Website / Instagram', EngageMock.gymWeb, type: TextInputType.url),
            Row(
              children: [
                Text(_genSaved ? 'Saved just now' : 'Last saved 2 Oct', style: AppText.caption),
                const Spacer(),
                AppButton('Save changes', small: true, icon: Icons.check_rounded, onPressed: () {
                  setState(() => _genSaved = true);
                  showToast(context, 'Gym profile saved', subtitle: 'Emails and the client app use the new details', kind: ToastKind.ok);
                }),
              ],
            ),
          ],
        ),
      ),
      AppCard(
        clip: false,
        child: Spaced(
          gap: 14,
          children: [
            const EditorHead(
              icon: Icons.public_rounded,
              tint: Tint.green,
              title: 'Regional & defaults',
              subtitle: 'New clients get these by default and can change their own units',
            ),
            _SettingRow(
              title: 'Units',
              subtitle: _metric ? 'Weight in kg, body in cm, food in grams' : 'Weight in lb, body in inches, food in ounces',
              child: SegmentedTabs<bool>(
                items: const [(true, 'Metric · kg, cm'), (false, 'Imperial · lb, in')],
                value: _metric,
                onChanged: (v) {
                  final prev = _metric;
                  setState(() => _metric = v);
                  showToast(context, 'Units set to ${v ? 'metric' : 'imperial'}',
                      subtitle: 'For new clients', kind: ToastKind.ok, onUndo: () => setState(() => _metric = prev));
                },
              ),
            ),
            _SettingRow(
              title: 'Week starts on',
              subtitle: 'Calendar, weekly check-ins and habit streaks',
              child: SegmentedTabs<bool>(
                items: const [(true, 'Monday'), (false, 'Sunday')],
                value: _mondayFirst,
                onChanged: (v) => setState(() => _mondayFirst = v),
              ),
            ),
            _SettingRow(
              title: 'Timezone',
              subtitle: 'Reminders and automations run on this clock',
              child: SelectBox(
                value: _timezone,
                onTap: () async {
                  const z = ['Asia/Kolkata (IST)', 'Asia/Dubai (GST)', 'Europe/London (GMT)', 'America/New_York (ET)'];
                  final v = await pickFromSheet<String>(context, title: 'Timezone', items: [for (final x in z) (x, x)], selected: _timezone);
                  if (v != null) setState(() => _timezone = v);
                },
              ),
            ),
            _SettingRow(
              title: 'App language',
              subtitle: 'Menus and default messages',
              child: SelectBox(
                value: _language,
                onTap: () async {
                  const l = ['English', 'Hindi', 'Marathi', 'Gujarati'];
                  final v = await pickFromSheet<String>(context, title: 'App language', items: [for (final x in l) (x, x)], selected: _language);
                  if (v != null) setState(() => _language = v);
                },
              ),
            ),
          ],
        ),
      ),
      SideCard(
        title: 'Where these details show',
        children: [
          LinkRow(
            icon: Icons.phone_iphone_rounded,
            title: 'Client app',
            subtitle: 'Name, logo and brand colour',
            onTap: () => setState(() => _tab = _Tab.branding),
          ),
          LinkRow(icon: Icons.mail_rounded, title: 'Emails and WhatsApp', subtitle: 'Sender name and contact details', onTap: () => _go('emails')),
          LinkRow(icon: Icons.link_rounded, title: 'Invite links', subtitle: 'Name and address on the invite page', onTap: () => _go('approvals')),
          LinkRow(icon: Icons.assignment_rounded, title: 'Forms and waivers', subtitle: 'Business name on signed waivers', onTap: () => _go('forms')),
        ],
      ),
    ];
  }

  // --- branding --------------------------------------------------------------

  String get _hex => '#${(_col.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  List<Widget> _branding() {
    return [
      AppCard(
        clip: false,
        child: Spaced(
          gap: 14,
          children: [
            const EditorHead(
              icon: Icons.palette_rounded,
              tint: Tint.purple,
              title: 'Branding',
              subtitle: 'Your logo and colour in the client app, emails and invite links',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _hasLogo ? _col : AppColors.sub, borderRadius: BorderRadius.circular(14)),
                  child: Text('TV', style: AppText.cardTitle.copyWith(color: _hasLogo ? Colors.white : AppColors.muted, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logo', style: AppText.bodyBold),
                      Text('Square PNG or SVG, at least 512 x 512. Shown on the app icon screen, emails and invites.',
                          style: AppText.caption.copyWith(height: 1.4)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppButton.outline('Upload logo', small: true, icon: Icons.upload_rounded, onPressed: () {
                            setState(() => _hasLogo = true);
                            showToast(context, 'Logo uploaded', subtitle: 'logo-trainwithvimal.png · 512 x 512', kind: ToastKind.ok);
                          }),
                          const SizedBox(width: 6),
                          TextLink('Remove', onTap: () {
                            setState(() => _hasLogo = false);
                            showToast(context, 'Logo removed', subtitle: 'Your initials show until you upload a new one', kind: ToastKind.info);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FieldBlock(
              label: 'Brand colour',
              hint: 'Buttons, links, progress bars and the selected tab use this colour.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final c in EngageMock.brandSwatches)
                    GestureDetector(
                      onTap: () => setState(() {
                        _col = c;
                        _brDirty = true;
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c == _col ? AppColors.text : Colors.transparent, width: 2),
                        ),
                        child: c == _col ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
                      ),
                    ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.line)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 14, height: 14, decoration: BoxDecoration(color: _col, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 6),
                        Text(_hex, style: AppText.bodyBold.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FieldBlock(
              label: 'Default theme for clients',
              hint: _theme == 'system'
                  ? 'The app follows each client’s phone setting. Clients can still pick their own.'
                  : 'Clients start in $_theme mode and can change it in their app.',
              child: SegmentedTabs<String>(
                items: const [('light', 'Light'), ('dark', 'Dark'), ('system', 'Match phone')],
                value: _theme,
                onChanged: (v) => setState(() {
                  _theme = v;
                  _brDirty = true;
                }),
              ),
            ),
            Row(
              children: [
                TextLink('Reset', icon: Icons.restart_alt_rounded, onTap: () {
                  setState(() {
                    _col = EngageMock.brandSwatches.first;
                    _theme = 'light';
                    _brDirty = false;
                  });
                  showToast(context, 'Branding reset', subtitle: 'Blue and light theme', kind: ToastKind.ok);
                }),
                const Spacer(),
                Text(_brDirty ? 'Not applied yet' : 'Applied', style: AppText.caption),
                const SizedBox(width: 8),
                AppButton('Apply', small: true, icon: Icons.check_rounded, onPressed: () {
                  setState(() => _brDirty = false);
                  showToast(context, 'Branding applied', subtitle: 'Clients see it next time they open the app', kind: ToastKind.ok);
                }),
              ],
            ),
          ],
        ),
      ),
      SideCard(
        title: 'Client app preview',
        trailing: Text(_theme == 'dark' ? 'Dark' : _theme == 'system' ? 'Match phone · light shown' : 'Light',
            style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
        children: [
          BrandPreview(color: _col, dark: _theme == 'dark'),
          const FieldHint('Changes show for every client after Apply.'),
        ],
      ),
    ];
  }

  // --- roles -----------------------------------------------------------------

  List<Widget> _roles() {
    return [
      for (final r in EngageMock.roles)
        AppCard(
          clip: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHeader(icon: r.icon, tint: r.tint, title: r.name, subtitle: r.count),
              const SizedBox(height: 8),
              Text(r.scope, style: AppText.body.copyWith(fontSize: 13.5)),
              const SizedBox(height: 8),
              NoteBox(r.note, icon: Icons.info_outline_rounded),
              if (r.link != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton.outline(r.linkLabel!, small: true, icon: Icons.arrow_forward_rounded, onPressed: () => _go(r.link!)),
                ),
              ],
            ],
          ),
        ),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What each role can do', style: AppText.cardTitle),
                  Text(_pmDirty ? 'Not saved yet' : 'Tick a box to give a role that permission.', style: AppText.caption),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
              child: Row(
                children: [
                  Expanded(child: Text('PERMISSION', style: AppText.overline.copyWith(fontSize: 10.5))),
                  for (final h in ['Admin', 'Trainer', 'Client'])
                    SizedBox(width: 52, child: Text(h.toUpperCase(), textAlign: TextAlign.center, style: AppText.overline.copyWith(fontSize: 9.5, letterSpacing: 0))),
                ],
              ),
            ),
            for (var i = 0; i < _perms.length; i++) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
                child: Row(
                  children: [
                    Expanded(child: Text(_perms[i].name, style: AppText.bodyBold.copyWith(fontSize: 13))),
                    const SizedBox(width: 52, child: Center(child: TickBox(value: true, locked: true))),
                    SizedBox(
                      width: 52,
                      child: Center(
                        child: TickBox(
                          value: _perms[i].trainer,
                          onTap: () => setState(() {
                            _perms = [..._perms]..[i] = _perms[i].copyWith(trainer: !_perms[i].trainer);
                            _pmDirty = true;
                          }),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Center(
                        child: TickBox(
                          value: _perms[i].client,
                          onTap: () => setState(() {
                            _perms = [..._perms]..[i] = _perms[i].copyWith(client: !_perms[i].client);
                            _pmDirty = true;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('The admin always has every permission. Changes apply to every trainer and client.', style: AppText.caption),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextLink('Reset', icon: Icons.restart_alt_rounded, onTap: () => setState(() {
                        _perms = EngageMock.permissions;
                        _pmDirty = false;
                      })),
                      const Spacer(),
                      AppButton('Save', small: true, icon: Icons.check_rounded, onPressed: () {
                        setState(() => _pmDirty = false);
                        showToast(context, 'Permissions saved', subtitle: 'Applied to every trainer and client', kind: ToastKind.ok);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // --- integrations ----------------------------------------------------------

  List<Widget> _integrations() {
    return [
      for (final x in EngageMock.integrations) _IntegrationCard(x: x, state: _int[x.id]!, onOpen: () => _manage(x), onUse: _go),
      NoteBox(
        'Which alerts go out, and the sender name clients see, are set in Emails & alerts.',
        icon: Icons.notifications_rounded,
        action: TextLink('Open', onTap: () => _go('emails')),
      ),
    ];
  }

  Future<void> _manage(Integration x) async {
    final res = await showIntegrationSheet(
      context,
      integration: x,
      state: _int[x.id]!,
      health: _health,
      onHealth: (m) => setState(() => _health = m),
    );
    if (res == null || !mounted) return;
    final was = _int[x.id]!;
    if (res == IntegrationAction.disconnect) {
      final prev = _int;
      setState(() => _int = {..._int, x.id: IntegrationState.off});
      showToast(context, '${x.name} disconnected', kind: ToastKind.del, onUndo: () => setState(() => _int = prev));
      return;
    }
    final next = x.id == 'email' ? IntegrationState.dns : IntegrationState.on;
    setState(() => _int = {..._int, x.id: next});
    showToast(
      context,
      was == IntegrationState.off ? '${x.name} connected' : (x.id == 'email' ? 'Checking the DNS records' : 'Saved'),
      subtitle: x.id == 'email' ? 'We will email you when all three are verified' : null,
      kind: ToastKind.ok,
    );
  }
}

/// Title + help on the left, control below (st-row on a phone).
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
        Text(subtitle, style: AppText.caption),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({required this.x, required this.state, required this.onOpen, required this.onUse});
  final Integration x;
  final IntegrationState state;
  final VoidCallback onOpen;
  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context) {
    final tone = switch (state) { IntegrationState.on => BadgeTone.ok, IntegrationState.dns => BadgeTone.warn, IntegrationState.off => BadgeTone.neutral };
    final meta = switch (state) {
      IntegrationState.on => x.id == 'whatsapp' ? EngageMock.gymPhone : (x.id == 'health' ? '64 clients linked' : EngageMock.gymEmail),
      IntegrationState.dns => 'Sending from the platform address for now',
      IntegrationState.off => 'Not set up',
    };
    return AppCard(
      clip: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: x.bg, borderRadius: BorderRadius.circular(11)),
                child: Text(x.short, style: AppText.bodyBold.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: x.fg)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(x.name, style: AppText.bodyBold),
                    const SizedBox(height: 3),
                    AppBadge(state.label, tone: tone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(x.description, style: AppText.body.copyWith(fontSize: 13.5)),
          const SizedBox(height: 10),
          Text('USED IN', style: AppText.overline.copyWith(fontSize: 10.5)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [for (final u in x.used) TextLink(u.label, icon: Icons.arrow_outward_rounded, onTap: () => onUse(u.target))],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(child: Text(meta, style: AppText.caption)),
              state == IntegrationState.off
                  ? AppButton('Connect', small: true, onPressed: onOpen)
                  : AppButton.outline('Manage', small: true, onPressed: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}
