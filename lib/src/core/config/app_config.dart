class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  }) {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'SUPABASE_URL must be an absolute http(s) URL.',
      );
    }
    if (supabaseAnonKey.trim().isEmpty) {
      throw const FormatException('SUPABASE_ANON_KEY must not be empty.');
    }
  }

  factory AppConfig.fromEnvironment() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
}
