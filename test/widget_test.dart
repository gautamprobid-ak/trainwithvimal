import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_with_vimal/app/app.dart';

void main() {
  testWidgets('app boots on the welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TrainWithVimalApp()));
    await tester.pump();
    expect(find.byType(TrainWithVimalApp), findsOneWidget);
  });
}
