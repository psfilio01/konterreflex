import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => SupabaseScenarioRepository(
    ref.watch(supabaseClientProvider),
    languageCode: ref.watch(appLanguageProvider).code,
  ),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFeedbackRepository(
    client: client,
    ai: SupabaseAiGateway(
      client,
      language: ref.watch(appLanguageProvider),
    ),
  );
});
