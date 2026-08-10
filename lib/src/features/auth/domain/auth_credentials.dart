import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';

const minimumPasswordLength = 8;

String? validateEmail(String email, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('de'));
  final normalized = email.trim();
  final at = normalized.indexOf('@');
  if (at <= 0 || at == normalized.length - 1) {
    return l10n.validEmailError;
  }
  return null;
}

String? validatePassword(String password, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('de'));
  if (password.length < minimumPasswordLength) {
    return l10n.passwordLengthError(minimumPasswordLength);
  }
  return null;
}

String? validatePasswordConfirmation(
  String password,
  String confirmation, {
  AppLocalizations? strings,
}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('de'));
  if (password != confirmation) {
    return l10n.passwordMismatchError;
  }
  return null;
}
