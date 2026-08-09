import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

void main() {
  for (final state in IntelligenceOrbState.values) {
    testWidgets('renders ${state.name} with icon, text and semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IntelligenceOrb(state: state)),
        ),
      );

      expect(find.byIcon(state.icon), findsOneWidget);
      expect(find.text(state.label), findsOneWidget);
      expect(find.bySemanticsLabel(state.label), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('reduced motion keeps an active state visually still', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: IntelligenceOrb(state: IntelligenceOrbState.speaking),
          ),
        ),
      ),
    );
    final before = tester
        .widget<Transform>(
          find.byKey(const Key('intelligence-orb-motion')),
        )
        .transform
        .clone();

    await tester.pump(const Duration(milliseconds: 700));

    final after = tester
        .widget<Transform>(
          find.byKey(const Key('intelligence-orb-motion')),
        )
        .transform;
    expect(after, before);
  });
}
