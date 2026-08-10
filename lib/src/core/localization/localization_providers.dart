import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

final appLanguageProvider = Provider<AppLanguage>((ref) {
  final locale = ref.watch(profileProvider).valueOrNull?.locale;
  return AppLanguage.fromCode(locale);
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final language = ref.watch(appLanguageProvider);
  return lookupAppLocalizations(language.locale);
});
