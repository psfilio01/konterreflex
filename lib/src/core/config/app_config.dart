enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' => AppEnvironment.development,
      'staging' => AppEnvironment.staging,
      'production' => AppEnvironment.production,
      _ => throw const FormatException(
          'APP_ENV must be development, staging or production.',
        ),
    };
  }
}

class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.environment = AppEnvironment.development,
  }) {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'SUPABASE_URL must be an absolute http(s) URL.',
      );
    }
    if (supabasePublishableKey.trim().isEmpty) {
      throw const FormatException(
        'SUPABASE_PUBLISHABLE_KEY must not be empty.',
      );
    }

    if (environment == AppEnvironment.production) {
      _validateProduction(uri, supabasePublishableKey);
    }
  }

  factory AppConfig.fromEnvironment() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    // Legacy alias still accepted while local CLI / older env files catch up.
    const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const environment = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    final key = publishableKey.isNotEmpty ? publishableKey : legacyAnonKey;

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: key,
      environment: AppEnvironment.parse(environment),
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;
  final AppEnvironment environment;

  static void _validateProduction(Uri uri, String publishableKey) {
    final host = uri.host.toLowerCase();
    if (uri.scheme != 'https') {
      throw const FormatException('Production SUPABASE_URL must use HTTPS.');
    }
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host.endsWith('.local')) {
      throw const FormatException(
        'Production SUPABASE_URL must not point to a local host.',
      );
    }

    final normalizedKey = publishableKey.trim().toLowerCase();
    const placeholderParts = ['replace', 'change-me', 'placeholder'];
    if (placeholderParts.any(normalizedKey.contains)) {
      throw const FormatException(
        'Production SUPABASE_PUBLISHABLE_KEY must not be a placeholder.',
      );
    }
  }
}
