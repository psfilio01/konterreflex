import 'dart:convert';

import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';

class AdminScenarioImportService {
  AdminScenarioImportService({
    required AdminScenarioRepository repository,
    String Function()? createBatchId,
  })  : _repository = repository,
        _createBatchId = createBatchId ??
            (() => 'import-${DateTime.now().microsecondsSinceEpoch}');

  final AdminScenarioRepository _repository;
  final String Function() _createBatchId;

  Future<List<String>> importDrafts(String source) async {
    final batch = ScenarioImportBatch.parse(source);
    final batchId = _createBatchId();
    final ids = <String>[];
    for (final scenario in batch.scenarios) {
      ids.add(await _repository.saveDraft(scenario));
    }
    await _repository.audit(
      action: 'import_batch',
      scenarioIds: ids,
      batchId: batchId,
      detail: {
        'schema_version': ScenarioImportBatch.schemaVersion,
        'locale': batch.locale,
        'requested_count': batch.scenarios.length,
      },
    );
    return ids;
  }
}

class ScenarioImportBatch {
  const ScenarioImportBatch({required this.locale, required this.scenarios});

  static const schemaVersion = 'konterreflex.scenarios.v1';
  static const _batchKeys = {'schema_version', 'locale', 'scenarios'};
  static const _characterKeys = {'name', 'description'};
  static const _turnKeys = {
    'character_name',
    'body',
    'stage_direction',
  };

