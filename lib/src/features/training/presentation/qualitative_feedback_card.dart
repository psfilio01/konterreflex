import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';

class QualitativeFeedbackCard extends StatelessWidget {
  const QualitativeFeedbackCard(
      {required this.feedback, this.onSavePhrase, super.key});

  final QualitativeFeedback feedback;
  final Future<void> Function(String phrase)? onSavePhrase;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback.headline,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(feedback.explanation),
            if (feedback.strengths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(context.l10n.feedbackStrengths,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              for (final strength in feedback.strengths)
                _FeedbackPoint(icon: Icons.check_rounded, text: strength),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.feedbackNextStep,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            _FeedbackPoint(
              icon: Icons.arrow_forward_rounded,
              text: feedback.improvement,
            ),
            if (feedback.alternatives.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(context.l10n.feedbackAlternatives),
                children: [
                  for (final alternative in feedback.alternatives)
                    Row(
                      children: [
                        Expanded(
                          child: _FeedbackPoint(
                            icon: Icons.format_quote_rounded,
                            text: alternative,
                            selectable: true,
                          ),
                        ),
                        if (onSavePhrase != null)
                          IconButton(
                            tooltip: context.l10n.saveInGoldenBook,
                            onPressed: () => onSavePhrase!(alternative),
                            icon: const Icon(Icons.bookmark_add_outlined),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackPoint extends StatelessWidget {
  const _FeedbackPoint(
      {required this.icon, required this.text, this.selectable = false});

  final IconData icon;
  final String text;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.sage),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: selectable ? SelectableText(text) : Text(text)),
        ],
      ),
    );
  }
}
