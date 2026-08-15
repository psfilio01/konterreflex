import 'dart:typed_data';

enum VoiceRole { moderator, actor, intelligence }

enum SharedSpeechResourceKind {
  scenarioIntro('scenario_intro'),
  scenarioStageDirection('scenario_stage_direction'),
  scenarioTurn('scenario_turn'),
  scenarioResponseCue('scenario_response_cue'),
  challengePrompt('challenge_prompt');

  const SharedSpeechResourceKind(this.wireName);

  final String wireName;
}

class SharedSpeechReference {
  const SharedSpeechReference({required this.kind, required this.id});

  final SharedSpeechResourceKind kind;
  final String id;
}

class SpeechLine {
  const SpeechLine({
    required this.text,
    required this.role,
    this.voiceId,
    this.sharedReference,
  });

  final String text;
  final VoiceRole role;
  final String? voiceId;
  final SharedSpeechReference? sharedReference;
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
