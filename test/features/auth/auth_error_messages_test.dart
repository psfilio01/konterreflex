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
      contains('Zu viele Versuche'),
    );
  });

  test('does not expose raw invalid credential errors', () {
    const error = AuthException(
      'Invalid login credentials',
      code: 'invalid_credentials',
    );
    expect(
      authErrorMessageFor(error, fallback: 'fallback'),
      'E-Mail-Adresse oder Passwort stimmen nicht.',
    );
  });

  test('explains disabled social providers without technical details', () {
    const error = AuthException('Unsupported provider: google');
    expect(
      authErrorMessageFor(error, fallback: 'fallback'),
      'Diese Anmeldung ist noch nicht freigeschaltet.',
    );
  });
}
