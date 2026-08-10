import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSpeechGateway implements SpeechGateway {
  SupabaseSpeechGateway(
    this._client, {
    this.language = AppLanguage.german,
  });

  final SupabaseClient _client;
  final AppLanguage language;

  @override
  Future<SpeechClip> synthesize(SpeechLine line) async {
    final response = await _invoke({
      'operation': 'tts',
      'schemaVersion': '1',
      'text': line.text,
      'role': line.role.name,
      'languageCode': language.code,
      if (line.voiceId != null) 'voiceId': line.voiceId,
    });
    final data = _responseMap(response);
    final audioBase64 = data['audioBase64'];
    final mimeType = data['mimeType'];
    if (audioBase64 is! String || mimeType is! String) {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.invalidResponse,
        'SPEECH_RESPONSE',
      );
    }
    try {
      return SpeechClip(
        bytes: Uint8List.fromList(base64Decode(audioBase64)),
        mimeType: mimeType,
        role: line.role,
        transcript: line.text,
      );
    } on FormatException {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.invalidResponse,
        'SPEECH_AUDIO_FORMAT',
      );
    }
  }

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async {
    final response = await _invoke({
      'operation': 'stt',
      'schemaVersion': '1',
      'audioBase64': base64Encode(audio.bytes),
      'mimeType': audio.mimeType,
      'languageCode': language.code,
    });
    final data = _responseMap(response);
    final transcript = data['transcript'];
    final provider = data['provider'];
    final model = data['model'];
    if (transcript is! String || provider is! String || model is! String) {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.invalidResponse,
        'SPEECH_RESPONSE',
      );
    }
    return TranscriptionResult(
      transcript: transcript,
      provider: provider,
      model: model,
    );
  }

  Future<FunctionResponse> _invoke(Map<String, dynamic> body) async {
    try {
      return await _client.functions.invoke('speech-gateway', body: body);
    } on FunctionException catch (error) {
      throw _functionFailure(error);
    } on TimeoutException {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.timeout,
        'SPEECH_TIMEOUT',
      );
    } catch (_) {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.unavailable,
        'SPEECH_CONNECTION',
      );
    }
  }

  VoiceServiceException _functionFailure(FunctionException error) {
    final serverCode = _serverErrorCode(error.details);
    if (error.status == 401 ||
        error.status == 403 ||
        serverCode == 'unauthorized') {
      return const VoiceServiceException(
        VoiceServiceFailureKind.authentication,
        'SPEECH_AUTH',
      );
    }
    if (error.status == 408 ||
        error.status == 504 ||
        serverCode == 'provider_timeout') {
      return const VoiceServiceException(
        VoiceServiceFailureKind.timeout,
        'SPEECH_TIMEOUT',
      );
    }
    if (error.status >= 400 && error.status < 500) {
      return const VoiceServiceException(
        VoiceServiceFailureKind.request,
        'SPEECH_REQUEST',
      );
    }
    return const VoiceServiceException(
      VoiceServiceFailureKind.unavailable,
      'SPEECH_SERVICE',
    );
  }

  String? _serverErrorCode(dynamic details) {
    if (details is! Map) return null;
    final error = details['error'];
    if (error is! Map) return null;
    final code = error['code'];
    return code is String ? code : null;
  }

  Map<String, dynamic> _responseMap(FunctionResponse response) {
    if (response.status < 200 || response.status >= 300) {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.unavailable,
        'SPEECH_SERVICE',
      );
    }
    final data = response.data;
    if (data is! Map) {
      throw const VoiceServiceException(
        VoiceServiceFailureKind.invalidResponse,
        'SPEECH_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(data);
  }
}
