import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_evaluation_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/speech_challenge/presentation/speech_challenge_screen.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('challenge cards use the same spacing as training cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          challengeSetsProvider.overrideWith((ref) async => challengeSets),
        ],
        child: const MaterialApp(home: SpeechChallengeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(2));
    final firstCard = tester.getRect(cards.at(0));
    final secondCard = tester.getRect(cards.at(1));

    expect(secondCard.top - firstCard.bottom, AppSpacing.md);
  });

  testWidgets('session setup offers presets and a validated custom count', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            SupabaseClient(
              'https://example.supabase.co',
              'public-key',
              authOptions: const AuthClientOptions(autoRefreshToken: false),
            ),
          ),
          appLanguageProvider.overrideWithValue(AppLanguage.german),
          speechChallengeRepositoryProvider.overrideWithValue(_Repository()),
          speechChallengeEvaluationRepositoryProvider.overrideWithValue(
            _EvaluationRepository(),
          ),
        ],
        child: MaterialApp(
          home: ChallengeSessionScreen(challengeSet: challengeSets.first),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('challenge-count-5')), findsOneWidget);
    expect(find.byKey(const Key('challenge-count-10')), findsOneWidget);
    expect(find.byKey(const Key('challenge-count-15')), findsOneWidget);
    expect(find.text('Challenge mit 5 Impulsen starten'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('challenge-custom-count')),
      '7',
    );
    await tester.pump();
    expect(find.text('Challenge mit 7 Impulsen starten'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('challenge-custom-count')),
      '16',
    );
    await tester.pump();
    expect(find.text('Bitte wähle 1 bis 15.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('start-configured-challenge')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('consolidated result keeps response details collapsed', (
    tester,
  ) async {
    final result = challengeResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpeechChallengeResultView(
              result: result,
              targetCount: 2,
              onNewChallenge: () {},
            ),
          ),
        ),
      ),
    );

    expect(
        find.byKey(const Key('feedback-overall-developing')), findsOneWidget);
    expect(find.byKey(const Key('challenge-detail-1')), findsOneWidget);
    expect(find.byKey(const Key('challenge-detail-2')), findsOneWidget);
    expect(find.text('Antwort 1').hitTestable(), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('challenge-detail-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('challenge-detail-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Antwort 1'));
    await tester.pumpAndSettle();

    expect(find.text('Antwort 1').hitTestable(), findsOneWidget);
    expect(
      find.text('Nenne den nächsten Schritt.').hitTestable(),
      findsOneWidget,
    );
  });
}

final challengeSets = [
  ChallengeSet(
    id: 'position',
    title: 'Präzise Position',
    description: 'Eine Haltung kurz und anschlussfähig ausdrücken.',
    prompts: prompts,
  ),
  ChallengeSet(
    id: 'boundaries',
    title: 'Klare Grenzen',
    description: 'Spontan Grenzen setzen, ohne unnötig zu verschärfen.',
    prompts: prompts,
  ),
];

final prompts = [
  for (var index = 1; index <= 15; index++)
    ChallengePrompt(
      id: 'prompt-$index',
      remark: 'Impuls $index',
      context: 'Kontext $index',
      sortOrder: index - 1,
    ),
];

final challengeResult = ChallengeSessionResult(
  summary: feedback,
  details: [
    for (var index = 0; index < 2; index++)
      ChallengeResponseDetail(
        answer: ChallengeAnswer(
          prompt: prompts[index],
          responseId: 'response-$index',
          transcript: 'Antwort ${index + 1}',
        ),
        signal: index == 0 ? FeedbackSignal.strong : FeedbackSignal.developing,
        headline: 'Klar begonnen',
        strength: 'Direkter Einstieg',
        improvement: 'Nenne den nächsten Schritt.',
        alternative: 'Ich möchte den Gedanken kurz beenden.',
      ),
  ],
  provider: 'mock',
  model: 'mock',
  promptVersion: 'challenge-v1',
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
  headline: 'Klar begonnen',
  explanation: 'Die Position ist verständlich.',
  strengths: ['Direkter Einstieg'],
  improvement: 'Nenne den nächsten Schritt.',
  alternatives: ['Ich möchte den Gedanken kurz beenden.'],
  dimensions: FeedbackDimensions(
    posture: 'ruhig',
    precision: 'klar',
    frame: 'gesetzt',
    socialEffect: 'anschlussfähig',
    naturalness: 'sprechbar',
    escalationFit: 'passend',
  ),
  provider: 'mock',
  model: 'mock',
  promptVersion: 'mock-v1',
);

class _Repository implements SpeechChallengeRepository {
  @override
  Future<List<ChallengeSet>> fetchActiveSets() async => challengeSets;

  @override
  Future<TrainingSessionRecord> startSession({
    required String setId,
    required String clientId,
    required int targetCount,
    required List<String> promptIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> saveResponse({
    required String sessionId,
    required String promptId,
    required String clientId,
    required String transcript,
    required int position,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> completeSession(String sessionId) => throw UnimplementedError();

  @override
  Future<void> saveResult({
    required String sessionId,
    required ChallengeSessionResult result,
  }) =>
      throw UnimplementedError();
}

class _EvaluationRepository implements SpeechChallengeEvaluationRepository {
  @override
  Future<ChallengeSessionResult> evaluate({
    required ChallengeSet challengeSet,
    required List<ChallengeAnswer> answers,
  }) =>
      throw UnimplementedError();
}
