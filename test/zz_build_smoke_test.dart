import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:train_with_vimal/features/build/exercises/exercise_add_screen.dart';
import 'package:train_with_vimal/features/build/exercises/exercise_detail_screen.dart';
import 'package:train_with_vimal/features/build/exercises/exercise_library_screen.dart';
import 'package:train_with_vimal/features/build/programs/program_builder_screen.dart';
import 'package:train_with_vimal/features/build/programs/programs_screen.dart';

Widget app(String path, Widget child) => ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(initialLocation: path, routes: [GoRoute(path: path, builder: (_, _) => Scaffold(body: child))]),
      ),
    );

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  final cases = {
    'programs': const ProgramsScreen(),
    'builder': const ProgramBuilderScreen(),
    'library': const ExerciseLibraryScreen(),
    'detail': const ExerciseDetailScreen(exerciseId: 'barbell-bench-press'),
    'add': const ExerciseAddScreen(),
  };
  for (final c in cases.entries) {
    testWidgets(c.key, (t) async {
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(app('/a/more/x', c.value));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
