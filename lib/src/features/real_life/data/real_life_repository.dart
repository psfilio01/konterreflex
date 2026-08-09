import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class RealLifeRepository {
  Future<RealLifeCaseRecord> saveCase({
    required String clientId,
    required String sourceTranscript,
    required RealLifeExtraction extraction,
  });

  Future<TrainingSessionRecord> startSession({
    required String caseId,
    required String clientId,
  });

  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  });

  Future<void> completeSession(String sessionId);
}

class SupabaseRealLifeRepository implements RealLifeRepository {
  SupabaseRealLifeRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required.');
    return id;
  }

  @override
  Future<RealLifeCaseRecord> saveCase({
    required String clientId,
    required String sourceTranscript,
    required RealLifeExtraction extraction,
  }) async {
    final data = await _client
        .from('real_life_cases')
        .upsert({
          'user_id': _userId,
          'client_id': clientId,
          'source_transcript': sourceTranscript,
          'extracted_context': extraction.toJson(),
        }, onConflict: 'user_id,client_id')
        .select('id,client_id')
        .single();
    return RealLifeCaseRecord(
      id: data['id'] as String,
      clientId: data['client_id'] as String,
    );
  }

  @override
  Future<TrainingSessionRecord> startSession({
    required String caseId,
    required String clientId,
  }) async {
    final data = await _client
        .from('training_sessions')
        .upsert({
          'user_id': _userId,
          'scenario_id': null,
          'mode': 'real_life',
          'client_id': clientId,
          'state': {'real_life_case_id': caseId},
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
