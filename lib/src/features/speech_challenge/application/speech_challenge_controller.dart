import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_evaluation_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

enum SpeechChallengeStatus {
  ready,
  playing,
  listening,
  transitioning,
  evaluating,
  complete,
  error,
}

class SpeechChallengeController extends ChangeNotifier {
  SpeechChallengeController({
    required this.challengeSet,
    required SpeechChallengeRepository repository,
    required SpeechChallengeEvaluationRepository evaluationRepository,
    required VoiceTurnController voice,
    String Function()? createId,
    Random? random,
    AppLocalizations? strings,
  })  : _repository = repository,
        _evaluationRepository = evaluationRepository,
        _voice = voice,
        _createId = createId ?? createClientUuid,
        _random = random ?? Random(),
        _strings = strings ?? lookupAppLocalizations(const Locale('de')) {
    _voice.addListener(_relayVoice);
  }

  final ChallengeSet challengeSet;
  final SpeechChallengeRepository _repository;
  final SpeechChallengeEvaluationRepository _evaluationRepository;
  final VoiceTurnController _voice;
  final String Function() _createId;
  final Random _random;
  final AppLocalizations _strings;

  SpeechChallengeStatus _status = SpeechChallengeStatus.ready;
  TrainingSessionRecord? _session;
  List<ChallengePrompt> _selectedPrompts = const [];
  final List<ChallengeAnswer> _answers = [];
  int _activePromptIndex = 0;
  int _targetCount = 0;
  bool _stopRequested = false;
  bool _sessionCompleted = false;
  ChallengeSessionResult? _result;
  String? _message;

  SpeechChallengeStatus get status => _status;
  ChallengePrompt? get currentPrompt =>
      _selectedPrompts.isEmpty || _activePromptIndex >= _selectedPrompts.length
          ? null
          : _selectedPrompts[_activePromptIndex];
  int get completedCount => _answers.length;
  int get targetCount => _targetCount;
  int get activePromptNumber => _selectedPrompts.isEmpty
      ? 0
      : min(_activePromptIndex + 1, _selectedPrompts.length);
  int get availablePromptCount =>
      min(challengeSet.prompts.length, maxSpeechChallengePromptCount);
  List<ChallengeAnswer> get answers => List.unmodifiable(_answers);
  VoiceTurnSnapshot get voice => _voice.snapshot;
  VoiceTurnController get voiceController => _voice;
  ChallengeSessionResult? get result => _result;
  String? get message => _message ?? _voice.snapshot.message;
  bool get canRetryEvaluation =>
      _status == SpeechChallengeStatus.error &&
      _sessionCompleted &&
      _answers.isNotEmpty &&
      _result == null;

  Future<void> startHandsFree({required int promptCount}) async {
    if (_status != SpeechChallengeStatus.ready) return;
    if (promptCount < 1 || promptCount > availablePromptCount) {
      throw ArgumentError.value(
        promptCount,
        'promptCount',
        'Must be between 1 and $availablePromptCount.',
      );
    }
    _prepareSession(promptCount);
    try {
      _session = await _repository.startSession(
        setId: challengeSet.id,
        clientId: _createId(),
        targetCount: promptCount,
        promptIds: _selectedPrompts.map((prompt) => prompt.id).toList(),
      );
      while (_activePromptIndex < _selectedPrompts.length && !_stopRequested) {
        final completed = await _runPrompt(
          _selectedPrompts[_activePromptIndex],
        );
        if (!completed) break;
        _activePromptIndex += 1;
      }
      if (_answers.isEmpty) {
        _setStatus(SpeechChallengeStatus.ready);
        return;
      }
      if (_status == SpeechChallengeStatus.error) return;
      await _repository.completeSession(_session!.id);
      _sessionCompleted = true;
      await _evaluateCompletedAnswers();
    } catch (_) {
      _setError(_strings.challengeContinueError);
    }
  }

  void _prepareSession(int promptCount) {
    final prompts = List<ChallengePrompt>.of(challengeSet.prompts)
      ..shuffle(_random);
    _selectedPrompts = prompts.take(promptCount).toList(growable: false);
    _answers.clear();
    _activePromptIndex = 0;
    _targetCount = promptCount;
    _stopRequested = false;
    _sessionCompleted = false;
    _result = null;
    _message = null;
  }

  Future<bool> _runPrompt(ChallengePrompt prompt) async {
    _voice.reset();
    _setStatus(SpeechChallengeStatus.playing);
    final played = await _voice.playScene([prompt.speechLine]);
    if (_stopRequested) return false;
    if (!played || _voice.snapshot.state != VoiceTurnState.awaitingUser) {
      _setError(_voice.snapshot.message ?? _strings.promptPlaybackError);
      return false;
    }
    _setStatus(SpeechChallengeStatus.listening);
    final recording = await _voice.captureHandsFree();
    if (_stopRequested) return false;
    if (recording == null || recording.transcript.trim().isEmpty) {
      _setError(_strings.responseNotUnderstood);
      return false;
    }
    _setStatus(SpeechChallengeStatus.transitioning);
    final transcript = recording.transcript.trim();
    final responseId = await _repository.saveResponse(
      sessionId: _session!.id,
      promptId: prompt.id,
      clientId: _createId(),
      transcript: transcript,
      position: _activePromptIndex,
    );
    _answers.add(
      ChallengeAnswer(
        prompt: prompt,
        responseId: responseId,
        transcript: transcript,
      ),
    );
    notifyListeners();
    return true;
  }

  Future<void> _evaluateCompletedAnswers() async {
    _setStatus(SpeechChallengeStatus.evaluating);
    try {
      final result = await _evaluationRepository.evaluate(
        challengeSet: challengeSet,
        answers: List.unmodifiable(_answers),
      );
      await _repository.saveResult(
        sessionId: _session!.id,
        result: result,
      );
      _result = result;
      _setStatus(SpeechChallengeStatus.complete);
      if (_voice.snapshot.state == VoiceTurnState.processing) {
        await _voice.presentFeedback(
          result.summary.spokenSummaryFor(_strings),
        );
      }
    } on AiGatewayException catch (error) {
      _setError(
        error.isCapacityUnavailable
            ? _strings.challengeEvaluationCapacityError
            : _strings.challengeEvaluationError,
      );
    } on FormatException {
      _setError(_strings.challengeEvaluationError);
    } catch (_) {
      _setError(_strings.challengeEvaluationError);
    }
  }

  Future<void> retryEvaluation() async {
    if (!canRetryEvaluation) return;
    await _evaluateCompletedAnswers();
  }

  Future<void> stop() async {
    if (_status == SpeechChallengeStatus.ready ||
        _status == SpeechChallengeStatus.complete ||
        _status == SpeechChallengeStatus.evaluating) {
      return;
    }
    _stopRequested = true;
    await _voice.interrupt();
  }

  Future<void> reset() async {
    _stopRequested = true;
    await _voice.interrupt();
    _voice.reset();
    _selectedPrompts = const [];
    _answers.clear();
    _activePromptIndex = 0;
    _targetCount = 0;
    _session = null;
    _sessionCompleted = false;
    _result = null;
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
