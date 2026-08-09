import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/analytics/privacy_analytics.dart';

void main() {
  test('analytics event has only fixed non-content fields', () {
    final payload = const PrivacyAnalyticsEvent(
      name: AnalyticsEventName.sessionCompleted,
      feature: AnalyticsFeature.realLife,
      step: AnalyticsStep.completion,
      outcome: AnalyticsOutcome.completed,
    ).toDatabase(userId: 'user-1', platform: 'web');
    expect(payload.keys, {
      'user_id',
      'event_name',
      'feature_key',
      'step_key',
      'outcome_key',
      'platform_key'
    });
    final encoded = jsonEncode(payload).toLowerCase();
    for (final forbidden in [
      'transcript',
      'audio',
      'phrase',
      'spoken',
      'response_text'
    ]) {
      expect(encoded, isNot(contains(forbidden)));
    }
  });
}
