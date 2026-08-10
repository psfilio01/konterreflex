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
        _strings = strings ?? lookupAppLocalizations(const Locale('de'));

  final MicrophonePermissionGateway _permission;
  final VoiceRecorder _recorder;
  final AudioPlaybackQueue _playback;
  final SpeechGateway _speech;
  final RealLifeAiService _ai;
  final RealLifeRepository _repository;
  final FeedbackRepository _feedbackRepository;
  final String Function() _createId;
  final AppLocalizations _strings;
  String _caseClientId;
  String _sessionClientId;
  String _responseClientId;

  RealLifeReplayStatus _status = RealLifeReplayStatus.ready;
  RealLifeExtraction? _extraction;
  RealLifeCaseRecord? _case;
  TrainingScenario? _scenario;
  String? _sourceTranscript;
  String? _responseTranscript;
  QualitativeFeedback? _feedback;
  String? _message;
  int _followUpCount = 0;

  RealLifeReplayStatus get status => _status;
  RealLifeExtraction? get extraction => _extraction;
  TrainingScenario? get scenario => _scenario;
  String? get sourceTranscript => _sourceTranscript;
  String? get responseTranscript => _responseTranscript;
  QualitativeFeedback? get feedback => _feedback;
  String? get message => _message;
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
    _case = await _repository.saveCase(
      clientId: _caseClientId,
      sourceTranscript: transcript,
      extraction: _extraction!,
    );
    _setStatus(RealLifeReplayStatus.confirmExtraction);
  }

  Future<void> confirmAndReconstruct() async {
    final extraction = _extraction;
    final caseRecord = _case;
    if (extraction == null || caseRecord == null) return;
    _setStatus(RealLifeReplayStatus.reconstructing);
    try {
      final result = await _ai.reconstruct(
        caseId: caseRecord.id,
        extraction: extraction,
      );
      _scenario = result.scenario;
      _setStatus(RealLifeReplayStatus.readyToReplay);
    } catch (_) {
      _setError(_strings.realLifeReconstructError);
    }
  }

  Future<void> playReplay() async {
    final scenario = _scenario;
    final caseRecord = _case;
    if (scenario == null || caseRecord == null) return;
    _setStatus(RealLifeReplayStatus.playing);
    try {
      await _repository.startSession(
        caseId: caseRecord.id,
        clientId: _sessionClientId,
      );
      for (final line in scenario.speechLines) {
        await _playback.enqueue(await _speech.synthesize(line));
      }
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
    _scenario = null;
    _sourceTranscript = null;
    _responseTranscript = null;
    _feedback = null;
    _followUpCount = 0;
    _setStatus(RealLifeReplayStatus.ready);
  }

  void _setStatus(RealLifeReplayStatus status) {
    _status = status;
    _message = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = RealLifeReplayStatus.error;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _playback.dispose();
    super.dispose();
  }
}
