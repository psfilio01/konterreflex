import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_ai_service.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_repository.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/training/application/scenario_session_controller.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

enum RealLifeReplayStatus {
  ready,
  describing,
  extracting,
  confirmExtraction,
  recordingFollowUp,
  reconstructing,
  readyToReplay,
  preparingPlayback,
  playing,
  awaitingResponse,
  recordingResponse,
  processingResponse,
  feedbackReady,
  error,
}

class RealLifeReplayController extends ChangeNotifier {
  RealLifeReplayController({
    required MicrophonePermissionGateway permission,
    required VoiceRecorder recorder,
    required AudioPlaybackQueue playback,
    required SpeechGateway speech,
    required RealLifeAiService ai,
    required RealLifeRepository repository,
    required FeedbackRepository feedbackRepository,
    this.languageCode = 'de',
    String Function()? createId,
    AppLocalizations? strings,
  })  : _permission = permission,
        _recorder = recorder,
        _playback = playback,
        _speech = speech,
        _ai = ai,
        _repository = repository,
        _feedbackRepository = feedbackRepository,
        _createId = createId ?? createClientUuid,
        _caseClientId = (createId ?? createClientUuid)(),
        _sessionClientId = (createId ?? createClientUuid)(),
        _responseClientId = (createId ?? createClientUuid)(),
        _strings = strings ?? lookupAppLocalizations(const Locale('de')) {
    if (recorder case final VoiceActivitySource source) {
      _recorderActivitySubscription = source.voiceActivity.listen((level) {
        if (_isRecordingStatus(_status)) {
          voiceActivity.value = level.clamp(0.0, 1.0).toDouble();
        }
      });
    }
    if (playback case final VoiceActivitySource source) {
      _playbackActivitySubscription = source.voiceActivity.listen((level) {
        if (_status == RealLifeReplayStatus.playing) {
          voiceActivity.value = level.clamp(0.0, 1.0).toDouble();
        }
      });
    }
  }

  final MicrophonePermissionGateway _permission;
  final VoiceRecorder _recorder;
  final AudioPlaybackQueue _playback;
  final SpeechGateway _speech;
  final RealLifeAiService _ai;
  final RealLifeRepository _repository;
  final FeedbackRepository _feedbackRepository;
  final String Function() _createId;
  final AppLocalizations _strings;
  final String languageCode;
  String _caseClientId;
  String _sessionClientId;
  String _responseClientId;

  RealLifeReplayStatus _status = RealLifeReplayStatus.ready;
  RealLifeExtraction? _extraction;
  RealLifeCaseRecord? _case;
  RealLifeReconstruction? _reconstruction;
  TrainingScenario? _scenario;
  String? _sourceTranscript;
  String? _responseTranscript;
  QualitativeFeedback? _feedback;
  String? _message;
  int _followUpCount = 0;
  String? _loadedCaseId;
  final ValueNotifier<double> voiceActivity = ValueNotifier(0);
  StreamSubscription<double>? _recorderActivitySubscription;
  StreamSubscription<double>? _playbackActivitySubscription;

  RealLifeReplayStatus get status => _status;
  RealLifeExtraction? get extraction => _extraction;
  TrainingScenario? get scenario => _scenario;
  String? get sourceTranscript => _sourceTranscript;
  String? get responseTranscript => _responseTranscript;
  QualitativeFeedback? get feedback => _feedback;
  String? get message => _message;
  bool get canRetryReconstructionSave =>
      _reconstruction != null && _case == null && _sourceTranscript != null;
  bool get isSavedCase => _loadedCaseId != null;
  String? get nextEssentialQuestion =>
      _followUpCount < 2 ? _extraction?.unresolvedQuestions.firstOrNull : null;

  IntelligenceOrbState get orbState => switch (_status) {
        RealLifeReplayStatus.describing ||
        RealLifeReplayStatus.recordingFollowUp ||
        RealLifeReplayStatus.recordingResponse =>
          IntelligenceOrbState.listening,
        RealLifeReplayStatus.extracting ||
        RealLifeReplayStatus.reconstructing ||
        RealLifeReplayStatus.processingResponse =>
          IntelligenceOrbState.thinking,
        RealLifeReplayStatus.preparingPlayback =>
          IntelligenceOrbState.preparing,
        RealLifeReplayStatus.playing => IntelligenceOrbState.speaking,
        RealLifeReplayStatus.feedbackReady => IntelligenceOrbState.success,
        _ => IntelligenceOrbState.idle,
      };

