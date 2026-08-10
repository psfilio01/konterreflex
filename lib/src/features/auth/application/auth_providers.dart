import 'dart:async';

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
  yield repository.currentUser;
  yield* repository.userChanges;
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authUserProvider).asData?.value;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).fetchProfile(user.id).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException(
          'Profil konnte nicht geladen werden.',
        ),
      );
});

final authActionControllerProvider =
    NotifierProvider<AuthActionController, AsyncValue<void>>(
  AuthActionController.new,
);

class AuthActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> sendSignInLink(String email) {
    return _run(() => ref.read(authRepositoryProvider).sendSignInLink(email));
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
