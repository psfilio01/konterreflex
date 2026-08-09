import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_safety_service.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';

void main() {
  test('realistic hostile training material can pass without being endorsed',
      () async {
    final repository = _Repository();
    final service = AdminScenarioSafetyService(
        ai: _Ai({
          'decision': 'pass',
          'findings': ['Feindselige Aussage ist klarer Trainingsgegenstand.'],
          'rationale': 'Die Szene simuliert den Satz, ohne ihn gutzuheißen.',
          'hostile_content_as_training': true,
          'protected_trait_linkage': false,
          'stereotype_risk': false,
        }),
        repository: repository);
    final result = await service.review(scenario);
    expect(result.decision, 'pass');
    expect(result.hostileContentAsTraining, isTrue);
    expect(repository.savedRevision, 3);
  });

  test('protected-trait behavior linkage is retained as a blocking finding',
      () async {
    final service = AdminScenarioSafetyService(
        ai: _Ai({
          'decision': 'block',
          'findings': ['Verhalten wird mit einem geschützten Merkmal erklärt.'],
          'rationale': 'Die Rollenkonstruktion ist diskriminierend.',
          'hostile_content_as_training': false,
          'protected_trait_linkage': true,
          'stereotype_risk': true,
        }),
        repository: _Repository());
    final result = await service.review(scenario);
    expect(result.decision, 'block');
    expect(result.protectedTraitLinkage, isTrue);
  });
}

const scenario = AdminScenario(
  id: 'scenario-1',
  title: 'Grenze setzen',
  category: 'Arbeit',
  moderatorIntro: 'Eine Person reagiert abwertend.',
  triggerStatement: 'Jetzt stell dich nicht so an.',
  underlyingIntent: 'Die Aussage spielt das Anliegen herunter.',
  evaluationFocus: ['ruhige Grenze'],
  characters: [AdminCharacter(name: 'Alex', description: 'Teammitglied')],
  turns: [
    AdminTurn(
        characterName: 'Alex',
        body: 'Jetzt stell dich nicht so an.',
        stageDirection: '')
  ],
  contentRevision: 3,
);

class _Ai implements AiGateway {
  _Ai(this.data);
  final Map<String, dynamic> data;
  @override
  Future<AiGatewayResult> invoke(
          {required String task,
          required Map<String, dynamic> payload}) async =>
      AiGatewayResult(
          data: data,
          provider: 'mock',
          model: 'mock',
          promptVersion: 'scenario_safety_review_v1');
}

class _Repository implements AdminScenarioRepository {
  int? savedRevision;
  @override
  Future<List<AdminScenario>> fetchAll() async => [];
  @override
  Future<String> saveDraft(AdminScenario scenario) async => 'scenario-1';
  @override
  Future<void> review(List<String> ids, AdminScenarioStatus status,
      {String? reason, String? batchId}) async {}
  @override
  Future<void> audit(
      {required String action,
      required List<String> scenarioIds,
      String? batchId,
      Map<String, dynamic> detail = const {}}) async {}
  @override
  Future<void> saveSafetyReview(
      {required String scenarioId,
      required int contentRevision,
      required ScenarioSafetyReview review}) async {
    savedRevision = contentRevision;
  }
}
