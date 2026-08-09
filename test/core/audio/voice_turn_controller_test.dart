import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';

void main() {
  test('a mocked audio turn runs end to end without text input', () async {
    final playback = _MockPlayback();
    final speech = _MockSpeech();
    final controller = VoiceTurnController(
      permission: _MockPermission(MicrophonePermissionStatus.granted),
      recorder: _MockRecorder(),
      playback: playback,
      speech: speech,
    );
    final states = <VoiceTurnState>[];
    controller.addListener(() => states.add(controller.snapshot.state));

    await controller.playScene(const [
      SpeechLine(text: 'Eine kurze Situation.', role: VoiceRole.moderator),
      SpeechLine(
          text: 'Warum so still?', role: VoiceRole.actor, voiceId: 'actor-1'),
    ]);
    expect(controller.snapshot.state, VoiceTurnState.awaitingUser);

    await controller.startRecording();
    expect(controller.snapshot.state, VoiceTurnState.recording);

    await controller.stopAndProcess(
      buildFeedback: (transcript) async => 'Klar und ruhig formuliert.',
    );

    expect(controller.snapshot.state, VoiceTurnState.followUp);
    expect(controller.snapshot.transcript, 'Das sehe ich anders.');
    expect(controller.snapshot.feedback, 'Klar und ruhig formuliert.');
    expect(speech.synthesizedRoles, [
      VoiceRole.moderator,
      VoiceRole.actor,
      VoiceRole.intelligence,
    ]);
    expect(playback.playCount, 2);
    expect(
        states,
        containsAllInOrder([
          VoiceTurnState.introducing,
          VoiceTurnState.acting,
          VoiceTurnState.awaitingUser,
          VoiceTurnState.recording,
          VoiceTurnState.processing,
          VoiceTurnState.feedback,
          VoiceTurnState.followUp,
        ]));
  });

  test('microphone denial stays recoverable and explains the failure',
      () async {
    final controller = VoiceTurnController(
      permission: _MockPermission(MicrophonePermissionStatus.permanentlyDenied),
      recorder: _MockRecorder(),
      playback: _MockPlayback(),
      speech: _MockSpeech(),
    );
    await controller.playScene(const [
      SpeechLine(text: 'Deine Situation.', role: VoiceRole.moderator),
    ]);

    final permission = await controller.startRecording();

    expect(permission, MicrophonePermissionStatus.permanentlyDenied);
    expect(controller.snapshot.state, VoiceTurnState.awaitingUser);
    expect(controller.snapshot.message, contains('Einstellungen'));
  });

  test('an interruption stops playback or recording and returns control',
      () async {
    final recorder = _MockRecorder();
    final playback = _MockPlayback();
    final controller = VoiceTurnController(
      permission: _MockPermission(MicrophonePermissionStatus.granted),
      recorder: recorder,
      playback: playback,
      speech: _MockSpeech(),
    );
    await controller.playScene(const [
      SpeechLine(text: 'Deine Situation.', role: VoiceRole.moderator),
    ]);
    await controller.startRecording();

    await controller.interrupt();

    expect(controller.snapshot.state, VoiceTurnState.awaitingUser);
    expect(recorder.cancelled, isTrue);
    expect(playback.stopped, isTrue);
  });

  test('state machine rejects steps outside the voice contract', () {
    final machine = VoiceStateMachine();
    expect(
      () => machine.transitionTo(VoiceTurnState.recording),
      throwsA(isA<VoiceStateTransitionError>()),
    );
  });
}

class _MockPermission implements MicrophonePermissionGateway {
  _MockPermission(this.status);

  final MicrophonePermissionStatus status;

  @override
  Future<MicrophonePermissionStatus> request() async => status;

  @override
  Future<bool> openSettings() async => true;
}

class _MockRecorder implements VoiceRecorder {
  bool cancelled = false;

  @override
  Future<void> start() async {}

  @override
  Future<RecordedAudio> stop() async => RecordedAudio(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'audio/pcm;rate=16000',
      );

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async {}
}

class _MockPlayback implements AudioPlaybackQueue {
  final clips = <SpeechClip>[];
  int playCount = 0;
  bool stopped = false;

  @override
  Future<void> enqueue(SpeechClip clip) async => clips.add(clip);

  @override
  Future<void> playAll() async => playCount += 1;

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> dispose() async {}
}

class _MockSpeech implements SpeechGateway {
  final synthesizedRoles = <VoiceRole>[];

  @override
  Future<SpeechClip> synthesize(SpeechLine line) async {
    synthesizedRoles.add(line.role);
    return SpeechClip(
      bytes: Uint8List.fromList([line.role.index]),
      mimeType: 'audio/mpeg',
      role: line.role,
      transcript: line.text,
    );
  }

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async {
    return const TranscriptionResult(
      transcript: 'Das sehe ich anders.',
      provider: 'mock',
      model: 'mock-stt',
    );
  }
}
