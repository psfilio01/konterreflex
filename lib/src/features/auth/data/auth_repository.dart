import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:konterreflex/src/features/auth/data/auth_deep_link.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> get userChanges;

  Future<void> sendSignInOtp(String email);

  Future<void> verifySignInOtp({
    required String email,
    required String token,
  });

  /// Completes passwordless sign-in from a copied Supabase email verify URL.
  /// Prefer this over opening the link in Mail/Safari, which often prefetches
  /// and burns the one-time token on iOS.
  Future<void> completeSignInFromEmailLink(String rawLink);

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
  Future<void> sendSignInOtp(String email) {
    final redirectUrl =
        kIsWeb ? Uri.base.resolve('/').toString() : kAuthCallbackRedirectUrl;
    return _client.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<void> verifySignInOtp({
    required String email,
    required String token,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedToken = token.trim();
    final types = <OtpType>[
      OtpType.email,
      OtpType.magiclink,
      OtpType.signup,
    ];

    AuthException? lastError;
    for (final type in types) {
      try {
        await _client.auth.verifyOTP(
          email: normalizedEmail,
          token: normalizedToken,
          type: type,
        );
        return;
      } on AuthException catch (error) {
        lastError = error;
      }
    }
    throw lastError ??
        const AuthException('Der Anmeldecode konnte nicht geprüft werden.');
  }

  @override
  Future<void> completeSignInFromEmailLink(String rawLink) async {
    final verifyUri = _extractVerifyUri(rawLink);
    if (verifyUri == null) {
      throw const AuthException(
        'Kein gültiger Anmelde-Link. Kopiere den vollständigen Link aus der E-Mail.',
      );
    }

    final callbackUri = await _resolveAuthCallback(verifyUri);
    await _client.auth.getSessionFromUrl(callbackUri);
  }

  @visibleForTesting
  static Uri? extractVerifyUriForTest(String rawLink) =>
      _extractVerifyUri(rawLink);

  static Uri? _extractVerifyUri(String rawLink) {
    final trimmed = rawLink.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'https?://[^\s<>"]+', caseSensitive: false)
        .firstMatch(trimmed);
    final candidate = match?.group(0) ?? trimmed;
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme || !uri.host.contains('supabase')) {
      return null;
    }
    if (!uri.path.contains('/auth/v1/verify') &&
        !uri.queryParameters.containsKey('token')) {
      return null;
    }
    return uri;
  }

  Future<Uri> _resolveAuthCallback(Uri verifyUri) async {
    if (kIsWeb) {
      throw const AuthException(
        'E-Mail-Link-Anmeldung bitte in der mobilen App abschließen.',
      );
    }

    final client = HttpClient();
    try {
      var current = verifyUri;
      for (var i = 0; i < 5; i++) {
        final request = await client.getUrl(current);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.userAgentHeader, 'Konterreflex/1.0');
        final response = await request.close();
        await response.drain<void>();

        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null || location.isEmpty) {
          throw const AuthException(
            'Der Anmelde-Link konnte nicht bestätigt werden.',
          );
        }

        final next = verifyUri.resolve(location);
        if (isAuthCallbackUri(next) ||
            next.scheme == 'konterreflex' ||
            next.queryParameters.containsKey('code') ||
            next.queryParameters.containsKey('access_token')) {
          return next;
        }
        if (response.statusCode >= 300 && response.statusCode < 400) {
          current = next;
          continue;
        }
        throw AuthException(
          'Unerwartete Antwort bei der Anmeldung (${response.statusCode}).',
        );
      }
      throw const AuthException('Der Anmelde-Link konnte nicht bestätigt werden.');
    } finally {
      client.close(force: true);
    }
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
