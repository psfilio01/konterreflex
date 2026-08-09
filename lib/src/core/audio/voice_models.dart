import 'dart:typed_data';

enum VoiceRole { moderator, actor, intelligence }

class SpeechLine {
  const SpeechLine({
    required this.text,
    required this.role,
    this.voiceId,
  });

  final String text;
  final VoiceRole role;
  final String? voiceId;
}

class RecordedAudio {
  const RecordedAudio({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class SpeechClip {
  const SpeechClip({
    required this.bytes,
    required this.mimeType,
    required this.role,
    this.transcript,
  });

  final Uint8List bytes;
  final String mimeType;
  final VoiceRole role;
  final String? transcript;
}

class TranscriptionResult {
  const TranscriptionResult({
    required this.transcript,
    required this.provider,
    required this.model,
  });

  final String transcript;
  final String provider;
  final String model;
}
