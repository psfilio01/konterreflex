import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/observability/error_reporter.dart';

void main() {
  group('safe error reporting', () {
    test('maps errors to a fixed allow-list', () {
      expect(
        safeErrorCodeFor(const FormatException('private value')),
        SafeErrorCode.configurationInvalid,
      );
      expect(
          safeErrorCodeFor(TimeoutException('private')), SafeErrorCode.timeout);
      expect(safeErrorCodeFor(Exception('private')), SafeErrorCode.unexpected);
    });

    test('serializes metadata without private or arbitrary fields', () {
      const event = SafeErrorEvent(
        code: SafeErrorCode.unexpected,
        area: ErrorArea.flutter,
        fatal: false,
        environment: ErrorEnvironment.production,
      );

      expect(event.toJson(), {
        'code': 'unexpected',
        'area': 'flutter',
        'fatal': false,
        'environment': 'production',
      });
      expect(
        event.toJson().keys,
        isNot(containsAll(
            ['message', 'stack', 'transcript', 'audio', 'payload'])),
      );
    });

    test('sanitizes the environment to a fixed value', () {
      expect(
        safeErrorEnvironmentFor('private transcript'),
        ErrorEnvironment.invalid,
      );
      expect(
        safeErrorEnvironmentFor('production'),
        ErrorEnvironment.production,
      );
    });
  });
}
