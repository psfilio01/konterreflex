import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/theme/app_theme.dart';

class KonterreflexApp extends ConsumerWidget {
  const KonterreflexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Konterreflex',
      theme: AppTheme.light(),
      locale: language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
