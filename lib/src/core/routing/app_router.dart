import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/presentation/reset_password_screen.dart';
import 'package:konterreflex/src/features/auth/presentation/sign_in_screen.dart';
import 'package:konterreflex/src/features/home/home_screen.dart';
import 'package:konterreflex/src/features/history/presentation/history_screen.dart';
import 'package:konterreflex/src/features/golden_book/presentation/golden_book_screen.dart';
import 'package:konterreflex/src/features/onboarding/onboarding_screen.dart';
import 'package:konterreflex/src/features/real_life/presentation/real_life_replay_screen.dart';
import 'package:konterreflex/src/features/real_life/presentation/real_life_library_screen.dart';
import 'package:konterreflex/src/features/settings/settings_screen.dart';
import 'package:konterreflex/src/features/settings/privacy_settings_screen.dart';
import 'package:konterreflex/src/features/subscription/subscription_screen.dart';
import 'package:konterreflex/src/features/speech_challenge/presentation/speech_challenge_screen.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:konterreflex/src/features/training/presentation/scenario_session_screen.dart';
import 'package:konterreflex/src/features/training/presentation/training_screen.dart';

abstract final class AppRoute {
  static const home = 'home';
  static const signIn = 'sign-in';
  static const resetPassword = 'reset-password';
  static const onboarding = 'onboarding';
  static const settings = 'settings';
  static const training = 'training';
  static const trainingSession = 'training-session';
  static const realLife = 'real-life';
  static const realLifeNew = 'real-life-new';
  static const realLifeCase = 'real-life-case';
  static const speechChallenge = 'speech-challenge';
  static const goldenBook = 'golden-book';
  static const subscription = 'subscription';
  static const history = 'history';
  static const privacy = 'privacy';
}

/// Notifies [GoRouter] when auth/profile state changes without recreating it.
class _RouterAuthRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterAuthRefresh();
  ref.listen(authUserProvider, (_, __) => refresh.notify());
  ref.listen(passwordRecoveryProvider, (_, __) => refresh.notify());
  ref.listen(profileProvider, (_, __) => refresh.notify());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authUser = ref.read(authUserProvider);
      final passwordRecovery = ref.read(passwordRecoveryProvider);
      final profile = ref.read(profileProvider);
      final location = state.matchedLocation;

      // Never block the UI on a blank loading route while auth resolves.
      if (authUser.isLoading) {
        return location == '/sign-in' ? null : '/sign-in';
      }

      final user = authUser.asData?.value ?? authUser.valueOrNull;
      if (user == null) {
        return location == '/sign-in' ? null : '/sign-in';
      }

      if (passwordRecovery.asData?.value ?? false) {
        return location == '/reset-password' ? null : '/reset-password';
      }

      if (profile.isLoading) {
        return null;
      }

      final hasProfile = profile.asData?.value?.hasCompletedOnboarding ?? false;
      if (!hasProfile) {
        return location == '/onboarding' ? null : '/onboarding';
      }
      if (location == '/sign-in' || location == '/onboarding') {
        return '/';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              context.l10n.routeLoadError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.foreground, fontSize: 16),
            ),
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/sign-in',
        name: AppRoute.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: AppRoute.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
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
        path: '/privacy',
        name: AppRoute.privacy,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: AppRoute.history,
        builder: (context, state) => const HistoryScreen(),
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
              autoStart: state.uri.queryParameters['autoStart'] == 'true',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/real-life',
        name: AppRoute.realLife,
        builder: (context, state) => const RealLifeLibraryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: AppRoute.realLifeNew,
            builder: (context, state) => const RealLifeReplayScreen(),
          ),
          GoRoute(
            path: 'case/:caseId',
            name: AppRoute.realLifeCase,
            builder: (context, state) => RealLifeReplayScreen(
              caseId: state.pathParameters['caseId']!,
              autoStart: true,
            ),
          ),
        ],
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
