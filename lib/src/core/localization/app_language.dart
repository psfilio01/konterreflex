import 'dart:ui';

enum AppLanguage {
  german('de'),
  english('en');

  const AppLanguage(this.code);

  factory AppLanguage.fromCode(String? code) => switch (code) {
        'en' => AppLanguage.english,
        _ => AppLanguage.german,
      };

  final String code;

  Locale get locale => Locale(code);
}
