import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
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
    _controller = RealLifeReplayController(
      permission: PermissionHandlerMicrophone(),
      recorder: RecordVoiceRecorder(),
      playback: JustAudioPlaybackQueue(),
      speech: SupabaseSpeechGateway(client),
      ai: ref.read(realLifeAiServiceProvider),
      repository: ref.read(realLifeRepositoryProvider),
      feedbackRepository: ref.read(feedbackRepositoryProvider),
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
      appBar: AppBar(title: const Text('Echte Situation')),
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
                      IntelligenceOrb(size: 156, state: _controller.orbState),
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
        RealLifeReplayStatus.ready => 'Was ist passiert?',
        RealLifeReplayStatus.describing => 'Erzähl in deinem Tempo',
        RealLifeReplayStatus.extracting => 'Situation wird verstanden …',
        RealLifeReplayStatus.confirmExtraction =>
          'Passt diese Zusammenfassung?',
        RealLifeReplayStatus.recordingFollowUp => 'Ergänze nur das Wesentliche',
        RealLifeReplayStatus.reconstructing => 'Szene wird rekonstruiert …',
        RealLifeReplayStatus.readyToReplay => 'Bereit für den zweiten Versuch?',
        RealLifeReplayStatus.playing => 'Hör dir die Szene an',
        RealLifeReplayStatus.awaitingResponse => 'Wie antwortest du jetzt?',
        RealLifeReplayStatus.recordingResponse => 'Du sprichst',
        RealLifeReplayStatus.processingResponse => 'Antwort wird reflektiert …',
        RealLifeReplayStatus.feedbackReady => 'Dein Feedback',
        RealLifeReplayStatus.error => 'Das hat noch nicht geklappt',
      };

  String _subtitle(RealLifeReplayStatus status) => switch (status) {
        RealLifeReplayStatus.ready =>
          'Beschreibe Ort, Beteiligte und den entscheidenden Satz. Tippen ist nicht nötig.',
        RealLifeReplayStatus.confirmExtraction =>
          'Du kannst bestätigen oder eine wesentliche Lücke per Stimme ergänzen.',
        RealLifeReplayStatus.feedbackReady =>
          'Wiederhole die Szene oder übe eine ähnliche Variante.',
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
            _Detail(label: 'Ort und Rahmen', value: extraction.setting),
            _Detail(
              label: 'Beteiligte',
              value: extraction.participants
                  .map((person) => '${person.name} · ${person.relationship}')
                  .join(', '),
            ),
            _Detail(
              label: 'Entscheidender Satz',
              value: extraction.triggerStatement,
            ),
            _Detail(
              label: 'Beobachtbarer Ton',
              value: extraction.observableTone,
            ),
            _Detail(
              label: 'Soziale Spannung',
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
          Text(value.isEmpty ? 'Nicht sicher' : value),
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
          label: const Text('Situation erzählen'),
        ),
      RealLifeReplayStatus.describing => FilledButton.icon(
          onPressed: controller.finishDescription,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Erzählung beenden'),
        ),
      RealLifeReplayStatus.confirmExtraction => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: controller.confirmAndReconstruct,
              child: const Text('Passt · Szene erstellen'),
            ),
            if (controller.nextEssentialQuestion != null)
              OutlinedButton.icon(
                onPressed: controller.startEssentialFollowUp,
                icon: const Icon(Icons.mic_none_rounded),
                label: const Text('Per Stimme ergänzen'),
              ),
          ],
        ),
      RealLifeReplayStatus.recordingFollowUp => FilledButton(
          onPressed: controller.finishEssentialFollowUp,
          child: const Text('Ergänzung übernehmen'),
        ),
      RealLifeReplayStatus.readyToReplay => FilledButton.icon(
          onPressed: controller.playReplay,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Szene abspielen'),
        ),
      RealLifeReplayStatus.awaitingResponse => FilledButton.icon(
          onPressed: controller.startResponse,
          icon: const Icon(Icons.mic_none_rounded),
          label: const Text('Neu antworten'),
        ),
      RealLifeReplayStatus.recordingResponse => FilledButton.icon(
          onPressed: controller.finishResponse,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Antwort beenden'),
        ),
      RealLifeReplayStatus.feedbackReady => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: controller.repeatReplay,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Gleiche Szene wiederholen'),
            ),
            OutlinedButton(
              onPressed: controller.createSimilarVariation,
              child: const Text('Ähnliche Variante'),
            ),
          ],
        ),
      RealLifeReplayStatus.error => OutlinedButton(
          onPressed: controller.reset,
          child: const Text('Neu beginnen'),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
