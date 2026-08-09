import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

enum ScenarioSessionStatus {
  ready,
  starting,
  playing,
  awaitingResponse,
  recording,
  processing,
  completed,
  error,
}

class ScenarioSessionController extends ChangeNotifier {
  ScenarioSessionController({
    required this.scenario,
    required ScenarioRepository repository,
    required VoiceTurnController voice,
    String Function()? createId,
  })  : _repository = repository,
        _voice = voice,
        _sessionClientId = (createId ?? createClientUuid)(),
        _responseClientId = (createId ?? createClientUuid)() {
    _voice.addListener(_relayVoiceState);
  }

  final TrainingScenario scenario;
  final ScenarioRepository _repository;
  final VoiceTurnController _voice;
  final String _sessionClientId;
  final String _responseClientId;
  TrainingSessionRecord? _session;
  String? _transcript;
  ScenarioSessionStatus _status = ScenarioSessionStatus.ready;
  String? _message;

  ScenarioSessionStatus get status => _status;
  VoiceTurnSnapshot get voice => _voice.snapshot;
  String? get transcript => _transcript;
  String? get message => _message ?? _voice.snapshot.message;

  Future<void> start() async {
    _setStatus(ScenarioSessionStatus.starting);
    try {
      if (_voice.snapshot.state != VoiceTurnState.idle) _voice.reset();
      _session ??= await _repository.startSession(
        scenarioId: scenario.id,
        clientId: _sessionClientId,
      );
      _setStatus(ScenarioSessionStatus.playing);
      await _voice.playScene(scenario.speechLines);
      if (_voice.snapshot.state == VoiceTurnState.awaitingUser) {
        _setStatus(ScenarioSessionStatus.awaitingResponse);
      } else {
        _setError('Die Szene konnte nicht vollständig abgespielt werden.');
      }
    } catch (_) {
      _setError('Die Trainingseinheit konnte nicht gestartet werden.');
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
        _setError('Deine Antwort konnte nicht transkribiert werden.');
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
      _setError('Es gibt noch keine Antwort zum Speichern.');
      return;
    }
    _setStatus(ScenarioSessionStatus.processing);
    try {
      await _repository.saveResponse(
        sessionId: session.id,
        clientId: _responseClientId,
        transcript: transcript,
      );
      await _repository.completeSession(session.id);
      if (_voice.snapshot.state == VoiceTurnState.processing) {
        _voice.finishWithoutFeedback();
      }
      _setStatus(ScenarioSessionStatus.completed);
    } catch (_) {
      _setError(
          'Die Antwort ist noch nicht gespeichert. Bitte versuche es erneut.');
    }
  }

  Future<void> interrupt() => _voice.interrupt();

  Future<bool> openMicrophoneSettings() => _voice.openMicrophoneSettings();

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
