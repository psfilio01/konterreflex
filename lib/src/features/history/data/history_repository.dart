import 'package:konterreflex/src/features/history/domain/history_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryItem>> fetch();
  Future<void> deleteSession(String id);
  Future<void> deleteRealLifeCase(String id);
}

class SupabaseHistoryRepository implements HistoryRepository {
  SupabaseHistoryRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<List<HistoryItem>> fetch() async {
    final sessions = await _client
        .from('training_sessions')
        .select('id,mode,started_at,completed_at,scenario:scenarios(title)')
        .order('started_at', ascending: false);
    final cases = await _client
        .from('real_life_cases')
        .select('id,created_at')
        .order('created_at', ascending: false);
    final result = <HistoryItem>[
      for (final item in sessions)
        HistoryItem(
          id: item['id'] as String,
          kind: HistoryItemKind.session,
          title: _sessionTitle(item),
          createdAt: DateTime.parse(item['started_at'] as String),
          completedAt: item['completed_at'] == null
              ? null
              : DateTime.parse(item['completed_at'] as String),
        ),
      for (final item in cases)
        HistoryItem(
            id: item['id'] as String,
            kind: HistoryItemKind.realLifeCase,
            title: 'Erzählte echte Situation',
            createdAt: DateTime.parse(item['created_at'] as String)),
    ];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> deleteSession(String id) async {
    final deleted = await _client
        .rpc('delete_own_training_session', params: {'p_session_id': id});
    if (deleted != true) throw StateError('Session not found.');
  }

  @override
  Future<void> deleteRealLifeCase(String id) async {
    final deleted = await _client
        .rpc('delete_own_real_life_case', params: {'p_case_id': id});
    if (deleted != true) throw StateError('Case not found.');
  }
}

String _sessionTitle(Map<String, dynamic> item) {
  final scenario = item['scenario'];
  if (scenario is Map && scenario['title'] is String) {
    return scenario['title'] as String;
  }
  return switch (item['mode']) {
    'real_life' => 'Wiederholung einer echten Situation',
    'speech_challenge' => 'Speech Challenge',
    _ => 'Trainingseinheit',
  };
}
