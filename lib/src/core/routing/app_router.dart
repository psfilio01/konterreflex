import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/presentation/auth_loading_screen.dart';
import 'package:konterreflex/src/features/auth/presentation/sign_in_screen.dart';
import 'package:konterreflex/src/features/home/home_screen.dart';
import 'package:konterreflex/src/features/onboarding/onboarding_screen.dart';
import 'package:konterreflex/src/features/settings/settings_screen.dart';

abstract final class AppRoute {
  static const home = 'home';
  static const loading = 'loading';
  static const signIn = 'sign-in';
  static const onboarding = 'onboarding';
  static const settings = 'settings';
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
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
