import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/data/auth_repository.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

final authUserProvider = StreamProvider<User?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  try {
    yield repository.currentUser;
    yield* repository.userChanges;
  } catch (error, stackTrace) {
    debugPrint('authUserProvider failed: $error\n$stackTrace');
    yield null;
  }
});

final passwordRecoveryProvider = StreamProvider<bool>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield false;
  await for (final state in repository.authStateChanges) {
    yield state.event == AuthChangeEvent.passwordRecovery;
  }
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authUserProvider);
  if (authState.isLoading) return null;
  final user = authState.asData?.value;
  if (user == null) return null;
  try {
    return await ref
        .watch(authRepositoryProvider)
        .fetchProfile(user.id)
        .timeout(
          const Duration(seconds: 8),
        );
  } on TimeoutException {
    return null;
  } catch (error, stackTrace) {
    debugPrint('profileProvider failed: $error\n$stackTrace');
    return null;
  }
});

final authActionControllerProvider =
    NotifierProvider<AuthActionController, AsyncValue<void>>(
  AuthActionController.new,
);

class AuthActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: password),
    );
  }

  Future<RegistrationOutcome?> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    RegistrationOutcome? outcome;
    await _run(
      () async => outcome = await ref
          .read(authRepositoryProvider)
          .signUpWithPassword(email: email, password: password),
    );
    return state.hasError ? null : outcome;
  }

  Future<void> signInWithGoogle() {
    return _run(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> signInWithApple() {
    return _run(() => ref.read(authRepositoryProvider).signInWithApple());
  }

  Future<void> requestPasswordReset(String email) {
    return _run(
      () => ref.read(authRepositoryProvider).requestPasswordReset(email),
    );
  }

  Future<void> updatePassword(String password) {
    return _run(
      () => ref.read(authRepositoryProvider).updatePassword(password),
    );
  }

  Future<void> completeOnboarding(String displayName) async {
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) {
      state =
          AsyncError(StateError('Keine aktive Sitzung.'), StackTrace.current);
      return;
    }
    await _run(
      () => ref
          .read(authRepositoryProvider)
          .completeOnboarding(userId: user.id, displayName: displayName),
    );
    if (!state.hasError) ref.invalidate(profileProvider);
  }

  Future<void> signOut() {
    return _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<void> deleteAccount() {
    return _run(() => ref.read(authRepositoryProvider).deleteAccount());
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}
