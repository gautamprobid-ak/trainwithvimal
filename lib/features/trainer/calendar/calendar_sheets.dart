import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';
import 'calendar_utils.dart';

enum SessionAction { profile, reschedule, toggleDone, cancel }

/// Session details (cal-det) — returns what the trainer tapped.
Future<SessionAction?> showSessionDetails(BuildContext context, CalSession s, int wo) {
  final k = s.kind.color;
  return showAppSheet<SessionAction>(
    context,
    title: s.client,
    subtitle: '${dayLabel(wo, s.day)} · ${fmtRange(s.start, s.minutes)}',
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: k.line, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(s.kind.label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: k.text)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppBadge(s.done ? 'Done' : 'Booked', tone: s.done ? BadgeTone.ok : BadgeTone.info),
            const Spacer(),
            LinkButton('Open profile', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.of(ctx).pop(SessionAction.profile)),
          ],
        ),
        const SizedBox(height: 6),
        KvGrid.text([
          ('Plan', TrainerMock.clientPlans[s.client] ?? 'No plan yet'),
          ('Length', '${s.minutes} min'),
          (s.onCall ? 'Where' : 'Place', s.onCall ? 'On a call' : s.place),
          ('Booked by', s.bookedBy),
        ], padding: EdgeInsets.zero),
        if (s.note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined, size: 17, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(s.note, style: AppText.body.copyWith(fontSize: 13, color: AppColors.text2))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton.outline('Reschedule', icon: Icons.schedule_rounded, onPressed: () => Navigator.of(ctx).pop(SessionAction.reschedule)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: s.done
                  ? AppButton.outline('Mark as not done', onPressed: () => Navigator.of(ctx).pop(SessionAction.toggleDone))
                  : AppButton('Mark as done', icon: Icons.check_rounded, onPressed: () => Navigator.of(ctx).pop(SessionAction.toggleDone)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: LinkButton('Cancel session', icon: Icons.close_rounded, color: AppColors.bad, onTap: () => Navigator.of(ctx).pop(SessionAction.cancel)),
        ),
      ],
    ),
  );
}

/// Result of the New / Move session form.
class SessionDraft {
  const SessionDraft({required this.kind, required this.client, required this.weekOffset, required this.day, required this.start, required this.place, required this.note});
  final CalKind kind;
  final String client;
  final int weekOffset;
  final int day;
  final int start;
  final String place;
  final String note;
}

/// New session / Move session drawer.
Future<SessionDraft?> showSessionForm(
  BuildContext context, {
  CalSession? moving,
  required List<CalSession> Function(int weekOffset) sessionsIn,
  required List<WorkDay> hours,
}) {
  return showModalBottomSheet<SessionDraft>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SessionForm(moving: moving, sessionsIn: sessionsIn, hours: hours),
  );
}

class _SessionForm extends StatefulWidget {
  const _SessionForm({required this.moving, required this.sessionsIn, required this.hours});
  final CalSession? moving;
  final List<CalSession> Function(int) sessionsIn;
  final List<WorkDay> hours;

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  late CalKind _kind = widget.moving?.kind ?? CalKind.session;
  late String _client = widget.moving?.client ?? 'Riya Sharma';
  int _wo = 0;
  late int _day = widget.moving?.day ?? 5;
  late int _hour = widget.moving != null ? widget.moving!.start ~/ 60 : 8;
  late int _min = widget.moving != null ? widget.moving!.start % 60 : 0;
  bool? _call;
  bool _tell = true;
  final _note = TextEditingController();

