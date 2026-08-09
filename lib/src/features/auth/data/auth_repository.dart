import 'package:flutter/foundation.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> get userChanges;

  Future<void> sendSignInLink(String email);

  Future<UserProfile?> fetchProfile(String userId);

  Future<void> completeOnboarding({
    required String userId,
    required String displayName,
  });

  Future<void> signOut();

  Future<void> deleteAccount();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<User?> get userChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  @override
  Future<void> sendSignInLink(String email) {
    final redirectUrl = kIsWeb
        ? Uri.base.resolve('/').toString()
        : 'konterreflex://login-callback';
    return _client.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final data =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data == null ? null : UserProfile.fromJson(data);
  }

  @override
  Future<void> completeOnboarding({
    required String userId,
    required String displayName,
  }) async {
    await _client
        .from('profiles')
        .update({'display_name': displayName.trim()}).eq('id', userId);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw const AuthException('Das Konto konnte nicht gelöscht werden.');
    }
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}
