import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_evaluation_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

void main() {
  test('hands-free session evaluates once after every selected response',
      () async {
    final events = <String>[];
    final repository = _Repository(events);
    final evaluation = _EvaluationRepository(events);
    final speech = _Speech();
    final ids = <String>[
      'session-client',
      'response-1',
      'response-2',
      'response-3',
    ];
    final controller = SpeechChallengeController(
      challengeSet: challengeSet,
      repository: repository,
      evaluationRepository: evaluation,
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _HandsFreeRecorder(),
        playback: _Playback(),
        speech: speech,
      ),
      createId: () => ids.removeAt(0),
      random: Random(1),
    );

    await controller.startHandsFree(promptCount: 3);

    expect(controller.status, SpeechChallengeStatus.complete);
    expect(controller.completedCount, 3);
    expect(repository.responses, ['Antwort 1', 'Antwort 2', 'Antwort 3']);
    expect(evaluation.calls, 1);
    expect(controller.result?.details, hasLength(3));
    expect(repository.completed, isTrue);
    expect(repository.savedResult, isNotNull);
    expect(events.last, 'result-saved');
    expect(events.indexOf('evaluation'),
        greaterThan(events.indexOf('response-3')));
    expect(
      speech.synthesizedTexts.take(3),
      everyElement(startsWith('Impuls ')),
      reason: 'No feedback is spoken between prompts.',
    );
    expect(speech.synthesizedTexts.last, contains(feedback.headline));
  });

  test('failed final evaluation retries without recording answers again',
      () async {
    final events = <String>[];
    final repository = _Repository(events);
    final evaluation = _FlakyEvaluationRepository(events);
    final speech = _Speech();
    final ids = <String>['session-client', 'response-1', 'response-2'];
    final controller = SpeechChallengeController(
      challengeSet: challengeSet,
      repository: repository,
      evaluationRepository: evaluation,
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _HandsFreeRecorder(),
        playback: _Playback(),
        speech: speech,
      ),
      createId: () => ids.removeAt(0),
      random: Random(2),
    );

    await controller.startHandsFree(promptCount: 2);

    expect(controller.status, SpeechChallengeStatus.error);
    expect(controller.canRetryEvaluation, isTrue);
    expect(repository.responses, hasLength(2));

    await controller.retryEvaluation();

    expect(controller.status, SpeechChallengeStatus.complete);
    expect(evaluation.calls, 2);
    expect(repository.responses, hasLength(2));
    expect(speech.transcriptions, 2);
  });

  test('session length must fit the available unique prompts', () async {
    final controller = SpeechChallengeController(
      challengeSet: challengeSet,
      repository: _Repository([]),
      evaluationRepository: _EvaluationRepository([]),
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _HandsFreeRecorder(),
        playback: _Playback(),
        speech: _Speech(),
      ),
    );

    expect(
      () => controller.startHandsFree(promptCount: 16),
      throwsArgumentError,
    );
    expect(
      () => controller.startHandsFree(promptCount: 0),
      throwsArgumentError,
    );
  });

  test('challenge result requires one ordered detail per answer', () {
    final answer = ChallengeAnswer(
      prompt: challengeSet.prompts.first,
      responseId: 'response-1',
      transcript: 'Meine Antwort',
    );

    expect(
      () => ChallengeSessionResult.fromGateway(
        data: {
          'summary': feedback.toJson(),
          'details': [detailData, detailData],
        },
        answers: [answer],
        provider: 'mock',
        model: 'mock',
        promptVersion: 'challenge-v1',
      ),
      throwsFormatException,
    );
  });

  test('challenge domain contains no score, leaderboard or reaction time', () {
    final serializedShape = {
      'id': challengeSet.id,
      'title': challengeSet.title,
      'prompts': challengeSet.prompts.map((prompt) => prompt.remark).toList(),
    }.toString().toLowerCase();
    expect(serializedShape, isNot(contains('score')));
    expect(serializedShape, isNot(contains('leaderboard')));
    expect(serializedShape, isNot(contains('reaction')));
  });

  test('challenge prompts use approved shared audio references', () {
    expect(
      challengeSet.prompts.first.speechLine.sharedReference?.kind,
      SharedSpeechResourceKind.challengePrompt,
    );
    expect(challengeSet.prompts.first.speechLine.sharedReference?.id, 'p1');
  });
}

final challengeSet = ChallengeSet(
  id: 'set-1',
  title: 'Klare Position',
  description: 'Kurz antworten.',
  prompts: [
    for (var index = 1; index <= 15; index++)
      ChallengePrompt(
        id: 'p$index',
        remark: 'Impuls $index.',
        context: 'Kontext $index',
        sortOrder: index - 1,
      ),
  ],
);

class _Repository implements SpeechChallengeRepository {
  _Repository(this.events);

  final List<String> events;
  final responses = <String>[];
  bool completed = false;
  ChallengeSessionResult? savedResult;

  @override
  Future<List<ChallengeSet>> fetchActiveSets() async => [challengeSet];

