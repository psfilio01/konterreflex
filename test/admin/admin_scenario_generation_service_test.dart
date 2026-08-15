import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_generation_service.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';

void main() {
  test(
      'batch generation persists every result as draft and writes a batch audit',
      () async {
    final repository = _Repository();
    final service = AdminScenarioGenerationService(
        ai: _Ai(), repository: repository, createBatchId: () => 'batch-1');
    final ids =
        await service.generateDrafts(request: 'Teamgespräche', count: 6);
    expect(ids, hasLength(6));
    expect(
        repository.saved,
        everyElement(predicate<AdminScenario>((item) =>
            item.status == AdminScenarioStatus.draft &&
            item.source == 'generated')));
    expect(repository.auditAction, 'generate_batch');
    expect(repository.auditIds, ids);
    expect(repository.auditBatch, 'batch-1');
  });

  test('batch generation rejects counts above the reviewed maximum', () async {
    final service =
        AdminScenarioGenerationService(ai: _Ai(), repository: _Repository());
    expect(() => service.generateDrafts(request: 'Test', count: 51),
        throwsRangeError);
  });
}

class _Ai implements AiGateway {
  int index = 0;
  @override
  Future<AiGatewayResult> invoke(
      {required String task, required Map<String, dynamic> payload}) async {
    index += 1;
    return AiGatewayResult(data: {
      'title': 'Entwurf $index',
      'category': 'Arbeit',
      'moderator_intro':
          'Du sitzt nach einem langen Termin mit einem Teammitglied in einem ruhigen Besprechungsraum. Ihr habt gerade über einen wichtigen Vorschlag gesprochen, als die andere Person deinen Beitrag vor der Gruppe offen infrage stellt.',
      'response_cue': 'Was antwortest du?',
      'trigger_statement': 'Was ist dein Punkt?',
      'underlying_intent': 'Die Aussage fordert eine klare Position.',
      'evaluation_focus': ['Präzision'],
      'characters': [
        {'name': 'Alex', 'description': 'Teammitglied'}
      ],
      'turns': [
        {
          'character_name': 'Alex',
          'body': 'Was ist dein Punkt?',
          'stage_direction': 'Alex schaut dich direkt an und fragt ruhig:'
        }
      ],
    }, provider: 'mock', model: 'mock', promptVersion: 'scenario_generate_v1');
  }
}

class _Repository implements AdminScenarioRepository {
  final saved = <AdminScenario>[];
  String? auditAction;
  List<String>? auditIds;
  String? auditBatch;
  @override
  Future<List<AdminScenario>> fetchAll() async => saved;
  @override
  Future<String> saveDraft(AdminScenario scenario) async {
    saved.add(scenario);
    return 'scenario-${saved.length}';
  }

  @override
  Future<void> review(List<String> ids, AdminScenarioStatus status,
      {String? reason, String? batchId}) async {}
  @override
  Future<void> audit(
      {required String action,
      required List<String> scenarioIds,
      String? batchId,
      Map<String, dynamic> detail = const {}}) async {
    auditAction = action;
    auditIds = scenarioIds;
    auditBatch = batchId;
  }

  @override
  Future<void> saveSafetyReview(
      {required String scenarioId,
      required int contentRevision,
      required ScenarioSafetyReview review}) async {}
}
