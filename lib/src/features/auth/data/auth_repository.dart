import 'package:flutter/foundation.dart';
import 'package:konterreflex/src/features/auth/data/auth_redirects.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RegistrationOutcome { signedIn, emailConfirmationRequired }

abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> get userChanges;

  Stream<AuthState> get authStateChanges;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<RegistrationOutcome> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> requestPasswordReset(String email);

  Future<void> updatePassword(String password);

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
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Stream<User?> get userChanges =>
      authStateChanges.map((event) => event.session?.user);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<RegistrationOutcome> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirectUrl(AuthRedirectPurpose.authentication),
    );
    return response.session == null
        ? RegistrationOutcome.emailConfirmationRequired
        : RegistrationOutcome.signedIn;
  }

  @override
  Future<void> signInWithGoogle() => _signInWithOAuth(OAuthProvider.google);

  @override
  Future<void> signInWithApple() => _signInWithOAuth(OAuthProvider.apple);

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final launched = await _client.auth.signInWithOAuth(
      provider,
      redirectTo: authRedirectUrl(AuthRedirectPurpose.authentication),
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const AuthException(
          'Die Anbieter-Anmeldung konnte nicht geöffnet werden.');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirectUrl(AuthRedirectPurpose.passwordRecovery),
    );
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
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
