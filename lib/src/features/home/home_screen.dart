import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/analytics/analytics_providers.dart';
import 'package:konterreflex/src/core/analytics/privacy_analytics.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final modes = [
      _HomeMode(
        route: AppRoute.training,
        title: 'Training',
        description: l10n.homeTrainingDescription,
        icon: Icons.forum_outlined,
        analyticsFeature: AnalyticsFeature.training,
      ),
      _HomeMode(
        route: AppRoute.realLife,
        title: l10n.realLifeTitle,
        description: l10n.homeRealLifeDescription,
        icon: Icons.replay_rounded,
        analyticsFeature: AnalyticsFeature.realLife,
      ),
      _HomeMode(
        route: AppRoute.speechChallenge,
        title: l10n.speechChallengeTitle,
        description: l10n.homeSpeechChallengeDescription,
        icon: Icons.bolt_outlined,
        analyticsFeature: AnalyticsFeature.speechChallenge,
      ),
      _HomeMode(
        route: AppRoute.goldenBook,
        title: l10n.goldenBookTitle,
        description: l10n.homeGoldenBookDescription,
        icon: Icons.auto_stories_outlined,
        analyticsFeature: AnalyticsFeature.goldenBook,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konterreflex'),
        actions: [
          IconButton(
            tooltip: l10n.historyTitle,
            onPressed: () => context.pushNamed(AppRoute.history),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.pushNamed(AppRoute.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = mathMin(constraints.maxWidth, 760);
            final twoColumns = contentWidth >= 620;
            final cardWidth =
                twoColumns ? (contentWidth - AppSpacing.lg) / 2 : contentWidth;
            final orbSize =
                (contentWidth * 0.25).clamp(112.0, 164.0).toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      IntelligenceOrb(size: orbSize),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.homeQuestion,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.homeTagline,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.muted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final mode in modes)
                            SizedBox(
                              width: cardWidth,
                              child: _HomeModeCard(
                                mode: mode,
                                onTap: () {
                                  unawaited(ref
                                      .read(privacyAnalyticsProvider)
                                      .track(PrivacyAnalyticsEvent(
                                        name: AnalyticsEventName.modeOpened,
                                        feature: mode.analyticsFeature,
                                        step: AnalyticsStep.entry,
                                      ))
                                      .catchError((_) {}));
                                  context.pushNamed(mode.route);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double mathMin(double a, double b) => a < b ? a : b;

class _HomeMode {
  const _HomeMode({
    required this.route,
    required this.title,
    required this.description,
    required this.icon,
    required this.analyticsFeature,
  });

  final String route;
  final String title;
  final String description;
  final IconData icon;
  final AnalyticsFeature analyticsFeature;
}

class _HomeModeCard extends StatelessWidget {
  const _HomeModeCard({required this.mode, required this.onTap});

  final _HomeMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Icon(mode.icon, color: AppColors.sage),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
