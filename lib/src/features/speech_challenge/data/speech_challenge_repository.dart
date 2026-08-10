import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SpeechChallengeRepository {
  Future<List<ChallengeSet>> fetchActiveSets();
  Future<TrainingSessionRecord> startSession({
    required String setId,
    required String clientId,
    required int targetCount,
    required List<String> promptIds,
  });
  Future<String> saveResponse({
    required String sessionId,
    required String promptId,
    required String clientId,
    required String transcript,
    required int position,
  });
  Future<void> completeSession(String sessionId);
  Future<void> saveResult({
    required String sessionId,
    required ChallengeSessionResult result,
  });
}

class SupabaseSpeechChallengeRepository implements SpeechChallengeRepository {
  SupabaseSpeechChallengeRepository(
    this._client, {
    this.languageCode = 'de',
  });
  final SupabaseClient _client;
  final String languageCode;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required.');
    return id;
  }

  @override
  Future<List<ChallengeSet>> fetchActiveSets() async {
    final data = await _client
        .from('speech_challenge_sets')
        .select(
            'id,title,description,speech_challenge_prompts(id,remark,context,sort_order)')
        .eq('active', true)
        .eq('locale', languageCode)
        .order('title');
    return data
        .map(ChallengeSet.fromJson)
        .where((set) => set.prompts.isNotEmpty)
        .toList();
  }

  @override
  Future<TrainingSessionRecord> startSession(
      {required String setId,
      required String clientId,
      required int targetCount,
      required List<String> promptIds}) async {
    final data = await _client
        .from('training_sessions')
        .upsert({
          'user_id': _userId,
          'mode': 'speech_challenge',
          'client_id': clientId,
          'state': {
            'challenge_set_id': setId,
            'target_count': targetCount,
            'prompt_ids': promptIds,
          },
        }, onConflict: 'user_id,client_id')
        .select('id,client_id')
        .single();
    return TrainingSessionRecord(
        id: data['id'] as String, clientId: data['client_id'] as String);
  }

  @override
  Future<String> saveResponse(
      {required String sessionId,
      required String promptId,
      required String clientId,
      required String transcript,
      required int position}) async {
    final data = await _client
        .from('user_responses')
        .upsert({
          'session_id': sessionId,
          'user_id': _userId,
          'client_id': clientId,
          'transcript': transcript,
          'context': {
            'challenge_prompt_id': promptId,
            'challenge_position': position,
          },
        }, onConflict: 'user_id,client_id')
        .select('id')
        .single();
    return data['id'] as String;
  }

  @override
  Future<void> completeSession(String sessionId) async {
    await _client
        .from('training_sessions')
        .update({
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('user_id', _userId);
  }

  @override
  Future<void> saveResult({
    required String sessionId,
    required ChallengeSessionResult result,
  }) async {
    await _client.from('speech_challenge_results').upsert({
      'session_id': sessionId,
      'user_id': _userId,
      'result': result.toJson(),
      'model_meta': result.modelMeta,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'session_id');
  }
}
