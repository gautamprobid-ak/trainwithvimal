import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/core/widgets/widgets.dart';
import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

import '../dashboard/trainer_widgets.dart';
import 'checkin_review_state.dart';

/// Pieces of a check-in review, used by the Check-ins tab and the dashboard sheet.

Color? trendColor(Trend? t) => switch (t) { Trend.up => const Color(0xFF027A48), Trend.down => const Color(0xFFB42318), null => null };

/// Top numbers (dr-kpis): 4 columns split by thin lines.
class CheckinKpiRow extends StatelessWidget {
  const CheckinKpiRow(this.kpis, {super.key, this.colored = true});
  final List<CheckinKpi> kpis;
  final bool colored;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < kpis.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1, color: AppColors.line),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 10, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kpis[i].label,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(kpis[i].value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800, color: colored ? trendColor(kpis[i].trend) : null)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Answers compared with last time (dr-qa).
class CheckinAnswers extends StatelessWidget {
  const CheckinAnswers(this.answers, {super.key, this.colored = true});
  final List<CheckinAnswer> answers;
  final bool colored;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < answers.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.line))),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(answers[i].label, style: AppText.secondary.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(answers[i].value, style: AppText.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600))),
                Text('last ${answers[i].last}',
                    style: AppText.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: (colored ? trendColor(answers[i].trend) : null) ?? AppColors.muted)),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Riya wrote" quote (dr-quote).
class CheckinNote extends StatelessWidget {
  const CheckinNote({super.key, required this.first, required this.note});
  final String first;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$first wrote', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(note, style: AppText.body.copyWith(fontSize: 13, color: AppColors.text2, height: 1.5)),
        ],
      ),
    );
  }
}

/// Section heading inside a review (h4 + caption on the right).
class ReviewHeading extends StatelessWidget {
  const ReviewHeading(this.title, {super.key, this.caption, this.info});
  final String title;
  final String? caption;
  final String? info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.bodyBold.copyWith(fontSize: 13.5))),
          if (caption != null) Text(caption!, style: AppText.caption),
          if (info != null)
            Tooltip(
              message: info!,
              triggerMode: TooltipTriggerMode.tap,
              child: const Icon(Icons.info_outline_rounded, size: 17, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// Reply box with quick replies (dr-reply). Keeps the text in [checkinReviewProvider].
class CheckinReplyBox extends ConsumerStatefulWidget {
  const CheckinReplyBox({super.key, required this.checkin});
  final TrainerCheckin checkin;

  @override
  ConsumerState<CheckinReplyBox> createState() => _CheckinReplyBoxState();
}

class _CheckinReplyBoxState extends ConsumerState<CheckinReplyBox> {
  late final _ctrl = TextEditingController(text: ref.read(checkinReviewProvider).replyOf(widget.checkin.id));

  @override
  void didUpdateWidget(covariant CheckinReplyBox old) {
    super.didUpdateWidget(old);
    if (old.checkin.id != widget.checkin.id) _ctrl.text = ref.read(checkinReviewProvider).replyOf(widget.checkin.id);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pick(String t) {
    _ctrl.text = t;
    ref.read(checkinReviewProvider.notifier).setReply(widget.checkin.id, t);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          minLines: 3,
          maxLines: 5,
          style: AppText.body,
          onChanged: (v) => ref.read(checkinReviewProvider.notifier).setReply(widget.checkin.id, v),
          decoration: InputDecoration(hintText: 'Write a short reply for ${widget.checkin.firstName}…'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final q in TrainerMock.quickReplies) CountChip(q, selected: false, onTap: () => _pick(q))],
        ),
      ],
    );
  }
}

/// The body of a check-in review: numbers, answers, note, photos.
class CheckinReviewBody extends StatelessWidget {
  const CheckinReviewBody({super.key, required this.checkin, this.onPhoto, this.colored = true, this.alwaysShowPhotos = false});
  final TrainerCheckin checkin;
  final ValueChanged<int>? onPhoto;
  final bool colored;

  /// Dashboard sheet shows the Photos section even when there are none.
  final bool alwaysShowPhotos;

  @override
  Widget build(BuildContext context) {
    final c = checkin;
    final hasPh = c.photos.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckinKpiRow(c.kpis, colored: colored),
        const SizedBox(height: 14),
        ReviewHeading('Answers', caption: 'Compared with last time'),
        CheckinAnswers(c.answers, colored: colored),
        if (c.note.isNotEmpty) ...[const SizedBox(height: 14), CheckinNote(first: c.firstName, note: c.note)],
        if (hasPh || alwaysShowPhotos) ...[
          const SizedBox(height: 16),
          ReviewHeading('Photos', caption: hasPh ? '${c.photos.length} new${onPhoto != null ? ' · tap to open' : ''}' : 'No photos this time'),
          if (hasPh)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < c.photos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    PhotoTile(c.photos[i], tone: i, onTap: onPhoto == null ? null : () => onPhoto!(i)),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}
