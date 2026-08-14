import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_ai_service.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_repository.dart';

final realLifeAiServiceProvider = Provider<RealLifeAiService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GatewayRealLifeAiService(
    SupabaseAiGateway(
      client,
      language: ref.watch(appLanguageProvider),
    ),
    scenarioTitle: ref.watch(appLocalizationsProvider).realLifeScenarioTitle,
    scenarioCategory: ref.watch(appLocalizationsProvider).realLifeTitle,
  );
});

final realLifeRepositoryProvider = Provider<RealLifeRepository>(
  (ref) => SupabaseRealLifeRepository(
    ref.watch(supabaseClientProvider),
    fallbackTitle: ref.watch(appLocalizationsProvider).savedRealLifeSituation,
    scenarioCategory: ref.watch(appLocalizationsProvider).realLifeTitle,
  ),
);
