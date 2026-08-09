import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_generation_service.dart';
import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

final adminAccessProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider).asData?.value;
  if (user == null) return false;
  final result = await ref.watch(supabaseClientProvider).rpc('is_admin');
  return result == true;
});

final adminScenarioRepositoryProvider = Provider<AdminScenarioRepository>(
  (ref) => SupabaseAdminScenarioRepository(ref.watch(supabaseClientProvider)),
);

final adminScenariosProvider = FutureProvider<List<AdminScenario>>(
  (ref) => ref.watch(adminScenarioRepositoryProvider).fetchAll(),
);

final adminScenarioGenerationProvider =
    Provider<AdminScenarioGenerationService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminScenarioGenerationService(
      ai: SupabaseAiGateway(client),
      repository: ref.watch(adminScenarioRepositoryProvider));
});

final actorVoiceOptionsProvider =
    FutureProvider<List<ActorVoiceOption>>((ref) async {
  final result = await ref
      .watch(supabaseClientProvider)
      .from('app_config')
      .select('value')
      .eq('key', 'actor_voice_options')
      .maybeSingle();
  final values = result?['value'];
  if (values is! List) return const [];
  return values
      .whereType<Map>()
      .map((item) => ActorVoiceOption(
          label: item['label'] as String, id: item['id'] as String))
      .toList();
});

class ActorVoiceOption {
  const ActorVoiceOption({required this.label, required this.id});
  final String label;
  final String id;
}
