import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/auth/data/auth_repository.dart';

void main() {
  group('extractVerifyUri', () {
    test('parses a bare Supabase verify URL', () {
      final uri = SupabaseAuthRepository.extractVerifyUriForTest(
        'https://abc.supabase.co/auth/v1/verify?token=pkce_x&type=signup&redirect_to=konterreflex://login-callback',
      );
      expect(uri, isNotNull);
      expect(uri!.path, contains('/auth/v1/verify'));
      expect(uri.queryParameters['token'], 'pkce_x');
    });

    test('extracts a URL embedded in copied mail text', () {
      final uri = SupabaseAuthRepository.extractVerifyUriForTest(
        'Follow this link:\nhttps://abc.supabase.co/auth/v1/verify?token=pkce_y&type=magiclink\nThanks',
      );
      expect(uri, isNotNull);
      expect(uri!.queryParameters['token'], 'pkce_y');
    });

    test('rejects unrelated text', () {
      expect(
        SupabaseAuthRepository.extractVerifyUriForTest('hello world'),
        isNull,
      );
    });
  });
}
