import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
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

      if (state == IntelligenceOrbState.processingSpeech ||
          state == IntelligenceOrbState.processingSpeechComplete) {
        expect(
          find.byKey(const Key('speech-processing-spiral')),
          findsOneWidget,
        );
      } else {
        expect(find.byIcon(state.icon), findsOneWidget);
      }
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

  testWidgets('speech spiral grows outside-in and waits before the center', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntelligenceOrb(
            state: IntelligenceOrbState.processingSpeech,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    final growing = _spiralPainter(tester);
    expect(
      tester
          .getSize(find.byKey(const Key('speech-processing-spiral')))
          .shortestSide,
      greaterThan(120),
    );
    expect(growing.progress, greaterThan(0));
    expect(growing.progress, lessThan(0.85));
    expect(growing.sage, AppColors.sage);
    expect(growing.success, AppColors.success);

    await tester.pump(const Duration(milliseconds: 900));
    expect(_spiralPainter(tester).progress, closeTo(0.85, 0.001));
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });

  testWidgets('successful processing closes the spiral at the center', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntelligenceOrb(
            state: IntelligenceOrbState.processingSpeech,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntelligenceOrb(
            state: IntelligenceOrbState.processingSpeechComplete,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(_spiralPainter(tester).progress, closeTo(1, 0.001));
    expect(find.text('Antwort ist verarbeitet'), findsOneWidget);
  });

  testWidgets('reduced motion shows static spiral stages immediately', (
    tester,
  ) async {
    Future<void> show(IntelligenceOrbState state) => tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(body: IntelligenceOrb(state: state)),
            ),
          ),
        );

    await show(IntelligenceOrbState.processingSpeech);
    expect(_spiralPainter(tester).progress, closeTo(0.85, 0.001));
    expect(_spiralPainter(tester).pulse, 0);

    await show(IntelligenceOrbState.processingSpeechComplete);
    expect(_spiralPainter(tester).progress, closeTo(1, 0.001));
    expect(_spiralPainter(tester).pulse, 0);
  });

  testWidgets('generic thinking keeps the neutral dots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntelligenceOrb(state: IntelligenceOrbState.thinking),
        ),
      ),
    );

    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(
      find.byKey(const Key('speech-processing-spiral')),
      findsNothing,
    );
  });
}

SpeechProcessingSpiralPainter _spiralPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const Key('speech-processing-spiral')))
    .painter! as SpeechProcessingSpiralPainter;
