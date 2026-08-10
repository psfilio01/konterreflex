import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/features/history/domain/history_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryItem>> fetch();
  Future<void> deleteSession(String id);
  Future<void> deleteRealLifeCase(String id);
}

class SupabaseHistoryRepository implements HistoryRepository {
  SupabaseHistoryRepository(this._client, {AppLocalizations? strings})
      : _strings = strings ?? lookupAppLocalizations(const Locale('de'));
  final SupabaseClient _client;
  final AppLocalizations _strings;
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
          title: _sessionTitle(item, _strings),
          createdAt: DateTime.parse(item['started_at'] as String),
          completedAt: item['completed_at'] == null
              ? null
              : DateTime.parse(item['completed_at'] as String),
        ),
      for (final item in cases)
        HistoryItem(
            id: item['id'] as String,
            kind: HistoryItemKind.realLifeCase,
            title: _strings.toldRealLifeSituation,
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

String _sessionTitle(Map<String, dynamic> item, AppLocalizations strings) {
  final scenario = item['scenario'];
  if (scenario is Map && scenario['title'] is String) {
    return scenario['title'] as String;
  }
  return switch (item['mode']) {
    'real_life' => strings.realLifeReplayHistory,
    'speech_challenge' => strings.speechChallengeTitle,
    _ => strings.trainingSessionHistory,
  };
}
