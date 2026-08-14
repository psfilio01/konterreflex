import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/features/real_life/application/real_life_providers.dart';
import 'package:konterreflex/src/features/real_life/data/real_life_repository.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/real_life/presentation/real_life_library_screen.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';

void main() {
  testWidgets('first use opens the existing capture flow without empty list', (
    tester,
  ) async {
    final repository = _Repository(cases: const []);
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();

    expect(find.text('capture-flow'), findsOneWidget);
    expect(find.text('Deine Situationen'), findsNothing);
  });

  testWidgets('saved cases show library actions and calm separated cards', (
    tester,
  ) async {
    final repository = _Repository(cases: cases);
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();

    expect(find.text('Deine Situationen'), findsOneWidget);
    expect(find.byKey(const Key('random-real-life-practice')), findsOneWidget);
    expect(find.byKey(const Key('new-real-life-case')), findsOneWidget);
    expect(find.text('Teamgespräch'), findsOneWidget);
    expect(find.text('Spontane Rückfrage'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('adaptive random mode opens only the selected private case', (
    tester,
  ) async {
    final repository = _Repository(cases: cases, selectedId: 'case-2');
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('random-real-life-practice')));
    await tester.pumpAndSettle();

    expect(find.text('case-flow-case-2'), findsOneWidget);
    expect(repository.selectionCalls, 1);
  });

  testWidgets('a case card opens that exact saved situation', (tester) async {
    final repository = _Repository(cases: cases);
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('real-life-case-case-1')));
    await tester.pumpAndSettle();

    expect(find.text('case-flow-case-1'), findsOneWidget);
    expect(repository.selectionCalls, 0);
  });
}

Widget _app(GoRouter router, RealLifeRepository repository) => ProviderScope(
      overrides: [
        appLanguageProvider.overrideWithValue(AppLanguage.german),
        realLifeRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );

GoRouter _router() => GoRouter(
      initialLocation: '/real-life',
      routes: [
        GoRoute(
          path: '/real-life',
          name: AppRoute.realLife,
          builder: (context, state) => const RealLifeLibraryScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: AppRoute.realLifeNew,
              builder: (context, state) =>
                  const Scaffold(body: Text('capture-flow')),
            ),
            GoRoute(
              path: 'case/:caseId',
              name: AppRoute.realLifeCase,
              builder: (context, state) => Scaffold(
                body: Text('case-flow-${state.pathParameters['caseId']}'),
              ),
            ),
          ],
        ),
      ],
    );

final cases = [
  RealLifeCaseSummary(
    id: 'case-1',
    title: 'Teamgespräch',
    setting: 'Teamrunde',
    relationships: const ['Teammitglied'],
    createdAt: DateTime.utc(2026, 8, 14),
    hasCurrentLanguage: true,
  ),
  RealLifeCaseSummary(
    id: 'case-2',
    title: 'Spontane Rückfrage',
    setting: 'Nach einem Termin',
    relationships: const ['Kollege'],
    createdAt: DateTime.utc(2026, 8, 13),
    hasCurrentLanguage: false,
  ),
];

class _Repository implements RealLifeRepository {
  _Repository({required this.cases, this.selectedId});

  final List<RealLifeCaseSummary> cases;
  final String? selectedId;
  int selectionCalls = 0;

  @override
  Future<List<RealLifeCaseSummary>> fetchCases(
          {required String locale}) async =>
      cases;

  @override
  Future<String?> selectNextCaseId({required String locale}) async {
    selectionCalls += 1;
    return selectedId;
  }

  @override
  Future<SavedRealLifeCase> fetchCase({
    required String caseId,
    required String locale,
  }) =>
      throw UnimplementedError();

  @override
  Future<RealLifeCaseRecord> saveCaseWithReconstruction({
    required String clientId,
    required String sourceTranscript,
    required RealLifeExtraction extraction,
    required String locale,
    required RealLifeReconstruction reconstruction,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveReconstruction({
    required String caseId,
    required String locale,
    required RealLifeReconstruction reconstruction,
  }) =>
      throw UnimplementedError();

  @override
  Future<TrainingSessionRecord> startSession({
    required String caseId,
    required String clientId,
    required String locale,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> completeSession(String sessionId) => throw UnimplementedError();
}
