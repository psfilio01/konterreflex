import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(approvedScenariosProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trainingTitle)),
      body: SafeArea(
        child: scenarios.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.scenariosLoadError),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(approvedScenariosProvider),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => _ScenarioList(scenarios: items),
        ),
      ),
    );
  }
}

class _ScenarioList extends StatelessWidget {
  const _ScenarioList({required this.scenarios});

  final List<TrainingScenario> scenarios;

  @override
  Widget build(BuildContext context) {
    if (scenarios.isEmpty) {
      return Center(child: Text(context.l10n.noApprovedScenarios));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: scenarios.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            leading: CircleAvatar(
              backgroundColor: AppColors.mist,
              child: Icon(
                scenario.isGroup ? Icons.groups_outlined : Icons.person_outline,
                color: AppColors.sage,
              ),
            ),
            title: Text(scenario.title),
            subtitle: Text(
              '${scenario.category} · ${scenario.isGroup ? context.l10n.groupLabel : '1:1'}',
            ),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () => context.pushNamed(
              AppRoute.trainingSession,
              pathParameters: {'scenarioId': scenario.id},
              extra: scenario,
            ),
          ),
        );
      },
    );
  }
}
