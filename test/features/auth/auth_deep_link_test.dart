import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/auth/data/auth_deep_link.dart';

void main() {
  group('isAuthCallbackUri', () {
    test('detects PKCE code callbacks', () {
      expect(
        isAuthCallbackUri(
          Uri.parse('konterreflex://login-callback?code=abc123'),
        ),
        isTrue,
      );
    });

    test('detects implicit tokens in the fragment', () {
      expect(
        isAuthCallbackUri(
          Uri.parse(
            'konterreflex://login-callback#access_token=tok&refresh_token=ref',
          ),
        ),
        isTrue,
      );
    });

    test('ignores plain app opens without auth params', () {
      expect(
        isAuthCallbackUri(Uri.parse('konterreflex://login-callback')),
        isFalse,
      );
    });
  });
}
