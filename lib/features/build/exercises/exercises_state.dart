import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/programs_mock.dart';
import 'package:train_with_vimal/data/models/programs.dart';

/// The exercise library. New exercises show up in the library and in the
/// program builder's exercise picker.
class ExercisesNotifier extends Notifier<List<Exercise>> {
  @override
  List<Exercise> build() => ProgramsMock.exercises;

  void add(Exercise e) => state = [...state, e];

  void remove(String id) => state = state.where((e) => e.id != id).toList();

  void restore(List<Exercise> snapshot) => state = snapshot;
}

final exercisesProvider = NotifierProvider<ExercisesNotifier, List<Exercise>>(ExercisesNotifier.new);

extension ExerciseListX on List<Exercise> {
  Exercise? byId(String id) {
    for (final e in this) {
      if (e.id == id) return e;
    }
    return null;
  }

  Exercise? byName(String name) {
    for (final e in this) {
      if (e.name == name) return e;
    }
    return null;
  }
}
