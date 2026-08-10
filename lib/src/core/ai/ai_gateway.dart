import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';

class AiGatewayResult {
  const AiGatewayResult({
    required this.data,
    required this.provider,
    required this.model,
    required this.promptVersion,
  });

  final Map<String, dynamic> data;
  final String provider;
  final String model;
  final String promptVersion;
}

class AiGatewayException implements Exception {
  const AiGatewayException({
    required this.code,
    required this.message,
    required this.status,
  });

  factory AiGatewayException.fromFunctionException(
    FunctionException exception,
  ) {
    final details = exception.details;
    if (details is Map) {
      final error = details['error'];
      if (error is Map) {
        final code = error['code'];
        final message = error['message'];
        if (code is String && message is String) {
          return AiGatewayException(
            code: code,
            message: message,
            status: exception.status,
          );
        }
      }
    }
    return AiGatewayException(
      code: 'gateway_request_failed',
      message: 'Die KI ist gerade nicht erreichbar.',
      status: exception.status,
    );
  }

  final String code;
  final String message;
  final int status;

  bool get isCapacityUnavailable => code == 'provider_capacity';
}

abstract interface class AiGateway {
  Future<AiGatewayResult> invoke({
    required String task,
    required Map<String, dynamic> payload,
  });
}

class SupabaseAiGateway implements AiGateway {
  SupabaseAiGateway(
    this._client, {
    this.language = AppLanguage.german,
  });

  final SupabaseClient _client;
  final AppLanguage language;

  @override
  Future<AiGatewayResult> invoke({
    required String task,
    required Map<String, dynamic> payload,
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'ai-gateway',
        body: {
          'task': task,
          'payload': payload,
          'responseLanguage': language.code,
          'schemaVersion': '1',
        },
      );
    } on FunctionException catch (error) {
      throw AiGatewayException.fromFunctionException(error);
    }
    if (response.status < 200 || response.status >= 300) {
      throw StateError('AI gateway request failed.');
    }
    final body = response.data;
    if (body is! Map) throw const FormatException('Invalid AI response.');
    final data = body['data'];
    final provider = body['provider'];
    final model = body['model'];
    final promptVersion = body['promptVersion'];
    if (data is! Map ||
        provider is! String ||
        model is! String ||
        promptVersion is! String) {
      throw const FormatException('Invalid AI response metadata.');
    }
    return AiGatewayResult(
      data: Map<String, dynamic>.from(data),
      provider: provider,
      model: model,
      promptVersion: promptVersion,
    );
  }
}
