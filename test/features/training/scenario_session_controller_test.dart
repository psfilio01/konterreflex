import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

void main() {
  test('complete mocked session persists once across a retry', () async {
    final repository = _MemoryScenarioRepository()..failCompletionOnce = true;
    final ids = [
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
    ];
    final controller = ScenarioSessionController(
      scenario: testScenario,
      repository: repository,
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

    expect(controller.status, ScenarioSessionStatus.completed);
    expect(repository.sessions.length, 1);
    expect(repository.responses.length, 1);
    expect(repository.completedSessionIds, {'session-1'});
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
  Future<void> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  }) async {
    responses[clientId] = transcript;
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
