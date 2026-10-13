import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/engage_mock.dart';
import 'package:train_with_vimal/data/models/engage.dart';

/// All forms & check-ins. Shared by the list and the builder so edits made in
/// the builder show up in the list after going back.
class FormsNotifier extends Notifier<List<FormDef>> {
  int _seq = 0;

  @override
  List<FormDef> build() => EngageMock.forms;

  FormDef? byId(String id) {
    for (final f in state) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Puts back an earlier list (undo).
  void restore(List<FormDef> previous) => state = previous;

  String _newId(String base) => '$base-${++_seq}';

  /// Creates a draft form and returns its id.
  String create({required FormKind kind, required String name, required bool fromTemplate}) {
    final id = _newId('f-new');
    final f = FormDef(
      id: id,
      name: name.trim().isEmpty ? kind.label : name.trim(),
      kind: kind,
      updated: 'just now',
      questions: fromTemplate ? EngageMock.templateFor(kind) : const [],
    );
    state = [f, ...state];
    return id;
  }

  /// Copies a form as a draft at the top of the list and returns the new id.
  String duplicate(String id) {
    final f = byId(id)!;
    final copy = f.copyWith(id: _newId('${f.id}c'), name: '${f.name} (copy)', automations: const [], published: false, updated: 'just now', archived: false);
    state = [copy, ...state];
    return copy.id;
  }

  void setArchived(String id, bool archived) => _edit(id, (f) => f.copyWith(archived: archived), touch: false);

  void delete(String id) => state = [for (final f in state) if (f.id != id) f];

  void setPublished(String id, bool published) => _edit(id, (f) => f.copyWith(published: published), touch: false);

  void rename(String id, String name) => _edit(id, (f) => f.copyWith(name: name));

  void setKind(String id, FormKind kind) => _edit(id, (f) => f.copyWith(kind: kind));

  /// Replaces the questions. Any change moves a published form back to draft,
  /// as in the design.
  void setQuestions(String id, List<FormQuestion> questions, {bool toDraft = false}) =>
      _edit(id, (f) => f.copyWith(questions: questions, published: toDraft ? false : f.published));

  void _edit(String id, FormDef Function(FormDef) fn, {bool touch = true}) {
    state = [
      for (final f in state)
        if (f.id == id) (touch ? fn(f).copyWith(updated: 'just now') : fn(f)) else f,
    ];
  }
}

final formsProvider = NotifierProvider<FormsNotifier, List<FormDef>>(FormsNotifier.new);
