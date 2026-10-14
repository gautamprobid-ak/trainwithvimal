import 'package:flutter/material.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';
import 'package:train_with_vimal/data/models/people.dart';

import '../client_profile_controller.dart';
import '../cp_widgets.dart';

// ───────────────────────── Assign plan menu ─────────────────────────

void showAssignMenu(BuildContext context, ClientProfileController c) {
  showActionSheet(
    context,
    title: 'Assign plan',
    subtitle: '${c.first} gets her own copy; the master is not changed.',
    actions: [
      SheetAction('Workout plan', Icons.fitness_center_rounded, () => showAssignPlanSheet(context, c, 'workout')),
      SheetAction('Meal plan', Icons.restaurant_rounded, () => showAssignPlanSheet(context, c, 'meal')),
      SheetAction('Supplement plan', Icons.medication_outlined, () => showAssignPlanSheet(context, c, 'supp')),
      SheetAction('Habit plan', Icons.check_circle_outline_rounded, () => showAssignPlanSheet(context, c, 'habit')),
    ],
  );
}

// ───────────────────────── Edit profile ─────────────────────────

void showEditProfileSheet(BuildContext context, ClientProfileController c) {
  showCpSheet(
    context,
    title: "Edit ${c.first}'s profile",
    subtitle: 'Changes save to her account right away.',
    builder: (_) => _EditProfile(c),
  );
}

class _EditProfile extends StatefulWidget {
  const _EditProfile(this.c);
  final ClientProfileController c;
  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  String gender = 'Female';
  String goal = 'Lose fat';
  late ClientStatus status = widget.c.status;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final phone = c.client.phone.replaceFirst('+91 ', '');
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => SheetBody(
        note: 'Last edited by Aman Verma · 3 Oct',
        actions: [
          AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
          AppButton('Save changes', onPressed: () {
            c.setStatus(status);
            Navigator.of(context).pop();
            showToast(context, 'Profile saved', subtitle: '${c.first} sees the changes in her app', kind: ToastKind.ok);
          }),
        ],
        children: [
          SheetSection(title: 'Personal', children: [
            LabeledField(label: 'Full name', initialValue: c.name),
            const SizedBox(height: 10),
            SelectField(label: 'Gender', value: gender, options: const ['Female', 'Male', 'Other'], onChanged: (v) => setState(() => gender = v)),
            const SizedBox(height: 10),
            const FieldPair(LabeledField(label: 'Date of birth', initialValue: '14 Mar 1997'), LabeledField(label: 'Height', initialValue: '162 cm')),
          ]),
          SheetSection(title: 'Contact', children: [
            LabeledField(label: 'Phone', prefix: '+91', initialValue: phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            const LabeledField(label: 'City', initialValue: 'Mumbai'),
          ]),
          SheetSection(
            title: 'Sign-in',
            help: c.isAdmin ? 'She gets a notice when her email or password changes.' : 'She gets a notice when her email changes.',
            children: [
              LabeledField(label: 'Email', initialValue: c.client.email, help: 'She signs in with this email.'),
              if (c.isAdmin) ...[
                const SizedBox(height: 10),
                const LabeledField(label: 'New password', hint: 'Leave empty to keep it', obscure: true, help: 'At least 8 characters.'),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.key_rounded, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(c.isAdmin ? 'Or let ${c.first} pick her own:' : '${c.first} forgot her password?', style: AppText.secondary),
                  ),
                  CpTextButton('Send a reset link',
                      size: 13,
                      onTap: () => showToast(context, 'Reset link sent', subtitle: 'To ${c.client.email}', kind: ToastKind.ok)),
                ],
              ),
            ],
          ),
          SheetSection(title: 'Coaching', children: [
            FieldPair(
              SelectField(label: 'Goal', value: goal, options: const ['Lose fat', 'Build muscle', 'Get stronger', 'General fitness'], onChanged: (v) => setState(() => goal = v)),
              const LabeledField(label: 'Goal weight', initialValue: '68 kg'),
            ),
            const SizedBox(height: 10),
            FieldPair(
              const LabeledField(label: 'Target date', initialValue: 'Feb 2027'),
              SelectField(
                label: 'Status',
                value: status.label,
                options: [for (final s in ClientStatus.values) s.label],
                onChanged: (v) => setState(() => status = ClientStatus.values.firstWhere((s) => s.label == v)),
              ),
            ),
            const SizedBox(height: 12),
            _TrainerLine(c),
          ]),
          const SheetSection(title: 'Health', children: [
            LabeledField(label: 'Injuries or conditions', initialValue: 'Right knee hurts on deep squats'),
            SizedBox(height: 10),
            LabeledField(label: 'Food preference', initialValue: 'Vegetarian · no eggs'),
          ]),
        ],
      ),
    );
  }
}

