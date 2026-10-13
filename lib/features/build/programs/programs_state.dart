import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/programs_mock.dart';
import 'package:train_with_vimal/data/models/programs.dart';

/// Master programs (Programs list + Program builder). Shared by the admin and
/// trainer apps, kept alive so edits survive navigation.
class ProgramsNotifier extends Notifier<List<Program>> {
  @override
  List<Program> build() => ProgramsMock.programs;

  Program? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Adds a program at the top of the list.
  void add(Program p) => state = [p, ...state];

  /// Replaces the program with the same id.
  void put(Program p) => state = [for (final q in state) q.id == p.id ? p : q];

  void remove(String id) => state = state.where((p) => p.id != id).toList();

  /// Puts back an earlier snapshot (Undo).
  void restore(List<Program> snapshot) => state = snapshot;

  String newId() => 'p${DateTime.now().microsecondsSinceEpoch}';

  /// Creates a program from the New program modal: the first [daysPerWeek]
  /// days are workout days, the other days start as rest days.
  Program create({required String name, required int weeks, required int daysPerWeek}) {
    final p = Program(
      id: newId(),
      name: name,
      goal: 'New program · $daysPerWeek ${daysPerWeek == 1 ? 'day' : 'days'}',
      weeks: weeks,
      days: [
        for (var i = 0; i < 7; i++)
          i < daysPerWeek ? ProgramDay(id: 'n$i', title: 'Day ${i + 1}') : ProgramDay(id: 'n$i', title: 'Rest', rest: true),
      ],
      clients: const [],
      edited: 'just now',
      tone: state.length % 4 + 1,
    );
    add(p);
    return p;
  }

  Program duplicate(Program p) {
    final copy = p.copyWith(id: newId(), name: '${p.name} (copy)', clients: const [], edited: 'just now', archived: false);
    add(copy);
    return copy;
  }
}

final programsProvider = NotifierProvider<ProgramsNotifier, List<Program>>(ProgramsNotifier.new);

/// Which program the builder shows (the route has no id; Programs sets it before opening).
class SelectedProgramNotifier extends Notifier<String> {
  @override
  String build() => 'p1';

  void select(String id) => state = id;
}

final selectedProgramProvider = NotifierProvider<SelectedProgramNotifier, String>(SelectedProgramNotifier.new);
