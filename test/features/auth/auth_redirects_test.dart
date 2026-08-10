import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/auth/data/auth_redirects.dart';

void main() {
  test('uses separate mobile callbacks for auth and password recovery', () {
    expect(
      authRedirectUrl(AuthRedirectPurpose.authentication, web: false),
      'konterreflex://auth-callback',
    );
    expect(
      authRedirectUrl(AuthRedirectPurpose.passwordRecovery, web: false),
      'konterreflex://reset-password',
    );
  });

  test('uses the current web origin for auth callbacks', () {
    final base = Uri.parse('https://app.example.com/current/path');
    expect(
      authRedirectUrl(
        AuthRedirectPurpose.authentication,
        web: true,
        webBaseUrl: base,
      ),
      'https://app.example.com/',
    );
    expect(
      authRedirectUrl(
        AuthRedirectPurpose.passwordRecovery,
        web: true,
        webBaseUrl: base,
      ),
      'https://app.example.com/reset-password',
    );
  });
}
