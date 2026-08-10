import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_capture_service.dart';
import 'package:konterreflex/src/core/analytics/privacy_analytics.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

enum ScenarioSessionStatus {
  ready,
  starting,
  playing,
  awaitingResponse,
  recording,
  processing,
  feedbackReady,
  followUpRecording,
  followUpProcessing,
  goldenBookRecording,
  goldenBookProcessing,
  error,
}

class ScenarioSessionController extends ChangeNotifier {
  ScenarioSessionController({
    required this.scenario,
    required ScenarioRepository repository,
    required FeedbackRepository feedbackRepository,
    required VoiceTurnController voice,
    GoldenBookCaptureService? goldenBookCapture,
    PrivacyAnalytics? analytics,
    String Function()? createId,
    AppLocalizations? strings,
  })  : _repository = repository,
        _feedbackRepository = feedbackRepository,
        _voice = voice,
        _goldenBookCapture = goldenBookCapture,
        _analytics = analytics,
        _createId = createId ?? createClientUuid,
        _sessionClientId = (createId ?? createClientUuid)(),
        _responseClientId = (createId ?? createClientUuid)(),
        _strings = strings ?? lookupAppLocalizations(const Locale('de')) {
    _voice.addListener(_relayVoiceState);
  }

  final TrainingScenario scenario;
  final ScenarioRepository _repository;
  final FeedbackRepository _feedbackRepository;
  final VoiceTurnController _voice;
  final GoldenBookCaptureService? _goldenBookCapture;
  final PrivacyAnalytics? _analytics;
  final String Function() _createId;
  final AppLocalizations _strings;
  String _sessionClientId;
  String _responseClientId;
  TrainingSessionRecord? _session;
  String? _responseId;
  String? _transcript;
  QualitativeFeedback? _feedback;
  String? _followUpAnswer;
  ScenarioSessionStatus _status = ScenarioSessionStatus.ready;
  String? _message;
  String? _savedPhrase;
  bool _startTracked = false;
  bool _completionTracked = false;

  ScenarioSessionStatus get status => _status;
  VoiceTurnSnapshot get voice => _voice.snapshot;
  VoiceTurnController get voiceController => _voice;
  String? get transcript => _transcript;
  QualitativeFeedback? get feedback => _feedback;
  String? get followUpAnswer => _followUpAnswer;
  String? get message => _message ?? _voice.snapshot.message;
  String? get savedPhrase => _savedPhrase;
  String? get sessionId => _session?.id;

  Future<void> start() async {
    _setStatus(ScenarioSessionStatus.starting);
    try {
      if (_voice.snapshot.state != VoiceTurnState.idle) _voice.reset();
      _session ??= await _repository.startSession(
        scenarioId: scenario.id,
        clientId: _sessionClientId,
      );
      if (!_startTracked) {
        _startTracked = true;
        _track(AnalyticsEventName.sessionStarted, AnalyticsStep.scene,
            AnalyticsOutcome.started);
      }
      _setStatus(ScenarioSessionStatus.playing);
      final played = await _voice.playScene(scenario.speechLines);
      if (played && _voice.snapshot.state == VoiceTurnState.awaitingUser) {
        _setStatus(ScenarioSessionStatus.awaitingResponse);
      } else {
        _setError(
          _voice.snapshot.message ?? _strings.sceneIncompleteError,
        );
      }
    } catch (_) {
      _setError(_strings.trainingStartError);
    }
  }

  Future<void> startRecording() async {
    final permission = await _voice.startRecording();
    if (permission == MicrophonePermissionStatus.granted &&
        _voice.snapshot.state == VoiceTurnState.recording) {
      _setStatus(ScenarioSessionStatus.recording);
    } else {
      _setStatus(ScenarioSessionStatus.awaitingResponse);
    }
  }

  Future<void> submitResponse() async {
    _setStatus(ScenarioSessionStatus.processing);
    if (_transcript == null) {
      final transcription = await _voice.stopAndTranscribe();
      if (transcription == null) {
        _setError(_strings.transcriptionError);
        return;
      }
      _transcript = transcription.transcript;
    }
    await retryPersistence();
  }

  Future<void> retryPersistence() async {
    final session = _session;
    final transcript = _transcript;
    if (session == null || transcript == null) {
      _setError(_strings.nothingToSaveError);
      return;
    }
    _setStatus(ScenarioSessionStatus.processing);
    try {
      _responseId ??= await _repository.saveResponse(
        sessionId: session.id,
        clientId: _responseClientId,
        transcript: transcript,
      );
      _feedback ??= await _feedbackRepository.evaluate(
        scenario: scenario,
        transcript: transcript,
      );
      await _feedbackRepository.save(
        responseId: _responseId!,
        feedback: _feedback!,
      );
      await _repository.completeSession(session.id);
      if (!_completionTracked) {
        _completionTracked = true;
        _track(AnalyticsEventName.sessionCompleted, AnalyticsStep.completion,
            AnalyticsOutcome.completed);
      }
      if (_voice.snapshot.state == VoiceTurnState.processing) {
        await _voice.presentFeedback(_feedback!.spokenSummaryFor(_strings));
      }
      _setStatus(ScenarioSessionStatus.feedbackReady);
    } catch (_) {
      _setError(
        _strings.feedbackSaveError,
      );
    }
  }

