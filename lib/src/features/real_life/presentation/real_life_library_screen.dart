import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/real_life/application/real_life_providers.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class RealLifeLibraryScreen extends ConsumerStatefulWidget {
  const RealLifeLibraryScreen({super.key});

  @override
  ConsumerState<RealLifeLibraryScreen> createState() =>
      _RealLifeLibraryScreenState();
}

class _RealLifeLibraryScreenState extends ConsumerState<RealLifeLibraryScreen> {
  List<RealLifeCaseSummary> _cases = const [];
  bool _loading = true;
  bool _startingRandom = false;
  Object? _error;

  String get _locale => ref.read(appLanguageProvider).code;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final cases = await ref
          .read(realLifeRepositoryProvider)
          .fetchCases(locale: _locale);
      if (!mounted) return;
      if (cases.isEmpty) {
        context.replaceNamed(AppRoute.realLifeNew);
        return;
      }
      setState(() {
        _cases = cases;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _startRandom() async {
    if (_startingRandom) return;
    setState(() => _startingRandom = true);
    try {
      final id = await ref
          .read(realLifeRepositoryProvider)
          .selectNextCaseId(locale: _locale);
      if (!mounted) return;
      if (id == null) {
        await _load();
        return;
      }
      await context.pushNamed(
        AppRoute.realLifeCase,
        pathParameters: {'caseId': id},
      );
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _startingRandom = false);
    }
  }

  Future<void> _openCase(String id) async {
    await context.pushNamed(
      AppRoute.realLifeCase,
      pathParameters: {'caseId': id},
    );
    if (mounted) await _load();
  }

  Future<void> _openNew() async {
    await context.pushNamed(AppRoute.realLifeNew);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.realLifeTitle)),
      body: SafeArea(
        child: _loading
            ? Center(
                child: IntelligenceOrb(
                  size: 148,
                  state: IntelligenceOrbState.preparing,
                ),
              )
            : _error != null
                ? _ErrorState(onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      Text(
                        context.l10n.savedRealLifeSituationsTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.realLifeLibraryIntro,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        key: const Key('random-real-life-practice'),
                        onPressed: _startingRandom ? null : _startRandom,
                        icon: const Icon(Icons.shuffle_rounded),
                        label: Text(
                          _startingRandom
                              ? context.l10n.realLifeRandomPreparing
                              : context.l10n.randomPractice,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        key: const Key('new-real-life-case'),
                        onPressed: _openNew,
                        icon: const Icon(Icons.mic_none_rounded),
                        label: Text(context.l10n.tellNewSituation),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      for (var index = 0; index < _cases.length; index++) ...[
                        _RealLifeCaseCard(
                          realCase: _cases[index],
                          onTap: () => _openCase(_cases[index].id),
                        ),
                        if (index < _cases.length - 1)
                          const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _RealLifeCaseCard extends StatelessWidget {
  const _RealLifeCaseCard({required this.realCase, required this.onTap});

  final RealLifeCaseSummary realCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (realCase.setting.isNotEmpty) realCase.setting,
      ...realCase.relationships,
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('real-life-case-${realCase.id}'),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: const CircleAvatar(
          backgroundColor: AppColors.mist,
          child: Icon(Icons.replay_rounded, color: AppColors.sage),
        ),
        title: Text(realCase.title),
        subtitle: details.isEmpty ? null : Text(details),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.realLifeLibraryLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const Key('retry-real-life-library'),
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