  bool get _move => widget.moving != null;
  int get _start => _hour * 60 + _min;
  bool get _onCall => _call ?? (_kind != CalKind.session);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  CalSession? get _clash => widget
      .sessionsIn(_wo)
      .where((s) =>
          s.trainer == TrainerMock.me && s.day == _day && s.id != widget.moving?.id && s.start < _start + _kind.minutes && s.end > _start)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final clash = _clash;
    final av = widget.hours[_day];
    final outside = !av.open || _start < av.from || _start + _kind.minutes > av.to;
    final m = widget.moving;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                TintIcon(_move ? Icons.schedule_rounded : Icons.event_rounded, tint: Tint.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_move ? 'Move session' : 'New session', style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(_move ? '${m!.client} · now ${dayLabel(0, m.day)} · ${fmtRange(m.start, m.minutes)}' : 'Book one of your clients',
                          style: AppText.secondary.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _who(),
                  _type(),
                  _when(clash, outside, av),
                  _where(),
                  _noteSection(),
                ],
              ),
            ),
          ),
          _footer(clash),
        ],
      ),
    );
  }

  Widget _who() => SheetSection(title: 'Who', children: [
        SelectField(
          label: 'Client *',
          value: _client,
          hint: 'Only clients given to you',
          onTap: () async {
            final v = await pickOption(context,
                title: 'Client',
                options: TrainerMock.bookableClients,
                current: _client,
                ends: {for (final e in TrainerMock.clientPlans.entries) e.key: e.value.split(' · ').first});
            if (v != null) setState(() => _client = v);
          },
        ),
      ]);

  Widget _type() => SheetSection(title: 'Type', children: [
        for (final k in CalKind.values)
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: k == _kind ? AppColors.accent : AppColors.line2, width: k == _kind ? 1.5 : 1),
            ),
            child: InkWell(
              onTap: () => setState(() {
                _kind = k;
                _call = null;
              }),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: k.color.line, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(k.label, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
                    Text('${k.minutes} min', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ]);

  Widget _when(CalSession? clash, bool outside, WorkDay av) {
    return SheetSection(title: 'When', children: [
      Row(
        children: [
          AppIconButton(Icons.chevron_left_rounded, small: true, tooltip: 'Week before', onPressed: () => setState(() => _wo--)),
          const SizedBox(width: 3),
          for (var i = 0; i < 7; i++) Expanded(child: _dayPick(i)),
          const SizedBox(width: 3),
          AppIconButton(Icons.chevron_right_rounded, small: true, tooltip: 'Week after', onPressed: () => setState(() => _wo++)),
        ],
      ),
      SelectField(
        label: 'Starts',
        value: fmtTime(_hour * 60),
        onTap: () async {
          final opts = [for (var h = 6; h < 22; h++) fmtTime(h * 60)];
          final v = await pickOption(context, title: 'Starts', options: opts, current: fmtTime(_hour * 60));
          if (v != null) setState(() => _hour = opts.indexOf(v) + 6);
        },
      ),
      SegmentedTabs<int>(
        items: [for (final m in [0, 15, 30, 45]) (m, ':${m.toString().padLeft(2, '0')}')],
        value: _min,
        onChanged: (v) => setState(() => _min = v),
      ),
      Text('Length ${_kind.minutes} min · ${fmtRange(_start, _kind.minutes)}', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
      if (clash != null)
        _notice(false, 'You already have ${clash.client} at ${fmtRange(clash.start, clash.minutes)}', 'Pick another time.')
      else if (outside)
        _notice(false, 'Outside your working hours (${av.open ? fmtRange(av.from, av.to - av.from) : 'day off'})', 'Pick another time.')
      else
        _notice(true, 'You are free at this time', null),
    ]);
  }

  Widget _dayPick(int i) {
    final on = i == _day;
    final past = _wo == 0 && i < TrainerMock.todayIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Opacity(
        opacity: past && !on ? .45 : 1,
        child: Material(
          color: on ? AppColors.accent : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: on ? AppColors.accent : AppColors.line)),
          child: InkWell(
            onTap: () => setState(() => _day = i),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(weekdayShort[i], style: AppText.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, color: on ? Colors.white70 : AppColors.muted)),
                  Text('${dayDate(_wo, i).day}', style: AppText.bodyBold.copyWith(fontSize: 14, color: on ? Colors.white : AppColors.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notice(bool ok, String title, String? sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: ok ? AppColors.okBg : AppColors.warnBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, size: 18, color: ok ? AppColors.okText : AppColors.warnText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyBold.copyWith(fontSize: 13, color: ok ? AppColors.okText : AppColors.warnText)),
                if (sub != null) Text(sub, style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _where() => SheetSection(title: 'Where', children: [
        PillTabs(labels: const ['In person', 'Call'], index: _onCall ? 1 : 0, onChanged: (i) => setState(() => _call = i == 1)),
        if (_onCall)
          const LabeledField(label: 'Call link or number', hint: 'meet.google.com/abc-defg-hij', help: 'Optional')
        else
          const LabeledField(label: 'Place', initialValue: 'Andheri gym floor', help: 'Where they meet'),
      ]);

  Widget _noteSection() => SheetSection(title: 'Note', children: [
        LabeledField(label: '', hint: 'e.g. Check the left shoulder first', help: 'Optional. Only you and Vimal see it.', controller: _note, maxLines: 3),
        ToggleRow(
          title: 'Tell the client',
          subtitle: 'Push notice and WhatsApp with the time and place',
          value: _tell,
          onChanged: (v) => setState(() => _tell = v),
        ),
      ]);

  Widget _footer(CalSession? clash) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${dayLabel(_wo, _day)} · ${fmtRange(_start, _kind.minutes)}', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  _move ? 'Move session' : 'Create session',
                  icon: Icons.check_rounded,
                  onPressed: clash != null
                      ? null
                      : () => Navigator.of(context).pop(SessionDraft(
                            kind: _kind,
                            client: _client,
                            weekOffset: _wo,
                            day: _day,
                            start: _start,
                            place: _onCall ? '' : 'Andheri gym floor',
                            note: _note.text,
                          )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "My working hours" drawer. Returns the new hours on Save.
Future<List<WorkDay>?> showWorkingHours(BuildContext context, List<WorkDay> current) {
  return showModalBottomSheet<List<WorkDay>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _HoursSheet(initial: current),
  );
}

class _HoursSheet extends StatefulWidget {
  const _HoursSheet({required this.initial});
  final List<WorkDay> initial;
  @override
  State<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<_HoursSheet> {
  late final List<WorkDay> _d = [...widget.initial];

  Future<void> _pickTime(int i, bool from) async {
    final opts = [for (var m = 360; m <= 1320; m += 30) fmtTime(m)];
    final d = _d[i];
    final v = await pickOption(context, title: from ? 'From' : 'To', options: opts, current: fmtTime(from ? d.from : d.to));
    if (v == null) return;
    final m = 360 + opts.indexOf(v) * 30;
    setState(() => _d[i] = from ? WorkDay(true, m, d.to) : WorkDay(true, d.from, m));
  }

  @override
  Widget build(BuildContext context) {
    final n = _d.where((d) => d.open).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const TintIcon(Icons.schedule_rounded, tint: Tint.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My working hours', style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Vimal sees them when he books for you', style: AppText.secondary.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SheetSection(
              title: 'Working hours, week after week',
              help: '$n working days. The calendar shades the rest, and a session outside them shows a warning.',
              children: [for (var i = 0; i < 7; i++) _row(i)],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Booked sessions stay as they are', style: AppText.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
                  const SizedBox(width: 10),
                  Expanded(child: AppButton('Save availability', icon: Icons.check_rounded, onPressed: () => Navigator.of(context).pop(_d))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(int i) {
    final d = _d[i];
    return Row(
      children: [
        SizedBox(width: 84, child: Text(weekdayLong[i], style: AppText.bodyBold.copyWith(fontSize: 13.5, color: d.open ? AppColors.text : AppColors.muted))),
        GestureDetector(
          onTap: () => setState(() => _d[i] = d.open ? const WorkDay.off() : const WorkDay(true, 420, 1260)),
          child: MiniToggle(d.open),
        ),
        const SizedBox(width: 10),
        if (d.open) ...[
          Expanded(child: SelectField(label: '', value: fmtTime(d.from), onTap: () => _pickTime(i, true))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('to', style: AppText.caption)),
          Expanded(child: SelectField(label: '', value: fmtTime(d.to), onTap: () => _pickTime(i, false))),
        ] else
          Text('Day off', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
