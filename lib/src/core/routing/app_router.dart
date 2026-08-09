import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/presentation/auth_loading_screen.dart';
import 'package:konterreflex/src/features/auth/presentation/sign_in_screen.dart';
import 'package:konterreflex/src/features/home/home_screen.dart';
import 'package:konterreflex/src/features/golden_book/presentation/golden_book_screen.dart';
import 'package:konterreflex/src/features/onboarding/onboarding_screen.dart';
import 'package:konterreflex/src/features/real_life/presentation/real_life_replay_screen.dart';
import 'package:konterreflex/src/features/settings/settings_screen.dart';
import 'package:konterreflex/src/features/subscription/subscription_screen.dart';
import 'package:konterreflex/src/features/speech_challenge/presentation/speech_challenge_screen.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/features/training/presentation/scenario_session_screen.dart';
import 'package:konterreflex/src/features/training/presentation/training_screen.dart';

abstract final class AppRoute {
  static const home = 'home';
  static const loading = 'loading';
  static const signIn = 'sign-in';
  static const onboarding = 'onboarding';
  static const settings = 'settings';
  static const training = 'training';
  static const trainingSession = 'training-session';
  static const realLife = 'real-life';
  static const speechChallenge = 'speech-challenge';
  static const goldenBook = 'golden-book';
  static const subscription = 'subscription';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authUser = ref.watch(authUserProvider);
  final profile = ref.watch(profileProvider);
  final router = GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      final isAuthLoading = authUser.isLoading;
      final user = authUser.asData?.value;
      final isProfileLoading = user != null && profile.isLoading;
      final location = state.matchedLocation;

      if (isAuthLoading || isProfileLoading) {
        return location == '/loading' ? null : '/loading';
      }
      if (user == null) {
        return location == '/sign-in' ? null : '/sign-in';
      }

      final hasProfile = profile.asData?.value?.hasCompletedOnboarding ?? false;
      if (!hasProfile) {
        return location == '/onboarding' ? null : '/onboarding';
      }
      if (location == '/loading' ||
          location == '/sign-in' ||
          location == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        name: AppRoute.loading,
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: AppRoute.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: AppRoute.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        name: AppRoute.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/training',
        name: AppRoute.training,
        builder: (context, state) => const TrainingScreen(),
        routes: [
          GoRoute(
            path: 'scenario/:scenarioId',
            name: AppRoute.trainingSession,
            redirect: (context, state) =>
                state.extra is TrainingScenario ? null : '/training',
            builder: (context, state) => ScenarioSessionScreen(
              scenario: state.extra! as TrainingScenario,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/real-life',
        name: AppRoute.realLife,
        builder: (context, state) => const RealLifeReplayScreen(),
      ),
      GoRoute(
        path: '/speech-challenge',
        name: AppRoute.speechChallenge,
        builder: (context, state) => const SpeechChallengeScreen(),
      ),
      GoRoute(
        path: '/golden-book',
        name: AppRoute.goldenBook,
        builder: (context, state) => const GoldenBookScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
