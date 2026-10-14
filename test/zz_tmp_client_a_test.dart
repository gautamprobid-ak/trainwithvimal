import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:train_with_vimal/features/client/home/client_home_screen.dart';
import 'package:train_with_vimal/features/client/train/client_train_screen.dart';
import 'package:train_with_vimal/features/client/progress/client_progress_screen.dart';
import 'package:train_with_vimal/features/client/progress/progress_state.dart';
import 'package:train_with_vimal/features/client/workout/workout_session.dart';
import 'package:train_with_vimal/features/client/workout/workout_panel.dart';
import 'package:train_with_vimal/features/client/workout/workout_done_view.dart';

Future<void> pump(WidgetTester t, Widget w, ProviderContainer c) async {
  t.view.physicalSize = const Size(390, 3000);
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: Scaffold(body: w))));
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('home', (t) async { final c = ProviderContainer(); await pump(t, const ClientHomeScreen(), c); c.dispose(); });
  testWidgets('train', (t) async { final c = ProviderContainer(); c.read(workoutSessionProvider.notifier).ensureStarted(); await pump(t, const ClientTrainScreen(), c); c.dispose(); });
  testWidgets('panel all exercises', (t) async {
    final c = ProviderContainer();
    c.read(workoutSessionProvider.notifier).ensureStarted();
    for (var i = 0; i < 4; i++) {
      c.read(workoutSessionProvider.notifier).goTo(i);
      await pump(t, ListView(padding: const EdgeInsets.all(16), children: [WorkoutPanel(key: ValueKey(i))]), c);
    }
    c.read(workoutSessionProvider.notifier).finish();
    await pump(t, WorkoutDoneView(onHome: () {}), c);
    c.dispose();
  });
  testWidgets('progress views', (t) async {
    final c = ProviderContainer();
    for (final v in ProgressView.values) {
      for (final tab in ['Weight', 'Body', 'Strength']) {
        c.read(progressProvider.notifier).set((s) => s.copyWith(view: v, tab: tab, compareOn: true));
        await pump(t, const ClientProgressScreen(), c);
      }
    }
    c.dispose();
  });
}
