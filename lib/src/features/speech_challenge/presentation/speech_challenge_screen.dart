import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';
import 'package:konterreflex/src/shared/widgets/optional_transcript.dart';
import 'package:konterreflex/src/shared/widgets/voice_turn_orb.dart';

class SpeechChallengeScreen extends ConsumerWidget {
  const SpeechChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(challengeSetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Challenge')),
      body: SafeArea(
        child: sets.when(
          data: (items) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Wähle ein Thema',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                  'Kurze Impulse, gesprochene Antworten und direktes qualitatives Feedback.'),
              const SizedBox(height: AppSpacing.lg),
              for (final set in items)
                Card(
                  child: ListTile(
                    title: Text(set.title),
                    subtitle: Text(set.description),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) =>
                          _ChallengeSessionScreen(challengeSet: set),
                    )),
                  ),
                ),
            ],
          ),
          error: (_, __) => const Center(
              child: Text('Die Challenge-Sets konnten nicht geladen werden.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ChallengeSessionScreen extends ConsumerStatefulWidget {
  const _ChallengeSessionScreen({required this.challengeSet});
  final ChallengeSet challengeSet;

  @override
  ConsumerState<_ChallengeSessionScreen> createState() =>
      _ChallengeSessionScreenState();
}

class _ChallengeSessionScreenState
    extends ConsumerState<_ChallengeSessionScreen> {
  late final SpeechChallengeController _controller;

  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);
    _controller = SpeechChallengeController(
      challengeSet: widget.challengeSet,
      repository: ref.read(speechChallengeRepositoryProvider),
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
                  child: Column(
                    children: [
                      IntelligenceOrb(
                          size: 156, state: _controller.voice.state.orbState),
                      const SizedBox(height: AppSpacing.xl),
                      Text(_statusText(_controller.status),
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      if (_controller.message != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(_controller.message!, textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      if (_controller.status == SpeechChallengeStatus.ready ||
                          _controller.status == SpeechChallengeStatus.error ||
                          _controller.status == SpeechChallengeStatus.complete)
                        FilledButton.icon(
                          onPressed: _controller.startHandsFree,
                          icon: const Icon(Icons.mic_none_rounded),
                          label: Text(_controller.status ==
                                  SpeechChallengeStatus.complete
                              ? 'Noch einmal'
                              : 'Freihändig starten'),
                        )
                      else
                        OutlinedButton.icon(
                            onPressed: _controller.stop,
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Challenge beenden')),
                      if (_controller.transcript case final transcript?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OptionalTranscript(transcript: transcript),
                      ],
                      if (_controller.feedback case final feedback?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                    '${feedback.headline}\n\n${feedback.improvement}'))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  String _statusText(SpeechChallengeStatus status) => switch (status) {
        SpeechChallengeStatus.ready => 'Bereit für kurze Impulse?',
        SpeechChallengeStatus.playing => 'Hör zu',
        SpeechChallengeStatus.listening => 'Sprich deine Antwort',
        SpeechChallengeStatus.reflecting => 'Kurze Reflexion …',
        SpeechChallengeStatus.complete => 'Set abgeschlossen',
        SpeechChallengeStatus.error => 'Kurz unterbrochen',
      };
}
