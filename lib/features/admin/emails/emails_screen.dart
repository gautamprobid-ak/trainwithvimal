import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

import '../forms/widgets/engage_ui.dart';
import 'widgets/message_previews.dart';

enum _Tab { templates, alerts, sender }

/// Design: EmailsMobile.dc.html — client message templates per channel, team
/// alerts and the sender identity.
class EmailsScreen extends StatefulWidget {
  const EmailsScreen({super.key});

  @override
  State<EmailsScreen> createState() => _EmailsScreenState();
}

class _EmailsScreenState extends State<EmailsScreen> {
  _Tab _tab = _Tab.templates;
  List<MsgTemplate> _tps = EngageMock.templates;
  String _tid = 'checkin-reminder';
  Channel? _ch;
  final Set<String> _off = {};
  bool _detail = false;
  bool _dirty = false;

  /// Bumped when text changes from outside the fields (variables, reset).
  int _rev = 0;
  List<TeamAlert> _alerts = EngageMock.teamAlerts;
  bool _quiet = true;
  String _quietFrom = '10:00 pm';
  String _quietTo = '7:00 am';
  String _digest = 'daily';

  MsgTemplate get _t => _tps.firstWhere((t) => t.id == _tid, orElse: () => _tps.firstWhere((t) => t.id == 'checkin-reminder', orElse: () => _tps.first));

  Channel get _channel {
    final t = _t;
    if (_ch != null) return _ch!;
    return t.texts.containsKey(Channel.push) ? Channel.push : t.texts.keys.first;
  }

  bool _isOn(MsgTemplate t, Channel c) => t.texts.containsKey(c) && !_off.contains('${t.id}${c.name}');

  void _setText(Channel c, MsgText v, {bool external = false}) {
    final t = _t;
    setState(() {
      _tps = [for (final x in _tps) x.id == t.id ? x.copyWith(texts: {...x.texts, c: v}) : x];
      _dirty = true;
      if (external) _rev++;
    });
  }

  void _toggleChannel() {
    final t = _t, c = _channel;
    if (!t.texts.containsKey(c)) {
      _setText(c, const MsgText('Check-in time', 'Hi {{first_name}}, your weekly check-in is due today.'), external: true);
      showToast(context, '${c.label} turned on', subtitle: 'Write the text and save', kind: ToastKind.ok);
      return;
    }
    final key = '${t.id}${c.name}';
    setState(() => _off.contains(key) ? _off.remove(key) : _off.add(key));
  }

