import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps provider errors to calm German product copy without exposing internals.
String authErrorMessageFor(
  Object error, {
  required String fallback,
  AppLocalizations? strings,
}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('de'));
  if (error is! AuthException) return fallback;

  final message = error.message.toLowerCase();
  final code = (error.code ?? '').toLowerCase();
  final status = error.statusCode ?? '';

  if (status == '429' ||
      code.contains('rate_limit') ||
      message.contains('rate limit') ||
      message.contains('over_email')) {
    return l10n.authTooManyAttempts;
  }
  if (message.contains('invalid login credentials') ||
      code.contains('invalid_credentials')) {
    return l10n.authInvalidCredentials;
  }
  if (message.contains('email not confirmed')) {
    return l10n.authEmailNotConfirmed;
  }
  if (message.contains('weak password') || code.contains('weak_password')) {
    return l10n.authWeakPassword;
  }
  if (message.contains('user already registered') ||
      code.contains('user_already_exists')) {
    return l10n.authUserExists;
  }
  if (message.contains('same password')) {
    return l10n.authSamePassword;
  }
  if (message.contains('provider is not enabled') ||
      message.contains('unsupported provider')) {
    return l10n.authProviderDisabled;
  }
  if (message.contains('expired') ||
      code.contains('otp_expired') ||
      message.contains('flow state')) {
    return l10n.authRequestExpired;
  }
  return fallback;
}
