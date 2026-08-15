import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';
import 'package:konterreflex/src/features/training/domain/training_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class RealLifeRepository {
  Future<List<RealLifeCaseSummary>> fetchCases({required String locale});

  Future<SavedRealLifeCase> fetchCase({
    required String caseId,
    required String locale,
  });

  Future<String?> selectNextCaseId({required String locale});

  Future<RealLifeCaseRecord> saveCaseWithReconstruction({
    required String clientId,
    required String sourceTranscript,
    required RealLifeExtraction extraction,
    required String locale,
    required RealLifeReconstruction reconstruction,
  });

  Future<void> saveReconstruction({
    required String caseId,
    required String locale,
    required RealLifeReconstruction reconstruction,
  });

  Future<TrainingSessionRecord> startSession({
    required String caseId,
    required String clientId,
    required String locale,
  });

  Future<String> saveResponse({
    required String sessionId,
    required String clientId,
    required String transcript,
  });

  Future<void> completeSession(String sessionId);
}

class SupabaseRealLifeRepository implements RealLifeRepository {
  SupabaseRealLifeRepository(
    this._client, {
    this.fallbackTitle = 'Gespeicherte Situation',
    this.scenarioCategory = 'Echte Situation',
  });

  final SupabaseClient _client;
  final String fallbackTitle;
  final String scenarioCategory;

  static const _caseSelection = '''
    id,
    client_id,
    source_transcript,
    extracted_context,
    created_at,
    real_life_reconstructions(locale,title,scenario_snapshot,model_meta)
  ''';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required.');
    return id;
  }

  @override
  Future<List<RealLifeCaseSummary>> fetchCases({required String locale}) async {
    final data = await _client
        .from('real_life_cases')
        .select(_caseSelection)
        .order('created_at', ascending: false);
    return data.map((item) => _summary(item, locale)).toList();
  }

  @override
  Future<SavedRealLifeCase> fetchCase({
    required String caseId,
    required String locale,
  }) async {
    final data = await _client
        .from('real_life_cases')
        .select(_caseSelection)
        .eq('id', caseId)
        .single();
    final extraction = RealLifeExtraction.fromJson(
      Map<String, dynamic>.from(data['extracted_context'] as Map),
    );
    final row = _localizedRow(data, locale);
    return SavedRealLifeCase(
      record: RealLifeCaseRecord(
        id: data['id'] as String,
        clientId: data['client_id'] as String,
      ),
      sourceTranscript: data['source_transcript'] as String,
      extraction: extraction,
      reconstruction: row == null
          ? null
          : RealLifeReconstruction.fromJson(
              Map<String, dynamic>.from(row['scenario_snapshot'] as Map),
              id: data['id'] as String,
              category: scenarioCategory,
              provider: _metaText(row, 'provider'),
              model: _metaText(row, 'model'),
              promptVersion: _metaText(row, 'prompt_version'),
              fallbackResponseCue: locale == 'en'
                  ? 'Your turn. What do you say?'
                  : 'Du bist dran. Was antwortest du?',
            ),
    );
  }

  @override
  Future<String?> selectNextCaseId({required String locale}) async {
    final selection = await _client.rpc(
      'select_next_practice_item',
      params: {'p_pool': 'real_life', 'p_locale': locale},
    );
    if (selection is! List || selection.isEmpty) return null;
    final first = selection.first;
    if (first is! Map || first['item_id'] is! String) {
      throw const FormatException('Invalid adaptive real-life selection.');
    }
    return first['item_id'] as String;
  }

  @override
  Future<RealLifeCaseRecord> saveCaseWithReconstruction({
    required String clientId,
    required String sourceTranscript,
    required RealLifeExtraction extraction,
    required String locale,
    required RealLifeReconstruction reconstruction,
  }) async {
    final result = await _client.rpc(
      'save_real_life_case_with_reconstruction',
      params: {
        'p_client_id': clientId,
        'p_source_transcript': sourceTranscript,
        'p_extracted_context': extraction.toJson(),
        'p_locale': locale,
        'p_title': reconstruction.scenario.title,
        'p_scenario_snapshot': reconstruction.toJson(),
        'p_model_meta': reconstruction.modelMeta,
      },
    );
    if (result is! List || result.isEmpty || result.first is! Map) {
      throw const FormatException('Invalid saved real-life case.');
    }
    final data = Map<String, dynamic>.from(result.first as Map);
    return RealLifeCaseRecord(
      id: data['case_id'] as String,
      clientId: data['case_client_id'] as String,
    );
  }

  @override
  Future<void> saveReconstruction({
    required String caseId,
    required String locale,
    required RealLifeReconstruction reconstruction,
  }) async {
    await _client.from('real_life_reconstructions').upsert({
      'case_id': caseId,
      'user_id': _userId,
      'locale': locale,
      'title': reconstruction.scenario.title,
      'scenario_snapshot': reconstruction.toJson(),
      'model_meta': reconstruction.modelMeta,
    }, onConflict: 'case_id,locale');
  }

  @override
  Future<TrainingSessionRecord> startSession({
    required String caseId,
    required String clientId,
    required String locale,
  }) async {
    final data = await _client
        .from('training_sessions')
        .upsert({
          'user_id': _userId,
          'scenario_id': null,
          'mode': 'real_life',
          'client_id': clientId,
          'state': {'real_life_case_id': caseId, 'locale': locale},
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

  RealLifeCaseSummary _summary(Map<String, dynamic> data, String locale) {
    final extraction = RealLifeExtraction.fromJson(
      Map<String, dynamic>.from(data['extracted_context'] as Map),
    );
    final localized = _localizedRow(data, locale);
    final rows = _reconstructionRows(data);
    final anyTitle = rows
        .map((row) => row['title'])
        .whereType<String>()
        .where((title) => title.trim().isNotEmpty)
        .firstOrNull;
    return RealLifeCaseSummary(
      id: data['id'] as String,
      title: (localized?['title'] as String?)?.trim().isNotEmpty == true
          ? localized!['title'] as String
          : anyTitle ??
              (extraction.setting.isNotEmpty
                  ? extraction.setting
                  : fallbackTitle),
      setting: extraction.setting,
      relationships: extraction.participants
          .map((participant) => participant.relationship)
          .where((relationship) => relationship.isNotEmpty)
          .toSet()
          .toList(),
      createdAt: DateTime.parse(data['created_at'] as String),
      hasCurrentLanguage: localized != null,
    );
  }

  Map<String, dynamic>? _localizedRow(
    Map<String, dynamic> data,
    String locale,
  ) {
    for (final row in _reconstructionRows(data)) {
      if (row['locale'] == locale) return row;
    }
    return null;
  }

  List<Map<String, dynamic>> _reconstructionRows(Map<String, dynamic> data) {
    final rows = data['real_life_reconstructions'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String _metaText(Map<String, dynamic> row, String key) {
    final meta = row['model_meta'];
    if (meta is Map && meta[key] is String) return meta[key] as String;
    return 'stored';
  }
}
