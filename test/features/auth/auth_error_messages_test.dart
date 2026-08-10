import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/auth/domain/auth_error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps email rate limits to a German wait message', () {
    const error = AuthException(
      'email rate limit exceeded',
      statusCode: '429',
      code: 'over_email_send_rate_limit',
    );
    expect(
      authErrorMessageFor(error, fallback: 'fallback'),
      contains('Zu viele E-Mails'),
    );
  });
}
