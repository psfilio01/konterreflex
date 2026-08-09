import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_card.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';
import 'package:konterreflex/src/shared/widgets/optional_transcript.dart';
import 'package:konterreflex/src/shared/widgets/voice_turn_orb.dart';

class ScenarioSessionScreen extends ConsumerStatefulWidget {
  const ScenarioSessionScreen({required this.scenario, super.key});

  final TrainingScenario scenario;

  @override
  ConsumerState<ScenarioSessionScreen> createState() =>
      _ScenarioSessionScreenState();
}

class _ScenarioSessionScreenState extends ConsumerState<ScenarioSessionScreen> {
  late final ScenarioSessionController _controller;

  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);
    _controller = ScenarioSessionController(
      scenario: widget.scenario,
      repository: ref.read(scenarioRepositoryProvider),
      feedbackRepository: ref.read(feedbackRepositoryProvider),
      voice: VoiceTurnController(
        permission: PermissionHandlerMicrophone(),
        recorder: RecordVoiceRecorder(),
        playback: JustAudioPlaybackQueue(),
        speech: SupabaseSpeechGateway(client),
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      IntelligenceOrb(
                        size: 156,
                        state: _controller.voice.state.orbState,
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
                      const SizedBox(height: AppSpacing.xl),
                      _PrimaryAction(controller: _controller),
                      if (permission ==
                          MicrophonePermissionStatus.permanentlyDenied)
                        TextButton(
                          onPressed: _controller.openMicrophoneSettings,
                          child:
                              const Text('Mikrofon in Einstellungen erlauben'),
                        ),
                      if (status == ScenarioSessionStatus.playing)
                        TextButton.icon(
                          onPressed: _controller.interrupt,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Wiedergabe unterbrechen'),
                        ),
                      if (_controller.transcript case final transcript?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OptionalTranscript(transcript: transcript),
                      ],
                      if (_controller.feedback case final feedback?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        QualitativeFeedbackCard(feedback: feedback),
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
        ScenarioSessionStatus.ready => 'Bereit für die Situation?',
        ScenarioSessionStatus.starting => 'Training wird vorbereitet …',
        ScenarioSessionStatus.playing => 'Hör dir die Situation an',
        ScenarioSessionStatus.awaitingResponse => 'Wie antwortest du?',
        ScenarioSessionStatus.recording => 'Du sprichst',
        ScenarioSessionStatus.processing => 'Antwort wird verarbeitet …',
        ScenarioSessionStatus.feedbackReady => 'Dein Feedback',
        ScenarioSessionStatus.followUpRecording => 'Deine Rückfrage',
        ScenarioSessionStatus.followUpProcessing =>
          'Rückfrage wird beantwortet …',
        ScenarioSessionStatus.error => 'Noch nicht abgeschlossen',
      };
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.controller});

  final ScenarioSessionController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.status) {
      ScenarioSessionStatus.ready => FilledButton.icon(
          onPressed: controller.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Szene starten'),
        ),
      ScenarioSessionStatus.awaitingResponse => FilledButton.icon(
          onPressed: controller.startRecording,
          icon: const Icon(Icons.mic_none_rounded),
          label: const Text('Antwort aufnehmen'),
        ),
      ScenarioSessionStatus.recording => FilledButton.icon(
          onPressed: controller.submitResponse,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Aufnahme beenden'),
        ),
      ScenarioSessionStatus.followUpRecording => FilledButton.icon(
          onPressed: controller.submitFollowUp,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Rückfrage senden'),
        ),
      ScenarioSessionStatus.feedbackReady => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: controller.startFollowUp,
              icon: const Icon(Icons.mic_none_rounded),
              label: const Text('Rückfrage stellen'),
            ),
            OutlinedButton.icon(
              onPressed: controller.retryScene,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Szene wiederholen'),
            ),
          ],
        ),
      ScenarioSessionStatus.error when controller.transcript != null =>
        FilledButton(
          onPressed: controller.retryPersistence,
          child: const Text('Speichern erneut versuchen'),
        ),
      ScenarioSessionStatus.error => FilledButton(
          onPressed: controller.start,
          child: const Text('Erneut starten'),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
