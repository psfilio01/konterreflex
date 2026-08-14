import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/features/training/application/scenario_providers.dart';
import 'package:konterreflex/src/features/training/data/scenario_repository.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/features/training/presentation/training_screen.dart';

void main() {
  testWidgets('opening Training selects once and replaces the catalogue', (
    tester,
  ) async {
    final repository = _Repository([() async => scenario]);
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();

    expect(find.text('session-scenario-1-auto'), findsOneWidget);
    expect(repository.selectionCalls, 1);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('selection failure offers retry without a scenario list', (
    tester,
  ) async {
    final repository = _Repository([
      () async => throw StateError('offline'),
      () async => scenario,
    ]);
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Die Szenarien konnten nicht geladen werden.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry-adaptive-training')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry-adaptive-training')));
    await tester.pumpAndSettle();

    expect(find.text('session-scenario-1-auto'), findsOneWidget);
    expect(repository.selectionCalls, 2);
  });

  testWidgets('empty adaptive pool has a calm explicit state', (tester) async {
    final repository = _Repository([() async => null]);
    final router = _router();

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine freigegebenen Szenarien.'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
}

Widget _app(GoRouter router, ScenarioRepository repository) => ProviderScope(
      overrides: [scenarioRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );

GoRouter _router() => GoRouter(
      initialLocation: '/training',
      routes: [
        GoRoute(
          path: '/training',
          name: AppRoute.training,
          builder: (context, state) => const TrainingScreen(),
          routes: [
            GoRoute(
              path: 'scenario/:scenarioId',
              name: AppRoute.trainingSession,
              builder: (context, state) => Scaffold(
                body: Text(
                  'session-${(state.extra! as TrainingScenario).id}-'
                  '${state.uri.queryParameters['autoStart'] == 'true' ? 'auto' : 'manual'}',
                ),
              ),
            ),
          ],
        ),
      ],
    );

const scenario = TrainingScenario(
  id: 'scenario-1',
  title: 'Situation',
  category: 'Arbeit',
  moderatorIntro: 'Einleitung',
  characters: [],
  turns: [],
);

class _Repository implements ScenarioRepository {
  _Repository(this.selections);

  final List<Future<TrainingScenario?> Function()> selections;
  int selectionCalls = 0;

  @override
  Future<TrainingScenario?> fetchNextAdaptiveScenario() {
    final selection = selections[selectionCalls];
    selectionCalls += 1;
    return selection();
  }

  @override
  Future<TrainingSessionRecord> startSession({
    required String scenarioId,
    required String clientId,
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
