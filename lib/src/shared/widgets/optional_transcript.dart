import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';

class OptionalTranscript extends StatefulWidget {
  const OptionalTranscript({
    required this.transcript,
    this.initiallyVisible = false,
    super.key,
  });

  final String transcript;
  final bool initiallyVisible;

  @override
  State<OptionalTranscript> createState() => _OptionalTranscriptState();
}

class _OptionalTranscriptState extends State<OptionalTranscript> {
  late bool _visible = widget.initiallyVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _visible = !_visible),
          icon:
              Icon(_visible ? Icons.visibility_off : Icons.subtitles_outlined),
          label: Text(_visible
              ? context.l10n.hideTranscript
              : context.l10n.showTranscript),
        ),
        if (_visible)
          Semantics(
            label: context.l10n.transcriptLabel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppRadii.medium),
                ),
              ),
              child: SelectableText(widget.transcript),
            ),
          ),
      ],
    );
  }
}
