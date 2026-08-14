import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  bool _loading = true;
  bool _empty = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_selectScenario());
  }

  Future<void> _selectScenario() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _empty = false;
        _error = null;
      });
    }
    try {
      final scenario = await ref
          .read(scenarioRepositoryProvider)
          .fetchNextAdaptiveScenario();
      if (!mounted) return;
      if (scenario == null) {
        setState(() {
          _loading = false;
          _empty = true;
        });
        return;
      }
      context.replaceNamed(
        AppRoute.trainingSession,
        pathParameters: {'scenarioId': scenario.id},
        queryParameters: {'autoStart': 'true'},
        extra: scenario,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trainingTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntelligenceOrb(
                    size: 156,
                    state: _loading
                        ? IntelligenceOrbState.preparing
                        : IntelligenceOrbState.idle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _empty
                        ? context.l10n.noApprovedScenarios
                        : _error != null
                            ? context.l10n.scenariosLoadError
                            : context.l10n.trainingSelectingTitle,
                    key: const Key('training-selection-status'),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_loading) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.trainingSelectingBody,
                      style: const TextStyle(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      key: const Key('retry-adaptive-training'),
                      onPressed: _selectScenario,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
