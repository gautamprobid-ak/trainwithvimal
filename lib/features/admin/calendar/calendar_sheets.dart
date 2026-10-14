import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';

import '../clients/admin_ui.dart';
import 'cal_format.dart';

// --------------------------------------------------------- Session detail

void showSessionSheet(
  BuildContext context, {
  required CalSession session,
  required String when,
  required VoidCallback onOpenProfile,
  required VoidCallback onToggleDone,
  required VoidCallback onReschedule,
  required VoidCallback onCancel,
}) {
  final s = session;
  final k = s.kind.color;
  showAppSheet(
    context,
    title: s.client,
    subtitle: when,
    builder: (ctx) => Spaced(
      gap: 14,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(6)),
              child: Text(s.kind.label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: k.text)),
            ),
            const SizedBox(width: 8),
            AppBadge(s.done ? 'Done' : 'Booked', tone: s.done ? BadgeTone.ok : BadgeTone.info),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                onOpenProfile();
              },
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Open profile'),
            ),
          ],
        ),
        KvGrid(KvGrid.text([
          ('Trainer', s.trainer),
          ('Length', '${s.minutes} min'),
          (s.place.isEmpty ? 'Where' : 'Place', s.place.isEmpty ? 'On a call' : s.place),
          ('Booked by', s.bookedBy),
        ])),
        if (s.note.isNotEmpty) InfoBanner(text: s.note, icon: Icons.sticky_note_2_outlined, bg: AppColors.sub, fg: AppColors.text2),
        AppButton.ghost('Cancel session', icon: Icons.event_busy_rounded, onPressed: () async {
          final ok = await showConfirmDialog(
            ctx,
            title: 'Cancel this session?',
            message: '${s.client}, $when. It is removed from the calendar.\n\nThe client is told by push notice and WhatsApp.',
            confirmLabel: 'Cancel session',
            destructive: true,
            icon: Icons.event_busy_rounded,
          );
          if (!ok || !ctx.mounted) return;
          Navigator.of(ctx).pop();
          onCancel();
        }),
      ],
    ),
    actions: (ctx) => [
      AppButton.outline('Reschedule', icon: Icons.schedule_rounded, onPressed: () {
        Navigator.of(ctx).pop();
        onReschedule();
      }),
      s.done
          ? AppButton.outline('Mark as not done', onPressed: () {
              Navigator.of(ctx).pop();
              onToggleDone();
            })
          : AppButton('Mark as done', icon: Icons.check_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              onToggleDone();
            }),
    ],
  );
}

// ------------------------------------------------------ New / move session

class SessionFormResult {
  const SessionFormResult(this.week, this.day, this.start, this.kind, this.client, this.trainer, this.place);
  final int week;
  final int day;
  final int start;
  final SessionKind kind;
  final String client;
  final String trainer;
  final String place;
}

void showSessionForm(
  BuildContext context, {
  CalSession? move,
  String? moveWhen,
  required List<CalSession> Function(int week) sessionsIn,
  required List<DayHours> Function(String trainer) hoursOf,
  required ValueChanged<SessionFormResult> onSave,
}) {
  showFormSheet(
    context,
    title: move != null ? 'Move session' : 'New session',
    subtitle: move != null ? '${move.client} · now $moveWhen' : 'Book a client with a trainer',
    builder: (_) => _SessionForm(move: move, sessionsIn: sessionsIn, hoursOf: hoursOf, onSave: onSave),
  );
}

class _SessionForm extends StatefulWidget {
  const _SessionForm({this.move, required this.sessionsIn, required this.hoursOf, required this.onSave});
  final CalSession? move;
  final List<CalSession> Function(int week) sessionsIn;
  final List<DayHours> Function(String trainer) hoursOf;
  final ValueChanged<SessionFormResult> onSave;

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  late SessionKind _kind = widget.move?.kind ?? SessionKind.session;
  late String _client = widget.move?.client ?? 'Riya Sharma';
  late String _trainer = widget.move?.trainer ?? AdminMock.clientTrainer[_client]!;
  int _week = 0;
  late int _day = widget.move?.day ?? 5;
  late int _hour = widget.move == null ? 8 : widget.move!.start ~/ 60;
  late int _min = widget.move == null ? 0 : widget.move!.start % 60;
  bool? _inPerson;

  bool get _person => _inPerson ?? _kind == SessionKind.session;

