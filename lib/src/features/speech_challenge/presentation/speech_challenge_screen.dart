import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_card.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_summary.dart';
import 'package:konterreflex/src/shared/widgets/voice_turn_orb.dart';

class SpeechChallengeScreen extends ConsumerWidget {
  const SpeechChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(challengeSetsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.speechChallengeTitle)),
      body: SafeArea(
        child: sets.when(
          data: (items) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                context.l10n.chooseTopic,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.speechChallengeIntro),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < items.length; index++) ...[
                Card(
                  child: ListTile(
                    title: Text(items[index].title),
                    subtitle: Text(items[index].description),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChallengeSessionScreen(
                          challengeSet: items[index],
                        ),
                      ),
                    ),
                  ),
                ),
                if (index < items.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
          error: (_, __) =>
              Center(child: Text(context.l10n.challengeSetsLoadError)),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class ChallengeSessionScreen extends ConsumerStatefulWidget {
  const ChallengeSessionScreen({required this.challengeSet, super.key});

  final ChallengeSet challengeSet;

  @override
  ConsumerState<ChallengeSessionScreen> createState() =>
      _ChallengeSessionScreenState();
}

class _ChallengeSessionScreenState
    extends ConsumerState<ChallengeSessionScreen> {
  late final SpeechChallengeController _controller;
  late final TextEditingController _customCountController;
  late final int _maxCount;
  int? _selectedCount;

  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);
    final strings = ref.read(appLocalizationsProvider);
    final language = ref.read(appLanguageProvider);
    _maxCount = min(
      widget.challengeSet.prompts.length,
      maxSpeechChallengePromptCount,
    );
    _selectedCount = min(5, _maxCount);
    _customCountController = TextEditingController();
    _controller = SpeechChallengeController(
      challengeSet: widget.challengeSet,
      repository: ref.read(speechChallengeRepositoryProvider),
      evaluationRepository:
          ref.read(speechChallengeEvaluationRepositoryProvider),
      strings: strings,
      voice: VoiceTurnController(
        permission: PermissionHandlerMicrophone(),
        recorder: RecordVoiceRecorder(),
        playback: JustAudioPlaybackQueue(),
        speech: SupabaseSpeechGateway(client, language: language),
        strings: strings,
      ),
    );
  }

  @override
  void dispose() {
    _customCountController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.challengeSet.title)),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _content(),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _content() {
    if (_controller.status == SpeechChallengeStatus.ready) {
      return _setup();
    }
    if (_controller.status == SpeechChallengeStatus.complete &&
        _controller.result != null) {
      return _result(_controller.result!);
    }
    if (_controller.status == SpeechChallengeStatus.error &&
        _controller.canRetryEvaluation) {
      return _evaluationError();
    }
    return _activeSession();
  }

  Widget _setup() {
    final presets = [5, 10, 15].where((count) => count <= _maxCount);
    final customText = _customCountController.text;
    final customCount = int.tryParse(customText);
    final hasInvalidCustomValue = customText.isNotEmpty &&
        (customCount == null || customCount < 1 || customCount > _maxCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.sage,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.challengeLengthTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.challengeLengthBody,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          key: const Key('challenge-count-presets'),
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final count in presets)
              ChoiceChip(
                key: Key('challenge-count-$count'),
                label: Text('$count'),
                selected: _selectedCount == count && customText.isEmpty,
                onSelected: (_) => setState(() {
                  _selectedCount = count;
                  _customCountController.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('challenge-custom-count'),
          controller: _customCountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 2,
          decoration: InputDecoration(
            labelText: context.l10n.challengeLengthCustom,
            helperText: context.l10n.challengeAvailableCount(_maxCount),
            errorText: hasInvalidCustomValue
                ? context.l10n.challengeLengthRange(_maxCount)
                : null,
            counterText: '',
          ),
          onChanged: (value) => setState(() {
            final parsed = int.tryParse(value);
            _selectedCount =
                parsed != null && parsed >= 1 && parsed <= _maxCount
                    ? parsed
                    : null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          key: const Key('start-configured-challenge'),
          onPressed: _selectedCount == null
              ? null
              : () => _controller.startHandsFree(
                    promptCount: _selectedCount!,
                  ),
          icon: const Icon(Icons.mic_none_rounded),
          label: Text(
            context.l10n.startChallengeWithCount(_selectedCount ?? 0),
          ),
        ),
      ],
    );
  }

  Widget _activeSession() {
    final status = _controller.status;
    final showProgress = _controller.targetCount > 0;
    return Column(
      children: [
        VoiceTurnOrb(
          size: 156,
          controller: _controller.voiceController,
        ),
        if (showProgress) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.challengeProgress(
              _controller.activePromptNumber,
              _controller.targetCount,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            key: const Key('challenge-session-progress'),
            value: _controller.completedCount / _controller.targetCount,
            semanticsLabel: context.l10n.challengeProgress(
              _controller.activePromptNumber,
              _controller.targetCount,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            backgroundColor: AppColors.mist,
            color: AppColors.sage,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          _statusText(status),
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (_controller.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_controller.message!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (status == SpeechChallengeStatus.error)
          FilledButton.icon(
            onPressed: _newChallenge,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.newChallenge),
          )
        else if (status != SpeechChallengeStatus.evaluating)
          OutlinedButton.icon(
            onPressed: _controller.stop,
            icon: const Icon(Icons.stop_rounded),
            label: Text(context.l10n.endChallenge),
          ),
      ],
    );
  }

  Widget _evaluationError() => Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: AppColors.sage,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.brieflyInterrupted,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (_controller.message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_controller.message!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const Key('retry-challenge-evaluation'),
            onPressed: _controller.retryEvaluation,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retryChallengeEvaluation),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _newChallenge,
            child: Text(context.l10n.newChallenge),
          ),
        ],
      );

  Widget _result(ChallengeSessionResult result) {
    return SpeechChallengeResultView(
      result: result,
      targetCount: _controller.targetCount,
      onNewChallenge: _newChallenge,
    );
  }

  Future<void> _newChallenge() async {
    await _controller.reset();
    if (!mounted) return;
    setState(() {
      _selectedCount = min(5, _maxCount);
      _customCountController.clear();
    });
  }

  String _statusText(SpeechChallengeStatus status) => switch (status) {
        SpeechChallengeStatus.ready => context.l10n.challengeReady,
        SpeechChallengeStatus.playing => context.l10n.listen,
        SpeechChallengeStatus.listening => context.l10n.speakResponse,
        SpeechChallengeStatus.transitioning =>
          context.l10n.challengeTransitioning,
        SpeechChallengeStatus.evaluating => context.l10n.challengeEvaluating,
        SpeechChallengeStatus.complete => context.l10n.setComplete,
        SpeechChallengeStatus.error => context.l10n.brieflyInterrupted,
      };
}