  factory ScenarioImportBatch.parse(String source) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Der Import ist kein gültiges JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('Der Import muss ein JSON-Objekt sein.');
    }
    final root = Map<String, dynamic>.from(decoded);
    _requireExactKeys(root, _batchKeys, 'Import');
    if (root['schema_version'] != schemaVersion) {
      throw const FormatException(
        'schema_version muss konterreflex.scenarios.v1 sein.',
      );
    }
    final locale = root['locale'];
    if (locale is! String || !const {'de', 'en'}.contains(locale)) {
      throw const FormatException('locale muss de oder en sein.');
    }
    final rawScenarios = root['scenarios'];
    if (rawScenarios is! List ||
        rawScenarios.isEmpty ||
        rawScenarios.length > 50) {
      throw const FormatException(
        'scenarios muss zwischen 1 und 50 Einträge enthalten.',
      );
    }

    final scenarios = <AdminScenario>[];
    for (var index = 0; index < rawScenarios.length; index += 1) {
      final number = index + 1;
      final raw = rawScenarios[index];
      if (raw is! Map) {
        throw FormatException('Szenario $number muss ein Objekt sein.');
      }
      final data = Map<String, dynamic>.from(raw);
      _validateNestedFields(data, number);
      final AdminScenario scenario;
      try {
        scenario = AdminScenario.fromGateway(
          data,
          locale: locale,
          source: 'imported',
        );
      } on Object {
        throw FormatException(
          'Szenario $number entspricht nicht dem erwarteten Datenformat.',
        );
      }
      _validateQuality(scenario, number);
      scenarios.add(scenario);
    }
    return ScenarioImportBatch(locale: locale, scenarios: scenarios);
  }

  final String locale;
  final List<AdminScenario> scenarios;

  static void _validateNestedFields(
    Map<String, dynamic> data,
    int number,
  ) {
    final characters = data['characters'];
    if (characters is! List || characters.isEmpty || characters.length > 4) {
      throw FormatException(
        'Szenario $number: characters muss 1 bis 4 Einträge enthalten.',
      );
    }
    for (var index = 0; index < characters.length; index += 1) {
      final character = characters[index];
      if (character is! Map) {
        throw FormatException(
          'Szenario $number: Figur ${index + 1} muss ein Objekt sein.',
        );
      }
      _requireExactKeys(
        Map<String, dynamic>.from(character),
        _characterKeys,
        'Szenario $number, Figur ${index + 1}',
      );
    }

    final turns = data['turns'];
    if (turns is! List || turns.isEmpty || turns.length > 8) {
      throw FormatException(
        'Szenario $number: turns muss 1 bis 8 Einträge enthalten.',
      );
    }
    for (var index = 0; index < turns.length; index += 1) {
      final turn = turns[index];
      if (turn is! Map) {
        throw FormatException(
          'Szenario $number: Satz ${index + 1} muss ein Objekt sein.',
        );
      }
      _requireExactKeys(
        Map<String, dynamic>.from(turn),
        _turnKeys,
        'Szenario $number, Satz ${index + 1}',
      );
    }

    final intro = data['moderator_intro'];
    if (intro is! String || _wordCount(intro) < 25 || _wordCount(intro) > 110) {
      throw FormatException(
        'Szenario $number: moderator_intro muss 25 bis 110 Wörter haben.',
      );
    }
    final responseCue = data['response_cue'];
    if (responseCue is! String ||
        _wordCount(responseCue) < 2 ||
        _wordCount(responseCue) > 16 ||
        !responseCue.trim().endsWith('?')) {
      throw FormatException(
        'Szenario $number: response_cue muss 2 bis 16 Wörter haben und mit ? enden.',
      );
    }
    final trigger = data['trigger_statement'];
    final finalTurn = Map<String, dynamic>.from(turns.last as Map);
    final direction = finalTurn['stage_direction'];
    if (direction is! String || direction.trim().isEmpty) {
      throw FormatException(
        'Szenario $number: Der letzte Satz braucht eine stage_direction.',
      );
    }
    if (trigger is! String ||
        finalTurn['body']?.toString().trim() != trigger.trim()) {
      throw FormatException(
        'Szenario $number: trigger_statement muss dem body des letzten Satzes entsprechen.',
      );
    }
  }

  static void _validateQuality(AdminScenario scenario, int number) {
    final titleWords = _wordCount(scenario.title);
    if (titleWords < 2 || titleWords > 8 || scenario.title.length > 80) {
      throw FormatException(
        'Szenario $number: title muss 2 bis 8 Wörter und höchstens 80 Zeichen haben.',
      );
    }
    if (scenario.category.isEmpty || scenario.category.length > 80) {
      throw FormatException(
        'Szenario $number: category muss 1 bis 80 Zeichen haben.',
      );
    }
    final introWords = _wordCount(scenario.moderatorIntro);
    if (introWords < 25 || introWords > 110) {
      throw FormatException(
        'Szenario $number: moderator_intro muss 25 bis 110 Wörter haben.',
      );
    }
    final cueWords = _wordCount(scenario.responseCue);
    if (cueWords < 2 || cueWords > 16 || !scenario.responseCue.endsWith('?')) {
      throw FormatException(
        'Szenario $number: response_cue muss 2 bis 16 Wörter haben und mit ? enden.',
      );
    }
    if (scenario.evaluationFocus.isEmpty ||
        scenario.evaluationFocus.length > 6 ||
        scenario.evaluationFocus.any((value) => value.trim().isEmpty)) {
      throw FormatException(
        'Szenario $number: evaluation_focus muss 1 bis 6 Texte enthalten.',
      );
    }

    final characterNames = <String>{};
    for (final character in scenario.characters) {
      if (character.name.isEmpty || character.description.isEmpty) {
        throw FormatException(
          'Szenario $number: Jede Figur braucht name und description.',
        );
      }
      if (!characterNames.add(character.name)) {
        throw FormatException(
          'Szenario $number: Figurennamen müssen eindeutig sein.',
        );
      }
    }

    for (var index = 0; index < scenario.turns.length; index += 1) {
      final turn = scenario.turns[index];
      if (!characterNames.contains(turn.characterName)) {
        throw FormatException(
          'Szenario $number: character_name in Satz ${index + 1} ist nicht definiert.',
        );
      }
      if (turn.body.isEmpty || _wordCount(turn.body) > 60) {
        throw FormatException(
          'Szenario $number: body in Satz ${index + 1} muss 1 bis 60 Wörter haben.',
        );
      }
      if (turn.stageDirection.isNotEmpty) {
        final directionWords = _wordCount(turn.stageDirection);
        if (directionWords < 4 || directionWords > 30) {
          throw FormatException(
            'Szenario $number: stage_direction in Satz ${index + 1} muss 4 bis 30 Wörter haben.',
          );
        }
      }
    }

    final finalTurn = scenario.turns.last;
    if (finalTurn.stageDirection.isEmpty) {
      throw FormatException(
        'Szenario $number: Der letzte Satz braucht eine stage_direction.',
      );
    }
    if (finalTurn.body.trim() != scenario.triggerStatement.trim()) {
      throw FormatException(
        'Szenario $number: trigger_statement muss dem body des letzten Satzes entsprechen.',
      );
    }
  }

  static void _requireExactKeys(
    Map<String, dynamic> value,
    Set<String> expected,
    String label,
  ) {
    final actual = value.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw FormatException('$label enthält fehlende oder unbekannte Felder.');
    }
  }

  static int _wordCount(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .length;
}
