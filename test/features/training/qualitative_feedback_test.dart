import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_card.dart';

void main() {
  test('rejects numeric scoring fields even alongside valid feedback', () {
    final data = validFeedbackData()..['score'] = 8;

    expect(
      () => QualitativeFeedback.fromGateway(
        data: data,
        provider: 'mock',
        model: 'mock',
        promptVersion: 'response_evaluate_v1',
      ),
      throwsFormatException,
    );
  });

  test('rejects numeric values disguised as qualitative signals', () {
    final data = validFeedbackData()..['overall_signal'] = '8';

    expect(
      () => QualitativeFeedback.fromGateway(
        data: data,
        provider: 'mock',
        model: 'mock',
        promptVersion: 'response_evaluate_visual_v3',
      ),
      throwsFormatException,
    );
  });

  testWidgets('feedback card stays concise and contains no score UI', (
    tester,
  ) async {
    final feedback = QualitativeFeedback.fromGateway(
      data: validFeedbackData(),
      provider: 'mock',
      model: 'mock',
      promptVersion: 'response_evaluate_v1',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QualitativeFeedbackCard(feedback: feedback),
          ),
        ),
      ),
    );

    expect(find.text('Klar positioniert'), findsOneWidget);
    expect(find.byKey(const Key('feedback-overall-strong')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Auf einen Blick: Stark gelöst'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('feedback-dimension-precision-strong')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('feedback-dimension-frame-developing')),
      findsOneWidget,
    );
    expect(find.text('Nächster Schritt'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+\s*(/|%|Punkte)')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

Map<String, dynamic> validFeedbackData() => {
      'overall_signal': 'strong',
      'dimension_signals': {
        'posture': 'strong',
        'precision': 'strong',
        'frame': 'developing',
        'social_effect': 'strong',
        'naturalness': 'strong',
        'escalation_fit': 'developing',
      },
      'headline': 'Klar positioniert',
      'explanation': 'Dein Standpunkt ist sofort verständlich.',
      'strengths': ['Ruhiger Einstieg', 'Klare Aussage'],
      'improvement': 'Mach den gewünschten nächsten Schritt konkreter.',
      'alternatives': ['Ich sehe das anders und erkläre kurz, warum.'],
      'dimensions': {
        'posture': 'ruhig und souverän',
        'precision': 'direkt',
        'frame': 'neu gesetzt',
        'social_effect': 'anschlussfähig',
        'naturalness': 'gut sprechbar',
        'escalation_fit': 'passend',
      },
    };
