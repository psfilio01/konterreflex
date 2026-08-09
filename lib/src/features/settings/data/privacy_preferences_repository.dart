import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyPreferences {
  const PrivacyPreferences(
      {required this.recordingRetentionDays, required this.analyticsEnabled});
  factory PrivacyPreferences.fromJson(Map<String, dynamic>? json) =>
      PrivacyPreferences(
        recordingRetentionDays: json?['recording_retention_days'] as int? ?? 0,
        analyticsEnabled: json?['analytics_enabled'] as bool? ?? false,
      );
  final int recordingRetentionDays;
  final bool analyticsEnabled;
}

abstract interface class PrivacyPreferencesRepository {
  Future<PrivacyPreferences> fetch();
  Future<void> save(PrivacyPreferences preferences);
}

class SupabasePrivacyPreferencesRepository
    implements PrivacyPreferencesRepository {
  SupabasePrivacyPreferencesRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<PrivacyPreferences> fetch() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Authentication required.');
    final data = await _client
        .from('user_privacy_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return PrivacyPreferences.fromJson(data);
  }

  @override
  Future<void> save(PrivacyPreferences preferences) =>
      _client.rpc('set_own_privacy_preferences', params: {
        'p_retention_days': preferences.recordingRetentionDays,
        'p_analytics_enabled': preferences.analyticsEnabled,
      });
}
