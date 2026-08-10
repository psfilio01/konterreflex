import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

void main() {
  test('complete mocked session persists once across a retry', () async {
    final repository = _MemoryScenarioRepository()..failCompletionOnce = true;
    final ids = [
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    ];
    final controller = ScenarioSessionController(
      scenario: testScenario,
      repository: repository,
      feedbackRepository: _FeedbackRepository(),
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _Recorder(),
        playback: _Playback(),
        speech: _Speech(),
      ),
      createId: () => ids.removeAt(0),
    );

    await controller.start();
    await controller.startRecording();
    await controller.submitResponse();

    expect(controller.status, ScenarioSessionStatus.error);
    expect(controller.transcript, 'Meine klare Antwort.');
    expect(repository.sessions.length, 1);
    expect(repository.responses.length, 1);

    await controller.retryPersistence();

    expect(controller.status, ScenarioSessionStatus.feedbackReady);
    expect(repository.sessions.length, 1);
    expect(repository.responses.length, 1);
    expect(repository.completedSessionIds, {'session-1'});

    await controller.startFollowUp();
    expect(controller.status, ScenarioSessionStatus.followUpRecording);
    await controller.submitFollowUp();
    expect(controller.status, ScenarioSessionStatus.feedbackReady);
    expect(controller.followUpAnswer, 'Eine kurze Antwort.');

    controller.retryScene();
    expect(controller.status, ScenarioSessionStatus.ready);
    expect(controller.transcript, isNull);
    expect(controller.feedback, isNull);
  });

  test('group scenarios retain distinct actors in playback order', () {
    expect(testScenario.isGroup, isTrue);
    expect(testScenario.speechLines.map((line) => line.role), [
      VoiceRole.moderator,
      VoiceRole.actor,
      VoiceRole.actor,
    ]);
    expect(testScenario.speechLines.map((line) => line.voiceId), [
      null,
      'voice-a',
      'voice-b',
    ]);
    expect(
      testScenario.speechLines.first.sharedReference?.kind,
      SharedSpeechResourceKind.scenarioIntro,
    );
  });

  test('database scenario turns carry stable shared audio references', () {
    final scenario = TrainingScenario.fromJson({
      'id': '10000000-0000-0000-0000-000000000001',
      'title': 'Szene',
      'category': 'Arbeit',
      'moderator_intro': 'Einleitung.',
      'scenario_characters': [
        {
          'id': '20000000-0000-0000-0000-000000000001',
          'name': 'Alex',
          'sort_order': 0,
          'voice_id': 'actor_voice',
        }
      ],
      'scenario_turns': [
        {
          'id': '30000000-0000-0000-0000-000000000001',
          'character_id': '20000000-0000-0000-0000-000000000001',
          'body': 'Einwand.',
          'sort_order': 0,
        }
      ],
    });

    expect(
      scenario.speechLines[1].sharedReference?.kind,
      SharedSpeechResourceKind.scenarioTurn,
    );
    expect(
      scenario.speechLines[1].sharedReference?.id,
      '30000000-0000-0000-0000-000000000001',
    );
  });

  test('scene playback failure offers a retry instead of recording', () async {
    final controller = ScenarioSessionController(
      scenario: testScenario,
      repository: _MemoryScenarioRepository(),
      feedbackRepository: _FeedbackRepository(),
      voice: VoiceTurnController(
        permission: _Permission(),
        recorder: _Recorder(),
        playback: _Playback(),
        speech: _FailingSpeech(),
      ),
      createId: () => 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    );

    await controller.start();

    expect(controller.status, ScenarioSessionStatus.error);
    expect(controller.message, contains('SPEECH_SERVICE'));
  });
}

const testScenario = TrainingScenario(
  id: 'scenario-1',
  title: 'Gruppensituation',
  category: 'Arbeit',
  moderatorIntro: 'Eine Gruppe reagiert auf deinen Vorschlag.',
  characters: [
    ScenarioCharacter(id: 'a', name: 'Alex', sortOrder: 0, voiceId: 'voice-a'),
    ScenarioCharacter(id: 'b', name: 'Kim', sortOrder: 1, voiceId: 'voice-b'),
  ],
  turns: [
    ScenarioTurn(characterId: 'a', body: 'Wir müssen weiter.', sortOrder: 0),
    ScenarioTurn(
        characterId: 'b', body: 'Der Punkt ist doch klar.', sortOrder: 1),
  ],
  sharedAudioEligible: true,
);

class _MemoryScenarioRepository implements ScenarioRepository {
  final sessions = <String, TrainingSessionRecord>{};
  final responses = <String, String>{};
  final completedSessionIds = <String>{};
  bool failCompletionOnce = false;

  @override
  Future<List<TrainingScenario>> fetchApprovedScenarios() async =>
      [testScenario];

  @override
  Future<TrainingSessionRecord> startSession({
    required String scenarioId,
    required String clientId,
  }) async {
    return sessions.putIfAbsent(
      clientId,
      () => TrainingSessionRecord(id: 'session-1', clientId: clientId),
    );
  }

  @override
  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  }) async {
    responses[clientId] = transcript;
    return 'response-1';
  }

  @override
  Future<void> completeSession(String sessionId) async {
    if (failCompletionOnce) {
      failCompletionOnce = false;
      throw StateError('temporary failure');
    }
    completedSessionIds.add(sessionId);
  }
}

class _FeedbackRepository implements FeedbackRepository {
  @override
  Future<QualitativeFeedback> evaluate({
    required TrainingScenario scenario,
    required String transcript,
  }) async =>
      testFeedback;

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
      'Eine kurze Antwort.';
}

const testFeedback = QualitativeFeedback(
  headline: 'Klar positioniert',
  explanation: 'Die Antwort macht deinen Standpunkt verständlich.',
  strengths: ['Ruhiger Einstieg'],
  improvement: 'Formuliere den nächsten Schritt noch konkreter.',
  alternatives: ['Ich sehe das anders und erkläre kurz, warum.'],
  dimensions: FeedbackDimensions(
    posture: 'ruhig',
    precision: 'klar',
    frame: 'neu gesetzt',
    socialEffect: 'anschlussfähig',
    naturalness: 'sprechbar',
    escalationFit: 'passend',
  ),
  provider: 'mock',
  model: 'mock',
  promptVersion: 'response_evaluate_v1',
);

class _Permission implements MicrophonePermissionGateway {
  @override
  Future<MicrophonePermissionStatus> request() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<bool> openSettings() async => true;
}

class _Recorder implements VoiceRecorder {
  @override
  Future<void> start() async {}

  @override
  Future<RecordedAudio> stop() async => RecordedAudio(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'audio/pcm;rate=16000',
      );

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
  @override
  Future<SpeechClip> synthesize(SpeechLine line) async => SpeechClip(
        bytes: Uint8List.fromList([1]),
        mimeType: 'audio/mpeg',
        role: line.role,
      );

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async =>
      const TranscriptionResult(
        transcript: 'Meine klare Antwort.',
        provider: 'mock',
        model: 'mock',
      );
}

class _FailingSpeech implements SpeechGateway {
  @override
  Future<SpeechClip> synthesize(SpeechLine line) => Future.error(
        const VoiceServiceException(
          VoiceServiceFailureKind.unavailable,
          'SPEECH_SERVICE',
        ),
      );

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) => Future.error(
        const VoiceServiceException(
          VoiceServiceFailureKind.unavailable,
          'SPEECH_SERVICE',
        ),
      );
}
