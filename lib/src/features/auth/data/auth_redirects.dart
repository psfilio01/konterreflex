import 'package:flutter/foundation.dart';

const mobileAuthCallbackUrl = 'konterreflex://auth-callback';
const mobilePasswordRecoveryUrl = 'konterreflex://reset-password';

enum AuthRedirectPurpose { authentication, passwordRecovery }

String authRedirectUrl(
  AuthRedirectPurpose purpose, {
  bool? web,
  Uri? webBaseUrl,
}) {
  final isWeb = web ?? kIsWeb;
  if (!isWeb) {
    return switch (purpose) {
      AuthRedirectPurpose.authentication => mobileAuthCallbackUrl,
      AuthRedirectPurpose.passwordRecovery => mobilePasswordRecoveryUrl,
    };
  }

  final baseUrl = webBaseUrl ?? Uri.base;
  return baseUrl
      .resolve(
        purpose == AuthRedirectPurpose.passwordRecovery
            ? '/reset-password'
            : '/',
      )
      .toString();
}
