import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_focus_studio/main.dart';

void main() {
  testWidgets('Adaptive Focus Studio launches', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AdaptiveFocusStudio()),
    );

    // Let the first frame and post-frame database seeding start.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Focus Studio'), findsOneWidget);
  });
}
