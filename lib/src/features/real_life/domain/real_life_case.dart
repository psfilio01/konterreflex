import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

class RealLifeParticipant {
  const RealLifeParticipant({required this.name, required this.relationship});

  final String name;
  final String relationship;
}

class RealLifeExtraction {
  const RealLifeExtraction({
    required this.setting,
    required this.participants,
    required this.statements,
    required this.triggerStatement,
    required this.observableTone,
    required this.emotionalSocialTension,
    required this.originalReaction,
    required this.unresolvedQuestions,
  });

  factory RealLifeExtraction.fromJson(Map<String, dynamic> json) {
    const keys = {
      'setting',
      'participants',
      'statements',
      'trigger_statement',
      'observable_tone',
      'emotional_social_tension',
      'original_reaction',
      'unresolved_questions',
    };
    if (json.keys.toSet().length != keys.length ||
        !json.keys.toSet().containsAll(keys)) {
      throw const FormatException('Invalid real-life extraction.');
    }
    final participants = json['participants'];
    final statements = json['statements'];
    final questions = json['unresolved_questions'];
    if (participants is! List || statements is! List || questions is! List) {
      throw const FormatException('Invalid real-life extraction lists.');
    }
    return RealLifeExtraction(
      setting: _text(json, 'setting'),
      participants: participants.map((item) {
        if (item is! Map) throw const FormatException('Invalid participant.');
        final data = Map<String, dynamic>.from(item);
        return RealLifeParticipant(
          name: _text(data, 'name'),
          relationship: _text(data, 'relationship'),
        );
      }).toList(),
      statements: statements.cast<String>(),
      triggerStatement: _text(json, 'trigger_statement'),
      observableTone: _text(json, 'observable_tone'),
      emotionalSocialTension: _text(json, 'emotional_social_tension'),
      originalReaction: _text(json, 'original_reaction'),
      unresolvedQuestions: questions.cast<String>().take(2).toList(),
    );
  }

  final String setting;
  final List<RealLifeParticipant> participants;
  final List<String> statements;
  final String triggerStatement;
  final String observableTone;
  final String emotionalSocialTension;
  final String originalReaction;
  final List<String> unresolvedQuestions;

  Map<String, dynamic> toJson() => {
        'setting': setting,
        'participants': [
          for (final participant in participants)
            {
              'name': participant.name,
              'relationship': participant.relationship
            },
        ],
        'statements': statements,
        'trigger_statement': triggerStatement,
        'observable_tone': observableTone,
        'emotional_social_tension': emotionalSocialTension,
        'original_reaction': originalReaction,
        'unresolved_questions': unresolvedQuestions,
      };
}

class RealLifeCaseRecord {
  const RealLifeCaseRecord({required this.id, required this.clientId});

  final String id;
  final String clientId;
}

class RealLifeReconstruction {
  const RealLifeReconstruction({required this.scenario});

  factory RealLifeReconstruction.fromJson(
    Map<String, dynamic> json, {
    required String id,
    String title = 'Deine echte Situation',
    String category = 'Echte Situation',
  }) {
    final rawCharacters = json['characters'];
    final rawTurns = json['turns'];
    if (rawCharacters is! List || rawTurns is! List) {
      throw const FormatException('Invalid reconstruction.');
    }
    final characters = <ScenarioCharacter>[];
    final idByName = <String, String>{};
    for (var index = 0; index < rawCharacters.length; index += 1) {
      final raw = rawCharacters[index];
      if (raw is! Map) throw const FormatException('Invalid character.');
      final data = Map<String, dynamic>.from(raw);
      final name = _text(data, 'name');
      final characterId = '$id-character-$index';
      idByName[name] = characterId;
      characters.add(
        ScenarioCharacter(
          id: characterId,
          name: name,
          description: _text(data, 'description'),
          sortOrder: index,
        ),
      );
    }
    final turns = <ScenarioTurn>[];
    for (var index = 0; index < rawTurns.length; index += 1) {
      final raw = rawTurns[index];
      if (raw is! Map) throw const FormatException('Invalid turn.');
      final data = Map<String, dynamic>.from(raw);
      turns.add(
        ScenarioTurn(
          characterId: idByName[_text(data, 'character_name')],
          body: _text(data, 'body'),
          stageDirection: _text(data, 'stage_direction'),
          sortOrder: index,
        ),
      );
    }
    return RealLifeReconstruction(
      scenario: TrainingScenario(
        id: id,
        title: title,
        category: category,
        moderatorIntro: _text(json, 'moderator_intro'),
        characters: characters,
        turns: turns,
      ),
    );
  }

  final TrainingScenario scenario;
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be text.');
  return value.trim();
}
