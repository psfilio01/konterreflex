import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

enum AdminScenarioStatus { draft, active, rejected, archived }

class AdminCharacter {
  const AdminCharacter(
      {required this.name, required this.description, this.voiceId});
  final String name;
  final String description;
  final String? voiceId;
}

class AdminTurn {
  const AdminTurn(
      {required this.characterName,
      required this.body,
      required this.stageDirection});
  final String characterName;
  final String body;
  final String stageDirection;
}

class AdminScenario {
  const AdminScenario({
    this.id,
    required this.title,
    required this.category,
    required this.moderatorIntro,
    required this.triggerStatement,
    required this.underlyingIntent,
    required this.evaluationFocus,
    required this.characters,
    required this.turns,
    this.status = AdminScenarioStatus.draft,
    this.source = 'manual',
  });

  factory AdminScenario.fromGateway(Map<String, dynamic> data) {
    const expected = {
      'title',
      'category',
      'moderator_intro',
      'trigger_statement',
      'underlying_intent',
      'evaluation_focus',
      'characters',
      'turns'
    };
    if (data.keys.toSet().length != expected.length ||
        !data.keys.toSet().containsAll(expected)) {
      throw const FormatException(
          'Generated scenario contains unsupported fields.');
    }
    final characters = (data['characters'] as List).map((item) {
      final value = Map<String, dynamic>.from(item as Map);
      return AdminCharacter(
          name: _text(value, 'name'), description: _text(value, 'description'));
    }).toList();
    final turns = (data['turns'] as List).map((item) {
      final value = Map<String, dynamic>.from(item as Map);
      return AdminTurn(
          characterName: _text(value, 'character_name'),
          body: _text(value, 'body'),
          stageDirection: _text(value, 'stage_direction'));
    }).toList();
    return AdminScenario(
      title: _text(data, 'title'),
      category: _text(data, 'category'),
      moderatorIntro: _text(data, 'moderator_intro'),
      triggerStatement: _text(data, 'trigger_statement'),
      underlyingIntent: _text(data, 'underlying_intent'),
      evaluationFocus: (data['evaluation_focus'] as List).cast<String>(),
      characters: characters,
      turns: turns,
      source: 'generated',
    );
  }

  factory AdminScenario.fromJson(Map<String, dynamic> json) {
    final rawCharacters = (json['scenario_characters'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList()
      ..sort(
          (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    final byId = {
      for (final character in rawCharacters)
        character['id'] as String: character['name'] as String
    };
    final rawTurns = (json['scenario_turns'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList()
      ..sort(
          (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    return AdminScenario(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      moderatorIntro: json['moderator_intro'] as String? ?? '',
      triggerStatement: json['trigger_statement'] as String? ?? '',
      underlyingIntent: json['underlying_intent'] as String? ?? '',
      evaluationFocus:
          (json['evaluation_focus'] as List? ?? const []).cast<String>(),
      status: AdminScenarioStatus.values.byName(json['status'] as String),
      source: json['source'] as String,
      characters: rawCharacters
          .map((item) => AdminCharacter(
              name: item['name'] as String,
              description: item['description'] as String? ?? '',
              voiceId: item['voice_id'] as String?))
          .toList(),
      turns: rawTurns
          .map((item) => AdminTurn(
              characterName: byId[item['character_id']] ?? '',
              body: item['body'] as String,
              stageDirection: item['stage_direction'] as String? ?? ''))
          .toList(),
    );
  }

  final String? id;
  final String title;
  final String category;
  final String moderatorIntro;
  final String triggerStatement;
  final String underlyingIntent;
  final List<String> evaluationFocus;
  final List<AdminCharacter> characters;
  final List<AdminTurn> turns;
  final AdminScenarioStatus status;
  final String source;

  TrainingScenario toTrainingScenario() {
    final actorByName = <String, ScenarioCharacter>{};
    for (var index = 0; index < characters.length; index++) {
      final character = characters[index];
      actorByName[character.name] = ScenarioCharacter(
          id: 'preview-$index',
          name: character.name,
          description: character.description,
          voiceId: character.voiceId,
          sortOrder: index);
    }
    return TrainingScenario(
      id: id ?? 'preview',
      title: title,
      category: category,
      moderatorIntro: moderatorIntro,
      characters: actorByName.values.toList(),
      turns: [
        for (var index = 0; index < turns.length; index++)
          ScenarioTurn(
              characterId: actorByName[turns[index].characterName]?.id,
              body: turns[index].body,
              stageDirection: turns[index].stageDirection,
              sortOrder: index)
      ],
    );
  }
}

String _text(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String) throw FormatException('$key must be text.');
  return value.trim();
}
