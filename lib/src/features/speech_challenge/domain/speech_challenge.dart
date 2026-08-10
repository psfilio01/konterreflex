import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

class ChallengeSet {
  const ChallengeSet({
    required this.id,
    required this.title,
    required this.description,
    required this.prompts,
  });

  factory ChallengeSet.fromJson(Map<String, dynamic> json) {
    final prompts = (json['speech_challenge_prompts'] as List? ?? const [])
        .map((item) =>
            ChallengePrompt.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ChallengeSet(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      prompts: prompts,
    );
  }

  final String id;
  final String title;
  final String description;
  final List<ChallengePrompt> prompts;
}

class ChallengePrompt {
  const ChallengePrompt({
    required this.id,
    required this.remark,
    required this.context,
    required this.sortOrder,
  });

  factory ChallengePrompt.fromJson(Map<String, dynamic> json) =>
      ChallengePrompt(
        id: json['id'] as String,
        remark: json['remark'] as String,
        context: json['context'] as String,
        sortOrder: json['sort_order'] as int,
      );

  final String id;
  final String remark;
  final String context;
  final int sortOrder;

  SpeechLine get speechLine => SpeechLine(
        text: remark,
        role: VoiceRole.moderator,
        sharedReference: SharedSpeechReference(
          kind: SharedSpeechResourceKind.challengePrompt,
          id: id,
        ),
      );

  TrainingScenario asScenario(String theme) => TrainingScenario(
        id: id,
        title: theme,
        category: 'Speech Challenge',
        moderatorIntro: context,
        characters: const [],
        turns: [ScenarioTurn(body: remark, sortOrder: 0)],
      );
}
