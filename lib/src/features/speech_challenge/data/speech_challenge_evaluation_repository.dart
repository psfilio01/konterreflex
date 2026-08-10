import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';

abstract interface class SpeechChallengeEvaluationRepository {
  Future<ChallengeSessionResult> evaluate({
    required ChallengeSet challengeSet,
    required List<ChallengeAnswer> answers,
  });
}

class AiSpeechChallengeEvaluationRepository
    implements SpeechChallengeEvaluationRepository {
  const AiSpeechChallengeEvaluationRepository(this._ai);

  final AiGateway _ai;

  @override
  Future<ChallengeSessionResult> evaluate({
    required ChallengeSet challengeSet,
    required List<ChallengeAnswer> answers,
  }) async {
    if (answers.isEmpty || answers.length > maxSpeechChallengePromptCount) {
      throw ArgumentError('Challenge answers must contain 1 to 15 items.');
    }
    final response = await _ai.invoke(
      task: 'response.evaluate_challenge_session',
      payload: {
        'theme': {
          'title': challengeSet.title,
          'description': challengeSet.description,
        },
        'answers': [
          for (final answer in answers)
            {
              'prompt': answer.prompt.remark,
              'context': answer.prompt.context,
              'spoken_response': answer.transcript,
            },
        ],
      },
    );
    return ChallengeSessionResult.fromGateway(
      data: response.data,
      answers: answers,
      provider: response.provider,
      model: response.model,
      promptVersion: response.promptVersion,
    );
  }
}
