import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_mock.dart';
import 'package:train_with_vimal/data/models/client_app.dart';

import '../food/food_state.dart';
import '../more/client_ui.dart';
import 'habit_widgets.dart';

/// Design: ClientHabits.dc.html — daily habits (steps, water, sleep) and supplements.
class ClientHabitsScreen extends ConsumerStatefulWidget {
  const ClientHabitsScreen({super.key});

  @override
  ConsumerState<ClientHabitsScreen> createState() => _ClientHabitsScreenState();
}

class _ClientHabitsScreenState extends ConsumerState<ClientHabitsScreen> {
  static const _today = ClientMock.habitToday;
  static const _dn = ClientMock.habitDayNames;
  static const _dd = ClientMock.habitDates;
  static const _hb = ClientMock.habits;
  static const _sp = ClientMock.supplements;

  bool _week = false;
  int _sd = _today;
  List<int?> _steps = [...ClientMock.steps0];
  List<int?> _water = [...ClientMock.water0];
  List<int?> _sleep = [...ClientMock.sleep0];
  List<List<bool>> _tk = [for (final r in ClientMock.taken0) [...r]];
  bool _remind = false;

  // ------------------------------------------------------------ helpers

  String _dl(int i) => '${_dn[i]}, ${_dd[i]} Oct';
  String _days(int n) => '$n${n == 1 ? ' day' : ' days'}';
  bool get _isToday => _sd == _today;
  bool get _past => _sd < _today;
  bool get _future => _sd > _today;

  List<int?> _values(String id) {
    if (id == 'water') return [for (var i = 0; i < _water.length; i++) i == _today ? ref.read(clientWaterProvider) : _water[i]];
    return id == 'steps' ? _steps : _sleep;
  }

  bool _met(HabitDef h, int i) {
    final v = _values(h.id)[i];
    return v != null && v >= h.goal;
  }

  int _streak(HabitDef h) {
    var i = _met(h, _today) ? _today : _today - 1;
    var n = 0;
    while (i >= 0 && _met(h, i)) {
      n++;
      i--;
    }
    return n + (i < 0 ? h.baseStreak : 0);
  }

  bool _allMet(int i) => _hb.every((h) => _met(h, i));

  String _fmt(HabitDef h, int v) => switch (h.id) { 'steps' => '${nf(v)} steps', 'water' => litres(v), _ => hoursMin(v) };

  String _of(HabitDef h, int v) => switch (h.id) {
        'steps' => '${nf(v)} of 8,000 steps',
        'water' => '${litres(v)} of 3 L · ${(v / 250).round()} glasses',
        _ => '${hoursMin(v)} of 7 h',
      };

  int _stockOf(int k) {
    var used = 0;
    for (var i = 0; i < _tk.length; i++) {
      used += (_tk[i][k] ? 1 : 0) - (ClientMock.taken0[i][k] ? 1 : 0);
    }
    return _sp[k].stock - used;
  }

  int _takenOn(int i) => _tk[i].where((x) => x).length;

  void _later() => showToast(context, 'You can log this on ${_dl(_sd)}', subtitle: 'Only today and earlier days can be logged', kind: ToastKind.info);

  // ------------------------------------------------------------ actions

  void _setWater(int d, [int? day]) {
    final di = day ?? _sd;
    final cur = _values('water')[di] ?? 0;
    final on = di == _today ? 'today' : 'on ${_dl(di)}';
    if (d < 0 && cur == 0) {
      showToast(context, 'Nothing to remove', subtitle: 'No water logged $on', kind: ToastKind.info);
      return;
    }
    final now = cur + d;
    final prevList = [..._water], prevToday = ref.read(clientWaterProvider), prevSd = _sd;
    setState(() {
      _sd = di;
      if (di == _today) {
        ref.read(clientWaterProvider.notifier).set(now);
      } else {
        _water[di] = now;
      }
    });
    void undo() => setState(() {
          _water = prevList;
          _sd = prevSd;
          ref.read(clientWaterProvider.notifier).set(prevToday);
        });
    if (d > 0 && cur < 3000 && now >= 3000) {
      showToast(context, 'Water goal complete!', subtitle: '${litres(now)} $on', kind: ToastKind.star, onUndo: undo);
    } else if (d > 0) {
      showToast(context, '+250 ml · ${litres(now)} $on', subtitle: now >= 3000 ? 'Goal complete' : '${litres(3000 - now)} to go', kind: ToastKind.water, onUndo: undo);
    } else {
      showToast(context, 'Removed 250 ml', subtitle: '${litres(now)} logged $on', kind: ToastKind.del, onUndo: undo);
    }
  }

