import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_import_service.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';

void main() {
  test('valid external batch is fully imported as localized drafts', () async {
    final repository = _Repository();
    final service = AdminScenarioImportService(
      repository: repository,
      createBatchId: () => 'import-1',
    );
    final source = _batch(
        [_validScenario(), _validScenario(title: 'Klare Grenze setzen')]);

    final ids = await service.importDrafts(source);

    expect(ids, ['scenario-1', 'scenario-2']);
    expect(repository.saved, hasLength(2));
    expect(
      repository.saved,
      everyElement(
        predicate<AdminScenario>(
          (scenario) =>
              scenario.status == AdminScenarioStatus.draft &&
              scenario.source == 'imported' &&
              scenario.locale == 'de' &&
              scenario.responseCue == 'Du bist dran. Was antwortest du?',
        ),
      ),
    );
    expect(repository.auditAction, 'import_batch');
    expect(repository.auditBatch, 'import-1');
    expect(repository.auditIds, ids);
    expect(repository.auditDetail, {
      'schema_version': ScenarioImportBatch.schemaVersion,
      'locale': 'de',
      'requested_count': 2,
    });
  });

  test('complete batch is validated before any draft is saved', () async {
    final repository = _Repository();
    final service = AdminScenarioImportService(repository: repository);
    final invalid = _validScenario(title: 'Ungültiger zweiter Entwurf');
    (invalid['turns'] as List).last['stage_direction'] = '';

    await expectLater(
      service.importDrafts(_batch([_validScenario(), invalid])),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('letzte Satz braucht eine stage_direction'),
        ),
      ),
    );
    expect(repository.saved, isEmpty);
  });

  test('unknown fields and unclear response cues are rejected', () {
    final withUnknownField = _validScenario()..['score'] = 10;
    expect(
      () => ScenarioImportBatch.parse(_batch([withUnknownField])),
      throwsFormatException,
    );

    final withoutQuestion = _validScenario()
      ..['response_cue'] = 'Du bist jetzt dran.';
    expect(
      () => ScenarioImportBatch.parse(_batch([withoutQuestion])),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('response_cue'),
        ),
      ),
    );
  });
}

String _batch(List<Map<String, dynamic>> scenarios) => jsonEncode({
      'schema_version': ScenarioImportBatch.schemaVersion,
      'locale': 'de',
      'scenarios': scenarios,
    });

Map<String, dynamic> _validScenario({
  String title = 'Vor Gruppe angezweifelt',
}) =>
    {
      'title': title,
      'category': 'Freundschaft · Gruppe',
      'moderator_intro':
          'Du sitzt nach einem langen Termin mit einem Teammitglied in einem ruhigen Besprechungsraum. Ihr habt gerade über einen wichtigen Vorschlag gesprochen, als die andere Person deinen Beitrag vor der Gruppe offen infrage stellt.',
      'trigger_statement': 'Hast du überhaupt einen klaren Punkt?',
      'underlying_intent':
          'Die Frage kann den Beitrag unter sozialen Rechtfertigungsdruck setzen; die genaue Absicht bleibt offen.',
      'evaluation_focus': [
        'ruhige Präsenz',
        'klare Position',
        'passende Intensität',
      ],
      'response_cue': 'Du bist dran. Was antwortest du?',
      'characters': [
        {
          'name': 'Alex',
          'description': 'Ein direktes Teammitglied',
        },
      ],
      'turns': [
        {
          'character_name': 'Alex',
          'body': 'Hast du überhaupt einen klaren Punkt?',
          'stage_direction':
              'Alex hält kurz inne, schaut dich direkt an und sagt:',
        },
      ],
    };

class _Repository implements AdminScenarioRepository {
  final saved = <AdminScenario>[];
  String? auditAction;
  String? auditBatch;
  List<String>? auditIds;
  Map<String, dynamic>? auditDetail;

  @override
  Future<List<AdminScenario>> fetchAll() async => saved;

  @override
  Future<String> saveDraft(AdminScenario scenario) async {
    saved.add(scenario);
    return 'scenario-${saved.length}';
  }

  @override
  Future<void> audit({
    required String action,
    required List<String> scenarioIds,
    String? batchId,
    Map<String, dynamic> detail = const {},
  }) async {
    auditAction = action;
    auditBatch = batchId;
    auditIds = scenarioIds;
    auditDetail = detail;
  }

  @override
  Future<void> review(
    List<String> ids,
    AdminScenarioStatus status, {
    String? reason,
    String? batchId,
  }) async {}

  @override
  Future<void> saveSafetyReview({
    required String scenarioId,
    required int contentRevision,
    required ScenarioSafetyReview review,
  }) async {}
}
