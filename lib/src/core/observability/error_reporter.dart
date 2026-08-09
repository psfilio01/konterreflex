import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

enum ErrorArea { bootstrap, flutter, platform }

enum ErrorEnvironment { development, staging, production, invalid }

enum SafeErrorCode {
  configurationInvalid,
  stateFailure,
  timeout,
  unexpected;

  String get wireValue => switch (this) {
        SafeErrorCode.configurationInvalid => 'configuration_invalid',
        SafeErrorCode.stateFailure => 'state_failure',
        SafeErrorCode.timeout => 'timeout',
        SafeErrorCode.unexpected => 'unexpected',
      };
}

class SafeErrorEvent {
  const SafeErrorEvent({
    required this.code,
    required this.area,
    required this.fatal,
    required this.environment,
  });

  final SafeErrorCode code;
  final ErrorArea area;
  final bool fatal;
  final ErrorEnvironment environment;

  Map<String, Object> toJson() => {
        'code': code.wireValue,
        'area': area.name,
        'fatal': fatal,
        'environment': environment.name,
      };
}

abstract interface class ErrorReporter {
  void capture(SafeErrorEvent event);
}

/// Local release hook. Replace it with a remote adapter without changing the
/// safe event contract. Error messages, stack traces, transcripts and audio
/// must never be added to [SafeErrorEvent].
class ConsoleErrorReporter implements ErrorReporter {
  const ConsoleErrorReporter();

  @override
  void capture(SafeErrorEvent event) {
    debugPrint('[safe-error] ${jsonEncode(event.toJson())}');
  }
}

SafeErrorCode safeErrorCodeFor(Object error) {
  if (error is FormatException) return SafeErrorCode.configurationInvalid;
  if (error is StateError) return SafeErrorCode.stateFailure;
  if (error is TimeoutException) return SafeErrorCode.timeout;
  return SafeErrorCode.unexpected;
}

ErrorEnvironment safeErrorEnvironmentFor(String value) {
  return switch (value.trim().toLowerCase()) {
    'development' => ErrorEnvironment.development,
    'staging' => ErrorEnvironment.staging,
    'production' => ErrorEnvironment.production,
    _ => ErrorEnvironment.invalid,
  };
}

void installGlobalErrorReporting({
  required ErrorReporter reporter,
  required String environment,
}) {
  final safeEnvironment = safeErrorEnvironmentFor(environment);
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    reporter.capture(
      SafeErrorEvent(
        code: safeErrorCodeFor(details.exception),
        area: ErrorArea.flutter,
        fatal: false,
        environment: safeEnvironment,
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.capture(
      SafeErrorEvent(
        code: safeErrorCodeFor(error),
        area: ErrorArea.platform,
        fatal: true,
        environment: safeEnvironment,
      ),
    );
    return true;
  };
}
