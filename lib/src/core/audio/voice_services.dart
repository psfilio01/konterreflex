import 'package:konterreflex/src/core/audio/voice_models.dart';

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