  Future<void> startDescription() async {
    if (await _startRecording()) _setStatus(RealLifeReplayStatus.describing);
  }

  Future<void> finishDescription() async {
    _setStatus(RealLifeReplayStatus.extracting);
    try {
      final audio = await _recorder.stop();
      final transcript = await _speech.transcribe(audio);
      _sourceTranscript = transcript.transcript;
      await _extractAndSave();
    } catch (_) {
      _setError(_strings.realLifeProcessError);
    }
  }

  Future<void> startEssentialFollowUp() async {
    final question = nextEssentialQuestion;
    if (question == null) return;
    try {
      await _playback.enqueue(
        await _speech.synthesize(
          SpeechLine(text: question, role: VoiceRole.intelligence),
        ),
      );
      await _playback.playAll();
      if (await _startRecording()) {
        _setStatus(RealLifeReplayStatus.recordingFollowUp);
      }
    } catch (_) {
      _setError(_strings.followUpStartError);
    }
  }

  Future<void> finishEssentialFollowUp() async {
    final question = nextEssentialQuestion;
    if (question == null || _sourceTranscript == null) return;
    _setStatus(RealLifeReplayStatus.extracting);
    try {
      final audio = await _recorder.stop();
      final answer = await _speech.transcribe(audio);
      _sourceTranscript = '${_sourceTranscript!}\n'
          '${_strings.realLifeFollowUpTranscript(question, answer.transcript)}';
      _followUpCount += 1;
      await _extractAndSave();
    } catch (_) {
      _setError(_strings.realLifeAdditionError);
    }
  }

  Future<void> _extractAndSave() async {
    final transcript = _sourceTranscript!;
    _extraction = await _ai.extract(transcript);
    _setStatus(RealLifeReplayStatus.confirmExtraction);
  }

  Future<void> confirmAndReconstruct() async {
    final extraction = _extraction;
    final sourceTranscript = _sourceTranscript;
    if (extraction == null || sourceTranscript == null) return;
    _setStatus(RealLifeReplayStatus.reconstructing);
    try {
      _reconstruction ??= await _ai.reconstruct(
        caseId: _caseClientId,
        extraction: extraction,
      );
      _case ??= await _repository.saveCaseWithReconstruction(
        clientId: _caseClientId,
        sourceTranscript: sourceTranscript,
        extraction: extraction,
        locale: languageCode,
        reconstruction: _reconstruction!,
      );
      _scenario = _reconstruction!.scenario;
      _setStatus(RealLifeReplayStatus.readyToReplay);
    } catch (_) {
      _setError(_strings.realLifeReconstructError);
    }
  }

  Future<void> loadSavedCase(String caseId, {bool autoPlay = true}) async {
    _loadedCaseId = caseId;
    _setStatus(RealLifeReplayStatus.reconstructing);
    try {
      final saved = await _repository.fetchCase(
        caseId: caseId,
        locale: languageCode,
      );
      _case = saved.record;
      _sourceTranscript = saved.sourceTranscript;
      _extraction = saved.extraction;
      _reconstruction = saved.reconstruction;
      if (_reconstruction == null) {
        _reconstruction = await _ai.reconstruct(
          caseId: caseId,
          extraction: saved.extraction,
        );
        await _repository.saveReconstruction(
          caseId: caseId,
          locale: languageCode,
          reconstruction: _reconstruction!,
        );
      }
      _scenario = _reconstruction!.scenario;
      _setStatus(RealLifeReplayStatus.readyToReplay);
      if (autoPlay) await playReplay();
    } catch (_) {
      _setError(_strings.realLifeReconstructError);
    }
  }

  Future<void> retryAfterError() async {
    if (canRetryReconstructionSave) {
      await confirmAndReconstruct();
      return;
    }
    final caseId = _loadedCaseId;
    if (caseId != null) {
      await loadSavedCase(caseId);
      return;
    }
    reset();
  }

  Future<void> playReplay() async {
    final scenario = _scenario;
    final caseRecord = _case;
    if (scenario == null || caseRecord == null) return;
    _setStatus(RealLifeReplayStatus.preparingPlayback);
    try {
      await _repository.startSession(
        caseId: caseRecord.id,
        clientId: _sessionClientId,
        locale: languageCode,
      );
      for (final line in scenario.speechLines) {
        await _playback.enqueue(await _speech.synthesize(line));
      }
      _setStatus(RealLifeReplayStatus.playing);
      await _playback.playAll();
      _setStatus(RealLifeReplayStatus.awaitingResponse);
    } catch (_) {
      _setError(_strings.realLifePlaybackError);
    }
  }