class _TrainerLine extends StatelessWidget {
  const _TrainerLine(this.c);
  final ClientProfileController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.sub, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Avatar(Avatar.initialsOf(c.trainer), size: 26, color: AvatarColor.c2),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(style: AppText.secondary.copyWith(color: AppColors.text), children: [
              const TextSpan(text: 'Trainer '),
              TextSpan(text: c.trainer, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (!c.isAdmin) const TextSpan(text: ' (you)'),
            ])),
          ),
          if (c.isAdmin)
            CpTextButton('Change trainer', size: 13, onTap: () => showChangeTrainerSheet(context, c))
          else
            Text('Only Vimal can change it', style: AppText.caption),
        ],
      ),
    );
  }
}

// ───────────────────────── Assign a plan ─────────────────────────

void showAssignPlanSheet(BuildContext context, ClientProfileController c, String kind) {
  final k = ClientProfileMock.assignKinds[kind]!;
  showCpSheet(
    context,
    title: k.title,
    subtitle: '${k.sub}. ${c.first} gets her own copy; the master is not changed.',
    builder: (_) => _AssignPlan(c, k),
  );
}

class _AssignPlan extends StatefulWidget {
  const _AssignPlan(this.c, this.k);
  final ClientProfileController c;
  final AssignKind k;
  @override
  State<_AssignPlan> createState() => _AssignPlanState();
}

class _AssignPlanState extends State<_AssignPlan> {
  late String pick = widget.k.options.first.id;
  String when = 'next';
  bool editFirst = false;
  bool tell = true;
  String search = '';
  late final Map<String, String> filters = {for (final f in widget.k.filters) f.$1: f.$2.first};