  Future<void> _delete() async {
    final t = _t;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this template?',
      message: '${t.name} is removed for good. Automations cannot use it any more.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_rounded,
    );
    if (!ok || !mounted) return;
    final prev = _tps, prevId = _tid;
    setState(() {
      _tps = _tps.where((x) => x.id != t.id).toList();
      _tid = 'checkin-reminder';
      _ch = null;
      _detail = false;
    });
    showToast(context, 'Template deleted', subtitle: t.name, kind: ToastKind.del, onUndo: () => setState(() {
      _tps = prev;
      _tid = prevId;
    }));
  }

  void _openNew() {
    showAppSheet(
      context,
      title: 'New message template',
      subtitle: 'Write it once, then use it in any automation',
      builder: (ctx) => _NewTemplateSheet(onCreate: (name, group, chs) {
        Navigator.of(ctx).pop();
        final prev = _tps, prevId = _tid;
        final id = 'custom-${_tps.length}';
        setState(() {
          _tps = [
            ..._tps,
            MsgTemplate(
              id: id,
              name: name,
              group: group,
              when: 'By an automation you pick',
              custom: true,
              texts: {
                for (final c in chs)
                  c: MsgText(c == Channel.whatsapp ? '' : 'You are on a roll, {{first_name}}',
                      'Hi {{first_name}}, 7 workouts in a row. Keep it going! {{coach_name}}'),
              },
            ),
          ];
          _tid = id;
          _ch = chs.first;
          _detail = true;
          _rev++;
        });
        showToast(context, 'Template created', subtitle: 'Edit the text, then add it to an automation', kind: ToastKind.ok, onUndo: () => setState(() {
          _tps = prev;
          _tid = prevId;
          _detail = false;
        }));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = switch (_tab) {
      _Tab.templates => 'The messages clients and trainers get, per channel. Change the words once and every send uses them.',
      _Tab.alerts => 'Alerts for you and your trainers when something happens.',
      _Tab.sender => 'Who clients see as the sender of emails and WhatsApp messages.',
    };
    return PageScroll(
      children: [
        SubPageHeader(
          title: 'Emails & alerts',
          actions: [
            if (_tab == _Tab.templates) AppButton('New template', icon: Icons.add_rounded, small: true, onPressed: _openNew),
          ],
        ),
        Text(sub, style: AppText.secondary),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.outline('Automations', small: true, icon: Icons.bolt_rounded, onPressed: () => context.push(Routes.aAutomations)),
        ),
        CountTabs<_Tab>(
          items: [(_Tab.templates, 'Client messages', _tps.length), (_Tab.alerts, 'Team alerts', _alerts.length), (_Tab.sender, 'Sender', null)],
          value: _tab,
          onChanged: (v) => setState(() {
            _tab = v;
            _detail = false;
          }),
        ),
        ...switch (_tab) {
          _Tab.templates => _detail ? _templateDetail() : [_templateList()],
          _Tab.alerts => _alertsTab(),
          _Tab.sender => _senderTab(),
        },
      ],
    );
  }

  // --- client messages -----------------------------------------------------

  Widget _templateList() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in EngageMock.templateGroups)
            if (_tps.any((t) => t.group == g)) ...[
              Overline(g, padding: const EdgeInsets.fromLTRB(14, 10, 14, 4)),
              for (final t in _tps.where((t) => t.group == g))
                InkWell(
                  onTap: () => setState(() {
                    _tid = t.id;
                    _ch = null;
                    _detail = true;
                    _rev++;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(t.name, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                                  if (t.custom) const AppBadge('Custom', tone: BadgeTone.info),
                                ],
                              ),
                              Text(t.when, style: AppText.caption),
                            ],
                          ),
                        ),
                        for (final c in Channel.values)
                          Tooltip(
                            message: '${c.label}${_isOn(t, c) ? ' · on' : ' · off'}',
                            child: Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(color: _isOn(t, c) ? const Color(0xFF10B981) : const Color(0xFFDADAD5), shape: BoxShape.circle),
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
            ],
        ],
      ),
    );
  }

  List<Widget> _templateDetail() {
    final t = _t, c = _channel, on = _isOn(t, c), cur = t.texts[c];
    final uses = EngageMock.templateUses[t.id] ?? const [];
    final max = switch (c) { Channel.push => 120, Channel.whatsapp => 1000, _ => 2000 };
    return [
      Row(
        children: [
          TextLink('Messages', icon: Icons.arrow_back_rounded, onTap: () => setState(() => _detail = false)),
          const SizedBox(width: 8),
          Expanded(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyBold)),
        ],
      ),
      AppCard(
        clip: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorHead(icon: Icons.mail_rounded, tint: Tint.blue, title: t.name, subtitle: 'Sent: ${t.when}'),
            const SizedBox(height: 10),
            _ChannelTabs(value: c, isOn: (x) => _isOn(t, x), onChanged: (x) => setState(() {
              _ch = x;
              _rev++;
            })),
            const SizedBox(height: 12),
            SwitchRow(
              title: 'Send by ${c.label}',
              subtitle: on ? 'This message goes out on this channel.' : 'Off: this message is not sent on this channel.',
              value: on,
              onChanged: (_) => _toggleChannel(),
            ),
            const SizedBox(height: 10),
            if (on && cur != null) ...[
              if (c != Channel.whatsapp) ...[
                FieldBlock(
                  label: c == Channel.email ? 'Subject' : 'Title',
                  hint: '${c == Channel.email ? 'Subject' : 'Title'} ${cur.subject.length} / 50',
                  child: TextFormField(
                    key: ValueKey('${t.id}-${c.name}-s-$_rev'),
                    initialValue: cur.subject,
                    style: AppText.body,
                    onChanged: (v) => _setText(c, MsgText(v, _t.texts[c]!.body)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FieldBlock(
                label: 'Message',
                hint: 'Message ${cur.body.length} / $max',
                child: TextFormField(
                  key: ValueKey('${t.id}-${c.name}-b-$_rev'),
                  initialValue: cur.body,
                  style: AppText.body,
                  minLines: 5,
                  maxLines: 12,
                  onChanged: (v) => _setText(c, MsgText(_t.texts[c]!.subject, v)),
                ),
              ),
              const SizedBox(height: 10),
              Text('Insert a variable', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in EngageMock.sampleVars.keys)
                    ActionChip(
                      label: Text('{{$v}}', style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentText)),
                      backgroundColor: AppColors.accentSoft,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        final x = _t.texts[c]!;
                        _setText(c, MsgText(x.subject, '${x.body} {{$v}}'), external: true);
                      },
                    ),
                ],
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
                child: Text('There is no ${c.label} text for this message yet. Turn it on to write one.',
                    textAlign: TextAlign.center, style: AppText.secondary),
              ),
            const Divider(height: 24),
            Row(
              children: [
                if (t.custom)
                  TextLink('Delete template', icon: Icons.delete_rounded, danger: true, onTap: _delete)
                else
                  TextLink('Reset to default', icon: Icons.restart_alt_rounded, onTap: () {
                    setState(() {
                      _tps = EngageMock.templates;
                      _dirty = false;
                      _rev++;
                    });
                    showToast(context, 'Default text restored', subtitle: t.name, kind: ToastKind.ok);
                  }),
                const Spacer(),
                Text(_dirty ? 'Not saved yet' : 'Saved', style: AppText.caption),
                const SizedBox(width: 8),
                AppButton('Save', small: true, icon: Icons.check_rounded, onPressed: () {
                  setState(() => _dirty = false);
                  showToast(context, 'Template saved', subtitle: '${t.name} · ${c.label}', kind: ToastKind.ok);
                }),
              ],
            ),
          ],
        ),
      ),
      SideCard(
        title: 'Preview',
        trailing: Text(c.label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
        children: [
          PhoneFrame(
            child: !on || cur == null
                ? Text('Off: this message is not sent on this channel.', textAlign: TextAlign.center, style: AppText.secondary)
                : switch (c) {
                    Channel.email => EmailPreview(subject: EngageMock.fillVars(cur.subject), body: EngageMock.fillVars(cur.body)),
                    Channel.push => PushPreview(title: EngageMock.fillVars(cur.subject), body: EngageMock.fillVars(cur.body)),
                    Channel.whatsapp => WhatsAppPreview(body: EngageMock.fillVars(cur.body)),
                    Channel.inApp => InAppPreview(title: EngageMock.fillVars(cur.subject), body: EngageMock.fillVars(cur.body)),
                  },
          ),
          const FieldHint('How Sana, a sample client, would see it. Variables are filled in for each person.'),
        ],
      ),
      SideCard(
        title: 'Where it is used',
        children: [
          if (uses.isNotEmpty)
            for (final u in uses)
              LinkRow(
                icon: Icons.bolt_rounded,
                title: u.automation,
                subtitle: u.where,
                onTap: () => context.push(Routes.aAutomations),
              )
          else if (t.custom) ...[
            const NoteBox('Not used yet. Add it to a Send message step in an automation.', icon: Icons.bolt_rounded),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton.outline('Open automation builder',
                  small: true, icon: Icons.bolt_rounded, onPressed: () => context.push(Routes.aAutomationBuilder)),
            ),
          ] else
            NoteBox(EngageMock.systemSends[t.id] ?? 'Sent by the app.', icon: Icons.phone_iphone_rounded),
        ],
      ),
    ];
  }

  // --- team alerts ---------------------------------------------------------

  List<Widget> _alertsTab() {
    final allOn = _alerts.every((e) => e.channels.length == 4);
    return [
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Who gets notified, where', style: AppText.cardTitle),
                        Text('Goes to you and the assigned trainer. Client messages are in the first tab.', style: AppText.caption.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton.outline(allOn ? 'All channels on' : 'Enable all', small: true, onPressed: () {
                    setState(() => _alerts = [for (final e in _alerts) e.copyWith(channels: Channel.values.toSet())]);
                    showToast(context, 'All channels on', kind: ToastKind.ok);
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
              child: Row(
                children: [
                  Expanded(child: Text('EVENT', style: AppText.overline.copyWith(fontSize: 10.5))),
                  for (final c in Channel.values)
                    SizedBox(width: 40, child: Text(c.label, textAlign: TextAlign.center, style: AppText.overline.copyWith(fontSize: 9.5, letterSpacing: 0))),
                ],
              ),
            ),
            for (var i = 0; i < _alerts.length; i++) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_alerts[i].name, style: AppText.bodyBold.copyWith(fontSize: 13)),
                          Text(_alerts[i].description, style: AppText.caption.copyWith(fontSize: 11.5)),
                        ],
                      ),
                    ),
                    for (final c in Channel.values)
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: TickBox(
                            value: _alerts[i].channels.contains(c),
                            onTap: () => setState(() {
                              final cs = {..._alerts[i].channels};
                              cs.contains(c) ? cs.remove(c) : cs.add(c);
                              _alerts = [..._alerts]..[i] = _alerts[i].copyWith(channels: cs);
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      SideCard(
        title: 'Quiet hours',
        trailing: MiniToggle(value: _quiet, onChanged: (v) => setState(() => _quiet = v)),
        children: [
          Text('No push or WhatsApp at night. Emails wait in a queue.', style: AppText.caption),
          if (_quiet) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: FieldBlock(label: 'From', child: SelectBox(value: _quietFrom, onTap: () => _pickTime(true)))),
                const SizedBox(width: 10),
                Expanded(child: FieldBlock(label: 'To', child: SelectBox(value: _quietTo, onTap: () => _pickTime(false)))),
              ],
            ),
          ],
        ],
      ),
      SideCard(
        title: 'Daily digest',
        children: [
          SegmentedTabs<String>(
            items: const [('off', 'Off'), ('daily', 'Daily'), ('weekly', 'Weekly')],
            value: _digest,
            onChanged: (v) => setState(() => _digest = v),
          ),
          FieldHint(_digest == 'off'
              ? 'No digest email.'
              : 'One email at 8:00 am with check-ins to review, at-risk clients and plans ending${_digest == 'weekly' ? ', every Monday.' : '.'}'),
        ],
      ),
    ];
  }

  Future<void> _pickTime(bool from) async {
    const opts = ['8:00 pm', '9:00 pm', '10:00 pm', '11:00 pm', '5:00 am', '6:00 am', '7:00 am', '8:00 am'];
    final v = await pickFromSheet<String>(context, title: from ? 'Quiet from' : 'Quiet until', items: [for (final o in opts) (o, o)], selected: from ? _quietFrom : _quietTo);
    if (v != null) setState(() => from ? _quietFrom = v : _quietTo = v);
  }

  // --- sender ----------------------------------------------------------------

  List<Widget> _senderTab() {
    return [
      AppCard(
        clip: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorHead(
              icon: Icons.badge_rounded,
              tint: Tint.blue,
              title: 'Sender identity',
              subtitle: 'Shown on every email and WhatsApp message to clients',
            ),
            const SizedBox(height: 14),
            FieldBlock(
              label: 'From name',
              required: true,
              hint: 'Your gym or coaching name',
              child: TextFormField(initialValue: EngageMock.gymName, style: AppText.body),
            ),
            const SizedBox(height: 12),
            FieldBlock(
              label: 'Reply-to email',
              hint: 'Client replies to emails land here',
              child: TextFormField(initialValue: EngageMock.gymEmail, style: AppText.body, keyboardType: TextInputType.emailAddress),
            ),
            const SizedBox(height: 12),
            FieldBlock(
              label: 'WhatsApp display number',
              hint: 'Shown in the WhatsApp chat header',
              child: TextFormField(initialValue: EngageMock.gymPhone, style: AppText.body, keyboardType: TextInputType.phone),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton('Save', small: true, icon: Icons.check_rounded, onPressed: () {
                showToast(context, 'Sender settings saved', subtitle: 'Used on every email and WhatsApp message', kind: ToastKind.ok);
              }),
            ),
          ],
        ),
      ),
      const SideCard(
        title: 'Clients see',
        children: [
          PhoneFrame(
            child: EmailPreview(
              subject: 'Weekly check-in time, Sana',
              body: 'It takes 2 minutes: your weight, measurements and how the week went.',
              line: 'reply to hello@trainwithvimal.com',
            ),
          ),
        ],
      ),
    ];
  }
}

