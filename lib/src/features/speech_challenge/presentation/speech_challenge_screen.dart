import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/permission_handler_microphone.dart';
import 'package:konterreflex/src/core/audio/record_voice_recorder.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/features/training/presentation/qualitative_feedback_summary.dart';
import 'package:konterreflex/src/shared/widgets/optional_transcript.dart';
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
              Text(context.l10n.chooseTopic,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.speechChallengeIntro),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < items.length; index++) ...[
                Card(
                  child: ListTile(
                    title: Text(items[index].title),
                    subtitle: Text(items[index].description),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => _ChallengeSessionScreen(
                        challengeSet: items[index],
                      ),
                    )),
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
    final strings = ref.read(appLocalizationsProvider);
    final language = ref.read(appLanguageProvider);
    _controller = SpeechChallengeController(
      challengeSet: widget.challengeSet,
      repository: ref.read(speechChallengeRepositoryProvider),
      feedbackRepository: ref.read(feedbackRepositoryProvider),
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
                      VoiceTurnOrb(
                        size: 156,
                        controller: _controller.voiceController,
                      ),
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
                              ? context.l10n.again
                              : context.l10n.startHandsFree),
                        )
                      else
                        OutlinedButton.icon(
                            onPressed: _controller.stop,
                            icon: const Icon(Icons.stop_rounded),
                            label: Text(context.l10n.endChallenge)),
                      if (_controller.transcript case final transcript?) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OptionalTranscript(transcript: transcript),
                      ],
                      if (_controller.feedback case final feedback?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                QualitativeFeedbackSummary(feedback: feedback),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  feedback.headline,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(feedback.improvement),
                              ],
                            ),
                          ),
                        ),
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
        SpeechChallengeStatus.ready => context.l10n.challengeReady,
        SpeechChallengeStatus.playing => context.l10n.listen,
        SpeechChallengeStatus.listening => context.l10n.speakResponse,
        SpeechChallengeStatus.reflecting => context.l10n.shortReflection,
        SpeechChallengeStatus.complete => context.l10n.setComplete,
        SpeechChallengeStatus.error => context.l10n.brieflyInterrupted,
      };
}
