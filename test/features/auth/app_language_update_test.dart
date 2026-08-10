import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/data/auth_repository.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _user = User(
  id: 'user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  test('language selection is persisted on the signed-in profile', () async {
    final repository = _LanguageAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authUserProvider.future);

    await container
        .read(authActionControllerProvider.notifier)
        .updateAppLanguage(AppLanguage.english);

    expect(repository.updatedUserId, _user.id);
    expect(repository.updatedLocale, 'en');
    expect(container.read(authActionControllerProvider).hasError, isFalse);
  });
}

class _LanguageAuthRepository implements AuthRepository {
  String? updatedUserId;
  String? updatedLocale;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> get userChanges => const Stream.empty();

  @override
  Future<void> updateLocale({
    required String userId,
    required String locale,
  }) async {
    updatedUserId = userId;
    updatedLocale = locale;
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async => UserProfile(
        id: userId,
        locale: updatedLocale ?? 'de',
        displayName: 'Ada',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
