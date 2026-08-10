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

  testWidgets('voice activity expands the halo behind the orb', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              IntelligenceOrb(
                state: IntelligenceOrbState.speaking,
                activityLevel: 0.1,
              ),
              IntelligenceOrb(
                state: IntelligenceOrbState.listening,
                activityLevel: 0.9,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final halos = tester
        .widgetList<Transform>(find.byKey(const Key('voice-activity-halo')))
        .toList();
    expect(halos, hasLength(2));
    expect(halos[1].transform.storage[0],
        greaterThan(halos[0].transform.storage[0]));
  });

  testWidgets('preparing audio does not claim that voice is active', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntelligenceOrb(state: IntelligenceOrbState.preparing),
        ),
      ),
    );

    expect(find.text('Audio wird vorbereitet'), findsOneWidget);
    expect(find.byKey(const Key('voice-activity-halo')), findsNothing);
  });
}
