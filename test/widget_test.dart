import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/app.dart';

void main() {
  testWidgets('shows the calm bootstrap home screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KonterreflexApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konterreflex'), findsOneWidget);
    expect(
      find.text('Hören. Reagieren. Reflektieren. Wiederholen.'),
      findsOneWidget,
    );
  });
}
