import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

/// All automations. Shared by the list and the builder so saving in the
/// builder shows up in the list after going back.
class AutomationsNotifier extends Notifier<List<Automation>> {
  int _seq = 0;

  @override
  List<Automation> build() => EngageMock.automations;

  Automation? byId(String id) {
    for (final a in state) {
      if (a.id == id) return a;
    }
    return null;
  }

  void restore(List<Automation> previous) => state = previous;

  String newId() => 'a-new-${++_seq}';

  void setStatus(String id, AutoStatus s) => state = [for (final a in state) a.id == id ? a.copyWith(status: s) : a];

  /// Copies an automation as a draft at the end of the list.
  void duplicate(String id) {
    final a = byId(id)!;
    state = [
      ...state,
      a.copyWith(id: '${a.id}c${++_seq}', name: '${a.name} (copy)', status: AutoStatus.draft, changed: 'just now', running: 0, finished: 0),
    ];
  }

  void delete(String id) => state = [
    for (final a in state)
      if (a.id != id) a,
  ];

  /// Adds or replaces an automation (new ones go to the top).
  void save(Automation a) {
    final exists = state.any((x) => x.id == a.id);
    state = exists ? [for (final x in state) x.id == a.id ? a : x] : [a, ...state];
  }
}

final automationsProvider = NotifierProvider<AutomationsNotifier, List<Automation>>(AutomationsNotifier.new);