  void _openLog(HabitDef h, int i) {
    if (h.id == 'water') return _setWater(250, i);
    setState(() => _sd = i);
    h.id == 'steps' ? _openSteps() : _openSleep();
  }

  void _setTaken(int day, int k, bool v, {bool fromDetail = false}) {
    final prev = [for (final r in _tk) [...r]];
    final x = _sp[k];
    setState(() => _tk[day][k] = v);
    void undo() => setState(() => _tk = prev);
    if (v) {
      final sub = day < _today && !fromDetail ? 'Logged for ${_dl(day)}' : '${_stockOf(k)} ${x.unit} left at home';
      showToast(context, '${x.name} taken', subtitle: sub, kind: ToastKind.ok, onUndo: undo);
    } else {
      showToast(context, '${x.name} un-ticked', subtitle: day == _today ? 'Not taken today' : 'Not taken on ${_dl(day)}', kind: ToastKind.del, onUndo: undo);
    }
  }

  // ------------------------------------------------------------ sheets

  void _openSteps() {
    var v = _steps[_sd] ?? 0;
    final sd = _sd;
    final onDay = sd == _today ? 'today' : 'on ${_dl(sd)}';
    showClientSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => ClientSheet(
          title: 'Add steps · ${sd == _today ? 'today' : _dl(sd)}',
          subtitle: 'Goal 8,000 steps a day',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BigValueStepper(value: nf(v), unit: 'steps', onMinus: () => setS(() => v = v - 500 < 0 ? 0 : v - 500), onPlus: () => setS(() => v += 500)),
              const SizedBox(height: 12),
              QuickButtons(labels: [for (final q in const [1000, 2000, 5000, 10000]) '+${nf(q)}'], onPick: (j) => setS(() => v += const [1000, 2000, 5000, 10000][j])),
              const SizedBox(height: 12),
              ProgressBar(v / 8000, height: 8, color: const Color(0xFF22C55E)),
              const SizedBox(height: 6),
              Text(v >= 8000 ? 'Goal reached' : '${nf(8000 - v)} steps to go', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            AppButton('Save steps', icon: Icons.check_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              final prev = [..._steps];
              final was = _steps[sd] ?? 0;
              setState(() => _steps[sd] = v);
              void undo() => setState(() => _steps = prev);
              if (v >= 8000 && was < 8000) {
                showToast(context, 'Step goal reached!', subtitle: '${nf(v)} steps $onDay', kind: ToastKind.star, onUndo: undo);
              } else {
                showToast(context, 'Steps saved', subtitle: '${nf(v)} of 8,000 $onDay', kind: ToastKind.ok, onUndo: undo);
              }
            }),
          ],
        ),
      ),
    );
  }

  void _openSleep() {
    var v = _sleep[_sd] ?? 420;
    final sd = _sd;
    showClientSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => ClientSheet(
          title: 'How long did you sleep?',
          subtitle: '${sd == _today ? 'Last night' : 'Night before ${_dl(sd)}'} · goal 7 hours',
          body: Column(
            children: [
              BigValueStepper(
                value: hoursMin(v),
                unit: v >= 420 ? 'Goal met' : '${hoursMin(420 - v)} short of 7 h',
                onMinus: () => setS(() => v = v - 15 < 0 ? 0 : v - 15),
                onPlus: () => setS(() => v = v + 15 > 900 ? 900 : v + 15),
              ),
              const SizedBox(height: 12),
              QuickButtons(
                labels: [for (final m in const [360, 390, 420, 450, 480]) '${m / 60 == (m ~/ 60) ? m ~/ 60 : m / 60} h'],
                selected: const [360, 390, 420, 450, 480].indexOf(v),
                onPick: (j) => setS(() => v = const [360, 390, 420, 450, 480][j]),
              ),
            ],
          ),
          actions: [
            AppButton('Save sleep', icon: Icons.check_rounded, onPressed: () {
              Navigator.of(ctx).pop();
              final prev = [..._sleep];
              setState(() => _sleep[sd] = v);
              showToast(context, 'Sleep saved',
                  subtitle: '${hoursMin(v)}${v >= 420 ? ' · goal met' : ' · aim for 7 h tonight'}',
                  kind: v >= 420 ? ToastKind.ok : ToastKind.info,
                  onUndo: () => setState(() => _sleep = prev));
            }),
          ],
        ),
      ),
    );
  }

  void _openHabit(HabitDef h) {
    final sk = _streak(h);
    final vals = _values(h.id);
    final n7 = [for (var i = 0; i <= 6; i++) if (_met(h, i)) i].length;
    final subDay = _future ? _today : _sd;
    final v = vals[subDay];
    showClientSheet<void>(
      context,
      builder: (ctx) => ClientSheet(
        title: h.name,
        subtitle: 'Goal ${h.target} · ${_isToday || _future ? 'today' : _dl(_sd)}: ${v == null ? 'not logged' : _fmt(h, v)}',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatCells([(_days(sk), 'Current streak'), (_days(h.best), 'Best streak'), ('$n7 of 7', 'Last 7 days')]),
            const Overline('Last 7 days', padding: EdgeInsets.only(top: 14, bottom: 6)),
            for (final i in const [6, 5, 4, 3, 2, 1, 0])
              HistoryRow(
                day: i == _today ? 'Today' : '${_dn[i]} ${_dd[i]}',
                frac: (vals[i] ?? 0) / h.goal,
                value: vals[i] == null ? '—' : _fmt(h, vals[i]!),
                met: _met(h, i),
                today: i == _today,
              ),
            const Overline('Target set by Aman', padding: EdgeInsets.only(top: 14, bottom: 4)),
            KvList([('Target', h.target), ('How often', h.how), ('Since', 'Mon, 12 Jan'), ('Set by', 'Aman Verma')]),
            const SizedBox(height: 8),
            _CheckinLinkCaption(onTap: () {
              Navigator.of(ctx).pop();
              context.go(Routes.cCheckins);
            }),
          ],
        ),
        actions: [
          AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
          AppButton(h.id == 'water' ? '+250 ml today' : h.id == 'steps' ? 'Add steps today' : 'Log sleep', onPressed: () {
            Navigator.of(ctx).pop();
            _openLog(h, _today);
          }),
        ],
      ),
    );
  }

  void _openSugar() {
    showClientSheet<void>(
      context,
      builder: (ctx) => ClientSheet(
        title: 'No sugar after 7 pm',
        subtitle: 'Starts Mon, 12 Oct · set by Aman Verma',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoBanner(
              icon: Icons.event_rounded,
              bg: AppColors.sub,
              fg: AppColors.text2,
              text: 'Nothing logged yet. This habit starts on Mon, 12 Oct. Each evening, tick it if you had no sugar after 7 pm.',
            ),
            const Overline('Target set by Aman', padding: EdgeInsets.only(top: 14, bottom: 4)),
            const KvList([('Target', 'No sugar after 7 pm'), ('Type', 'Yes / no, tick each evening'), ('How often', 'Every day'), ('Starts', 'Mon, 12 Oct')]),
            const SizedBox(height: 8),
            _CheckinLinkCaption(onTap: () {
              Navigator.of(ctx).pop();
              context.go(Routes.cCheckins);
            }),
          ],
        ),
        actions: [
          _remind
              ? AppButton.outline('Reminder on · Mon 9:00 pm', icon: Icons.notifications_active_rounded, onPressed: () => _toggleRemind(ctx))
              : AppButton('Remind me on Monday evening', icon: Icons.notifications_rounded, onPressed: () => _toggleRemind(ctx)),
        ],
      ),
    );
  }

  void _toggleRemind(BuildContext sheetCtx) {
    Navigator.of(sheetCtx).pop();
    final was = _remind;
    setState(() => _remind = !was);
    if (was) {
      showToast(context, 'Reminder removed', kind: ToastKind.del, onUndo: () => setState(() => _remind = true));
    } else {
      showToast(context, 'Reminder set', subtitle: 'Mon, 12 Oct at 9:00 pm', kind: ToastKind.ok, onUndo: () => setState(() => _remind = false));
    }
  }

  void _openSupplement(int k) {
    final x = _sp[k];
    final s = _stockOf(k);
    final tk = _tk[_today][k];
    final n = [for (var i = 0; i <= 6; i++) if (_tk[i][k]) i].length;
    showClientSheet<void>(
      context,
      builder: (ctx) => ClientSheet(
        title: x.name,
        subtitle: '${x.night ? 'Night' : 'Morning'} · ${x.dose}',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KvList([
              ('Dose', x.dose.replaceAll(RegExp(r',.*'), '').replaceAll(' with breakfast', '')),
              ('When', x.night ? 'Night, 10:30 pm' : 'Morning, 8:00 am'),
              ('How to take', x.how),
              ('Stock at home', '$s ${x.unit} left'),
              ('Plan', x.note ?? 'Fat loss basics · since 1 Sep'),
            ]),
            Overline('Last 7 days · $n of 7 taken', padding: const EdgeInsets.only(top: 14, bottom: 8)),
            DayDots(days: [for (var i = 0; i <= 6; i++) (_dn[i][0], _tk[i][k] ? DotState.ok : (i == _today ? DotState.now : DotState.no))], large: true),
            if (s <= 7) ...[
              const SizedBox(height: 12),
              const InfoBanner(
                icon: Icons.warning_amber_rounded,
                bg: AppColors.warnBg,
                fg: AppColors.warnText,
                text: 'Running low. Buy more this week so you do not miss days.',
              ),
            ],
          ],
        ),
        actions: [
          AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
          tk
              ? AppButton.outline('Undo today', onPressed: () {
                  Navigator.of(ctx).pop();
                  _setTaken(_today, k, false, fromDetail: true);
                })
              : AppButton('Take now', onPressed: () {
                  Navigator.of(ctx).pop();
                  _setTaken(_today, k, true, fromDetail: true);
                }),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    ref.watch(clientWaterProvider);
    return PageScroll(
      children: [
        ClientTop(
          title: 'Habits & supplements',
          subtitle: 'Daily basics · Fat loss basics · set by Aman',
          onBack: () => context.canPop() ? context.pop() : context.go(Routes.cMore),
        ),
        SegmentedTabs<bool>(items: const [(false, 'Day'), (true, 'Week')], value: _week, onChanged: (v) => setState(() => _week = v)),
        if (!_week) ..._dayView() else ..._weekView(),
      ],
    );
  }

  List<Widget> _dayView() {
    final nMet = _hb.where((h) => _met(h, _sd)).length;
    return [
      WeekStrip(
        selected: _sd - 2,
        onPick: (i) => setState(() => _sd = i + 2),
        days: [
          for (var i = 2; i <= 8; i++)
            WeekDay(_dn[i][0], _dd[i], today: i == _today, done: i <= _today && _allMet(i), partial: i < _today && !_allMet(i)),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Text(_isToday ? 'Today, ${_dl(_sd)}' : _dl(_sd), style: AppText.bodyBold.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              _future ? 'Coming up · nothing to log yet' : '$nMet of 3 habits done${_past && nMet < 3 ? ' · ${3 - nMet} missed' : ''}',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      for (final h in _hb) _habitCard(h),
      SugarCard(onOpen: _openSugar, onTick: () => showToast(context, 'This habit starts on Mon, 12 Oct', subtitle: 'Aman set the start date. Tick it from Monday evening.', kind: ToastKind.info)),
      _supplementsCard(),
    ];
  }

  Widget _habitCard(HabitDef h) {
    final v = _values(h.id)[_sd];
    final m = _met(h, _sd);
    final sk = _streak(h);
    final String line = _future ? 'Goal ${h.target}' : v == null ? 'Not logged yet · goal ${h.target}' : _of(h, v);
    return HabitCard(
      habit: h,
      line: line,
      met: m && !_future,
      missed: _past && !m,
      frac: v == null ? 0 : v / h.goal,
      barColor: m ? const Color(0xFF22C55E) : (_past ? const Color(0xFFF2A7A3) : const Color(0xFFF59E0B)),
      streak: sk > 0 ? '${_days(sk)} streak' : 'No streak yet',
      dots: [for (var i = 0; i <= 6; i++) (_dn[i][0], _met(h, i) ? DotState.ok : (i == _today ? DotState.now : DotState.no))],
      button: h.id == 'steps' ? 'Add steps' : v == null ? 'Log sleep' : 'Edit',
      onOpen: () => _openHabit(h),
      onTap: _future ? _later : () => _openLog(h, _sd),
      onMinus: _future ? _later : () => _setWater(-250),
      onPlus: _future ? _later : () => _setWater(250),
    );
  }

  Widget _supplementsCard() {
    final pct = _supPct;
    final sub = _future ? 'Coming up on ${_dl(_sd)}' : '${_takenOn(_sd)} of 3 taken${_isToday ? ' today' : ' on ${_dl(_sd)}'}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHead(
            icon: Icons.medication_rounded,
            tint: Tint.purple,
            title: 'Supplements',
            subtitle: sub,
            trailing: Pill('This week $pct%', tone: pct >= 80 ? PillTone.green : PillTone.amber),
          ),
          for (final night in const [false, true]) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(night ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(night ? 'Night' : 'Morning', style: AppText.bodyBold.copyWith(fontSize: 13)),
                const SizedBox(width: 6),
                Text(night ? 'Before bed · 10:30 pm' : 'With breakfast · 8:00 am', style: AppText.caption),
              ],
            ),
            for (var k = 0; k < _sp.length; k++)
              if (_sp[k].night == night) _supRow(k),
          ],
          const SizedBox(height: 10),
          const Caption('Plan “Fat loss basics” by Aman · since 1 Sep. Tap a supplement for dose and stock.'),
        ],
      ),
    );
  }

  Widget _supRow(int k) {
    final x = _sp[k];
    final tk = _tk[_sd][k];
    final gi = x.night ? 1 : 0;
    final String d = tk
        ? '${_isToday ? 'Taken ${ClientMock.supplementTimes[gi]}' : 'Taken'} · ${x.dose}'
        : _isToday && x.night
            ? 'Due 10:30 pm · ${x.dose}'
            : _past
                ? 'Not taken · ${x.dose}'
                : x.dose;
    void take() => _future ? _later() : _setTaken(_sd, k, true);
    void undo() => _setTaken(_sd, k, false);
    final Widget trailing;
    if (_future) {
      trailing = const Pill('Upcoming');
    } else if (tk) {
      trailing = AppButton.outline('Undo', small: true, onPressed: undo);
    } else if (_past) {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: [
        const Pill('Missed', tone: PillTone.red),
        const SizedBox(width: 6),
        AppButton.outline('Took it', small: true, onPressed: take),
      ]);
    } else {
      trailing = AppButton('Take', small: true, onPressed: take);
    }
    return SupplementRow(
      name: x.name,
      detail: d,
      taken: tk,
      missed: _past && !tk,
      onTick: _future ? _later : (tk ? undo : take),
      onInfo: () => _openSupplement(k),
      trailing: trailing,
    );
  }

  // week adherence, Mon 5 → today
  int get _hDue => 4 * 3 + _hb.where((h) => _met(h, _today)).length;
  int get _hMet => [2, 3, 4, 5, 6].fold(0, (a, i) => a + _hb.where((h) => _met(h, i)).length);
  int get _sDue => 4 * 3 + 2 + (_tk[_today][2] ? 1 : 0);
  int get _sTk => [2, 3, 4, 5, 6].fold(0, (a, i) => a + _takenOn(i));
  int get _supPct => (_sTk / _sDue * 100).round();

  List<Widget> _weekView() {
    final hPct = (_hMet / _hDue * 100).round();
    final best = _hb.map((h) => (h, _streak(h))).reduce((a, b) => b.$2 > a.$2 ? b : a);
    const wi = [2, 3, 4, 5, 6, 7, 8];
    WeekCell cell(bool ok, int i) => WeekCell(i > _today ? CellState.fut : ok ? CellState.ok : i == _today ? CellState.now : CellState.no, () => setState(() {
          _week = false;
          _sd = i;
        }));
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatCells([('$hPct%', 'Habits done'), ('$_supPct%', 'Supplements taken'), (_days(best.$2), '${best.$1.short} streak')]),
            const SizedBox(height: 10),
            Caption('Mon 5 – Sun 11 Oct · $_hMet of $_hDue habits and $_sTk of $_sDue supplements so far. Aman sees this in your profile.'),
          ],
        ),
      ),
      WeekGridCard(
        icon: Icons.local_fire_department_rounded,
        tint: Tint.amber,
        title: 'Habits this week',
        subtitle: 'Mon 5 – Sun 11 Oct · tap a day to open it',
        dayLetters: [for (final i in wi) (_dn[i][0], i == _today)],
        rows: [
          for (final h in _hb)
            WeekGridRow(
              name: h.name,
              sub: h.week,
              count: '${wi.where((i) => i <= _today && _met(h, i)).length}/5',
              onOpen: () => _openHabit(h),
              cells: [for (final i in wi) cell(_met(h, i), i)],
            ),
          WeekGridRow(
            name: 'No sugar after 7 pm',
            sub: 'Starts Mon, 12 Oct',
            count: '—',
            onOpen: _openSugar,
            cells: [
              for (final _ in wi)
                WeekCell(CellState.off, () => showToast(context, 'No sugar after 7 pm starts on Mon, 12 Oct', subtitle: 'Aman set the start date', kind: ToastKind.info)),
            ],
          ),
        ],
        legend: true,
      ),
      WeekGridCard(
        icon: Icons.medication_rounded,
        tint: Tint.purple,
        title: 'Supplements this week',
        subtitle: '$_sTk of $_sDue taken so far · $_supPct%',
        dayLetters: [for (final i in wi) (_dn[i][0], i == _today)],
        rows: [
          for (var k = 0; k < _sp.length; k++)
            WeekGridRow(
              name: _sp[k].name,
              sub: _sp[k].night ? 'Night' : 'Morning',
              count: '${wi.where((i) => i <= _today && _tk[i][k]).length}/5',
              onOpen: () => _openSupplement(k),
              cells: [for (final i in wi) cell(_tk[i][k], i)],
            ),
        ],
      ),
    ];
  }
}

class _CheckinLinkCaption extends StatelessWidget {
  const _CheckinLinkCaption({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Want a different target? Tell Aman in your ', style: AppText.secondary.copyWith(fontSize: 12.5)),
        GestureDetector(
          onTap: onTap,
          child: Text('weekly check-in',
              style: AppText.secondary.copyWith(fontSize: 12.5, color: AppColors.accentText, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
        ),
        Text('.', style: AppText.secondary.copyWith(fontSize: 12.5)),
      ],
    );
  }
}
