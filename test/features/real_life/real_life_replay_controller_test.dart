import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/features/real_life/application/real_life_replay_controller.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_ai_service.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_repository.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

void main() {
  test('private replay scenes never opt into the shared audio cache', () {
    expect(
      scenario.speechLines.every((line) => line.sharedReference == null),
      isTrue,
    );
  });

  test('voice-only real-life replay reaches qualitative feedback', () async {
    final ids = List.generate(
      8,
      (index) => '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
    );
    final repository = _Repository();
    final controller = RealLifeReplayController(
      permission: _Permission(),
      recorder: _Recorder(),
      playback: _Playback(),
      speech: _Speech(['Die ursprüngliche Situation.', 'Meine neue Antwort.']),
      ai: _Ai(),
      repository: repository,
      feedbackRepository: _Feedback(),
      createId: () => ids.removeAt(0),
    );

    await controller.startDescription();
    await controller.finishDescription();
    expect(controller.status, RealLifeReplayStatus.confirmExtraction);
    expect(
        controller.extraction?.emotionalSocialTension, 'Druck vor der Gruppe');
    expect(repository.savedCaseCount, 0);

    await controller.confirmAndReconstruct();
    expect(repository.savedCaseCount, 1);
    await controller.playReplay();
    expect(controller.status, RealLifeReplayStatus.awaitingResponse);

    await controller.startResponse();
    await controller.finishResponse();
    expect(controller.status, RealLifeReplayStatus.feedbackReady);
    expect(controller.responseTranscript, 'Meine neue Antwort.');
    expect(controller.feedback?.headline, 'Klarer zweiter Versuch');

    await controller.createSimilarVariation();
    expect(controller.status, RealLifeReplayStatus.readyToReplay);
  });

  test('saved localization is reused without another AI call', () async {
    final repository = _Repository()
      ..savedCase = const SavedRealLifeCase(
        record: RealLifeCaseRecord(id: 'case-1', clientId: 'client-1'),
        sourceTranscript: 'Private Situation',
        extraction: extraction,
        reconstruction: RealLifeReconstruction(scenario: scenario),
      );
    final ai = _Ai();
    final controller = RealLifeReplayController(
      permission: _Permission(),
      recorder: _Recorder(),
      playback: _Playback(),
      speech: _Speech([]),
      ai: ai,
      repository: repository,
      feedbackRepository: _Feedback(),
    );

    await controller.loadSavedCase('case-1', autoPlay: false);

    expect(controller.status, RealLifeReplayStatus.readyToReplay);
    expect(controller.scenario?.title, scenario.title);
    expect(ai.reconstructionCalls, 0);
    expect(repository.savedReconstructionCount, 0);
  });

  test('saved case autoplay starts exactly one localized session', () async {
    final repository = _Repository()
      ..savedCase = const SavedRealLifeCase(
        record: RealLifeCaseRecord(id: 'case-1', clientId: 'client-1'),
        sourceTranscript: 'Private Situation',
        extraction: extraction,
        reconstruction: RealLifeReconstruction(scenario: scenario),
      );
    final controller = RealLifeReplayController(
      permission: _Permission(),
      recorder: _Recorder(),
      playback: _Playback(),
      speech: _Speech([]),
      ai: _Ai(),
      repository: repository,
      feedbackRepository: _Feedback(),
      languageCode: 'en',
    );

    await controller.loadSavedCase('case-1');

    expect(controller.status, RealLifeReplayStatus.awaitingResponse);
    expect(repository.startedSessionCount, 1);
    expect(repository.startedLocale, 'en');
  });

  test('missing language snapshot is generated and persisted once', () async {
    final repository = _Repository()
      ..savedCase = const SavedRealLifeCase(
        record: RealLifeCaseRecord(id: 'case-1', clientId: 'client-1'),
        sourceTranscript: 'Private Situation',
        extraction: extraction,
        reconstruction: null,
      );
    final ai = _Ai();
    final controller = RealLifeReplayController(
      permission: _Permission(),
      recorder: _Recorder(),
      playback: _Playback(),
      speech: _Speech([]),
      ai: ai,
      repository: repository,
      feedbackRepository: _Feedback(),
      languageCode: 'en',
    );

    await controller.loadSavedCase('case-1', autoPlay: false);
    await controller.loadSavedCase('case-1', autoPlay: false);

    expect(ai.reconstructionCalls, 1);
    expect(repository.savedReconstructionCount, 1);
    expect(repository.savedLocale, 'en');
  });

  test('extraction rejects unsupported inferred fields', () {
    final json = extraction.toJson()
      ..['diagnosed_motive'] = 'Kontrollbedürfnis';
    expect(() => RealLifeExtraction.fromJson(json), throwsFormatException);
  });
}

const extraction = RealLifeExtraction(
  setting: 'Teamrunde',
  participants: [
    RealLifeParticipant(name: 'Alex', relationship: 'Teammitglied'),
  ],
  statements: ['Wir sind schon weiter.'],
  triggerStatement: 'Wir sind schon weiter.',
  observableTone: 'knapp',
  emotionalSocialTension: 'Druck vor der Gruppe',
  originalReaction: 'Ich habe abgebrochen.',
  unresolvedQuestions: [],
);

