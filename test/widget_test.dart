import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vargani_collection/main.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VarganiCollectionApp(),
      ),
    );

    expect(find.byType(VarganiCollectionApp), findsOneWidget);
    // Advance timers so splash navigation completes cleanly
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
  });
}
