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
        home: Scaffold(body: QualitativeFeedbackCard(feedback: feedback)),
      ),
    );

    expect(find.text('Klar positioniert'), findsOneWidget);
    expect(find.text('Nächster Schritt'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+\s*(/|%|Punkte)')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

Map<String, dynamic> validFeedbackData() => {
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
