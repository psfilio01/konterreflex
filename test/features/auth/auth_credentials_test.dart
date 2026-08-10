import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/auth/domain/auth_credentials.dart';

void main() {
  test('requires a usable email address', () {
    expect(validateEmail('person@example.com'), isNull);
    expect(validateEmail('person'), isNotNull);
    expect(validateEmail('@example.com'), isNotNull);
  });

  test('requires at least eight password characters', () {
    expect(validatePassword('12345678'), isNull);
    expect(validatePassword('1234567'), contains('8 Zeichen'));
  });

  test('requires matching password confirmation', () {
    expect(validatePasswordConfirmation('password', 'password'), isNull);
    expect(
      validatePasswordConfirmation('password', 'different'),
      contains('stimmen nicht überein'),
    );
  });
}
