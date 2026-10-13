import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/trainer_mock.dart';
import 'package:train_with_vimal/data/models/trainer_app.dart';

/// Which check-ins are reviewed and the replies typed so far.
/// Shared by the trainer dashboard ("Check-ins to review") and the Check-ins tab.
class CheckinReviewState {
  const CheckinReviewState({required this.done, required this.replies, required this.reviewedNow});

  final Set<String> done;

  /// Draft (or sent) replies by check-in id.
  final Map<String, String> replies;

  /// Check-ins reviewed in this session (shown as "Reviewed just now").
  final Set<String> reviewedNow;

  bool isDone(String id) => done.contains(id);
  String replyOf(String id) => replies[id] ?? '';

  /// Check-ins still to review, oldest first.
  List<TrainerCheckin> get toReview =>
      TrainerMock.checkins.where((c) => !done.contains(c.id)).toList()..sort((a, b) => b.hours.compareTo(a.hours));

  CheckinReviewState copyWith({Set<String>? done, Map<String, String>? replies, Set<String>? reviewedNow}) => CheckinReviewState(
        done: done ?? this.done,
        replies: replies ?? this.replies,
        reviewedNow: reviewedNow ?? this.reviewedNow,
      );
}

class CheckinReviewController extends Notifier<CheckinReviewState> {
  @override
  CheckinReviewState build() => CheckinReviewState(
        done: {for (final c in TrainerMock.checkins) if (c.reviewed) c.id},
        replies: const {},
        reviewedNow: const {},
      );

  void setReply(String id, String text) => state = state.copyWith(replies: {...state.replies, id: text});

  /// Marks a check-in reviewed and returns the state before, for Undo.
  CheckinReviewState markReviewed(String id) {
    final before = state;
    state = state.copyWith(done: {...state.done, id}, reviewedNow: {...state.reviewedNow, id});
    return before;
  }

  void reopen(String id) => state = state.copyWith(
        done: {...state.done}..remove(id),
        reviewedNow: {...state.reviewedNow}..remove(id),
      );

  void restore(CheckinReviewState s) => state = s;
}

final checkinReviewProvider = NotifierProvider<CheckinReviewController, CheckinReviewState>(CheckinReviewController.new);