class SpeechChallengeResultView extends StatelessWidget {
  const SpeechChallengeResultView({
    required this.result,
    required this.targetCount,
    required this.onNewChallenge,
    super.key,
  });

  final ChallengeSessionResult result;
  final int targetCount;
  final VoidCallback onNewChallenge;

  @override
  Widget build(BuildContext context) {
    final completed = result.details.length;
    final isPartial = completed < targetCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.challengeResultTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isPartial
              ? context.l10n.challengePartialResultBody(
                  completed,
                  targetCount,
                )
              : context.l10n.challengeResultBody(completed),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        QualitativeFeedbackCard(feedback: result.summary),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.challengeDetailsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < result.details.length; index++) ...[
          _ChallengeDetailCard(
            index: index,
            detail: result.details[index],
          ),
          if (index < result.details.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: onNewChallenge,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.newChallenge),
        ),
      ],
    );
  }
}

class _ChallengeDetailCard extends StatelessWidget {
  const _ChallengeDetailCard({required this.index, required this.detail});

  final int index;
  final ChallengeResponseDetail detail;

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          key: Key('challenge-detail-${index + 1}'),
          leading: Semantics(
            label: context.l10n.challengePromptNumber(index + 1),
            child: ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          title: Text(detail.answer.prompt.remark),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FeedbackSignalBadge(signal: detail.signal),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail.answer.prompt.context.isNotEmpty) ...[
              Text(
                detail.answer.prompt.context,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              detail.headline,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.challengeYourAnswer,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(detail.answer.transcript),
            const SizedBox(height: AppSpacing.md),
            _DetailPoint(
              icon: Icons.check_circle_outline_rounded,
              label: context.l10n.feedbackStrengths,
              text: detail.strength,
            ),
            _DetailPoint(
              icon: Icons.arrow_forward_rounded,
              label: context.l10n.feedbackNextStep,
              text: detail.improvement,
            ),
            _DetailPoint(
              icon: Icons.format_quote_rounded,
              label: context.l10n.challengeDetailAlternative,
              text: detail.alternative,
            ),
          ],
        ),
      );
}

class _DetailPoint extends StatelessWidget {
  const _DetailPoint({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.sage),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      );
}