  AssignOption get sel => widget.k.options.firstWhere((o) => o.id == pick);

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final k = widget.k;
    final end = k.currentEnd;
    final whenOpts = <(String, String, String)>[
      (
        'next',
        end.isNotEmpty ? 'After current ends' : 'Next to current',
        end.isNotEmpty
            ? 'Starts when ${k.currentName} ends on $end. It shows as Up next till then.'
            : 'Starts tomorrow. Both plans run together.'
      ),
      ('now', 'Replace current', 'Starts tomorrow. ${k.currentName} ends today and moves to Plan history.'),
      ('date', 'Pick a date', 'Starts on the date you pick, up to 3 months ahead.'),
    ];
    final start = when == 'now' ? 'Sat, 10 Oct' : when == 'date' ? 'Mon, 19 Oct' : (end.isNotEmpty ? end : 'Sat, 10 Oct');
    final from = when == 'now' ? 'from Sat, 10 Oct' : when == 'date' ? 'from Mon, 19 Oct' : (end.isNotEmpty ? 'from $end' : 'from tomorrow');
    final opts = k.options.where((o) => o.name.toLowerCase().contains(search.toLowerCase())).toList();
    return SheetBody(
      note: '${sel.name} · $from',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Assign plan', icon: Icons.check_rounded, onPressed: () {
          Navigator.of(context).pop();
          showToast(context, '${sel.name} assigned', subtitle: '${c.first} · $from${tell ? ' · she gets a push notice' : ''}', kind: ToastKind.ok);
          if (editFirst) c.openPlanEdit(plan: k.id);
        }),
      ],
      children: [
        SheetSection(
          title: '1. Pick a plan',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton.outline('Filter', icon: Icons.filter_list_rounded, small: true, onPressed: _filter),
              const SizedBox(width: 6),
              AppButton.outline('Duplicate', icon: Icons.copy_rounded, small: true, onPressed: () {
                Navigator.of(context).pop();
                c.openPlanEdit(plan: k.id, duplicate: true);
              }),
            ],
          ),
          children: [
            SheetSearch(k.search, onChanged: (v) => setState(() => search = v)),
            OptionList([
              for (final o in opts)
                OptionTile(
                  selected: o.id == pick,
                  disabled: o.current,
                  title: o.name,
                  titleExtras: [
                    if (o.current) const AppBadge('Current'),
                    if (o.tip.isNotEmpty) AppBadge(o.tip, tone: BadgeTone.info),
                  ],
                  sub: '${o.sub}\n${c.r(o.note)}',
                  trailing: Text('${o.used} clients', style: AppText.caption),
                  onTap: () => setState(() => pick = o.id),
                ),
            ]),
          ],
        ),
        SheetSection(title: 'Preview', children: [_Preview(sel, k.rowsTitle, c)]),
        SheetSection(title: '2. When does it start?', children: [
          SegmentedTabs<String>(
            items: [for (final w in whenOpts) (w.$1, w.$2)],
            value: when,
            onChanged: (v) => setState(() => when = v),
          ),
          HintLine(whenOpts.firstWhere((w) => w.$1 == when).$3),
          FieldPair(
            SelectField(label: 'Start date', value: start, onTap: () => setState(() => when = 'date')),
            SelectField(label: 'Length', value: k.length, onTap: () {}),
          ),
        ]),
        SheetSection(title: '3. Options', children: [
          ToggleLine(
            title: "Edit ${c.first}'s copy before she sees it",
            sub: 'Opens the editor after you assign. She sees it only when you save.',
            value: editFirst,
            onChanged: (v) => setState(() => editFirst = v),
          ),
          ToggleLine(
            title: 'Tell ${c.first} in the app',
            sub: 'Push notice: "${c.trainer.split(' ').first} added a new plan for you"',
            value: tell,
            onChanged: (v) => setState(() => tell = v),
          ),
        ]),
      ],
    );
  }

  Future<void> _filter() async {
    for (final f in widget.k.filters) {
      final v = await pickOption(context, title: f.$1, options: f.$2, current: filters[f.$1]);
      if (v == null || !mounted) return;
      setState(() => filters[f.$1] = v);
    }
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.o, this.rowsTitle, this.c);
  final AssignOption o;
  final String rowsTitle;
  final ClientProfileController c;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFAFAF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name, style: AppText.cardTitle),
                    Text(c.r(o.by), style: AppText.caption),
                  ],
                ),
              ),
              CpTextButton('Open in library',
                  icon: Icons.open_in_new_rounded, onTap: () => showToast(context, 'Opening ${o.name} in the library', kind: ToastKind.info)),
            ],
          ),
          const SizedBox(height: 10),
          KpiStrip(o.kpis, columns: o.kpis.length == 4 ? 2 : o.kpis.length),
          SubLabel(rowsTitle),
          for (final r in o.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 64, child: Text(r.k, style: AppText.caption.copyWith(fontWeight: FontWeight.w700))),
                  Expanded(
                    child: Text(r.v, style: AppText.bodyBold.copyWith(fontSize: 13, color: r.rest ? AppColors.muted : AppColors.text)),
                  ),
                  Text(r.m, style: AppText.caption),
                ],
              ),
            ),
          if (o.diff.isNotEmpty) ...[
            const SubLabel('Compared to her current plan'),
            for (final d in o.diff)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right_alt_rounded, size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(child: Text(d, style: AppText.secondary.copyWith(color: AppColors.text2))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Change trainer (admin) ─────────────────────────

void showChangeTrainerSheet(BuildContext context, ClientProfileController c) {
  showCpSheet(
    context,
    title: "Change ${c.first}'s trainer",
    subtitle: 'With ${c.trainer} since ${c.client.joined.split(' ').take(2).join(' ')}',
    builder: (_) => _ChangeTrainer(c),
  );
}

class _ChangeTrainer extends StatefulWidget {
  const _ChangeTrainer(this.c);
  final ClientProfileController c;
  @override
  State<_ChangeTrainer> createState() => _ChangeTrainerState();
}

class _ChangeTrainerState extends State<_ChangeTrainer> {
  String pick = 'nj';
  bool moveCheckins = true;
  bool tellClient = true;
  bool tellOld = false;
  String q = '';

  bool _isCurrent(TrainerOption t) => t.name == widget.c.trainer;

  @override
  void initState() {
    super.initState();
    if (widget.c.trainer == 'Neha Joshi') pick = 'sk';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final picked = ClientProfileMock.trainerOptions.firstWhere((t) => t.id == pick);
    final list = ClientProfileMock.trainerOptions.where((t) => t.name.toLowerCase().contains(q.toLowerCase()));
    return SheetBody(
      note: 'Plans, logs and notes stay with ${c.first}',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Move to ${picked.name}', onPressed: () {
          final old = c.trainer;
          c.setTrainer(picked.name);
          Navigator.of(context).pop();
          showToast(context, '${c.first} moved to ${picked.name}',
              subtitle: moveCheckins ? '2 open check-ins moved too' : 'Open check-ins stay with $old',
              kind: ToastKind.ok,
              onUndo: () => c.setTrainer(old));
        }),
      ],
      children: [
        SheetSection(title: 'Pick a trainer', help: 'Load shows clients now vs the most they take.', children: [
          SheetSearch('Search trainers', onChanged: (v) => setState(() => q = v)),
          OptionList([
            for (final t in list)
              OptionTile(
                selected: t.id == pick,
                disabled: _isCurrent(t) || t.full,
                leading: Avatar(t.initials, size: 32, color: AvatarColor.values[t.colorIndex]),
                title: t.name,
                titleExtras: [
                  if (_isCurrent(t)) const AppBadge('Current'),
                  if (t.full) const AppBadge('Full', tone: BadgeTone.warn),
                  if (t.best && !_isCurrent(t)) const AppBadge('Good fit', tone: BadgeTone.ok),
                ],
                sub: t.sub,
                trailing: SizedBox(
                  width: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(TextSpan(style: AppText.caption, children: [
                        TextSpan(text: '${t.clients} / ${t.max}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                        const TextSpan(text: ' clients'),
                      ])),
                      const SizedBox(height: 4),
                      ProgressBar(t.clients / t.max, height: 4, color: t.full ? AppColors.warn : AppColors.accent),
                    ],
                  ),
                ),
                onTap: () => setState(() => pick = t.id),
              ),
          ]),
        ]),
        SheetSection(title: 'When you move her', children: [
          ToggleLine(
            title: 'Move her open check-ins',
            sub: '2 waiting for review go to the new trainer',
            value: moveCheckins,
            onChanged: (v) => setState(() => moveCheckins = v),
          ),
          ToggleLine(
            title: 'Tell ${c.first}',
            sub: "She sees the new trainer's name and photo",
            value: tellClient,
            onChanged: (v) => setState(() => tellClient = v),
          ),
          ToggleLine(
            title: 'Tell ${c.trainer}',
            sub: 'He keeps read-only access to past notes',
            value: tellOld,
            onChanged: (v) => setState(() => tellOld = v),
          ),
        ]),
        const SheetSection(title: 'Note for the new trainer', children: [
          TextField(minLines: 3, maxLines: 5, decoration: InputDecoration(hintText: 'Knee issue, prefers veg meals, wedding in Feb…')),
        ]),
      ],
    );
  }
}

