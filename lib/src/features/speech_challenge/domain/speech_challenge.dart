import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

const maxSpeechChallengePromptCount = 15;

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

class ChallengeAnswer {
  const ChallengeAnswer({
    required this.prompt,
    required this.responseId,
    required this.transcript,
  });

  final ChallengePrompt prompt;
  final String responseId;
  final String transcript;
}

class ChallengeResponseDetail {
  const ChallengeResponseDetail({
    required this.answer,
    required this.signal,
    required this.headline,
    required this.strength,
    required this.improvement,
    required this.alternative,
  });

  factory ChallengeResponseDetail.fromGateway({
    required Map<String, dynamic> data,
    required ChallengeAnswer answer,
  }) {
    const requiredKeys = {
      'signal',
      'headline',
      'strength',
      'improvement',
      'alternative',
    };
    _requireExactKeys(data, requiredKeys);
    return ChallengeResponseDetail(
      answer: answer,
      signal: _requiredSignal(data, 'signal'),
      headline: _requiredText(data, 'headline'),
      strength: _requiredText(data, 'strength'),
      improvement: _requiredText(data, 'improvement'),
      alternative: _requiredText(data, 'alternative'),
    );
  }

  final ChallengeAnswer answer;
  final FeedbackSignal signal;
  final String headline;
  final String strength;
  final String improvement;
  final String alternative;

  Map<String, dynamic> toJson() => {
        'response_id': answer.responseId,
        'prompt_id': answer.prompt.id,
        'signal': signal.wireName,
        'headline': headline,
        'strength': strength,
        'improvement': improvement,
        'alternative': alternative,
      };
}

class ChallengeSessionResult {
  const ChallengeSessionResult({
    required this.summary,
    required this.details,
    required this.provider,
    required this.model,
    required this.promptVersion,
  });

  factory ChallengeSessionResult.fromGateway({
    required Map<String, dynamic> data,
    required List<ChallengeAnswer> answers,
    required String provider,
    required String model,
    required String promptVersion,
  }) {
    _requireExactKeys(data, const {'summary', 'details'});
    final summary = data['summary'];
    final details = data['details'];
    if (summary is! Map ||
        details is! List ||
        details.any((item) => item is! Map)) {
      throw const FormatException('Invalid challenge session result.');
    }
    if (details.length != answers.length || details.isEmpty) {
      throw const FormatException(
        'Challenge result must contain one detail per answer.',
      );
    }
    return ChallengeSessionResult(
      summary: QualitativeFeedback.fromGateway(
        data: Map<String, dynamic>.from(summary),
        provider: provider,
        model: model,
        promptVersion: promptVersion,
      ),
      details: [
        for (var index = 0; index < details.length; index++)
          ChallengeResponseDetail.fromGateway(
            data: Map<String, dynamic>.from(details[index] as Map),
            answer: answers[index],
          ),
      ],
      provider: provider,
      model: model,
      promptVersion: promptVersion,
    );
  }

  final QualitativeFeedback summary;
  final List<ChallengeResponseDetail> details;
  final String provider;
  final String model;
  final String promptVersion;

  Map<String, dynamic> toJson() => {
        'summary': summary.toJson(),
        'details': details.map((detail) => detail.toJson()).toList(),
      };

  Map<String, dynamic> get modelMeta => {
        'provider': provider,
        'model': model,
        'prompt_version': promptVersion,
      };
}

void _requireExactKeys(Map<String, dynamic> json, Set<String> expected) {
  final actual = json.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw const FormatException('Unexpected challenge feedback fields.');
  }
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be non-empty text.');
  }
  return value.trim();
}

FeedbackSignal _requiredSignal(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a qualitative signal.');
  }
  return FeedbackSignal.fromWireName(value);
}
