import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('reads a safe capacity error from an Edge Function failure', () {
    const exception = FunctionException(
      status: 503,
      details: {
        'error': {
          'code': 'provider_capacity',
          'message': 'Das KI-Feedback ist gerade ausgelastet.',
        },
        'requestId': 'request-1',
      },
    );

    final parsed = AiGatewayException.fromFunctionException(exception);

    expect(parsed.code, 'provider_capacity');
    expect(parsed.status, 503);
    expect(parsed.isCapacityUnavailable, isTrue);
    expect(parsed.message, 'Das KI-Feedback ist gerade ausgelastet.');
  });

  test('uses a safe fallback for malformed Edge Function failures', () {
    const exception = FunctionException(
      status: 502,
      details: 'raw provider output',
    );

    final parsed = AiGatewayException.fromFunctionException(exception);

    expect(parsed.code, 'gateway_request_failed');
    expect(parsed.status, 502);
    expect(parsed.message, isNot(contains('raw provider output')));
  });
}