// ───────────────────────── Send a form ─────────────────────────

void showSendFormSheet(BuildContext context, ClientProfileController c) {
  showCpSheet(
    context,
    title: 'Send a form to ${c.first}',
    subtitle: 'Check-ins, surveys and feedback forms. The master form is not changed.',
    builder: (_) => _SendForm(c),
  );
}

class _SendForm extends StatefulWidget {
  const _SendForm(this.c);
  final ClientProfileController c;
  @override
  State<_SendForm> createState() => _SendFormState();
}

class _SendFormState extends State<_SendForm> {
  String pick = 'ms';
  String mode = 'once';
  bool editFirst = false;
  bool remind = true;
  bool toTrainer = true;
  String send = 'Now';
  String within = '2 days';
  String every = 'Sunday';
  String at = '6:00 pm';
  String by = 'Push + WhatsApp';
  String q = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final f = ClientProfileMock.sendForms.firstWhere((x) => x.id == pick);
    final summary = '${f.name}${mode == 'once' ? ' · now, answer in 2 days' : ' · every Sunday, 6:00 pm'}';
    final list = ClientProfileMock.sendForms.where((x) => x.name.toLowerCase().contains(q.toLowerCase()));
    return SheetBody(
      note: summary,
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton('Send form', icon: Icons.send_rounded, onPressed: () {
          Navigator.of(context).pop();
          if (editFirst) {
            c.setForm(f.id == 'wk' || f.id == 'fb' ? f.id : 'wk');
            c.openFormEdit();
          }
          showToast(context, '${f.name} sent to ${c.first}', subtitle: summary, kind: ToastKind.ok);
        }),
      ],
      children: [
        SheetSection(title: '1. Pick a form', help: 'Master forms from the library. ${c.first} gets her own copy.', children: [
          SheetSearch('Search forms', onChanged: (v) => setState(() => q = v)),
          OptionList([
            for (final x in list)
              OptionTile(
                selected: x.id == pick,
                title: x.name,
                titleExtras: [if (x.has.isNotEmpty) AppBadge(x.has)],
                sub: x.sub,
                trailing: Text(x.questions, style: AppText.caption),
                onTap: () => setState(() => pick = x.id),
              ),
          ]),
        ]),
        SheetSection(title: '2. When', children: [
          SegmentedTabs<String>(items: const [('once', 'Once'), ('repeat', 'Repeats')], value: mode, onChanged: (v) => setState(() => mode = v)),
          const SizedBox(height: 10),
          if (mode == 'once')
            FieldPair(
              SelectField(label: 'Send', value: send, options: const ['Now', 'Tomorrow, 8:00 am', 'Sun, 11 Oct'], onChanged: (v) => setState(() => send = v)),
              SelectField(label: 'Answer within', value: within, options: const ['1 day', '2 days', '1 week'], onChanged: (v) => setState(() => within = v)),
            )
          else ...[
            FieldPair(
              SelectField(label: 'Every', value: every, options: const ['Day', 'Sunday', 'Monday', 'Month'], onChanged: (v) => setState(() => every = v)),
              SelectField(label: 'At', value: at, options: const ['8:00 am', '12:00 pm', '6:00 pm', '9:00 pm'], onChanged: (v) => setState(() => at = v)),
            ),
            const SizedBox(height: 10),
            const SelectField(label: 'Until', value: 'Plan ends · 23 Nov', options: ['Plan ends · 23 Nov', 'I stop it']),
          ],
          const SizedBox(height: 10),
          SelectField(label: 'Send by', value: by, options: const ['Push', 'Push + email', 'Push + WhatsApp'], onChanged: (v) => setState(() => by = v)),
        ]),
        SheetSection(title: '3. Options', children: [
          ToggleLine(
            title: "Edit ${c.first}'s copy before sending",
            sub: 'Opens the form editor first. Add, remove or change questions just for her.',
            value: editFirst,
            onChanged: (v) => setState(() => editFirst = v),
          ),
          ToggleLine(title: 'Remind her if she does not answer', sub: 'One reminder after 24 hours', value: remind, onChanged: (v) => setState(() => remind = v)),
          ToggleLine(
            title: 'Answers go to ${c.trainer}',
            sub: 'He gets them in Check-ins to review',
            value: toTrainer,
            onChanged: (v) => setState(() => toTrainer = v),
          ),
        ]),
      ],
    );
  }
}

