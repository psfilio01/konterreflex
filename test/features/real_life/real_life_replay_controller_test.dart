import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/audio/voice_models.dart';
import 'package:konterreflex/src/core/audio/voice_services.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_capture_service.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_repository.dart';
import 'package:konterreflex/src/features/golden_book/domain/golden_book_entry.dart';
import 'package:konterreflex/src/features/real_life/application/real_life_replay_controller.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_ai_service.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_repository.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/real_life/presentation/real_life_replay_screen.dart';
import 'package:konterreflex/src/features/training/data/feedback_repository.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

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
      processingCompletionDuration: Duration.zero,
    );
    final orbStates = <IntelligenceOrbState>[];
    controller.addListener(() => orbStates.add(controller.orbState));

    await controller.startDescription();
    await controller.finishDescription();
    expect(controller.status, RealLifeReplayStatus.confirmExtraction);
    expect(
        controller.extraction?.emotionalSocialTension, 'Druck vor der Gruppe');
    expect(repository.savedCaseCount, 0);
    expect(
      orbStates,
      containsAllInOrder([
        IntelligenceOrbState.processingSpeech,
        IntelligenceOrbState.processingSpeechComplete,
      ]),
    );

    await controller.confirmAndReconstruct();
    expect(repository.savedCaseCount, 1);
    await controller.playReplay();
    expect(controller.status, RealLifeReplayStatus.awaitingResponse);

    await controller.startResponse();
    await controller.finishResponse();
    expect(controller.status, RealLifeReplayStatus.feedbackReady);
    expect(controller.responseTranscript, 'Meine neue Antwort.');
    expect(controller.feedback?.headline, 'Klarer zweiter Versuch');
    expect(
      orbStates.where(
        (state) => state == IntelligenceOrbState.processingSpeechComplete,
      ),
      hasLength(2),
    );

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
      processingCompletionDuration: Duration.zero,
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
      processingCompletionDuration: Duration.zero,
    );

    await controller.loadSavedCase('case-1');

    expect(controller.status, RealLifeReplayStatus.awaitingResponse);
    expect(repository.startedSessionCount, 1);
    expect(repository.startedLocale, 'en');
  });

  testWidgets('real-life feedback exposes voice and direct Golden Book capture',
      (tester) async {
    final ids = List.generate(
      8,
      (index) => '10000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
    );
    final goldenBookRepository = _GoldenBookRepository();
    final goldenBookAi = _GoldenBookAi();
    final controller = RealLifeReplayController(
      permission: _Permission(),
      recorder: _Recorder(),
      playback: _Playback(),
      speech: _Speech([
        'Die ursprüngliche Situation.',
        'Meine neue Antwort.',
        'Speichere meine Antwort.',
      ]),
      ai: _Ai(),
      repository: _Repository(),
      feedbackRepository: _Feedback(),
      goldenBookCapture: GoldenBookCaptureService(
        ai: goldenBookAi,
        repository: goldenBookRepository,
      ),
      createId: () => ids.removeAt(0),
      processingCompletionDuration: Duration.zero,
    );

    await controller.startDescription();
    await controller.finishDescription();
    await controller.confirmAndReconstruct();
    await controller.playReplay();
    await controller.startResponse();
    await controller.finishResponse();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RealLifeReplayScreen(testController: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final voiceButton = find.byKey(const Key('real-life-golden-book-voice'));
    expect(voiceButton, findsOneWidget);
    await tester.ensureVisible(voiceButton);
    await tester.tap(voiceButton);
    await tester.pump();
    expect(controller.status, RealLifeReplayStatus.goldenBookRecording);

    final sendButton = find.text('Sprachbefehl senden');
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(controller.status, RealLifeReplayStatus.feedbackReady);
    expect(controller.savedPhrase, 'Meine neue Antwort.');
    expect(goldenBookRepository.sourceSessionId, 'session-1');
    expect(goldenBookAi.conversationContext?['user_response'],
        'Meine neue Antwort.');
    expect(
      find.text('Im Golden Book gespeichert: „Meine neue Antwort.“'),
      findsOneWidget,
    );

    final alternatives = find.text('Natürliche Alternativen');
    await tester.ensureVisible(alternatives);
    await tester.tap(alternatives);
    await tester.pumpAndSettle();
    final directSave = find.byTooltip('Im Golden Book speichern');
    expect(directSave, findsOneWidget);
    await tester.ensureVisible(directSave);
    await tester.tap(directSave);
    await tester.pumpAndSettle();

    expect(
      goldenBookRepository.savedPhrases,
      contains('Ich brauche noch einen Satz für meinen Punkt.'),
    );
    expect(
      find.text(
        'Im Golden Book gespeichert: '
        '„Ich brauche noch einen Satz für meinen Punkt.“',
      ),
      findsOneWidget,
    );
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
      processingCompletionDuration: Duration.zero,
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

  test('new reconstruction requires rich context and a clear handoff', () {
    expect(
      () => RealLifeReconstruction.fromJson(
        {
          'title': 'Unterbrochen im Gespräch',
          'moderator_intro':
              'Du sitzt nach einem langen Termin mit einem Teammitglied in einem ruhigen Besprechungsraum. Ihr habt gerade über einen wichtigen Vorschlag gesprochen, als die andere Person deinen Beitrag vor der Gruppe offen infrage stellt.',
          'response_cue': 'Was antwortest du?',
          'characters': [
            {'name': 'Alex', 'description': 'Teammitglied'},
          ],
          'turns': [
            {
              'character_name': 'Alex',
              'body': 'Wir müssen weiter.',
              'stage_direction': '',
            },
          ],
        },
        id: 'case-1',
        requireRichStructure: true,
      ),
      throwsFormatException,
    );
  });

  test('failed situation understanding never completes the spiral', () async {
    final controller = RealLifeReplayController(
      permission: _Permission(),
      recorder: _Recorder(),
      playback: _Playback(),
      speech: _Speech(['Private Situation']),
      ai: _FailingAi(),
      repository: _Repository(),
      feedbackRepository: _Feedback(),
      processingCompletionDuration: Duration.zero,
    );
    final orbStates = <IntelligenceOrbState>[];
    controller.addListener(() => orbStates.add(controller.orbState));

    await controller.startDescription();
    await controller.finishDescription();

    expect(controller.status, RealLifeReplayStatus.error);
    expect(orbStates, contains(IntelligenceOrbState.processingSpeech));
    expect(
      orbStates,
      isNot(contains(IntelligenceOrbState.processingSpeechComplete)),
    );
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

class _FailingAi implements RealLifeAiService {
  @override
  Future<RealLifeExtraction> extract(String transcript) =>
      Future<RealLifeExtraction>.error(StateError('unavailable'));

  @override
  Future<RealLifeReconstruction> reconstruct({
    required String caseId,
    required RealLifeExtraction extraction,
    bool similarVariation = false,
  }) =>
      Future<RealLifeReconstruction>.error(StateError('unavailable'));
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

class _GoldenBookAi implements AiGateway {
  Map<String, dynamic>? conversationContext;

  @override
  Future<AiGatewayResult> invoke({
    required String task,
    required Map<String, dynamic> payload,
  }) async {
    conversationContext =
        Map<String, dynamic>.from(payload['conversation_context'] as Map);
    return const AiGatewayResult(
      data: {
        'status': 'extracted',
        'phrase': 'Meine neue Antwort.',
        'category': 'Persönlicher Favorit',
        'source_reference': 'Eigene Antwort',
        'clarification_question': '',
      },
      provider: 'mock',
      model: 'mock',
      promptVersion: 'golden_book_extract_v1',
    );
  }
}

class _GoldenBookRepository implements GoldenBookRepository {
  final savedPhrases = <String>[];
  String? sourceSessionId;

  @override
  Future<List<GoldenBookEntry>> fetchEntries() async => const [];

  @override
  Future<GoldenBookEntry> save({
    required String phrase,
    String? category,
    String? note,
    String? sourceSessionId,
    Map<String, dynamic> modelMeta = const {},
  }) async {
    savedPhrases.add(phrase);
    this.sourceSessionId = sourceSessionId;
    return GoldenBookEntry(
      id: 'entry-${savedPhrases.length}',
      phrase: phrase,
      category: category,
      note: note,
      sourceSessionId: sourceSessionId,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> delete(String id) async {}
}
