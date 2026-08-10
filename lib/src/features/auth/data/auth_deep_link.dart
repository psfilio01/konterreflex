import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared mobile redirect used for magic-link / OTP email callbacks.
const kAuthCallbackRedirectUrl = 'konterreflex://login-callback';

/// Set in [bootstrapKonterreflex] after startup wiring is ready.
AuthDeepLinkCoordinator? konterreflexDeepLinks;

final authDeepLinkCoordinatorProvider = Provider<AuthDeepLinkCoordinator>((ref) {
  final coordinator = konterreflexDeepLinks;
  if (coordinator != null) return coordinator;
  final fallback = AuthDeepLinkCoordinator();
  ref.onDispose(fallback.dispose);
  return fallback;
});

/// True when [uri] carries an auth callback payload Supabase can exchange.
bool isAuthCallbackUri(Uri uri) {
  final fragmentParameters = Uri.splitQueryString(uri.fragment);
  bool hasParameter(String key) =>
      uri.queryParameters.containsKey(key) ||
      fragmentParameters.containsKey(key);

  return hasParameter('access_token') ||
      hasParameter('code') ||
      hasParameter('error') ||
      hasParameter('error_code') ||
      hasParameter('error_description');
}

/// Captures auth deep links early (including cold start) and exchanges them
/// for a Supabase session. Must start listening before any long async gap in
/// `main`, then [attach] after [Supabase.initialize].
class AuthDeepLinkCoordinator {
  AuthDeepLinkCoordinator({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final List<Uri> _pending = <Uri>[];
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  StreamSubscription<Uri>? _subscription;
  SupabaseClient? _client;
  bool _attached = false;
  String? _lastHandledUri;

  Future<void> attach(SupabaseClient client) async {
    _client = client;
    _attached = true;
    start();
    final pending = List<Uri>.of(_pending);
    _pending.clear();
    for (final uri in pending) {
      await _handle(uri);
    }
  }

  void start() {
    if (_subscription != null) return;
    try {
      _subscription = _appLinks.uriLinkStream.listen(
        _onUri,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Auth deep link stream error: $error');
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Auth deep link listener failed to start: $error\n$stackTrace');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    lastError.dispose();
  }

  void _onUri(Uri uri) {
    if (!_attached || _client == null) {
      _pending.add(uri);
      return;
    }
    unawaited(_handle(uri));
  }

  Future<void> _handle(Uri uri) async {
    if (!isAuthCallbackUri(uri)) return;
    final client = _client;
    if (client == null) return;

    final key = uri.toString();
    if (_lastHandledUri == key) return;
    _lastHandledUri = key;

    // A successful earlier attempt may already have created a session.
    if (client.auth.currentSession != null) return;

    try {
      await client.auth.getSessionFromUrl(uri).timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('auth callback timeout'),
          );
      lastError.value = null;
    } on AuthException catch (error) {
      if (client.auth.currentSession != null) return;
      lastError.value = _userMessageFor(error);
      debugPrint('Auth deep link failed: ${error.message}');
    } catch (error) {
      if (client.auth.currentSession != null) return;
      lastError.value = 'Die Anmeldung über den E-Mail-Link ist fehlgeschlagen.';
      debugPrint('Auth deep link failed: $error');
    }
  }

  static String _userMessageFor(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('flow state') ||
        message.contains('code verifier') ||
        message.contains('pkce')) {
      return 'Der Anmeldelink ist nicht mehr gültig. Bitte nutze den Code aus der E-Mail.';
    }
    if (message.contains('expired') || message.contains('otp_expired')) {
      return 'Der Anmeldelink ist abgelaufen. Bitte nutze den Code aus der E-Mail.';
    }
    return 'Bitte melde dich mit dem Code aus der E-Mail an.';
  }
}
