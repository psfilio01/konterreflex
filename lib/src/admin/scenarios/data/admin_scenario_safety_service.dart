import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';

class AdminScenarioSafetyService {
  AdminScenarioSafetyService(
      {required AiGateway ai, required AdminScenarioRepository repository})
      : _ai = ai,
        _repository = repository;
  final AiGateway _ai;
  final AdminScenarioRepository _repository;

  Future<ScenarioSafetyReview> review(AdminScenario scenario) async {
    if (scenario.id == null) throw StateError('Save the draft before review.');
    final result = await _ai.invoke(task: 'scenario.safety_review', payload: {
      'scenario': {
        'title': scenario.title,
        'category': scenario.category,
        'moderator_intro': scenario.moderatorIntro,
        'trigger_statement': scenario.triggerStatement,
        'underlying_intent': scenario.underlyingIntent,
        'evaluation_focus': scenario.evaluationFocus,
        'characters': [
          for (final character in scenario.characters)
            {'name': character.name, 'description': character.description}
        ],
        'turns': [
          for (final turn in scenario.turns)
            {
              'character_name': turn.characterName,
              'body': turn.body,
              'stage_direction': turn.stageDirection
            }
        ],
      },
    });
    final review = ScenarioSafetyReview.fromGateway(
        data: result.data,
        provider: result.provider,
        model: result.model,
        promptVersion: result.promptVersion);
    await _repository.saveSafetyReview(
        scenarioId: scenario.id!,
        contentRevision: scenario.contentRevision,
        review: review);
    return review;
  }
}
