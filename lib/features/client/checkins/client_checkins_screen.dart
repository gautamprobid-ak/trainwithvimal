import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../more/client_ui.dart';
import 'checkin_widgets.dart';

/// Design: ClientCheckin.dc.html — check-ins list, daily check-in and the
/// 6-question weekly check-in (week 7).
class ClientCheckinsScreen extends StatefulWidget {
  const ClientCheckinsScreen({super.key});

  @override
  State<ClientCheckinsScreen> createState() => _ClientCheckinsScreenState();
}

enum _View { list, daily, weekly }

class _ClientCheckinsScreenState extends State<ClientCheckinsScreen> {
  static const _face = ClientMock.faces, _hun = ClientMock.hunger, _sore = ClientMock.soreness, _sleep = ClientMock.sleepOptions;

  _View _v = _View.list;
  bool _weeklyTab = true;

  // daily
  double _dw = 71.4;
  int? _dsl, _de, _dm, _dh, _ds;
  final _dNote = TextEditingController();
  String? _dSentAt;
  bool _dEdit = false;

  // weekly
  double _ww = 71.6;
  int? _wk, _mp, _kn;
  List<bool> _ph = [false, false, false];
  bool _noPh = false;
  final _wText = TextEditingController();
  int _step = 0;
  bool _wSent = false;
  bool _wTouched = false;

  @override
  void dispose() {
    _dNote.dispose();
    _wText.dispose();
    super.dispose();
  }

  String _kg(double x) => '${x.toStringAsFixed(1)} kg';
  String _chg(double x) {
    final d = ((x - 71.6) * 10).round() / 10;
    return d == 0 ? 'No change' : '${d < 0 ? '−' : '+'}${d.abs().toStringAsFixed(1)} kg';
  }

  void _go(_View v) => setState(() => _v = v);

  // ------------------------------------------------------------ daily

  int get _dAnswered => [_dsl, _de, _dm, _dh, _ds].where((x) => x != null).length + 1;

  List<String> get _dMissing => [
        if (_dsl == null) 'sleep',
        if (_de == null) 'energy',
        if (_dm == null) 'mood',
        if (_dh == null) 'hunger',
        if (_ds == null) 'soreness',
      ];

  void _sendDaily() {
    if (_dMissing.isNotEmpty) {
      showToast(context, 'Answer ${_dMissing.join(', ')} first', subtitle: 'Only the note is optional', kind: ToastKind.warn);
      return;
    }
    final prevAt = _dSentAt, prevEdit = _dEdit;
    final wasEdit = _dEdit;
    setState(() {
      _dSentAt = '5:40 pm';
      _dEdit = false;
    });
    showToast(context, wasEdit ? 'Daily check-in updated' : 'Daily check-in sent',
        subtitle: 'Aman will see it today · 3-day streak',
        kind: ToastKind.ok,
        onUndo: () => setState(() {
              _dSentAt = prevAt;
              _dEdit = prevEdit;
            }));
  }

  List<(String, String)> get _dSummary => [
        ('Morning weight', _kg(_dw)),
        ('Sleep', _dsl == null ? '—' : _sleep[_dsl!]),
        ('Energy', _de == null ? '—' : _face[_de!]),
        ('Mood', _dm == null ? '—' : _face[_dm!]),
        ('Hunger', _dh == null ? '—' : _hun[_dh!]),
        ('Soreness', _ds == null ? '—' : _sore[_ds!]),
        ('Note', _dNote.text.isEmpty ? '—' : _dNote.text),
      ];

  // ------------------------------------------------------------ weekly

  static const _qs = [
    ('num', 'Body weight (kg)', 'Weigh in the morning, before you eat.', true, null),
    ('scale', 'How was your week?', '1 is very hard, 5 is great.', true, null),
    ('choice', 'Did you follow the meal plan?', 'Be honest, it helps Aman plan your food.', true, null),
    ('scale', 'How does your right knee feel?', '1 is very sore, 5 is no pain at all.', true, 'Added for you by Aman'),
    ('photo', 'Progress photos this week?', 'Front, side and back. Tap a slot to add a photo.', false, null),
    ('text', 'Anything your coach should know?', 'Optional. Travel, injuries, stress, questions.', false, null),
  ];
  static const _angles = ['Front', 'Side', 'Back'];