// ───────────────────────── Assign content ─────────────────────────

void showAssignContentSheet(BuildContext context, ClientProfileController c) {
  showCpSheet(
    context,
    title: 'Assign content to ${c.first}',
    subtitle: 'Videos, articles, PDFs and images from the library.',
    builder: (_) => _AssignContent(c),
  );
}

class _AssignContent extends StatefulWidget {
  const _AssignContent(this.c);
  final ClientProfileController c;
  @override
  State<_AssignContent> createState() => _AssignContentState();
}

class _AssignContentState extends State<_AssignContent> {
  String kind = 'all';
  final picked = <String>{'Knee-safe leg day warm-up', 'Sleep better in 7 days'};
  String how = 'plan';
  bool tell = true;
  String q = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final items = ClientProfileMock.contentPicks
        .where((x) => kind == 'all' || (kind == 'vid') == x.video)
        .where((x) => x.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
    const hows = <(String, String, String)>[
      ('always', 'Always', 'Stays in her Library until you remove it'),
      ('plan', 'Until plan ends', 'Goes away on Mon, 23 Nov'),
      ('date', 'Until a date', 'Pick the last day'),
    ];
    final n = picked.length;
    return SheetBody(
      note: '$n selected',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton(n == 0 ? 'Assign' : 'Assign $n ${n == 1 ? 'item' : 'items'}', icon: Icons.check_rounded, onPressed: n == 0
            ? null
            : () {
                Navigator.of(context).pop();
                showToast(context, '$n ${n == 1 ? 'item' : 'items'} assigned to ${c.first}',
                    subtitle: tell ? 'She gets a push notice with your note' : 'She sees it in her Library', kind: ToastKind.ok);
              }),
      ],
      children: [
        SheetSection(
          title: '1. Pick content',
          help: 'Pick one or more. ${c.first} sees them in the Library of her app.',
          trailing: Text('$n selected', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
          children: [
            SheetSearch('Search the library', onChanged: (v) => setState(() => q = v)),
            FChipBar(items: const [('all', 'All'), ('vid', 'Videos'), ('gui', 'Guides')], value: kind, onChanged: (v) => setState(() => kind = v)),
            const SizedBox(height: 10),
            OptionList([
              for (var i = 0; i < items.length; i++)
                OptionTile(
                  multi: true,
                  selected: picked.contains(items[i].name),
                  disabled: items[i].has,
                  leading: MediaBox(
                    tone: i,
                    width: 40,
                    height: 40,
                    icon: items[i].video ? Icons.play_arrow_rounded : Icons.description_outlined,
                    radius: 8,
                  ),
                  title: items[i].name,
                  titleExtras: [if (items[i].has) const AppBadge('Already has it')],
                  sub: '${items[i].note}\n${items[i].kind} · ${items[i].len}',
                  onTap: () => setState(() => picked.contains(items[i].name) ? picked.remove(items[i].name) : picked.add(items[i].name)),
                ),
            ]),
          ],
        ),
        SheetSection(title: '2. How long she keeps it', children: [
          SegmentedTabs<String>(items: [for (final h in hows) (h.$1, h.$2)], value: how, onChanged: (v) => setState(() => how = v)),
          HintLine(hows.firstWhere((h) => h.$1 == how).$3),
          if (how == 'date') const SelectField(label: 'Last day', value: 'Sun, 15 Nov', options: ['Sun, 1 Nov', 'Sun, 15 Nov', 'Mon, 23 Nov']),
        ]),
        SheetSection(title: '3. Message', children: [
          LabeledField(label: 'Note for ${c.first} (optional)', hint: "Watch this before Tuesday's leg day…", maxLines: 3),
          const SizedBox(height: 6),
          ToggleLine(title: 'Tell ${c.first} in the app', sub: 'Push notice with your note', value: tell, onChanged: (v) => setState(() => tell = v)),
        ]),
      ],
    );
  }
}
