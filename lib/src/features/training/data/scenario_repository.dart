import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ScenarioRepository {
  Future<List<TrainingScenario>> fetchApprovedScenarios();

  Future<TrainingSessionRecord> startSession({
    required String scenarioId,
    required String clientId,
  });

  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  });

  Future<void> completeSession(String sessionId);
}

class SupabaseScenarioRepository implements ScenarioRepository {
  SupabaseScenarioRepository(this._client);

  final SupabaseClient _client;

  static const _scenarioSelection = '''
    id,
    title,
    category,
    moderator_intro,
    scenario_characters(id,name,description,voice_id,sort_order),
    scenario_turns(character_id,body,stage_direction,sort_order)
  ''';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required.');
    return id;
  }

  @override
  Future<List<TrainingScenario>> fetchApprovedScenarios() async {
    final data = await _client
        .from('scenarios')
        .select(_scenarioSelection)
        .eq('status', 'active')
        .order('title');
    return data.map(TrainingScenario.fromJson).toList();
  }

  @override
  Future<TrainingSessionRecord> startSession({
    required String scenarioId,
    required String clientId,
  }) async {
    final data = await _client
        .from('training_sessions')
        .upsert({
          'user_id': _userId,
          'scenario_id': scenarioId,
          'mode': 'simulation',
          'client_id': clientId,
          'state': {'source': 'mobile'},
        }, onConflict: 'user_id,client_id')
        .select('id,client_id')
        .single();
    return TrainingSessionRecord(
      id: data['id'] as String,
      clientId: data['client_id'] as String,
    );
  }

  @override
  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  }) async {
    final data = await _client
        .from('user_responses')
        .upsert({
          'session_id': sessionId,
          'user_id': _userId,
          'client_id': clientId,
          'transcript': transcript,
        }, onConflict: 'user_id,client_id')
        .select('id')
        .single();
    return data['id'] as String;
  }

  @override
  Future<void> completeSession(String sessionId) async {
    await _client
        .from('training_sessions')
        .update({'completed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', sessionId)
        .eq('user_id', _userId);
  }
}
