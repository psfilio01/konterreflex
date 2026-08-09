import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AnalyticsEventName {
  modeOpened,
  sessionStarted,
  sessionCompleted,
  feedbackViewed,
  subscriptionOpened
}

enum AnalyticsFeature {
  training,
  realLife,
  speechChallenge,
  goldenBook,
  subscription
}

enum AnalyticsStep { entry, scene, response, feedback, completion }

enum AnalyticsOutcome { started, completed, cancelled, failed }

class PrivacyAnalyticsEvent {
  const PrivacyAnalyticsEvent(
      {required this.name, required this.feature, this.step, this.outcome});
  final AnalyticsEventName name;
  final AnalyticsFeature feature;
  final AnalyticsStep? step;
  final AnalyticsOutcome? outcome;

  Map<String, dynamic> toDatabase(
          {required String userId, required String platform}) =>
      {
        'user_id': userId,
        'event_name': _snake(name.name),
        'feature_key': _snake(feature.name),
        'step_key': step == null ? null : _snake(step!.name),
        'outcome_key': outcome == null ? null : _snake(outcome!.name),
        'platform_key': platform,
      };
}

abstract interface class PrivacyAnalytics {
  Future<void> track(PrivacyAnalyticsEvent event);
}

class SupabasePrivacyAnalytics implements PrivacyAnalytics {
  SupabasePrivacyAnalytics(this._client);
  final SupabaseClient _client;
  @override
  Future<void> track(PrivacyAnalyticsEvent event) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final preferences = await _client
        .from('user_privacy_preferences')
        .select('analytics_enabled')
        .eq('user_id', userId)
        .maybeSingle();
    if (preferences?['analytics_enabled'] != true) return;
    await _client
        .from('analytics_events')
        .insert(event.toDatabase(userId: userId, platform: _platform));
  }
}

String get _platform => kIsWeb
    ? 'web'
    : switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'other',
      };

String _snake(String value) => value.replaceAllMapped(
    RegExp('[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
