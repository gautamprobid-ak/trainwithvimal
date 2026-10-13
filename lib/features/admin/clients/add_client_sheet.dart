import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/admin_mock.dart';
import 'package:train_with_vimal/data/models/admin.dart';
import 'package:train_with_vimal/data/models/people.dart';

import 'admin_ui.dart';

/// "Add a client" drawer (Clients and Approvals pages).
Future<void> showAddClientSheet(BuildContext context) => showFormSheet(
      context,
      title: 'Add a client',
      subtitle: 'For someone you already know. Link sign-ups go to Approvals.',
      builder: (_) => const _AddClientBody(),
    );

const _goals = ['Lose fat', 'Build muscle', 'Get stronger', 'Recomp', 'General fitness'];
const _goalLabel = {
  'Lose fat': 'Fat loss',
  'Build muscle': 'Muscle gain',
  'Get stronger': 'Strength',
  'Recomp': 'Recomp',
  'General fitness': 'General fitness',
};
const _programs = ['Pick later', 'Fat Loss Phase 1', 'Hypertrophy · Push / Pull / Legs', 'Strength Foundations', 'Beginner Full Body'];
const _mealPlans = ['Pick later', '1,600 kcal · vegetarian', '1,800 kcal · high protein', '2,200 kcal · muscle gain'];

class _AddClientBody extends ConsumerStatefulWidget {
  const _AddClientBody();

  @override
  ConsumerState<_AddClientBody> createState() => _AddClientBodyState();
}

class _AddClientBodyState extends ConsumerState<_AddClientBody> {
  final _name = TextEditingController(text: 'Kavya Menon');
  final _mobile = TextEditingController(text: '98450 22118');
  final _email = TextEditingController();
  String _gender = 'Female';
  String _goal = 'Lose fat';
  String _trainer = _trainerLabel(AdminMock.trainerChoices.first);
  String _program = 'Pick later';
  String _meal = 'Pick later';
  bool _active = true;

  static String _trainerLabel(TrainerChoice t) => '${t.name} · ${t.clients} / ${t.capacity}';

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _mobile.text.trim().length >= 8;

  void _save() {
    final name = _name.text.trim();
    final trainer = _trainer.split(' · ').first;
    final id = '${name.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '-')}-${DateTime.now().millisecondsSinceEpoch}';
    final initials = Avatar.initialsOf(name);
    if (_active) {
      ref.read(adminClientsProvider.notifier).add(ClientSummary(
            id: id,
            name: name,
            email: _email.text.trim().isEmpty ? '—' : _email.text.trim(),
            trainer: trainer,
            goal: _goalLabel[_goal]!,
            status: ClientStatus.active,
            thisWeek: 'Not started',
            phone: '+91 ${_mobile.text.trim()}',
            joined: '9 Oct 2026',
            nextCheckin: 'Sun, 11 Oct',
            lastActive: 'Just now',
            program: _program == 'Pick later' ? null : _program,
          ));
    } else {
      final notifier = ref.read(approvalsProvider.notifier);
      final req = SignupRequest(
        id: id,
        name: name,
        initials: initials,
        color: AvatarColor.of(initials),
        email: _email.text.trim().isEmpty ? '—' : _email.text.trim(),
        phone: _mobile.text.trim(),
        invitedBy: 'Vimal',
        inviterInitials: 'V',
        inviterColor: AvatarColor.c3,
        code: 'Added by you',
        plan: 'Quarterly plan',
        device: 'Added by you',
        steps: 1,
        wait: 'Just now',
        when: 'Added today',
        waitLevel: WaitLevel.normal,
        answers: [('Goal', _goal)],
        healthNote: '',
        hoursWaiting: 0,
      );
      notifier.addWaiting(req);
    }
    showToast(
      context,
      _active ? '$name added' : '$name sent to Approvals',
      subtitle: _active ? 'Login link sent on WhatsApp and email' : 'Approve her from the Approvals tab',
      kind: ToastKind.ok,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      note: 'Only name and mobile are needed',
      actions: [
        AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton(_active ? 'Add client' : 'Add and send to Approvals', icon: Icons.person_add_alt_rounded, onPressed: _valid ? _save : null),
      ],
      children: [
        SheetSection(
          title: 'Must have',
          subtitle: 'She logs in with this mobile number. We check it is not already used.',
          children: [
            LabeledField(label: 'Full name *', controller: _name, onChanged: (_) => setState(() {})),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField(label: 'Mobile *', controller: _mobile, prefix: '+91', keyboardType: TextInputType.phone, onChanged: (_) => setState(() {})),
                const SizedBox(height: 6),
                const OkLine('No client or sign-up with this number'),
              ],
            ),
          ],
        ),
        SheetSection(
          title: 'Good to have',
          subtitle: 'She can fill or change these herself in the app.',
          children: [
            LabeledField(label: 'Email', controller: _email, hint: 'For login links and receipts', keyboardType: TextInputType.emailAddress),
            PickerField(label: 'Gender', value: _gender, options: const ['Female', 'Male', 'Other'], onChanged: (v) => setState(() => _gender = v)),
            const LabeledField(label: 'Date of birth', hint: 'DD / MM / YYYY', keyboardType: TextInputType.datetime),
            const LabeledField(label: 'City', initialValue: 'Bengaluru'),
          ],
        ),
        SheetSection(
          title: 'Goal and body',
          subtitle: 'Optional. If you leave these empty she fills them in onboarding.',
          children: [
            PickerField(label: 'Goal', value: _goal, options: _goals, onChanged: (v) => setState(() => _goal = v)),
            const Row(
              children: [
                Expanded(child: LabeledField(label: 'Goal weight', initialValue: '62 kg')),
                SizedBox(width: 10),
                Expanded(child: LabeledField(label: 'Height', initialValue: '160 cm')),
              ],
            ),
            const LabeledField(label: 'Current weight', initialValue: '68 kg'),
            const LabeledField(label: 'Injuries or health notes', hint: 'Back pain, thyroid, recent surgery…', maxLines: 2),
          ],
        ),
        SheetSection(
          title: 'Coaching',
          subtitle: 'Optional. Check-in forms are sent later from her profile, under Forms.',
          children: [
            PickerField(
              label: 'Trainer',
              value: _trainer,
              hint: 'You can change this later',
              options: [for (final t in AdminMock.trainerChoices) _trainerLabel(t)],
              onChanged: (v) => setState(() => _trainer = v),
            ),
            PickerField(label: 'Workout program', value: _program, placeholder: _program == 'Pick later', options: _programs, onChanged: (v) => setState(() => _program = v)),
            PickerField(label: 'Meal plan', value: _meal, placeholder: _meal == 'Pick later', options: _mealPlans, onChanged: (v) => setState(() => _meal = v)),
            const LabeledField(label: 'Plans start on', initialValue: 'Mon, 12 Oct', help: 'Her day 1 for workout and meal plans'),
          ],
        ),
        SheetSection(
          title: 'Access',
          children: [
            SegmentedTabs<bool>(
              items: const [(true, 'Active now'), (false, 'Send to Approvals')],
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            Text(
              _active ? 'She can log in as soon as she opens the link.' : 'She shows up in Approvals first, like people who sign up with a link.',
              style: AppText.caption.copyWith(fontSize: 12.5),
            ),
            const SwitchRow(title: 'Send her the login link', subtitle: 'WhatsApp and email. She sets her own password.', initial: true),
            const SwitchRow(title: 'Ask her to fill the health form (PAR-Q)', subtitle: 'Shown on her first login', initial: true),
          ],
        ),
      ],
    );
  }
}