  int get _nPh => _ph.where((x) => x).length;

  String? _answer(int q) => switch (q) {
        0 => _kg(_ww) + (_ww < 71.6 ? ' (−${(71.6 - _ww).toStringAsFixed(1)} kg)' : ''),
        1 => _wk == null ? null : '${_wk! + 1} / 5 · ${ClientMock.weekScale[_wk!]}',
        2 => _mp == null ? null : ClientMock.mealPlanOptions[_mp!],
        3 => _kn == null ? null : '${_kn! + 1} / 5 · ${ClientMock.kneeScale[_kn!]}',
        4 => _noPh
            ? 'No photos this week'
            : _nPh > 0
                ? '$_nPh of 3 photos${_nPh == 3 ? '' : ' (${[for (var i = 0; i < 3; i++) if (!_ph[i]) _angles[i]].join(', ').toLowerCase()} missing)'}'
                : null,
        _ => _wText.text.isEmpty ? null : _wText.text,
      };

  int get _wDone => [for (var i = 0; i < 6; i++) if (_answer(i) != null) i].length;

  void _touch(VoidCallback f) => setState(() {
        f();
        _wTouched = true;
      });

  void _exitWeekly() {
    final done = _wDone;
    _go(_View.list);
    if (!_wSent && done > 0 && _wTouched) {
      showToast(context, 'Draft saved', subtitle: '$done of 6 answered · finish by Sun, 6:00 pm', kind: ToastKind.info);
    }
  }

  void _next() {
    if (_step == _qs.length) {
      final missing = [for (var i = 0; i < 6; i++) if (_qs[i].$4 && _answer(i) == null) i];
      if (missing.isNotEmpty) {
        showToast(context, 'Answer “${_qs[missing.first].$2}” first', subtitle: 'Questions 1 to 4 are required', kind: ToastKind.warn);
        return;
      }
      setState(() => _wSent = true);
      showToast(context, 'Week 7 check-in sent', subtitle: 'Aman usually replies within a day', kind: ToastKind.star, onUndo: () => setState(() => _wSent = false));
      return;
    }
    if (_qs[_step].$4 && _answer(_step) == null) {
      showToast(context, 'Pick an answer to continue', subtitle: 'This question is required', kind: ToastKind.warn);
      return;
    }
    setState(() => _step++);
  }

  // ------------------------------------------------------------ list data

  List<WeeklyCheckin> get _weeklyList => [
        if (_wSent)
          WeeklyCheckin(
            title: 'Week 7',
            date: 'Fri, 9 Oct, 5:40 pm',
            summary: 'Fri, 9 Oct · ${_kg(_ww)} · ${_noPh || _nPh == 0 ? 'no photos' : '$_nPh photos'}',
            pill: 'Sent',
            waiting: true,
            mine: true,
            photoDate: '9 Oct',
            kpis: [(_kg(_ww), 'Weight'), (_chg(_ww), 'Change'), ('4 / 4', 'Workouts'), ('—', 'Meals on plan')],
            answers: [for (var i = 0; i < 6; i++) (_qs[i].$2, _answer(i) ?? 'Skipped')],
          ),
        ...ClientMock.weeklyCheckins,
      ];

  List<DailyCheckin> get _dailyList => [
        if (_dSentAt != null)
          DailyCheckin(
            title: 'Fri, 9 Oct · today',
            summary: '${_sleep[_dsl!]} sleep · energy ${_face[_de!]}${_dNote.text.isNotEmpty ? ' · “${_dNote.text}”' : ''}',
            at: _dSentAt,
            today: true,
            answers: [_sleep[_dsl!], _face[_de!], _face[_dm!], _hun[_dh!], _sore[_ds!], '6,240', '1.5 L', _kg(_dw), _dNote.text.isEmpty ? '—' : _dNote.text],
          ),
        ...ClientMock.dailyCheckins,
      ];

