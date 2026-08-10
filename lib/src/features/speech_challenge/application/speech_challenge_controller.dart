import 'package:flutter/foundation.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

enum SpeechChallengeStatus {
  ready,
  playing,
  listening,
  reflecting,
  complete,
  error
}

class SpeechChallengeController extends ChangeNotifier {
  SpeechChallengeController({
    required this.challengeSet,
    required SpeechChallengeRepository repository,
    required FeedbackRepository feedbackRepository,
    required VoiceTurnController voice,
    String Function()? createId,
  })  : _repository = repository,
        _feedbackRepository = feedbackRepository,
        _voice = voice,
        _createId = createId ?? createClientUuid {
    _voice.addListener(_relayVoice);
  }

  final ChallengeSet challengeSet;
  final SpeechChallengeRepository _repository;
  final FeedbackRepository _feedbackRepository;
  final VoiceTurnController _voice;
  final String Function() _createId;
  SpeechChallengeStatus _status = SpeechChallengeStatus.ready;
  TrainingSessionRecord? _session;
  int _promptIndex = 0;
  bool _stopRequested = false;
  QualitativeFeedback? _feedback;
  String? _transcript;
  String? _message;

  SpeechChallengeStatus get status => _status;
  ChallengePrompt get currentPrompt => challengeSet.prompts[_promptIndex];
  int get completedCount => _promptIndex;
  VoiceTurnSnapshot get voice => _voice.snapshot;
  QualitativeFeedback? get feedback => _feedback;
  String? get transcript => _transcript;
  String? get message => _message ?? _voice.snapshot.message;

  Future<void> startHandsFree() async {
    if (challengeSet.prompts.isEmpty) return;
    _stopRequested = false;
    _promptIndex = 0;
    _feedback = null;
    _transcript = null;
    try {
      _session = await _repository.startSession(
        setId: challengeSet.id,
        clientId: _createId(),
      );
      while (_promptIndex < challengeSet.prompts.length && !_stopRequested) {
        final completed = await _runPrompt(challengeSet.prompts[_promptIndex]);
        if (!completed) return;
        _promptIndex += 1;
      }
      if (_promptIndex == challengeSet.prompts.length) {
        await _repository.completeSession(_session!.id);
        _setStatus(SpeechChallengeStatus.complete);
      } else {
        _setStatus(SpeechChallengeStatus.ready);
      }
    } catch (_) {
      _setError('Die Challenge konnte gerade nicht fortgesetzt werden.');
    }
  }

  Future<bool> _runPrompt(ChallengePrompt prompt) async {
    _voice.reset();
    _setStatus(SpeechChallengeStatus.playing);
    final played = await _voice.playScene([prompt.speechLine]);
    if (!played || _voice.snapshot.state != VoiceTurnState.awaitingUser) {
      _setError(
        _voice.snapshot.message ?? 'Der Impuls konnte nicht abgespielt werden.',
      );
      return false;
    }
    _setStatus(SpeechChallengeStatus.listening);
    final result = await _voice.captureHandsFree();
    if (result == null || result.transcript.trim().isEmpty) {
      _setError('Deine Antwort konnte nicht verstanden werden.');
      return false;
    }
    _transcript = result.transcript.trim();
    _setStatus(SpeechChallengeStatus.reflecting);
    final scenario = prompt.asScenario(challengeSet.title);
    final responseId = await _repository.saveResponse(
      sessionId: _session!.id,
      promptId: prompt.id,
      clientId: _createId(),
      transcript: _transcript!,
    );
    _feedback = await _feedbackRepository.evaluate(
      scenario: scenario,
      transcript: _transcript!,
    );
    await _feedbackRepository.save(
        responseId: responseId, feedback: _feedback!);
    await _voice
        .presentFeedback('${_feedback!.headline}. ${_feedback!.improvement}');
    notifyListeners();
    return true;
  }

  Future<void> stop() async {
    _stopRequested = true;
    await _voice.interrupt();
    _setStatus(SpeechChallengeStatus.ready);
  }

  void _relayVoice() => notifyListeners();
  void _setStatus(SpeechChallengeStatus value) {
    _status = value;
    _message = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = SpeechChallengeStatus.error;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _voice.removeListener(_relayVoice);
    _voice.dispose();
    super.dispose();
  }
}
