import 'package:flutter/foundation.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';

class VoiceTurnSnapshot {
  const VoiceTurnSnapshot({
    required this.state,
    this.transcript,
    this.feedback,
    this.message,
    this.permissionStatus,
  });

  final VoiceTurnState state;
  final String? transcript;
  final String? feedback;
  final String? message;
  final MicrophonePermissionStatus? permissionStatus;
}

class VoiceTurnController extends ChangeNotifier {
  VoiceTurnController({
    required MicrophonePermissionGateway permission,
    required VoiceRecorder recorder,
    required AudioPlaybackQueue playback,
    required SpeechGateway speech,
  })  : _permission = permission,
        _recorder = recorder,
        _playback = playback,
        _speech = speech;

  final MicrophonePermissionGateway _permission;
  final VoiceRecorder _recorder;
  final AudioPlaybackQueue _playback;
  final SpeechGateway _speech;
  final VoiceStateMachine _machine = VoiceStateMachine();
  VoiceTurnSnapshot _snapshot = const VoiceTurnSnapshot(
    state: VoiceTurnState.idle,
  );
  int _operation = 0;

  VoiceTurnSnapshot get snapshot => _snapshot;

  Future<void> playScene(List<SpeechLine> lines) async {
    if (lines.isEmpty || lines.first.role != VoiceRole.moderator) {
      throw ArgumentError('A voice scene starts with a moderator line.');
    }
    final operation = ++_operation;
    _moveTo(VoiceTurnState.introducing);
    try {
      for (final line in lines) {
        if (operation != _operation) return;
        if (line.role == VoiceRole.actor &&
            _machine.state != VoiceTurnState.acting) {
          _moveTo(VoiceTurnState.acting);
        }
        await _playback.enqueue(await _speech.synthesize(line));
      }
      await _playback.playAll();
      if (operation == _operation) _moveTo(VoiceTurnState.awaitingUser);
    } catch (_) {
      if (operation == _operation) {
        _machine.interrupt();
        _publish(message: 'Die Szene konnte nicht abgespielt werden.');
      }
    }
  }

  Future<MicrophonePermissionStatus> startRecording() async {
    if (_machine.state != VoiceTurnState.awaitingUser) {
      throw StateError('The turn is not waiting for the user.');
    }
    final status = await _permission.request();
    if (status != MicrophonePermissionStatus.granted) {
      _publish(
        permissionStatus: status,
        message: status == MicrophonePermissionStatus.permanentlyDenied
            ? 'Mikrofonzugriff ist deaktiviert. Du kannst ihn in den Einstellungen erlauben.'
            : 'Ohne Mikrofonzugriff ist keine Sprachaufnahme möglich.',
      );
      return status;
    }
    try {
      await _recorder.start();
      _moveTo(VoiceTurnState.recording);
    } catch (_) {
      _publish(message: 'Die Aufnahme konnte nicht gestartet werden.');
    }
    return status;
  }

  Future<void> stopAndProcess({
    required Future<String> Function(String transcript) buildFeedback,
  }) async {
    if (_machine.state != VoiceTurnState.recording) {
      throw StateError('No voice recording is active.');
    }
    final operation = ++_operation;
    try {
      final audio = await _recorder.stop();
      _moveTo(VoiceTurnState.processing);
      final transcription = await _speech.transcribe(audio);
      if (operation != _operation) return;
      final feedback = await buildFeedback(transcription.transcript);
      if (operation != _operation) return;
      _moveTo(
        VoiceTurnState.feedback,
        transcript: transcription.transcript,
        feedback: feedback,
      );
      await _playback.enqueue(
        await _speech.synthesize(
          SpeechLine(text: feedback, role: VoiceRole.intelligence),
        ),
      );
      await _playback.playAll();
      if (operation == _operation) {
        _moveTo(
          VoiceTurnState.followUp,
          transcript: transcription.transcript,
          feedback: feedback,
        );
      }
    } catch (_) {
      if (operation == _operation) {
        _machine.interrupt();
        _publish(
            message:
                'Deine Antwort konnte nicht verarbeitet werden. Bitte versuche es erneut.');
      }
    }
  }

  Future<void> interrupt() async {
    _operation += 1;
    await _playback.stop();
    if (_machine.state == VoiceTurnState.recording) await _recorder.cancel();
    _machine.interrupt();
    _publish(message: 'Wiedergabe unterbrochen. Du bist dran.');
  }

  Future<bool> openMicrophoneSettings() => _permission.openSettings();

  void _moveTo(
    VoiceTurnState state, {
    String? transcript,
    String? feedback,
  }) {
    _machine.transitionTo(state);
    _publish(transcript: transcript, feedback: feedback);
  }

  void _publish({
    String? transcript,
    String? feedback,
    String? message,
    MicrophonePermissionStatus? permissionStatus,
  }) {
    _snapshot = VoiceTurnSnapshot(
      state: _machine.state,
      transcript: transcript ?? _snapshot.transcript,
      feedback: feedback ?? _snapshot.feedback,
      message: message,
      permissionStatus: permissionStatus,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _playback.dispose();
    super.dispose();
  }
}