class _ChannelTabs extends StatelessWidget {
  const _ChannelTabs({required this.value, required this.isOn, required this.onChanged});
  final Channel value;
  final bool Function(Channel) isOn;
  final ValueChanged<Channel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in Channel.values)
              InkWell(
                onTap: () => onChanged(c),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c == value ? AppColors.accent : Colors.transparent, width: 2))),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: isOn(c) ? const Color(0xFF10B981) : const Color(0xFFDADAD5), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(c.label,
                          style: AppText.secondary.copyWith(fontWeight: FontWeight.w600, color: c == value ? AppColors.accentText : AppColors.text2)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewTemplateSheet extends StatefulWidget {
  const _NewTemplateSheet({required this.onCreate});
  final void Function(String name, String group, List<Channel> channels) onCreate;

  @override
  State<_NewTemplateSheet> createState() => _NewTemplateSheetState();
}

class _NewTemplateSheetState extends State<_NewTemplateSheet> {
  final _name = TextEditingController(text: 'Workout streak');
  String _group = 'Coaching';
  final List<Channel> _chs = [Channel.push, Channel.whatsapp];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Spaced(
      gap: 14,
      children: [
        FieldBlock(label: 'Template name', required: true, child: TextField(controller: _name, style: AppText.body)),
        FieldBlock(
          label: 'Group',
          child: SegmentedTabs<String>(
            items: const [('Access', 'Access'), ('Coaching', 'Coaching'), ('Packages', 'Packages')],
            value: _group,
            onChanged: (v) => setState(() => _group = v),
          ),
        ),
        FieldBlock(
          label: 'Channels',
          hint: 'You can turn channels on or off later in the editor.',
          child: Spaced(
            gap: 6,
            children: [
              for (final c in Channel.values)
                OptionCard(
                  selected: _chs.contains(c),
                  square: true,
                  title: c.label,
                  subtitle: EngageMock.channelHint[c],
                  onTap: () => setState(() => _chs.contains(c) ? _chs.remove(c) : _chs.add(c)),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(
              child: Opacity(
                opacity: _chs.isEmpty ? .5 : 1,
                child: AppButton('Create template', icon: Icons.add_rounded, onPressed: () {
                  if (_chs.isEmpty) {
                    showToast(context, 'Pick a channel', subtitle: 'A template needs at least one', kind: ToastKind.warn);
                    return;
                  }
                  final ordered = Channel.values.where(_chs.contains).toList();
                  widget.onCreate(_name.text.trim().isEmpty ? 'Workout streak' : _name.text.trim(), _group, ordered);
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
