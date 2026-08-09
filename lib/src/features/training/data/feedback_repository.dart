import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FeedbackRepository {
  Future<QualitativeFeedback> evaluate({
    required TrainingScenario scenario,
    required String transcript,
  });

  Future<void> save({
    required String responseId,
    required QualitativeFeedback feedback,
  });

  Future<String> answerFollowUp({
    required TrainingScenario scenario,
    required QualitativeFeedback feedback,
    required String question,
  });
}

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository({
    required SupabaseClient client,
    required AiGateway ai,
  })  : _client = client,
        _ai = ai;

  final SupabaseClient _client;
  final AiGateway _ai;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required.');
    return id;
  }

  @override
  Future<QualitativeFeedback> evaluate({
    required TrainingScenario scenario,
    required String transcript,
  }) async {
    final result = await _ai.invoke(
      task: 'response.evaluate',
      payload: {
        'scenario': {
          'title': scenario.title,
          'category': scenario.category,
          'moderator_intro': scenario.moderatorIntro,
          'actor_turns': scenario.turns.map((turn) => turn.body).toList(),
        },
        'spoken_response': transcript,
      },
    );
    return QualitativeFeedback.fromGateway(
      data: result.data,
      provider: result.provider,
      model: result.model,
      promptVersion: result.promptVersion,
    );
  }

  @override
  Future<void> save({
    required String responseId,
    required QualitativeFeedback feedback,
  }) async {
    await _client.from('feedback').upsert({
      'response_id': responseId,
      'user_id': _userId,
      'headline': feedback.headline,
      'explanation': feedback.explanation,
      'strengths': feedback.strengths,
      'improvement': feedback.improvement,
      'alternatives': feedback.alternatives,
      'dimensions': feedback.dimensions.toJson(),
      'model_meta': {
        'provider': feedback.provider,
        'model': feedback.model,
        'prompt_version': feedback.promptVersion,
      },
    }, onConflict: 'response_id');
  }

  @override
  Future<String> answerFollowUp({
    required TrainingScenario scenario,
    required QualitativeFeedback feedback,
    required String question,
  }) async {
    final result = await _ai.invoke(
      task: 'conversation.reply',
      payload: {
        'scenario_title': scenario.title,
        'feedback': {
          'headline': feedback.headline,
          'explanation': feedback.explanation,
          'improvement': feedback.improvement,
        },
        'spoken_question': question,
      },
    );
    final reply = result.data['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const FormatException('Invalid follow-up reply.');
    }
    return reply.trim();
  }
}
