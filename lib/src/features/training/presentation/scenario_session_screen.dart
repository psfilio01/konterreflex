import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/golden_book/application/golden_book_providers.dart';
import 'package:konterreflex/src/core/analytics/analytics_providers.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_card.dart';
import 'package:konterreflex/src/shared/widgets/optional_transcript.dart';
import 'package:konterreflex/src/shared/widgets/voice_turn_orb.dart';

class ScenarioSessionScreen extends ConsumerStatefulWidget {
  const ScenarioSessionScreen({
    required this.scenario,
    this.autoStart = false,
    this.testController,
    super.key,
  });

  final TrainingScenario scenario;
  final bool autoStart;

  @visibleForTesting
  final ScenarioSessionController? testController;

  @override
  ConsumerState<ScenarioSessionScreen> createState() =>
      _ScenarioSessionScreenState();
}

class _ScenarioSessionScreenState extends ConsumerState<ScenarioSessionScreen> {
  late final ScenarioSessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.testController ?? _createController();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.status == ScenarioSessionStatus.ready) {
          unawaited(_controller.start());
        }
      });
    }
  }

  ScenarioSessionController _createController() {
    final client = ref.read(supabaseClientProvider);
    final strings = ref.read(appLocalizationsProvider);
    final language = ref.read(appLanguageProvider);
    return ScenarioSessionController(
      scenario: widget.scenario,
      repository: ref.read(scenarioRepositoryProvider),
      feedbackRepository: ref.read(feedbackRepositoryProvider),
      goldenBookCapture: ref.read(goldenBookCaptureProvider),
      analytics: ref.read(privacyAnalyticsProvider),
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scenario.title)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final status = _controller.status;
            final permission = _controller.voice.permissionStatus;
            final feedback = _controller.feedback;
            final showsCompletedResult =
                status == ScenarioSessionStatus.feedbackReady &&
                    feedback != null;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      if (!showsCompletedResult) ...[
                        VoiceTurnOrb(
                          size: 156,
                          controller: _controller.voiceController,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Text(
                        _statusText(status),
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (_controller.message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _controller.message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                      if (showsCompletedResult) ...[
                        const SizedBox(height: AppSpacing.lg),
                        QualitativeFeedbackCard(
                          feedback: feedback,
                          onSavePhrase: _controller.savePhrase,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ] else
                        const SizedBox(height: AppSpacing.xl),
                      _PrimaryAction(
                        controller: _controller,
                        onNextScenario: () =>
                            context.replaceNamed(AppRoute.training),
                      ),
                      if (permission ==
                          MicrophonePermissionStatus.permanentlyDenied)
                        TextButton(
                          onPressed: _controller.openMicrophoneSettings,
                          child: Text(context.l10n.allowMicrophoneSettings),
                        ),
                      if (status == ScenarioSessionStatus.playing)
                        TextButton.icon(
                          onPressed: _controller.interrupt,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: Text(context.l10n.interruptPlayback),
                        ),
                      if (_controller.transcript case final transcript?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OptionalTranscript(transcript: transcript),
                      ],
                      if (!showsCompletedResult && feedback != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        QualitativeFeedbackCard(
                          feedback: feedback,
                          onSavePhrase: _controller.savePhrase,
                        ),
                      ],
                      if (_controller.savedPhrase case final phrase?) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(context.l10n.savedInGoldenBook(phrase)),
                      ],
                      if (_controller.followUpAnswer case final answer?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(answer),
                          ),
                        ),
                      ],
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

  String _statusText(ScenarioSessionStatus status) => switch (status) {
        ScenarioSessionStatus.ready => context.l10n.trainingReady,
        ScenarioSessionStatus.starting => context.l10n.trainingStarting,
        ScenarioSessionStatus.playing => context.l10n.trainingPlaying,
        ScenarioSessionStatus.awaitingResponse =>
          context.l10n.trainingAnswerPrompt,
        ScenarioSessionStatus.recording => context.l10n.trainingRecording,
        ScenarioSessionStatus.processing => context.l10n.trainingProcessing,
        ScenarioSessionStatus.feedbackReady =>
          context.l10n.trainingFeedbackReady,
        ScenarioSessionStatus.followUpRecording =>
          context.l10n.trainingFollowUp,
        ScenarioSessionStatus.followUpProcessing =>
          context.l10n.trainingFollowUpProcessing,
        ScenarioSessionStatus.goldenBookRecording =>
          context.l10n.trainingGoldenBookPrompt,
        ScenarioSessionStatus.goldenBookProcessing =>
          context.l10n.trainingGoldenBookProcessing,
        ScenarioSessionStatus.error => context.l10n.notComplete,
      };
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.controller,
    required this.onNextScenario,
  });

  final ScenarioSessionController controller;
  final VoidCallback onNextScenario;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      ScenarioSessionStatus.ready => FilledButton.icon(
          onPressed: controller.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.l10n.startScene),
        ),
      ScenarioSessionStatus.awaitingResponse => FilledButton.icon(
          onPressed: controller.startRecording,
          icon: const Icon(Icons.mic_none_rounded),
          label: Text(context.l10n.recordAnswer),
        ),
      ScenarioSessionStatus.recording => FilledButton.icon(
          onPressed: controller.submitResponse,
          icon: const Icon(Icons.stop_rounded),
          label: Text(context.l10n.stopRecording),
        ),
      ScenarioSessionStatus.followUpRecording => FilledButton.icon(
          onPressed: controller.submitFollowUp,
          icon: const Icon(Icons.stop_rounded),
          label: Text(context.l10n.sendFollowUp),
        ),
      ScenarioSessionStatus.goldenBookRecording => FilledButton.icon(
          onPressed: controller.submitGoldenBookCommand,
          icon: const Icon(Icons.stop_rounded),
          label: Text(context.l10n.sendVoiceCommand),
        ),
      ScenarioSessionStatus.feedbackReady => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('next-adaptive-scenario'),
              onPressed: onNextScenario,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(context.l10n.nextScenario),
            ),
            OutlinedButton.icon(
              onPressed: controller.startFollowUp,
              icon: const Icon(Icons.mic_none_rounded),
              label: Text(context.l10n.askFollowUp),
            ),
            OutlinedButton.icon(
              onPressed: controller.startGoldenBookCommand,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(context.l10n.savePhraseByVoice),
            ),
            OutlinedButton.icon(
              onPressed: controller.retryScene,
              icon: const Icon(Icons.replay_rounded),
              label: Text(context.l10n.repeatScene),
            ),
          ],
        ),
      ScenarioSessionStatus.error when controller.transcript != null =>
        FilledButton(
          onPressed: controller.retryPersistence,
          child: Text(context.l10n.retrySave),
        ),
      ScenarioSessionStatus.error => FilledButton(
          onPressed: controller.start,
          child: Text(context.l10n.restart),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
