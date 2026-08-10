import 'dart:async';

import 'package:konterreflex/src/core/audio/voice_models.dart';

abstract interface class VoiceActivitySource {
  Stream<double> get voiceActivity;
}

enum VoiceServiceFailureKind {
  authentication,
  request,
  timeout,
  unavailable,
  invalidResponse,
  playback,
}

/// A privacy-safe failure passed across the speech provider boundary.
///
/// The diagnostic code must never contain transcripts, audio, provider
/// responses or credentials. It is safe to show in the UI and device logs.
class VoiceServiceException implements Exception {
  const VoiceServiceException(this.kind, this.diagnosticCode);

  final VoiceServiceFailureKind kind;
  final String diagnosticCode;
}

enum MicrophonePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract interface class MicrophonePermissionGateway {
  Future<MicrophonePermissionStatus> request();

  Future<bool> openSettings();
}

abstract interface class VoiceRecorder {
  Future<void> start();

  Future<RecordedAudio> stop();

  Future<void> cancel();

  Future<void> dispose();
}

abstract interface class HandsFreeVoiceRecorder implements VoiceRecorder {
  Future<RecordedAudio> recordUntilSilence();
}

abstract interface class AudioPlaybackQueue {
  Future<void> enqueue(SpeechClip clip);

  Future<void> playAll();

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class SpeechGateway {
  Future<SpeechClip> synthesize(SpeechLine line);

  Future<TranscriptionResult> transcribe(RecordedAudio audio);
}
