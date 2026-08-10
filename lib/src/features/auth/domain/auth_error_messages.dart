import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps provider errors to calm German product copy without exposing internals.
String authErrorMessageFor(Object error, {required String fallback}) {
  if (error is! AuthException) return fallback;

  final message = error.message.toLowerCase();
  final code = (error.code ?? '').toLowerCase();
  final status = error.statusCode ?? '';

  if (status == '429' ||
      code.contains('rate_limit') ||
      message.contains('rate limit') ||
      message.contains('over_email')) {
    return 'Zu viele Versuche in kurzer Zeit. Bitte warte einen Moment und versuche es erneut.';
  }
  if (message.contains('invalid login credentials') ||
      code.contains('invalid_credentials')) {
    return 'E-Mail-Adresse oder Passwort stimmen nicht.';
  }
  if (message.contains('email not confirmed')) {
    return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
  }
  if (message.contains('weak password') || code.contains('weak_password')) {
    return 'Das Passwort ist nicht sicher genug. Verwende mindestens 8 Zeichen.';
  }
  if (message.contains('user already registered') ||
      code.contains('user_already_exists')) {
    return 'Für diese E-Mail-Adresse besteht bereits ein Konto.';
  }
  if (message.contains('same password')) {
    return 'Das neue Passwort muss sich vom bisherigen unterscheiden.';
  }
  if (message.contains('provider is not enabled') ||
      message.contains('unsupported provider')) {
    return 'Diese Anmeldung ist noch nicht freigeschaltet.';
  }
  if (message.contains('expired') ||
      code.contains('otp_expired') ||
      message.contains('flow state')) {
    return 'Die Anfrage ist abgelaufen. Bitte starte den Vorgang erneut.';
  }
  return fallback;
}
