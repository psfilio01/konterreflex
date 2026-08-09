import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => SupabaseScenarioRepository(ref.watch(supabaseClientProvider)),
);

final approvedScenariosProvider = FutureProvider<List<TrainingScenario>>(
  (ref) => ref.watch(scenarioRepositoryProvider).fetchApprovedScenarios(),
);