  Future<void> startResponse() async {
    if (await _startRecording()) {
      _setStatus(RealLifeReplayStatus.recordingResponse);
    }
  }

  Future<void> finishResponse() async {
    final scenario = _scenario;
    final caseRecord = _case;
    if (scenario == null || caseRecord == null) return;
    _setStatus(RealLifeReplayStatus.processingResponse);
    try {
      final audio = await _recorder.stop();
      final transcription = await _speech.transcribe(audio);
      _responseTranscript = transcription.transcript;
      final session = await _repository.startSession(
        caseId: caseRecord.id,
        clientId: _sessionClientId,
        locale: languageCode,
      );
      final responseId = await _repository.saveResponse(
        sessionId: session.id,
        clientId: _responseClientId,
        transcript: transcription.transcript,
      );
      _feedback = await _feedbackRepository.evaluate(
        scenario: scenario,
        transcript: transcription.transcript,
      );
      await _feedbackRepository.save(
        responseId: responseId,
        feedback: _feedback!,
      );
      await _repository.completeSession(session.id);
      await _playback.enqueue(
        await _speech.synthesize(
          SpeechLine(
            text: _feedback!.spokenSummaryFor(_strings),
            role: VoiceRole.intelligence,
          ),
        ),
      );
      await _playback.playAll();
      _setStatus(RealLifeReplayStatus.feedbackReady);
    } catch (_) {
      _setError(_strings.realLifeEvaluationError);
    }
  }

  Future<void> createSimilarVariation() async {
    final extraction = _extraction;
    final caseRecord = _case;
    if (extraction == null || caseRecord == null) return;
    _setStatus(RealLifeReplayStatus.reconstructing);
    try {
      final variation = await _ai.reconstruct(
        caseId: '${caseRecord.id}-variation',
        extraction: extraction,
        similarVariation: true,
      );
      _scenario = variation.scenario;
      _sessionClientId = _createId();
      _responseClientId = _createId();
      _responseTranscript = null;
      _feedback = null;
      _setStatus(RealLifeReplayStatus.readyToReplay);
    } catch (_) {
      _setError(_strings.realLifeVariationError);
    }
  }

  Future<void> repeatReplay() async {
    _sessionClientId = _createId();
    _responseClientId = _createId();
    _responseTranscript = null;
    _feedback = null;
    await playReplay();
  }

  Future<bool> _startRecording() async {
    final permission = await _permission.request();
    if (permission != MicrophonePermissionStatus.granted) {
      _setError(
        permission == MicrophonePermissionStatus.permanentlyDenied
            ? _strings.microphoneSettingsDisabled
            : _strings.microphoneFlowRequired,
      );
      return false;
    }
    await _recorder.start();
    return true;
  }

  Future<void> interrupt() async {
    await _playback.stop();
    if (_status == RealLifeReplayStatus.describing ||
        _status == RealLifeReplayStatus.recordingFollowUp ||
        _status == RealLifeReplayStatus.recordingResponse) {
      await _recorder.cancel();
    }
    _setStatus(RealLifeReplayStatus.ready);
  }

  void reset() {
    _caseClientId = _createId();
    _sessionClientId = _createId();
    _responseClientId = _createId();
    _extraction = null;
    _case = null;
    _reconstruction = null;
    _scenario = null;
    _sourceTranscript = null;
    _responseTranscript = null;
    _feedback = null;
    _followUpCount = 0;
    _loadedCaseId = null;
    _setStatus(RealLifeReplayStatus.ready);
  }

  void _setStatus(RealLifeReplayStatus status) {
    _status = status;
    _message = null;
    if (status != RealLifeReplayStatus.playing && !_isRecordingStatus(status)) {
      voiceActivity.value = 0;
    }
    notifyListeners();
  }

  bool _isRecordingStatus(RealLifeReplayStatus status) =>
      status == RealLifeReplayStatus.describing ||
      status == RealLifeReplayStatus.recordingFollowUp ||
      status == RealLifeReplayStatus.recordingResponse;

  void _setError(String message) {
    _status = RealLifeReplayStatus.error;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_recorderActivitySubscription?.cancel());
    unawaited(_playbackActivitySubscription?.cancel());
    _recorder.dispose();
    _playback.dispose();
    voiceActivity.dispose();
    super.dispose();
  }
}
