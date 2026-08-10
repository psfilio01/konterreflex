import 'package:flutter/material.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';

class QualitativeFeedbackSummary extends StatelessWidget {
  const QualitativeFeedbackSummary({required this.feedback, super.key});

  final QualitativeFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final overall = _SignalPresentation(
      feedback.overallSignal,
      context.l10n,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          label: '${context.l10n.feedbackOverview}: ${overall.label}',
          child: ExcludeSemantics(
            child: Container(
              key: Key('feedback-overall-${feedback.overallSignal.wireName}'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.large),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [overall.background, AppColors.surface],
                ),
                border: Border.all(
                    color: overall.foreground.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: overall.foreground.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      overall.icon,
                      size: 30,
                      color: overall.foreground,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.feedbackOverview,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.muted,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          overall.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.xs;
            final columns = constraints.maxWidth >= 480 ? 3 : 2;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _DimensionSignal(
                  width: itemWidth,
                  keyName: 'posture',
                  label: context.l10n.feedbackDimensionPosture,
                  signal: feedback.dimensionSignals.posture,
                ),
                _DimensionSignal(
                  width: itemWidth,
                  keyName: 'precision',
                  label: context.l10n.feedbackDimensionPrecision,
                  signal: feedback.dimensionSignals.precision,
                ),
                _DimensionSignal(
                  width: itemWidth,
                  keyName: 'frame',
                  label: context.l10n.feedbackDimensionFrame,
                  signal: feedback.dimensionSignals.frame,
                ),
                _DimensionSignal(
                  width: itemWidth,
                  keyName: 'social-effect',
                  label: context.l10n.feedbackDimensionSocialEffect,
                  signal: feedback.dimensionSignals.socialEffect,
                ),
                _DimensionSignal(
                  width: itemWidth,
                  keyName: 'naturalness',
                  label: context.l10n.feedbackDimensionNaturalness,
                  signal: feedback.dimensionSignals.naturalness,
                ),
                _DimensionSignal(
                  width: itemWidth,
                  keyName: 'escalation-fit',
                  label: context.l10n.feedbackDimensionEscalationFit,
                  signal: feedback.dimensionSignals.escalationFit,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class FeedbackSignalBadge extends StatelessWidget {
  const FeedbackSignalBadge({required this.signal, super.key});

  final FeedbackSignal signal;

  @override
  Widget build(BuildContext context) {
    final presentation = _SignalPresentation(signal, context.l10n);
    return Semantics(
      label: presentation.label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: presentation.background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                presentation.icon,
                size: 18,
                color: presentation.foreground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  presentation.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: presentation.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DimensionSignal extends StatelessWidget {
  const _DimensionSignal({
    required this.width,
    required this.keyName,
    required this.label,
    required this.signal,
  });

  final double width;
  final String keyName;
  final String label;
  final FeedbackSignal signal;

  @override
  Widget build(BuildContext context) {
    final presentation = _SignalPresentation(signal, context.l10n);
    return Semantics(
      container: true,
      label: '$label: ${presentation.label}',
      child: ExcludeSemantics(
        child: Container(
          key: Key('feedback-dimension-$keyName-${signal.wireName}'),
          width: width,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: presentation.background.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(
              color: presentation.foreground.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                presentation.icon,
                size: 20,
                color: presentation.foreground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalPresentation {
  _SignalPresentation(this.signal, AppLocalizations strings)
      : label = switch (signal) {
          FeedbackSignal.strong => strings.feedbackSignalStrong,
          FeedbackSignal.developing => strings.feedbackSignalDeveloping,
          FeedbackSignal.focus => strings.feedbackSignalFocus,
        };

  final FeedbackSignal signal;
  final String label;

  IconData get icon => switch (signal) {
        FeedbackSignal.strong => Icons.check_circle_rounded,
        FeedbackSignal.developing => Icons.trending_up_rounded,
        FeedbackSignal.focus => Icons.replay_circle_filled_rounded,
      };

  Color get foreground => switch (signal) {
        FeedbackSignal.strong => AppColors.success,
        FeedbackSignal.developing => const Color(0xFF76562C),
        FeedbackSignal.focus => const Color(0xFF665778),
      };

  Color get background => switch (signal) {
        FeedbackSignal.strong => AppColors.mist,
        FeedbackSignal.developing => AppColors.sand,
        FeedbackSignal.focus => AppColors.lavender,
      };
}