  @override
  Widget build(BuildContext context) {
    final start = _hour * 60 + _min;
    final len = _kind.minutes;
    final clash = widget
        .sessionsIn(_week)
        .where((s) => s.trainer == _trainer && s.day == _day && s.id != widget.move?.id && s.start < start + len && s.end > start)
        .firstOrNull;
    final av = widget.hoursOf(_trainer)[_day];
    final outside = !av.open || start < av.from || start + len > av.to;
    final first = _trainer.split(' ').first;
    final clients = AdminMock.clientTrainer.keys.toList()
      ..sort((a, b) => (AdminMock.clientTrainer[b] == _trainer ? 1 : 0) - (AdminMock.clientTrainer[a] == _trainer ? 1 : 0));

    final String? warn = clash != null
        ? '$first already has ${clash.client} at ${fmtRange(clash.start, clash.minutes)}'
        : outside
            ? 'Outside $first’s working hours (${av.open ? fmtRange(av.from, av.to - av.from) : 'day off'})'
            : null;

    return SheetBody(
      note: '${fmtDayShort(_week, _day)} · ${fmtRange(start, len)}',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton(
          widget.move != null ? 'Move session' : 'Create session',
          icon: Icons.check_rounded,
          onPressed: clash != null
              ? null
              : () {
                  widget.onSave(SessionFormResult(_week, _day, start, _kind, _client, _trainer, _person ? 'Andheri gym floor' : ''));
                  Navigator.of(context).pop();
                },
        ),
      ],
      children: [
        SheetSection(title: 'Who', children: [
          PickerField(
            label: 'Client *',
            value: _client,
            hint: 'Shows clients of the picked trainer first',
            options: clients,
            trailingOf: (c) => AdminMock.clientTrainer[c] == _trainer ? 'Their client' : '',
            onChanged: (v) => setState(() {
              _client = v;
              _trainer = AdminMock.clientTrainer[v]!;
            }),
          ),
          PickerField(
            label: 'Trainer *',
            value: _trainer,
            hint: 'Their trainer is picked for you',
            options: AdminMock.calTrainers,
            trailingOf: (t) => t == AdminMock.clientTrainer[_client] ? 'Their trainer' : '',
            onChanged: (v) => setState(() => _trainer = v),
          ),
        ]),
        SheetSection(title: 'Type', children: [
          Row(
            children: [
              for (final k in SessionKind.values) ...[
                if (k != SessionKind.values.first) const SizedBox(width: 8),
                Expanded(child: _kindTile(k)),
              ],
            ],
          ),
        ]),
        SheetSection(title: 'When', children: [
          _weekStrip(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PickerField(
                      label: 'Starts',
                      value: fmtTime(_hour * 60),
                      options: [for (var h = 6; h < 22; h++) fmtTime(h * 60)],
                      onChanged: (v) => setState(() => _hour = [for (var h = 6; h < 22; h++) h][[for (var h = 6; h < 22; h++) fmtTime(h * 60)].indexOf(v)]),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final m in const [0, 15, 30, 45])
                          ChoicePill(':${m.toString().padLeft(2, '0')}', selected: m == _min, accent: true, onTap: () => setState(() => _min = m)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Length'),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(AppRadius.button)),
                      child: Text('$len min', style: AppText.body),
                    ),
                    const SizedBox(height: 5),
                    Text(fmtRange(start, len), style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          if (warn != null)
            InfoBanner(text: '$warn\nPick another time or another trainer.', icon: Icons.warning_amber_rounded, bg: AppColors.warnBg, fg: AppColors.warnText)
          else
            InfoBanner(text: '$first is free at this time', icon: Icons.check_circle_outline_rounded, bg: AppColors.okBg, fg: AppColors.okText),
        ]),
        SheetSection(title: 'Where', children: [
          SegmentedTabs<bool>(items: const [(true, 'In person'), (false, 'Call')], value: _person, onChanged: (v) => setState(() => _inPerson = v)),
          if (_person)
            const LabeledField(label: 'Place', initialValue: 'Andheri gym floor', help: 'Where they meet')
          else
            const LabeledField(label: 'Call link or number', hint: 'meet.google.com/abc-defg-hij', help: 'Optional'),
        ]),
        const SheetSection(title: 'Note', children: [
          LabeledField(label: 'Note', hint: 'e.g. Check the left shoulder first', help: 'Optional. The trainer sees it on the session.', maxLines: 2),
          SwitchRow(title: 'Tell the client', subtitle: 'Push notice and WhatsApp with the time and place', initial: true),
        ]),
      ],
    );
  }

  Widget _kindTile(SessionKind k) {
    final on = k == _kind;
    return GestureDetector(
      onTap: () => setState(() {
        _kind = k;
        _inPerson = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: on ? k.color.bg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? k.color.line : AppColors.line, width: on ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: k.color.line, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 6),
            Text(k.label, style: AppText.bodyBold.copyWith(fontSize: 12.5)),
            Text('${k.minutes} min', style: AppText.caption.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _weekStrip() {
    return Row(
      children: [
        AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Week before', onPressed: () => setState(() => _week--)),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _day = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(color: i == _day ? AppColors.text : null, borderRadius: BorderRadius.circular(8)),
                child: Opacity(
                  opacity: _week == 0 && i < 4 && i != _day ? .45 : 1,
                  child: Column(
                    children: [
                      Text(calWd[i], style: AppText.caption.copyWith(fontSize: 10, color: i == _day ? Colors.white70 : AppColors.muted)),
                      Text('${calDay(_week, i).day}', style: AppText.bodyBold.copyWith(fontSize: 13, color: i == _day ? Colors.white : AppColors.text)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Week after', onPressed: () => setState(() => _week++)),
      ],
    );
  }
}

// ----------------------------------------------------------- Availability

void showAvailabilitySheet(
  BuildContext context, {
  required List<DayHours> Function(String trainer) hoursOf,
  required void Function(String trainer, List<DayHours> hours) onSave,
}) {
  showFormSheet(
    context,
    title: 'Availability',
    subtitle: 'Working hours of each trainer',
    builder: (_) => _AvailabilityBody(hoursOf: hoursOf, onSave: onSave),
  );
}

class _AvailabilityBody extends StatefulWidget {
  const _AvailabilityBody({required this.hoursOf, required this.onSave});
  final List<DayHours> Function(String trainer) hoursOf;
  final void Function(String trainer, List<DayHours> hours) onSave;

  @override
  State<_AvailabilityBody> createState() => _AvailabilityBodyState();
}

class _AvailabilityBodyState extends State<_AvailabilityBody> {
  String _trainer = 'Aman Verma';
  final _edits = <String, List<DayHours>>{};

  List<DayHours> get _h => _edits[_trainer] ?? widget.hoursOf(_trainer);

  static final _times = [for (var m = 6 * 60; m <= 22 * 60; m += 30) m];

  void _set(int i, DayHours d) => setState(() => _edits[_trainer] = [for (var j = 0; j < 7; j++) j == i ? d : _h[j]]);

  @override
  Widget build(BuildContext context) {
    final h = _h;
    return SheetBody(
      note: 'Booked sessions stay as they are',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Save availability', icon: Icons.check_rounded, onPressed: () {
          for (final e in _edits.entries) {
            widget.onSave(e.key, e.value);
          }
          if (_edits.isEmpty) widget.onSave(_trainer, h);
          Navigator.of(context).pop();
        }),
      ],
      children: [
        SheetSection(
          title: 'Trainer',
          subtitle: 'Working hours repeat every week. The calendar shades the rest, and a session outside them shows a warning.',
          children: [PickerField(value: _trainer, options: AdminMock.calTrainers, onChanged: (v) => setState(() => _trainer = v))],
        ),
        SheetSection(
          title: 'Working hours, week after week',
          subtitle: '${h.where((d) => d.open).length} working days',
          children: [
            for (var i = 0; i < 7; i++)
              Row(
                children: [
                  SizedBox(width: 82, child: Text(calWdLong[i], style: AppText.bodyBold.copyWith(fontSize: 13))),
                  GestureDetector(
                    onTap: () => _set(i, h[i].open ? const DayHours(false, 0, 0) : const DayHours(true, 420, 1260)),
                    child: MiniToggle(h[i].open),
                  ),
                  const SizedBox(width: 10),
                  if (h[i].open) ...[
                    Expanded(child: _timePick(h[i].from, (v) => _set(i, DayHours(true, v, h[i].to)))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('to', style: AppText.caption)),
                    Expanded(child: _timePick(h[i].to, (v) => _set(i, DayHours(true, h[i].from, v)))),
                  ] else
                    Expanded(child: Text('Day off', style: AppText.secondary)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _timePick(int value, ValueChanged<int> onChanged) {
    final labels = [for (final m in _times) fmtTime(m)];
    return PickerField(
      value: fmtTime(value),
      options: labels,
      onChanged: (v) => onChanged(_times[labels.indexOf(v)]),
    );
  }
}
