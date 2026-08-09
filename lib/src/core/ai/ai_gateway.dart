import 'package:supabase_flutter/supabase_flutter.dart';

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

abstract interface class AiGateway {
  Future<AiGatewayResult> invoke({
    required String task,
    required Map<String, dynamic> payload,
  });
}

class SupabaseAiGateway implements AiGateway {
  SupabaseAiGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<AiGatewayResult> invoke({
    required String task,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _client.functions.invoke(
      'ai-gateway',
      body: {'task': task, 'payload': payload, 'schemaVersion': '1'},
    );
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
