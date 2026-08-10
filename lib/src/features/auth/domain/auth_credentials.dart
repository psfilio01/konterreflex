const minimumPasswordLength = 8;

String? validateEmail(String email) {
  final normalized = email.trim();
  final at = normalized.indexOf('@');
  if (at <= 0 || at == normalized.length - 1) {
    return 'Bitte gib eine gültige E-Mail-Adresse ein.';
  }
  return null;
}

String? validatePassword(String password) {
  if (password.length < minimumPasswordLength) {
    return 'Das Passwort muss mindestens $minimumPasswordLength Zeichen lang sein.';
  }
  return null;
}

String? validatePasswordConfirmation(String password, String confirmation) {
  if (password != confirmation) {
    return 'Die Passwörter stimmen nicht überein.';
  }
  return null;
}
