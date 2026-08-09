import 'dart:convert';
import 'dart:typed_data';

import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSpeechGateway implements SpeechGateway {
  SupabaseSpeechGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<SpeechClip> synthesize(SpeechLine line) async {
    final response = await _client.functions.invoke(
      'speech-gateway',
      body: {
        'operation': 'tts',
        'schemaVersion': '1',
        'text': line.text,
        'role': line.role.name,
        if (line.voiceId != null) 'voiceId': line.voiceId,
      },
    );
    final data = _responseMap(response);
    final audioBase64 = data['audioBase64'];
    final mimeType = data['mimeType'];
    if (audioBase64 is! String || mimeType is! String) {
      throw const FormatException('Invalid speech response.');
    }
    return SpeechClip(
      bytes: Uint8List.fromList(base64Decode(audioBase64)),
      mimeType: mimeType,
      role: line.role,
      transcript: line.text,
    );
  }

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async {
    final response = await _client.functions.invoke(
      'speech-gateway',
      body: {
        'operation': 'stt',
        'schemaVersion': '1',
        'audioBase64': base64Encode(audio.bytes),
        'mimeType': audio.mimeType,
        'languageCode': 'de',
      },
    );
    final data = _responseMap(response);
    final transcript = data['transcript'];
    final provider = data['provider'];
    final model = data['model'];
    if (transcript is! String || provider is! String || model is! String) {
      throw const FormatException('Invalid transcription response.');
    }
    return TranscriptionResult(
      transcript: transcript,
      provider: provider,
      model: model,
    );
  }

  Map<String, dynamic> _responseMap(FunctionResponse response) {
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Speech gateway request failed.');
    }
    final data = response.data;
    if (data is! Map) throw const FormatException('Invalid speech response.');
    return Map<String, dynamic>.from(data);
  }
}
