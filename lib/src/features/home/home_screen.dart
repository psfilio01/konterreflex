import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _modes = [
    _HomeMode(
      route: AppRoute.training,
      title: 'Training',
      description: 'Alltagssituationen sicher durchspielen',
      icon: Icons.forum_outlined,
    ),
    _HomeMode(
      route: AppRoute.realLife,
      title: 'Echte Situation',
      description: 'Erlebtes rekonstruieren und neu beantworten',
      icon: Icons.replay_rounded,
    ),
    _HomeMode(
      route: AppRoute.speechChallenge,
      title: 'Speech Challenge',
      description: 'Kurz und spontan auf einen Impuls reagieren',
      icon: Icons.bolt_outlined,
    ),
    _HomeMode(
      route: AppRoute.goldenBook,
      title: 'Golden Book',
      description: 'Starke Formulierungen griffbereit sammeln',
      icon: Icons.auto_stories_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konterreflex'),
        actions: [
          IconButton(
            tooltip: 'Einstellungen',
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
                        'Was möchtest du trainieren?',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Hören. Reagieren. Reflektieren. Wiederholen.',
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
                          for (final mode in _modes)
                            SizedBox(
                              width: cardWidth,
                              child: _HomeModeCard(mode: mode),
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
  });

  final String route;
  final String title;
  final String description;
  final IconData icon;
}

class _HomeModeCard extends StatelessWidget {
  const _HomeModeCard({required this.mode});

  final _HomeMode mode;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(mode.route),
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