  void _openPast(bool weekly, int i) {
    var idx = i;
    var angle = 0;
    showClientSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final len = weekly ? _weeklyList.length : _dailyList.length;
        void step(int d) {
          final j = idx + d;
          if (j < 0 || j >= len) {
            showToast(context, d < 0 ? 'This is the newest one' : 'No older check-ins here', kind: ToastKind.info);
            return;
          }
          setS(() {
            idx = j;
            angle = 0;
          });
        }

        final nav = [
          AppButton.outline('Newer', icon: Icons.chevron_left_rounded, onPressed: () => step(-1)),
          AppButton.outline('Older', icon: Icons.chevron_right_rounded, onPressed: () => step(1)),
        ];
        if (weekly) {
          final r = _weeklyList[idx];
          return ClientSheet(
            title: '${r.title} check-in',
            subtitle: r.missed ? '${r.date} · not sent' : 'Sent ${r.date}',
            body: WeeklyDetail(
              item: r,
              angle: angle,
              onAngle: (a) => setS(() => angle = a),
              showPhotos: !r.missed && !(r.mine && _nPh == 0),
            ),
            actions: nav,
          );
        }
        final r = _dailyList[idx];
        return ClientSheet(
          title: '${r.title.replaceAll(' · today', '')} · daily check-in',
          subtitle: r.missed ? 'Not sent' : 'Sent at ${r.at}',
          body: DailyDetail(item: r),
          actions: nav,
        );
      }),
    );
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _v == _View.list,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _v == _View.weekly ? _exitWeekly() : _go(_View.list);
      },
      child: PageScroll(
        children: switch (_v) {
          _View.list => _listView(),
          _View.daily => _dailyView(),
          _View.weekly => _weeklyView(),
        },
      ),
    );
  }

  List<Widget> _listView() {
    final wDraft = !_wSent && _wDone > 0 && _wTouched;
    final rowsW = _weeklyList;
    final rowsD = _dailyList;
    return [
      ClientTop(
        title: 'Check-ins',
        subtitle: 'Aman reads every one · Fat Loss Phase 1, week 6 of 12',
        onBack: () => context.canPop() ? context.pop() : context.go(Routes.cMore),
      ),
      AppCard(child: StatCells([(_dSentAt != null ? '3 days' : '2 days', 'Daily streak'), ('5 of 6', 'Weekly on time'), ('−0.7 kg', 'Last weekly change')])),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHead(
              icon: Icons.wb_sunny_rounded,
              tint: Tint.blue,
              title: 'Daily check-in',
              subtitle: _dSentAt != null ? 'Today · sent at $_dSentAt' : 'Today, Fri 9 Oct · 30 seconds',
              trailing: Pill(_dSentAt != null ? 'Sent' : 'Due today', tone: _dSentAt != null ? PillTone.green : PillTone.blue),
            ),
            const SizedBox(height: 10),
            if (_dSentAt == null) ...[
              const Caption('Weight, sleep, energy, mood, hunger and soreness. Takes about 30 seconds.'),
              const SizedBox(height: 10),
              AppButton('Start daily check-in', icon: Icons.play_arrow_rounded, onPressed: () => setState(() {
                    _dEdit = false;
                    _v = _View.daily;
                  })),
            ] else ...[
              DoneStrip('Sent at $_dSentAt · ${_sleep[_dsl!]} sleep, energy ${_face[_de!]}'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: AppButton.outline('View', small: true, icon: Icons.visibility_rounded, onPressed: () => setState(() {
                      _dEdit = false;
                      _v = _View.daily;
                    }))),
                const SizedBox(width: 8),
                Expanded(child: AppButton.outline('Edit answers', small: true, icon: Icons.edit_rounded, onPressed: () => setState(() {
                      _dEdit = true;
                      _v = _View.daily;
                    }))),
              ]),
            ],
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHead(
              icon: Icons.assignment_rounded,
              tint: Tint.amber,
              title: 'Weekly check-in · week 7',
              subtitle: _wSent ? 'Sent today, 5:40 pm · waiting for Aman' : 'Due Sun, 11 Oct, 6:00 pm · you can fill it in early',
              trailing: Pill(_wSent ? 'Sent' : 'Due Sun', tone: _wSent ? PillTone.green : PillTone.amber),
            ),
            const SizedBox(height: 10),
            if (!_wSent) ...[
              Wrap(spacing: 6, runSpacing: 6, children: [for (final q in ClientMock.weeklyQuestionChips) AppChip(q)]),
              if (wDraft) ...[
                const SizedBox(height: 10),
                ProgressBar(_wDone / 6),
                const SizedBox(height: 4),
                Text('Draft · $_wDone of 6 answered', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 10),
              wDraft
                  ? AppButton('Continue check-in', icon: Icons.arrow_forward_rounded, onPressed: () => _go(_View.weekly))
                  : AppButton.dark('Start weekly check-in', icon: Icons.arrow_forward_rounded, onPressed: () => _go(_View.weekly)),
            ] else ...[
              DoneStrip('Week 7 sent · ${_kg(_ww)} · ${_nPh > 0 ? '$_nPh photos' : 'no photos'}'),
              const SizedBox(height: 10),
              AppButton.outline('View what you sent', small: true, icon: Icons.visibility_rounded, onPressed: () {
                setState(() => _weeklyTab = true);
                _openPast(true, 0);
              }),
            ],
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Past check-ins', style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800))),
                SegmentedTabs<bool>(
                  expand: false,
                  items: const [(true, 'Weekly'), (false, 'Daily')],
                  value: _weeklyTab,
                  onChanged: (v) => setState(() => _weeklyTab = v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_weeklyTab)
              for (var i = 0; i < rowsW.length; i++)
                PastRow(
                  title: rowsW[i].title,
                  subtitle: rowsW[i].summary,
                  state: rowsW[i].missed ? PastState.missed : rowsW[i].waiting ? PastState.waiting : PastState.ok,
                  pill: rowsW[i].pill,
                  tone: switch (rowsW[i].pill) { 'Sent' => PillTone.blue, 'Missed' => PillTone.red, _ => PillTone.green },
                  reply: rowsW[i].reply,
                  onTap: () => _openPast(true, i),
                )
            else
              for (var i = 0; i < rowsD.length; i++)
                PastRow(
                  title: rowsD[i].title,
                  subtitle: rowsD[i].summary,
                  state: rowsD[i].missed ? PastState.missed : PastState.ok,
                  pill: rowsD[i].missed ? 'Missed' : rowsD[i].reply != null ? 'Replied' : 'Sent',
                  tone: rowsD[i].missed ? PillTone.red : rowsD[i].reply != null ? PillTone.green : PillTone.gray,
                  reply: rowsD[i].reply,
                  onTap: () => _openPast(false, i),
                ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _dailyView() {
    final form = _dSentAt == null || _dEdit;
    return [
      ClientTop(title: 'Daily check-in', subtitle: 'Fri, 9 Oct · $_dAnswered of 6 answered', onBack: () => _go(_View.list)),
      ProgressBar(_dAnswered / 6),
      if (form) ...[
        QuestionCard(
          title: 'Morning weight',
          label: '${_dw < 71.5 ? '−${(71.5 - _dw).toStringAsFixed(1)}' : _dw > 71.5 ? '+${(_dw - 71.5).toStringAsFixed(1)}' : '±0.0'} kg since Thu',
          child: Center(
            child: QtyStepper(
              large: true,
              value: _kg(_dw),
              onMinus: () => setState(() => _dw = ((_dw - .1) * 10).round() / 10),
              onPlus: () => setState(() => _dw = ((_dw + .1) * 10).round() / 10),
            ),
          ),
        ),
        QuestionCard(
          title: 'Sleep last night',
          label: _dsl == null ? 'Pick one' : _sleep[_dsl!],
          need: _dsl == null,
          child: ScaleButtons(labels: _sleep, selected: _dsl, numbered: false, onPick: (i) => setState(() => _dsl = i)),
        ),
        for (final (t, l, v, set) in [
          ('Energy', _face, _de, (int i) => _de = i),
          ('Mood', _face, _dm, (int i) => _dm = i),
          ('Hunger', _hun, _dh, (int i) => _dh = i),
          ('Soreness', _sore, _ds, (int i) => _ds = i),
        ])
          QuestionCard(
            title: t,
            label: v == null ? 'Pick one' : l[v],
            need: v == null,
            child: ScaleButtons(labels: l, selected: v, onPick: (i) => setState(() => set(i))),
          ),
        QuestionCard(
          title: 'Anything else?',
          label: 'Optional',
          child: NoteField(
            controller: _dNote,
            hint: 'Type a note for Aman, or tap a suggestion',
            chips: ClientMock.dailyNoteChips,
            onChanged: () => setState(() {}),
          ),
        ),
        const InfoBanner(
          icon: Icons.bolt_rounded,
          bg: AppColors.sub,
          fg: AppColors.text2,
          text: 'Steps (6,240) and water (1.5 L) come from your habits, so you do not need to add them.',
        ),
        Opacity(
          opacity: _dMissing.isEmpty ? 1 : .55,
          child: AppButton('Send to Aman', icon: Icons.send_rounded, expand: true, onPressed: _sendDaily),
        ),
      ] else
        SentCard(
          title: 'Sent to Aman',
          subtitle: 'Today at $_dSentAt · Aman will see it today',
          rows: _dSummary,
          actions: [
            AppButton.outline('Edit answers', icon: Icons.edit_rounded, onPressed: () => setState(() => _dEdit = true)),
            AppButton('Back to check-ins', onPressed: () => _go(_View.list)),
          ],
        ),
    ];
  }

  List<Widget> _weeklyView() {
    final n = _qs.length;
    final review = _step == n;
    final cur = review ? null : _qs[_step];
    final reqMissing = cur != null && cur.$4 && _answer(_step) == null;
    final nextL = review ? 'Send to Aman' : _step == n - 1 ? 'Review' : cur != null && !cur.$4 && _answer(_step) == null ? 'Skip' : 'Next';
    return [
      ClientTop(title: 'Weekly check-in', subtitle: 'Week 7 · due Sun, 11 Oct, 6:00 pm', onBack: _exitWeekly),
      if (!_wSent) ...[
        Text(review ? 'Review · all $n questions' : 'Question ${_step + 1} of $n', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
        ProgressBar((_step + 1).clamp(1, n) / n),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: review ? _reviewBody() : _questionBody(_step),
          ),
        ),
        Row(
          children: [
            Expanded(child: AppButton.outline('Back', icon: Icons.chevron_left_rounded, onPressed: _step == 0 ? null : () => setState(() => _step--))),
            const SizedBox(width: 10),
            Expanded(
              child: Opacity(
                opacity: reqMissing ? .55 : 1,
                child: AppButton(nextL, icon: review ? Icons.send_rounded : Icons.chevron_right_rounded, onPressed: _next),
              ),
            ),
          ],
        ),
      ] else
        SentCard(
          title: 'Week 7 check-in sent',
          subtitle: 'Fri, 9 Oct, 5:40 pm · Aman usually replies within a day',
          rows: [
            ('Weight', _kg(_ww)),
            ('Change', _chg(_ww)),
            ('Your week', _answer(1) ?? '—'),
            ('Knee', _answer(3) ?? '—'),
            ('Photos', _answer(4) ?? 'Skipped'),
          ],
          actions: [AppButton('Back to check-ins', onPressed: () => _go(_View.list))],
        ),
    ];
  }

  List<Widget> _questionBody(int s) {
    final q = _qs[s];
    final head = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${s + 1}. ${q.$2}', style: AppText.bodyBold.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
          if (q.$5 != null) Tag(q.$5!),
        ],
      ),
      const SizedBox(height: 2),
      Text(q.$3, style: AppText.secondary),
      const SizedBox(height: 14),
    ];
    switch (q.$1) {
      case 'num':
        final d = ((_ww - 71.6) * 10).round() / 10;
        return [
          ...head,
          Center(
            child: QtyStepper(
              large: true,
              value: _kg(_ww),
              onMinus: () => _touch(() => _ww = ((_ww - .1) * 10).round() / 10),
              onPlus: () => _touch(() => _ww = ((_ww + .1) * 10).round() / 10),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d == 0 ? 'Same as last week' : '${d < 0 ? '−' : '+'}${d.abs().toStringAsFixed(1)} kg since last week',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: d < 0 ? AppColors.okText : d > 0 ? AppColors.warnText : AppColors.muted),
          ),
          const SizedBox(height: 12),
          TryRow(label: 'Quick', chips: [
            TryChip('This morning, 71.4', onTap: () => _touch(() => _ww = 71.4)),
            TryChip('Last week, 71.6', onTap: () => _touch(() => _ww = 71.6)),
          ]),
        ];
      case 'scale':
        final knee = s == 3;
        return [
          ...head,
          ScaleButtons(
            large: true,
            labels: knee ? ClientMock.kneeScale : ClientMock.weekScale,
            selected: knee ? _kn : _wk,
            onPick: (i) => _touch(() => knee ? _kn = i : _wk = i),
          ),
        ];
      case 'choice':
        return [
          ...head,
          for (var i = 0; i < ClientMock.mealPlanOptions.length; i++) ...[
            RadioOption(compact: true, selected: _mp == i, title: Text(ClientMock.mealPlanOptions[i]), onTap: () => _touch(() => _mp = i)),
            const SizedBox(height: 8),
          ],
        ];
      case 'photo':
        return [
          ...head,
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: PhotoSlot(name: _angles[i], has: _ph[i], onTap: () => _togglePhoto(i))),
              ],
            ],
          ),
          const SizedBox(height: 10),
          CheckRow(
            on: _noPh,
            title: 'No photos this week',
            subtitle: 'Fine now and then. Aman compares photos every 2 weeks.',
            onTap: () => _touch(() {
              _noPh = !_noPh;
              _ph = [false, false, false];
            }),
          ),
          const SizedBox(height: 8),
          const Caption('Same spot, same light, in the morning. Only Aman sees your photos.'),
        ];
      default:
        return [
          ...head,
          NoteField(
            controller: _wText,
            hint: 'Type your answer, or tap a suggestion below',
            chips: ClientMock.weeklyNoteChips,
            chipsLabel: 'Tap to add',
            maxLines: 4,
            onChanged: () => _touch(() {}),
          ),
        ];
    }
  }

  void _togglePhoto(int i) {
    final prev = [..._ph], prevNo = _noPh;
    _touch(() {
      _ph[i] = !_ph[i];
      _noPh = false;
    });
    if (_ph[i]) {
      showToast(context, '${_angles[i]} photo added', subtitle: '$_nPh of 3 photos', kind: ToastKind.ok);
    } else {
      showToast(context, '${_angles[i]} photo removed', kind: ToastKind.del, onUndo: () => setState(() {
            _ph = prev;
            _noPh = prevNo;
          }));
    }
  }

  List<Widget> _reviewBody() {
    return [
      Text('Check your answers', style: AppText.bodyBold.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text('Tap Edit to change one. Aman gets it as soon as you send.', style: AppText.secondary),
      const SizedBox(height: 10),
      for (var i = 0; i < _qs.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.line))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${_qs[i].$2}', style: AppText.caption),
                    Builder(builder: (_) {
                      final a = _answer(i);
                      final req = _qs[i].$4;
                      return Text(
                        a ?? (req ? 'Not answered · required' : 'Skipped'),
                        style: AppText.bodyBold.copyWith(fontSize: 13.5, color: a != null ? AppColors.text : (req ? AppColors.badText : AppColors.muted)),
                      );
                    }),
                  ],
                ),
              ),
              AppButton.outline('Edit', small: true, onPressed: () => setState(() => _step = i)),
            ],
          ),
        ),
    ];
  }
}
