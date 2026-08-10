import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/real_life/application/real_life_providers.dart';
import 'package:konterreflex/src/features/real_life/application/real_life_replay_controller.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_card.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';
import 'package:konterreflex/src/shared/widgets/optional_transcript.dart';

class RealLifeReplayScreen extends ConsumerStatefulWidget {
  const RealLifeReplayScreen({super.key});

  @override
  ConsumerState<RealLifeReplayScreen> createState() =>
      _RealLifeReplayScreenState();
}

class _RealLifeReplayScreenState extends ConsumerState<RealLifeReplayScreen> {
  late final RealLifeReplayController _controller;

  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);
    final language = ref.read(appLanguageProvider);
    _controller = RealLifeReplayController(
      permission: PermissionHandlerMicrophone(),
      recorder: RecordVoiceRecorder(),
      playback: JustAudioPlaybackQueue(),
      speech: SupabaseSpeechGateway(client, language: language),
      ai: ref.read(realLifeAiServiceProvider),
      repository: ref.read(realLifeRepositoryProvider),
      feedbackRepository: ref.read(feedbackRepositoryProvider),
      strings: ref.read(appLocalizationsProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.realLifeTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      ValueListenableBuilder<double>(
                        valueListenable: _controller.voiceActivity,
                        builder: (context, activity, child) => IntelligenceOrb(
                          size: 156,
                          state: _controller.orbState,
                          activityLevel: activity,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        _title(_controller.status),
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _subtitle(_controller.status),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (_controller.message case final message?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(message, textAlign: TextAlign.center),
                      ],
                      if (_controller.extraction case final extraction?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ExtractionCard(extraction: extraction),
                      ],
                      if (_controller.sourceTranscript
                          case final transcript?) ...[
                        const SizedBox(height: AppSpacing.md),
                        OptionalTranscript(transcript: transcript),
                      ],
                      if (_controller.feedback case final feedback?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        QualitativeFeedbackCard(feedback: feedback),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _Actions(controller: _controller),
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

  String _title(RealLifeReplayStatus status) => switch (status) {
        RealLifeReplayStatus.ready => context.l10n.realLifeReadyTitle,
        RealLifeReplayStatus.describing => context.l10n.realLifeDescribingTitle,
        RealLifeReplayStatus.extracting => context.l10n.realLifeExtractingTitle,
        RealLifeReplayStatus.confirmExtraction =>
          context.l10n.realLifeConfirmTitle,
        RealLifeReplayStatus.recordingFollowUp =>
          context.l10n.realLifeFollowUpTitle,
        RealLifeReplayStatus.reconstructing =>
          context.l10n.realLifeReconstructingTitle,
        RealLifeReplayStatus.readyToReplay =>
          context.l10n.realLifeReplayReadyTitle,
        RealLifeReplayStatus.preparingPlayback =>
          context.l10n.realLifePreparingPlaybackTitle,
        RealLifeReplayStatus.playing => context.l10n.realLifePlayingTitle,
        RealLifeReplayStatus.awaitingResponse =>
          context.l10n.realLifeResponseTitle,
        RealLifeReplayStatus.recordingResponse =>
          context.l10n.realLifeRecordingTitle,
        RealLifeReplayStatus.processingResponse =>
          context.l10n.realLifeReflectingTitle,
        RealLifeReplayStatus.feedbackReady =>
          context.l10n.realLifeFeedbackTitle,
        RealLifeReplayStatus.error => context.l10n.realLifeErrorTitle,
      };

  String _subtitle(RealLifeReplayStatus status) => switch (status) {
        RealLifeReplayStatus.ready => context.l10n.realLifeReadyBody,
        RealLifeReplayStatus.confirmExtraction =>
          context.l10n.realLifeConfirmBody,
        RealLifeReplayStatus.feedbackReady => context.l10n.realLifeFeedbackBody,
        _ => '',
      };
}

class _ExtractionCard extends StatelessWidget {
  const _ExtractionCard({required this.extraction});

  final RealLifeExtraction extraction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Detail(
                label: context.l10n.settingDetail, value: extraction.setting),
            _Detail(
              label: context.l10n.participantsDetail,
              value: extraction.participants
                  .map((person) => '${person.name} · ${person.relationship}')
                  .join(', '),
            ),
            _Detail(
              label: context.l10n.triggerStatementDetail,
              value: extraction.triggerStatement,
            ),
            _Detail(
              label: context.l10n.observableToneDetail,
              value: extraction.observableTone,
            ),
            _Detail(
              label: context.l10n.socialTensionDetail,
              value: extraction.emotionalSocialTension,
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(value.isEmpty ? context.l10n.notSure : value),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.controller});

  final RealLifeReplayController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      RealLifeReplayStatus.ready => FilledButton.icon(
          onPressed: controller.startDescription,
          icon: const Icon(Icons.mic_none_rounded),
          label: Text(context.l10n.tellSituation),
        ),
      RealLifeReplayStatus.describing => FilledButton.icon(
          onPressed: controller.finishDescription,
          icon: const Icon(Icons.stop_rounded),
          label: Text(context.l10n.finishStory),
        ),
      RealLifeReplayStatus.confirmExtraction => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: controller.confirmAndReconstruct,
              child: Text(context.l10n.confirmCreateScene),
            ),
            if (controller.nextEssentialQuestion != null)
              OutlinedButton.icon(
                onPressed: controller.startEssentialFollowUp,
                icon: const Icon(Icons.mic_none_rounded),
                label: Text(context.l10n.addByVoice),
              ),
          ],
        ),
      RealLifeReplayStatus.recordingFollowUp => FilledButton(
          onPressed: controller.finishEssentialFollowUp,
          child: Text(context.l10n.acceptAddition),
        ),
      RealLifeReplayStatus.readyToReplay => FilledButton.icon(
          onPressed: controller.playReplay,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.l10n.playScene),
        ),
      RealLifeReplayStatus.awaitingResponse => FilledButton.icon(
          onPressed: controller.startResponse,
          icon: const Icon(Icons.mic_none_rounded),
          label: Text(context.l10n.answerAgain),
        ),
      RealLifeReplayStatus.recordingResponse => FilledButton.icon(
          onPressed: controller.finishResponse,
          icon: const Icon(Icons.stop_rounded),
          label: Text(context.l10n.finishAnswer),
        ),
      RealLifeReplayStatus.feedbackReady => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: controller.repeatReplay,
              icon: const Icon(Icons.replay_rounded),
              label: Text(context.l10n.repeatSameScene),
            ),
            OutlinedButton(
              onPressed: controller.createSimilarVariation,
              child: Text(context.l10n.similarVariation),
            ),
          ],
        ),
      RealLifeReplayStatus.error => OutlinedButton(
          onPressed: controller.reset,
          child: Text(context.l10n.startOver),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