const scenario = TrainingScenario(
  id: 'case-1',
  title: 'Deine echte Situation',
  category: 'Echte Situation',
  moderatorIntro: 'Du bist wieder in der Teamrunde.',
  characters: [ScenarioCharacter(id: 'a', name: 'Alex', sortOrder: 0)],
  turns: [
    ScenarioTurn(
        characterId: 'a', body: 'Wir sind schon weiter.', sortOrder: 0),
  ],
);

const feedback = QualitativeFeedback(
  overallSignal: FeedbackSignal.developing,
  dimensionSignals: FeedbackDimensionSignals(
    posture: FeedbackSignal.strong,
    precision: FeedbackSignal.developing,
    frame: FeedbackSignal.developing,
    socialEffect: FeedbackSignal.strong,
    naturalness: FeedbackSignal.strong,
    escalationFit: FeedbackSignal.developing,
  ),
  headline: 'Klarer zweiter Versuch',
  explanation: 'Du nimmst dir ruhig Raum.',
  strengths: ['Direkter Einstieg'],
  improvement: 'Nenne deinen Punkt noch konkreter.',
  alternatives: ['Ich brauche noch einen Satz für meinen Punkt.'],
  dimensions: FeedbackDimensions(
    posture: 'ruhig',
    precision: 'klar',
    frame: 'gehalten',
    socialEffect: 'anschlussfähig',
    naturalness: 'sprechbar',
    escalationFit: 'passend',
  ),
  provider: 'mock',
  model: 'mock',
  promptVersion: 'response_evaluate_v1',
);

class _Permission implements MicrophonePermissionGateway {
  @override
  Future<MicrophonePermissionStatus> request() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<bool> openSettings() async => true;
}

class _Recorder implements VoiceRecorder {
  @override
  Future<void> start() async {}

  @override
  Future<RecordedAudio> stop() async => RecordedAudio(
        bytes: Uint8List.fromList([1]),
        mimeType: 'audio/pcm;rate=16000',
      );

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class _Playback implements AudioPlaybackQueue {
  @override
  Future<void> enqueue(SpeechClip clip) async {}

  @override
  Future<void> playAll() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _Speech implements SpeechGateway {
  _Speech(this.transcripts);

  final List<String> transcripts;

  @override
  Future<SpeechClip> synthesize(SpeechLine line) async => SpeechClip(
        bytes: Uint8List.fromList([1]),
        mimeType: 'audio/mpeg',
        role: line.role,
      );

  @override
  Future<TranscriptionResult> transcribe(RecordedAudio audio) async =>
      TranscriptionResult(
        transcript: transcripts.removeAt(0),
        provider: 'mock',
        model: 'mock',
      );
}

class _Ai implements RealLifeAiService {
  int reconstructionCalls = 0;

  @override
  Future<RealLifeExtraction> extract(String transcript) async => extraction;

  @override
  Future<RealLifeReconstruction> reconstruct({
    required String caseId,
    required RealLifeExtraction extraction,
    bool similarVariation = false,
  }) async {
    reconstructionCalls += 1;
    return const RealLifeReconstruction(scenario: scenario);
  }
}

class _Repository implements RealLifeRepository {
  int savedCaseCount = 0;
  int savedReconstructionCount = 0;
  int startedSessionCount = 0;
  String? savedLocale;
  String? startedLocale;
  SavedRealLifeCase? savedCase;

  @override
  Future<List<RealLifeCaseSummary>> fetchCases(
          {required String locale}) async =>
      const [];

  @override
  Future<SavedRealLifeCase> fetchCase({
    required String caseId,
    required String locale,
  }) async =>
      savedCase!;

  @override
  Future<String?> selectNextCaseId({required String locale}) async =>
      savedCase?.record.id;

  @override
  Future<RealLifeCaseRecord> saveCaseWithReconstruction({
    required String clientId,
    required String sourceTranscript,
    required RealLifeExtraction extraction,
    required String locale,
    required RealLifeReconstruction reconstruction,
  }) async {
    savedCaseCount += 1;
    final record = RealLifeCaseRecord(id: 'case-1', clientId: clientId);
    savedCase = SavedRealLifeCase(
      record: record,
      sourceTranscript: sourceTranscript,
      extraction: extraction,
      reconstruction: reconstruction,
    );
    return record;
  }

  @override
  Future<void> saveReconstruction({
    required String caseId,
    required String locale,
    required RealLifeReconstruction reconstruction,
  }) async {
    savedReconstructionCount += 1;
    savedLocale = locale;
    final current = savedCase!;
    savedCase = SavedRealLifeCase(
      record: current.record,
      sourceTranscript: current.sourceTranscript,
      extraction: current.extraction,
      reconstruction: reconstruction,
    );
  }

  @override
  Future<TrainingSessionRecord> startSession({
    required String caseId,
    required String clientId,
    required String locale,
  }) async {
    startedSessionCount += 1;
    startedLocale = locale;
    return TrainingSessionRecord(id: 'session-1', clientId: clientId);
  }

  @override
  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  }) async =>
      'response-1';

  @override
  Future<void> completeSession(String sessionId) async {}
}

class _Feedback implements FeedbackRepository {
  @override
  Future<QualitativeFeedback> evaluate({
    required TrainingScenario scenario,
    required String transcript,
  }) async =>
      feedback;

  @override
  Future<void> save({
    required String responseId,
    required QualitativeFeedback feedback,
  }) async {}

  @override
  Future<String> answerFollowUp({
    required TrainingScenario scenario,
    required QualitativeFeedback feedback,
    required String question,
  }) async =>
      'Antwort';
}
