import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
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
    AppLocalizations? strings,
  })  : _permission = permission,
        _recorder = recorder,
        _playback = playback,
        _speech = speech,
        _strings = strings ?? lookupAppLocalizations(const Locale('de')) {
    if (recorder case final VoiceActivitySource source) {
      _recorderActivitySubscription = source.voiceActivity.listen(
        _onRecorderActivity,
      );
    }
    if (playback case final VoiceActivitySource source) {
      _playbackActivitySubscription = source.voiceActivity.listen(
        _onPlaybackActivity,
      );
    }
  }

  final MicrophonePermissionGateway _permission;
  final VoiceRecorder _recorder;
  final AudioPlaybackQueue _playback;
  final SpeechGateway _speech;
  final AppLocalizations _strings;
  final VoiceStateMachine _machine = VoiceStateMachine();
  final ValueNotifier<double> _voiceActivity = ValueNotifier(0);
  StreamSubscription<double>? _recorderActivitySubscription;
  StreamSubscription<double>? _playbackActivitySubscription;
  VoiceTurnSnapshot _snapshot = const VoiceTurnSnapshot(
    state: VoiceTurnState.idle,
  );
  int _operation = 0;

  VoiceTurnSnapshot get snapshot => _snapshot;
  ValueListenable<double> get voiceActivity => _voiceActivity;

  Future<bool> playScene(List<SpeechLine> lines) async {
    if (lines.isEmpty || lines.first.role != VoiceRole.moderator) {
      throw ArgumentError('A voice scene starts with a moderator line.');
    }
    final operation = ++_operation;
    _moveTo(VoiceTurnState.preparing);
    try {
      final prepared = <SpeechClip>[];
      for (final line in lines) {
        if (operation != _operation) return false;
        final clip = await _speech.synthesize(line);
        if (operation != _operation) return false;
        prepared.add(clip);
      }
      for (final clip in prepared) {
        await _playback.enqueue(clip);
      }
      _moveTo(VoiceTurnState.introducing);
      if (lines.any((line) => line.role == VoiceRole.actor)) {
        _moveTo(VoiceTurnState.acting);
      }
      await _playback.playAll();
      if (operation == _operation) _moveTo(VoiceTurnState.awaitingUser);
      return operation == _operation;
    } catch (error) {
      if (operation == _operation) {
        _machine.interrupt();
        _publish(message: _sceneFailureMessage(error));
      }
      return false;
    }
  }

  String _sceneFailureMessage(Object error) {
    if (error is! VoiceServiceException) {
      debugPrint('[voice] scene_failed code=VOICE_UNKNOWN');
      return _strings.voiceSceneUnknown('VOICE_UNKNOWN');
    }
    debugPrint('[voice] scene_failed code=${error.diagnosticCode}');
    return switch (error.kind) {
      VoiceServiceFailureKind.authentication =>
        _strings.voiceAuthExpired(error.diagnosticCode),
      VoiceServiceFailureKind.request =>
        _strings.voiceRequestRejected(error.diagnosticCode),
      VoiceServiceFailureKind.timeout =>
        _strings.voiceTimeout(error.diagnosticCode),
      VoiceServiceFailureKind.unavailable =>
        _strings.voiceUnavailable(error.diagnosticCode),
      VoiceServiceFailureKind.invalidResponse =>
        _strings.voiceInvalidAudio(error.diagnosticCode),
      VoiceServiceFailureKind.playback =>
        _strings.voicePlaybackError(error.diagnosticCode),
    };
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
            ? _strings.microphoneDisabled
            : _strings.microphoneRecordingRequired,
      );
      return status;
    }
    try {
      await _recorder.start();
      _moveTo(VoiceTurnState.recording);
    } catch (_) {
      _publish(message: _strings.recordingStartError);
    }
    return status;
  }

  Future<void> stopAndProcess({
    required Future<String> Function(String transcript) buildFeedback,
  }) async {
    final transcription = await stopAndTranscribe();
    if (transcription == null) return;
    try {
      final feedback = await buildFeedback(transcription.transcript);
      await presentFeedback(feedback);
    } catch (_) {
      if (_machine.state == VoiceTurnState.processing) {
        _machine.interrupt();
        _publish(
          message: _strings.responseProcessError,
        );
      }
    }
  }

  Future<TranscriptionResult?> stopAndTranscribe() async {
    if (_machine.state != VoiceTurnState.recording) {
      throw StateError('No voice recording is active.');
    }
    final operation = ++_operation;
    try {
      final audio = await _recorder.stop();
      _moveTo(VoiceTurnState.processing);
      final transcription = await _speech.transcribe(audio);
      if (operation != _operation) return null;
      _publish(transcript: transcription.transcript);
      return transcription;
    } catch (_) {
      if (operation == _operation) {
        _machine.interrupt();
        _publish(
          message: _strings.responseProcessError,
        );
      }
      return null;
    }
  }

  Future<TranscriptionResult?> captureHandsFree() async {
    if (_machine.state != VoiceTurnState.awaitingUser) {
      throw StateError('The turn is not waiting for the user.');
    }
    final recorder = _recorder;
    if (recorder is! HandsFreeVoiceRecorder) {
      throw StateError('The recorder does not support hands-free capture.');
    }
    final status = await _permission.request();
    if (status != MicrophonePermissionStatus.granted) {
      _publish(
        permissionStatus: status,
        message: _strings.microphoneHandsFreeRequired,
      );
      return null;
    }
    final operation = ++_operation;
    try {
      _moveTo(VoiceTurnState.recording);
      final audio = await recorder.recordUntilSilence();
      _moveTo(VoiceTurnState.processing);
      final transcription = await _speech.transcribe(audio);
      if (operation != _operation) return null;
      _publish(transcript: transcription.transcript);
      return transcription;
    } catch (_) {
      if (operation == _operation) {
        _machine.interrupt();
        _publish(message: _strings.responseNotUnderstood);
      }
      return null;
    }
  }

  Future<void> presentFeedback(String feedback) async {
    if (_machine.state != VoiceTurnState.processing) {
      throw StateError('No processed response is awaiting feedback.');
    }
    final operation = ++_operation;
    try {
      _moveTo(VoiceTurnState.preparing, feedback: feedback);
      final clip = await _speech.synthesize(
        SpeechLine(text: feedback, role: VoiceRole.intelligence),
      );
      if (operation != _operation) return;
      await _playback.enqueue(clip);
      _moveTo(VoiceTurnState.feedback, feedback: feedback);
      await _playback.playAll();
      if (operation == _operation) {
        _moveTo(
          VoiceTurnState.followUp,
          feedback: feedback,
        );
      }
    } catch (_) {
      if (operation == _operation) {
        _machine.interrupt();
        _publish(message: _strings.responseProcessError);
      }
    }
  }

  void finishWithoutFeedback() {
    if (_machine.state != VoiceTurnState.processing) {
      throw StateError('No processed response can be completed.');
    }
    _machine.transitionTo(VoiceTurnState.awaitingUser);
    _machine.transitionTo(VoiceTurnState.idle);
    _publish();
  }

  Future<void> interrupt() async {
    _operation += 1;
    await _playback.stop();
    if (_machine.state == VoiceTurnState.recording) await _recorder.cancel();
    _machine.interrupt();
    _publish(message: _strings.playbackInterrupted);
  }

  Future<bool> openMicrophoneSettings() => _permission.openSettings();

  void prepareFollowUpRecording() {
    if (_machine.state != VoiceTurnState.followUp) {
      throw StateError('No feedback conversation is active.');
    }
    _machine.transitionTo(VoiceTurnState.awaitingUser);
    _publish();
  }

  void reset() {
    _operation += 1;
    _machine.reset();
    _snapshot = const VoiceTurnSnapshot(state: VoiceTurnState.idle);
    _voiceActivity.value = 0;
    notifyListeners();
  }

  void _moveTo(
    VoiceTurnState state, {
    String? transcript,
    String? feedback,
  }) {
    _machine.transitionTo(state);
    if (!_isActivityState(state)) _voiceActivity.value = 0;
    _publish(transcript: transcript, feedback: feedback);
  }

  void _onRecorderActivity(double level) {
    if (_machine.state == VoiceTurnState.recording) {
      _voiceActivity.value = level.clamp(0.0, 1.0).toDouble();
    }
  }

  void _onPlaybackActivity(double level) {
    if (_machine.state == VoiceTurnState.introducing ||
        _machine.state == VoiceTurnState.acting ||
        _machine.state == VoiceTurnState.feedback) {
      _voiceActivity.value = level.clamp(0.0, 1.0).toDouble();
    }
  }

  bool _isActivityState(VoiceTurnState state) =>
      state == VoiceTurnState.introducing ||
      state == VoiceTurnState.acting ||
      state == VoiceTurnState.recording ||
      state == VoiceTurnState.feedback;

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
    unawaited(_recorderActivitySubscription?.cancel());
    unawaited(_playbackActivitySubscription?.cancel());
    _recorder.dispose();
    _playback.dispose();
    _voiceActivity.dispose();
    super.dispose();
  }
}
