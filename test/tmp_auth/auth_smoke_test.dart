import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:train_with_vimal/app/app.dart';
import 'package:train_with_vimal/app/router.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final path in [
    '/welcome', '/login', '/reset-password', '/verify-email', '/join', '/permissions', '/intro',
    '/setup/health', '/setup/health?step=0', '/setup/health?step=1', '/setup/health?step=2', '/setup/health?step=4',
    '/setup/health?view=pending',
  ]) {
    testWidgets('renders $path', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      final c = ProviderContainer();
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const TrainWithVimalApp()));
      c.read(routerProvider).go(path);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 40));
    });
  }
}
