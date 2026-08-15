import 'package:konterreflex/src/core/audio/voice_models.dart';

class ScenarioCharacter {
  const ScenarioCharacter({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.description,
    this.voiceId,
  });

  final String id;
  final String name;
  final String? description;
  final String? voiceId;
  final int sortOrder;
}

class ScenarioTurn {
  const ScenarioTurn({
    required this.body,
    required this.sortOrder,
    this.id,
    this.characterId,
    this.stageDirection,
  });

  final String? id;
  final String? characterId;
  final String body;
  final String? stageDirection;
  final int sortOrder;
}

class TrainingScenario {
  const TrainingScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.moderatorIntro,
    required this.characters,
    required this.turns,
    this.responseCue = 'Du bist dran. Was antwortest du?',
    this.sharedAudioEligible = false,
  });

  factory TrainingScenario.fromJson(Map<String, dynamic> json) {
    final characters =
        (json['scenario_characters'] as List? ?? const []).map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return ScenarioCharacter(
        id: data['id'] as String,
        name: data['name'] as String,
        description: data['description'] as String?,
        voiceId: data['voice_id'] as String?,
        sortOrder: data['sort_order'] as int? ?? 0,
      );
    }).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final turns = (json['scenario_turns'] as List? ?? const []).map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return ScenarioTurn(
        id: data['id'] as String?,
        characterId: data['character_id'] as String?,
        body: data['body'] as String,
        stageDirection: data['stage_direction'] as String?,
        sortOrder: data['sort_order'] as int,
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return TrainingScenario(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      moderatorIntro: json['moderator_intro'] as String,
      responseCue:
          json['response_cue'] as String? ?? 'Du bist dran. Was antwortest du?',
      characters: characters,
      turns: turns,
      sharedAudioEligible: true,
    );
  }

  final String id;
  final String title;
  final String category;
  final String moderatorIntro;
  final String responseCue;
  final List<ScenarioCharacter> characters;
  final List<ScenarioTurn> turns;
  final bool sharedAudioEligible;

  bool get isGroup => characters.length > 1;

  List<SpeechLine> get speechLines {
    final byId = {for (final character in characters) character.id: character};
    return [
      SpeechLine(
        text: moderatorIntro,
        role: VoiceRole.moderator,
        sharedReference: sharedAudioEligible
            ? SharedSpeechReference(
                kind: SharedSpeechResourceKind.scenarioIntro,
                id: id,
              )
            : null,
      ),
      for (final turn in turns) ...[
        if (turn.stageDirection?.trim().isNotEmpty == true)
          SpeechLine(
            text: turn.stageDirection!.trim(),
            role: VoiceRole.moderator,
            sharedReference: !sharedAudioEligible || turn.id == null
                ? null
                : SharedSpeechReference(
                    kind: SharedSpeechResourceKind.scenarioStageDirection,
                    id: turn.id!,
                  ),
          ),
        SpeechLine(
          text: turn.body,
          role: VoiceRole.actor,
          voiceId: byId[turn.characterId]?.voiceId,
          sharedReference: !sharedAudioEligible || turn.id == null
              ? null
              : SharedSpeechReference(
                  kind: SharedSpeechResourceKind.scenarioTurn,
                  id: turn.id!,
                ),
        ),
      ],
      SpeechLine(
        text: responseCue,
        role: VoiceRole.moderator,
        sharedReference: sharedAudioEligible
            ? SharedSpeechReference(
                kind: SharedSpeechResourceKind.scenarioResponseCue,
                id: id,
              )
            : null,
      ),
    ];
  }
}

class TrainingSessionRecord {
  const TrainingSessionRecord({required this.id, required this.clientId});

  final String id;
  final String clientId;
}
