import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';

class QualitativeFeedbackCard extends StatelessWidget {
  const QualitativeFeedbackCard({required this.feedback, super.key});

  final QualitativeFeedback feedback;

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
              Text('Das trägt', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              for (final strength in feedback.strengths)
                _FeedbackPoint(icon: Icons.check_rounded, text: strength),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Nächster Schritt',
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
                title: const Text('Natürliche Alternativen'),
                children: [
                  for (final alternative in feedback.alternatives)
                    _FeedbackPoint(
                      icon: Icons.format_quote_rounded,
                      text: alternative,
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
  const _FeedbackPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.sage),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