  @override
  Future<TrainingSessionRecord> startSession({
    required String setId,
    required String clientId,
    required int targetCount,
    required List<String> promptIds,
  }) async {
    expect(promptIds, hasLength(targetCount));
    expect(promptIds.toSet(), hasLength(targetCount));
    return TrainingSessionRecord(id: 'session-1', clientId: clientId);
  }

  @override
  Future<String> saveResponse({
    required String sessionId,
    required String promptId,
    required String clientId,
    required String transcript,
    required int position,
  }) async {
    responses.add(transcript);
    events.add('response-${responses.length}');
    return clientId;
  }

  @override
  Future<void> completeSession(String sessionId) async {
    completed = true;
    events.add('session-complete');
  }

  @override
  Future<void> saveResult({
    required String sessionId,
    required ChallengeSessionResult result,
  }) async {
    savedResult = result;
    events.add('result-saved');
  }
}

class _EvaluationRepository implements SpeechChallengeEvaluationRepository {
  _EvaluationRepository(this.events);

  final List<String> events;
  int calls = 0;

  @override
  Future<ChallengeSessionResult> evaluate({
    required ChallengeSet challengeSet,
    required List<ChallengeAnswer> answers,
  }) async {
    calls += 1;
    events.add('evaluation');
    return resultFor(answers);
  }
}

class _FlakyEvaluationRepository extends _EvaluationRepository {
  _FlakyEvaluationRepository(super.events);

  @override
  Future<ChallengeSessionResult> evaluate({
    required ChallengeSet challengeSet,
    required List<ChallengeAnswer> answers,
  }) async {
    calls += 1;
    events.add('evaluation');
    if (calls == 1) {
      throw const AiGatewayException(
        code: 'provider_capacity',
        message: 'Temporarily unavailable.',
        status: 503,
      );
    }
    return resultFor(answers);
  }
}

ChallengeSessionResult resultFor(List<ChallengeAnswer> answers) =>
    ChallengeSessionResult(
      summary: feedback,
      details: [
        for (final answer in answers)
          ChallengeResponseDetail(
            answer: answer,
            signal: FeedbackSignal.developing,
            headline: 'Klar begonnen',
            strength: 'Direkter Einstieg',
            improvement: 'Nenne den nächsten Schritt.',
            alternative: 'Ich möchte den Gedanken kurz beenden.',
          ),
      ],
      provider: 'mock',
      model: 'mock',
      promptVersion: 'challenge-v1',
    );

const detailData = {
  'signal': 'developing',
  'headline': 'Klar begonnen',
  'strength': 'Direkter Einstieg',
  'improvement': 'Nenne den nächsten Schritt.',
  'alternative': 'Ich möchte den Gedanken kurz beenden.',
};

const feedback = QualitativeFeedback(
  overallSignal: FeedbackSignal.developing,
  dimensionSignals: FeedbackDimensionSignals(
    posture: FeedbackSignal.strong,
    precision: FeedbackSignal.developing,
    frame: FeedbackSignal.developing,
    socialEffect: FeedbackSignal.strong,
    naturalness: FeedbackSignal.strong,
    escalationFit: FeedbackSignal.developing,
  ),
  headline: 'Klar begonnen',
  explanation: 'Die Position ist verständlich.',
  strengths: ['Direkter Einstieg'],
  improvement: 'Nenne noch den nächsten Schritt.',
  alternatives: ['Ich möchte den Gedanken kurz beenden.'],
  dimensions: FeedbackDimensions(
    posture: 'ruhig',
    precision: 'klar',
    frame: 'gesetzt',
    socialEffect: 'anschlussfähig',
    naturalness: 'sprechbar',
    escalationFit: 'passend',
  ),
  provider: 'mock',
  model: 'mock',
  promptVersion: 'mock-v1',
);

class _Permission implements MicrophonePermissionGateway {
  @override
  Future<MicrophonePermissionStatus> request() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<bool> openSettings() async => true;
}

class _HandsFreeRecorder implements HandsFreeVoiceRecorder {
  @override
  Future<RecordedAudio> recordUntilSilence() async =>
      RecordedAudio(bytes: Uint8List.fromList([1]), mimeType: 'audio/pcm');

  @override
  Future<void> start() async {}

  @override
  Future<RecordedAudio> stop() => recordUntilSilence();

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class _Playback implements AudioPlaybackQueue {
  @override
  Future<void> enqueue(SpeechClip clip) async {}

  @override
  Future<void> playAll() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _Speech implements SpeechGateway {
  int transcriptions = 0;
  final synthesizedTexts = <String>[];

  @override
  Future<SpeechClip> synthesize(SpeechLine line) async {
    synthesizedTexts.add(line.text);
    return SpeechClip(
      bytes: Uint8List.fromList([1]),
      mimeType: 'audio/mpeg',
      role: line.role,
    );
  }

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async =>
      TranscriptionResult(
        transcript: 'Antwort ${++transcriptions}',
        provider: 'mock',
        model: 'mock',
      );
}
