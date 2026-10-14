import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:train_with_vimal/app/router.dart';
import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../checkins/checkin_review_state.dart';
import '../checkins/checkin_review_view.dart';
import 'trainer_widgets.dart';

/// Notifications list (td-notes). [onReadAll] clears the bell dot.
Future<void> showTrainerNotices(BuildContext context, {required bool unread, required VoidCallback onReadAll}) {
  var isUnread = unread;
  return showAppSheet(
    context,
    title: 'Notifications',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isUnread)
            Align(
              alignment: Alignment.centerRight,
              child: LinkButton('Mark all read', onTap: () {
                onReadAll();
                set(() => isUnread = false);
              }),
            ),
          for (final n in TrainerMock.notices)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isUnread ? AppColors.hover : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Avatar(n.initials, size: 30, color: n.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.text, style: AppText.body.copyWith(fontSize: 13, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500)),
                        Text(n.when, style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// What the New session sheet returns.
class NewSessionResult {
  const NewSessionResult(this.client, this.minutes, this.videoCall, this.note);
  final String client;
  final int minutes;
  final bool videoCall;
  final String note;
}

/// "New session" modal from the dashboard hero.
Future<NewSessionResult?> showNewSessionSheet(BuildContext context) {
  return showModalBottomSheet<NewSessionResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _NewSessionSheet(),
  );
}

class _NewSessionSheet extends StatefulWidget {
  const _NewSessionSheet();
  @override
  State<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<_NewSessionSheet> {
  String _client = 'Neha Jain';
  int _len = 2;
  int _where = 0;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const TintIcon(Icons.event_rounded, tint: Tint.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New session', style: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('Shows in your calendar and the client’s app.', style: AppText.secondary.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectField(
              label: 'Client',
              value: _client,
              onTap: () async {
                final v = await pickOption(context, title: 'Client', options: TrainerMock.bookableClients, current: _client);
                if (v != null) setState(() => _client = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SelectField(label: 'Day', value: 'Today, 8 Oct', onTap: () => _fixed(context, 'Day'))),
                const SizedBox(width: 10),
                Expanded(child: SelectField(label: 'Time', value: '17:30', onTap: () => _fixed(context, 'Time'))),
              ],
            ),
            const SizedBox(height: 12),
            _label('Length'),
            PillTabs(
              labels: [for (final m in TrainerMock.newSessionLengths) '$m min'],
              index: _len,
              onChanged: (i) => setState(() => _len = i),
            ),
            const SizedBox(height: 12),
            _label('Where'),
            PillTabs(labels: TrainerMock.newSessionPlaces, index: _where, onChanged: (i) => setState(() => _where = i)),
            const SizedBox(height: 12),
            LabeledField(label: 'Note for the client', hint: 'Bring your lifting belt', controller: _note),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.of(context).pop())),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    'Add session',
                    onPressed: () => Navigator.of(context).pop(
                      NewSessionResult(_client, TrainerMock.newSessionLengths[_len], _where == 1, _note.text),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppText.secondary.copyWith(fontWeight: FontWeight.w700, color: AppColors.text2)),
      );

  void _fixed(BuildContext context, String what) =>
      showToast(context, 'Kept today at 17:30', subtitle: 'For another ${what.toLowerCase()}, use Calendar › New session');
}

/// Review drawer for one check-in from the dashboard.
Future<void> showCheckinReviewSheet(BuildContext context, WidgetRef ref, TrainerCheckin c) {
  return showAppSheet(
    context,
    title: '${c.firstName}’s ${c.kindLabel.toLowerCase()}',
    subtitle: 'Sent ${c.age} ago · ${c.line.split(' · ').first}',
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.outline('Open profile', icon: Icons.person_outline_rounded, small: true, onPressed: () {
            Navigator.of(ctx).pop();
            context.push(Routes.tClient(c.clientId ?? TrainerMock.clientIdFor(c.client)));
          }),
        ),
        const SizedBox(height: 14),
        CheckinReviewBody(checkin: c, colored: false, alwaysShowPhotos: true),
        const SizedBox(height: 16),
        const ReviewHeading('Reply', info: 'The client gets your reply in the app with their check-in. You can edit their plan from their profile.'),
        CheckinReplyBox(checkin: c),
      ],
    ),
    actions: (ctx) => [
      AppButton.outline('Close', onPressed: () => Navigator.of(ctx).pop()),
      Consumer(
        builder: (_, r, _) {
          final hasReply = r.watch(checkinReviewProvider).replyOf(c.id).trim().isNotEmpty;
          return AppButton(
            hasReply ? 'Send and mark reviewed' : 'Mark reviewed',
            icon: Icons.check_rounded,
            onPressed: () {
              Navigator.of(ctx).pop();
              final before = ref.read(checkinReviewProvider.notifier).markReviewed(c.id);
              showToast(
                context,
                '${c.firstName}’s check-in reviewed',
                subtitle: hasReply ? 'Your reply was sent' : 'Moved out of your list',
                kind: ToastKind.ok,
                onUndo: () => ref.read(checkinReviewProvider.notifier).restore(before),
              );
            },
          );
        },
      ),
    ],
  );
}
