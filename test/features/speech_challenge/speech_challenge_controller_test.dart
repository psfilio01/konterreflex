import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

void main() {
  test('mocked audio runs a complete set without manual turn actions',
      () async {
    final repository = _Repository();
    final feedback = _FeedbackRepository();
    final ids = <String>['session-client', 'response-1', 'response-2'];
    final controller = SpeechChallengeController(
      challengeSet: challengeSet,
      repository: repository,
      feedbackRepository: feedback,
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _HandsFreeRecorder(),
        playback: _Playback(),
        speech: _Speech(),
      ),
      createId: () => ids.removeAt(0),
    );

    await controller.startHandsFree();

    expect(controller.status, SpeechChallengeStatus.complete);
    expect(controller.completedCount, 2);
    expect(repository.responses, ['Antwort 1', 'Antwort 2']);
    expect(feedback.evaluatedRemarks, ['Impuls eins.', 'Impuls zwei.']);
    expect(repository.completed, isTrue);
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

  test('exhausted AI quota does not abort the hands-free challenge', () async {
    final repository = _Repository();
    final speech = _Speech();
    final ids = <String>['session-client', 'response-1', 'response-2'];
    final controller = SpeechChallengeController(
      challengeSet: challengeSet,
      repository: repository,
      feedbackRepository: _UnavailableFeedbackRepository(),
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _HandsFreeRecorder(),
        playback: _Playback(),
        speech: speech,
      ),
      createId: () => ids.removeAt(0),
    );

    await controller.startHandsFree();

    expect(controller.status, SpeechChallengeStatus.complete);
    expect(controller.completedCount, 2);
    expect(repository.responses, ['Antwort 1', 'Antwort 2']);
    expect(repository.completed, isTrue);
    expect(controller.feedback, isNull);
    expect(controller.message, contains('Antworten wurden gespeichert'));
    expect(
      speech.synthesizedTexts.where((text) => text.contains('ausgelastet')),
      hasLength(2),
    );
  });
}

const challengeSet = ChallengeSet(
  id: 'set-1',
  title: 'Klare Position',
  description: 'Kurz antworten.',
  prompts: [
    ChallengePrompt(
        id: 'p1', remark: 'Impuls eins.', context: 'Arbeit', sortOrder: 0),
    ChallengePrompt(
        id: 'p2',
        remark: 'Impuls zwei.',
        context: 'Freundeskreis',
        sortOrder: 1),
  ],
);

class _Repository implements SpeechChallengeRepository {
  final responses = <String>[];
  bool completed = false;

  @override
  Future<List<ChallengeSet>> fetchActiveSets() async => [challengeSet];

  @override
  Future<TrainingSessionRecord> startSession(
          {required String setId, required String clientId}) async =>
      TrainingSessionRecord(id: 'session-1', clientId: clientId);

  @override
  Future<String> saveResponse(
      {required String sessionId,
      required String promptId,
      required String clientId,
      required String transcript}) async {
    responses.add(transcript);
    return clientId;
  }

  @override
  Future<void> completeSession(String sessionId) async => completed = true;
}

class _FeedbackRepository implements FeedbackRepository {
  final evaluatedRemarks = <String>[];

  @override
  Future<QualitativeFeedback> evaluate(
      {required TrainingScenario scenario, required String transcript}) async {
    evaluatedRemarks.add(scenario.turns.single.body);
    return feedback;
  }

  @override
  Future<void> save(
      {required String responseId,
      required QualitativeFeedback feedback}) async {}

  @override
  Future<String> answerFollowUp(
          {required TrainingScenario scenario,
          required QualitativeFeedback feedback,
          required String question}) async =>
      '';
}

class _UnavailableFeedbackRepository implements FeedbackRepository {
  @override
  Future<QualitativeFeedback> evaluate({
    required TrainingScenario scenario,
    required String transcript,
  }) =>
      throw const AiGatewayException(
        code: 'provider_capacity',
        message: 'Temporarily unavailable.',
        status: 503,
      );

  @override
  Future<void> save({
    required String responseId,
    required QualitativeFeedback feedback,
  }) async {}

  @override
  Future<String> answerFollowUp({
    required TrainingScenario scenario,
    required QualitativeFeedback feedback,
    required String question,
  }) async =>
      '';
}

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
        role: line.role);
  }

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async =>
      TranscriptionResult(
          transcript: 'Antwort ${++transcriptions}',
          provider: 'mock',
          model: 'mock');
}
