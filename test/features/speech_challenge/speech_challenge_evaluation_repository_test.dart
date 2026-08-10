import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_evaluation_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';

void main() {
  test('sends all answers through one approved batch task', () async {
    final gateway = _Gateway();
    final repository = AiSpeechChallengeEvaluationRepository(gateway);
    final answers = [
      ChallengeAnswer(
        prompt: challengeSet.prompts.first,
        responseId: 'response-1',
        transcript: 'Ich möchte den Gedanken zuerst beenden.',
      ),
    ];

    final result = await repository.evaluate(
      challengeSet: challengeSet,
      answers: answers,
    );

    expect(gateway.calls, 1);
    expect(gateway.task, 'response.evaluate_challenge_session');
    expect((gateway.payload?['answers'] as List), hasLength(1));
    expect(result.details.single.answer.responseId, 'response-1');
    expect(result.details.single.signal.wireName, 'strong');
  });
}

const challengeSet = ChallengeSet(
  id: 'set-1',
  title: 'Klare Grenzen',
  description: 'Kurz Grenzen setzen.',
  prompts: [
    ChallengePrompt(
      id: 'prompt-1',
      remark: 'Jetzt stell dich nicht so an.',
      context: 'Ein Anliegen wird heruntergespielt.',
      sortOrder: 0,
    ),
  ],
);

class _Gateway implements AiGateway {
  int calls = 0;
  String? task;
  Map<String, dynamic>? payload;

  @override
  Future<AiGatewayResult> invoke({
    required String task,
    required Map<String, dynamic> payload,
  }) async {
    calls += 1;
    this.task = task;
    this.payload = payload;
    return const AiGatewayResult(
      data: {
        'summary': summaryData,
        'details': [
          {
            'signal': 'strong',
            'headline': 'Klare Grenze',
            'strength': 'Die Position ist direkt.',
            'improvement': 'Nenne den gewünschten nächsten Schritt.',
            'alternative': 'Ich möchte den Gedanken zuerst beenden.',
          },
        ],
      },
      provider: 'mock',
      model: 'mock-v1',
      promptVersion: 'response_challenge_session_v1',
    );
  }
}

const summaryData = {
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
  'explanation': 'Die Antwort ist direkt und anschlussfähig.',
  'strengths': ['Ruhiger Einstieg'],
  'improvement': 'Mache den nächsten Schritt konkreter.',
  'alternatives': ['Ich sehe das anders und erkläre kurz, warum.'],
  'dimensions': {
    'posture': 'ruhig',
    'precision': 'klar',
    'frame': 'gesetzt',
    'social_effect': 'anschlussfähig',
    'naturalness': 'sprechbar',
    'escalation_fit': 'passend',
  },
};