  Future<void> startFollowUp() async {
    if (_feedback == null) return;
    try {
      _voice.prepareFollowUpRecording();
      final permission = await _voice.startRecording();
      if (permission == MicrophonePermissionStatus.granted &&
          _voice.snapshot.state == VoiceTurnState.recording) {
        _setStatus(ScenarioSessionStatus.followUpRecording);
      } else {
        _setStatus(ScenarioSessionStatus.feedbackReady);
      }
    } catch (_) {
      _setError(_strings.followUpStartError);
    }
  }

  Future<void> submitFollowUp() async {
    final feedback = _feedback;
    if (feedback == null) return;
    _setStatus(ScenarioSessionStatus.followUpProcessing);
    final question = await _voice.stopAndTranscribe();
    if (question == null) {
      _setError(_strings.followUpUnderstandError);
      return;
    }
    try {
      final answer = await _feedbackRepository.answerFollowUp(
        scenario: scenario,
        feedback: feedback,
        question: question.transcript,
      );
      _followUpAnswer = answer;
      await _voice.presentFeedback(answer);
      _setStatus(ScenarioSessionStatus.feedbackReady);
    } catch (_) {
      _setError(_strings.followUpAnswerError);
    }
  }

  Future<void> startGoldenBookCommand() async {
    if (_feedback == null || _goldenBookCapture == null) return;
    try {
      _voice.prepareFollowUpRecording();
      final permission = await _voice.startRecording();
      if (permission == MicrophonePermissionStatus.granted &&
          _voice.snapshot.state == VoiceTurnState.recording) {
        _setStatus(ScenarioSessionStatus.goldenBookRecording);
      }
    } catch (_) {
      _setError(_strings.voiceCommandStartError);
    }
  }

  Future<void> submitGoldenBookCommand() async {
    final capture = _goldenBookCapture;
    final feedback = _feedback;
    if (capture == null || feedback == null) return;
    _setStatus(ScenarioSessionStatus.goldenBookProcessing);
    final command = await _voice.stopAndTranscribe();
    if (command == null) {
      _setError(_strings.voiceCommandUnderstandError);
      return;
    }
    try {
      final result = await capture.resolveCommand(
        command: command.transcript,
        sourceSessionId: _session?.id,
        conversationContext: {
          'scenario': scenario.title,
          'actor_statements': scenario.turns.map((turn) => turn.body).toList(),
          'user_response': _transcript,
          'feedback_alternatives': feedback.alternatives,
        },
      );
      final spoken = result.saved
          ? _strings.savedSpoken(result.entry!.phrase)
          : result.clarificationQuestion!;
      if (result.saved) _savedPhrase = result.entry!.phrase;
      await _voice.presentFeedback(spoken);
      _setStatus(ScenarioSessionStatus.feedbackReady);
    } catch (_) {
      _setError(_strings.phraseSaveError);
    }
  }

  Future<void> savePhrase(String phrase) async {
    final capture = _goldenBookCapture;
    if (capture == null) return;
    try {
      final entry =
          await capture.saveDirect(phrase, sourceSessionId: _session?.id);
      _savedPhrase = entry.phrase;
      notifyListeners();
    } catch (_) {
      _setError(_strings.phraseSaveError);
    }
  }

  void retryScene() {
    _voice.reset();
    _sessionClientId = _createId();
    _responseClientId = _createId();
    _session = null;
    _responseId = null;
    _transcript = null;
    _feedback = null;
    _followUpAnswer = null;
    _savedPhrase = null;
    _startTracked = false;
    _completionTracked = false;
    _setStatus(ScenarioSessionStatus.ready);
  }

  Future<void> interrupt() => _voice.interrupt();

  Future<bool> openMicrophoneSettings() => _voice.openMicrophoneSettings();

  void _track(
      AnalyticsEventName name, AnalyticsStep step, AnalyticsOutcome outcome) {
    final analytics = _analytics;
    if (analytics == null) return;
    unawaited(analytics
        .track(PrivacyAnalyticsEvent(
            name: name,
            feature: AnalyticsFeature.training,
            step: step,
            outcome: outcome))
        .catchError((_) {}));
  }

  void _relayVoiceState() => notifyListeners();

  void _setStatus(ScenarioSessionStatus next) {
    _status = next;
    _message = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ScenarioSessionStatus.error;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _voice.removeListener(_relayVoiceState);
    _voice.dispose();
    super.dispose();
  }
}

String createClientUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
