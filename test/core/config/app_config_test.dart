import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('accepts a public Supabase client configuration', () {
      final config = AppConfig(
        supabaseUrl: 'http://127.0.0.1:55421',
        supabasePublishableKey: 'sb_publishable_public-client-key',
      );

      expect(config.supabaseUrl, 'http://127.0.0.1:55421');
      expect(
        config.supabasePublishableKey,
        'sb_publishable_public-client-key',
      );
      expect(config.environment, AppEnvironment.development);
    });

    test('rejects a missing URL', () {
      expect(
        () => AppConfig(
          supabaseUrl: '',
          supabasePublishableKey: 'sb_publishable_public-client-key',
        ),
        throwsFormatException,
      );
    });

    test('rejects a missing publishable key', () {
      expect(
        () => AppConfig(
          supabaseUrl: 'http://127.0.0.1:55421',
          supabasePublishableKey: '',
        ),
        throwsFormatException,
      );
    });

    test('accepts an HTTPS production configuration', () {
      final config = AppConfig(
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'sb_publishable_public-client-key',
        environment: AppEnvironment.production,
      );

      expect(config.environment, AppEnvironment.production);
    });

    test('rejects HTTP and local production URLs', () {
      for (final url in [
        'http://project.supabase.co',
        'https://localhost:55421',
      ]) {
        expect(
          () => AppConfig(
            supabaseUrl: url,
            supabasePublishableKey: 'sb_publishable_public-client-key',
            environment: AppEnvironment.production,
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects placeholder production keys', () {
      expect(
        () => AppConfig(
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: 'replace-with-production-key',
          environment: AppEnvironment.production,
        ),
        throwsFormatException,
      );
    });

    test('parses only known environments', () {
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
      expect(() => AppEnvironment.parse('live'), throwsFormatException);
    });
  });
}
