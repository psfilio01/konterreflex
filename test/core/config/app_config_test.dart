import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('accepts a public Supabase client configuration', () {
      final config = AppConfig(
        supabaseUrl: 'http://127.0.0.1:55421',
        supabaseAnonKey: 'public-anon-key',
      );

      expect(config.supabaseUrl, 'http://127.0.0.1:55421');
      expect(config.supabaseAnonKey, 'public-anon-key');
    });

    test('rejects a missing URL', () {
      expect(
        () => AppConfig(supabaseUrl: '', supabaseAnonKey: 'public-anon-key'),
        throwsFormatException,
      );
    });

    test('rejects a missing anon key', () {
      expect(
        () => AppConfig(
          supabaseUrl: 'http://127.0.0.1:55421',
          supabaseAnonKey: '',
        ),
        throwsFormatException,
      );
    });
  });
}
