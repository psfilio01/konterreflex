import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps auth provider errors to calm German product copy.
String authErrorMessageFor(Object error, {required String fallback}) {
  if (error is! AuthException) return fallback;

  final message = error.message.toLowerCase();
  final code = (error.code ?? '').toLowerCase();
  final status = error.statusCode ?? '';

  if (status == '429' ||
      code.contains('rate_limit') ||
      message.contains('rate limit') ||
      message.contains('over_email')) {
    return 'Zu viele E-Mails in kurzer Zeit. Bitte warte etwa eine Stunde oder nutze einen bereits gesendeten Link.';
  }
  if (message.contains('invalid login') || message.contains('invalid email')) {
    return 'Bitte prüfe die E-Mail-Adresse.';
  }
  if (message.contains('expired') || code.contains('otp_expired')) {
    return 'Der Anmeldelink ist abgelaufen. Bitte fordere einen neuen an.';
  }
  if (message.contains('flow state') ||
      message.contains('code verifier') ||
      message.contains('pkce')) {
    return 'Der Anmeldelink ist nicht mehr gültig. Bitte fordere einen neuen an und kopiere ihn in die App.';
  }
  return fallback;
}
