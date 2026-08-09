import 'package:konterreflex/src/admin/knowledge/domain/knowledge_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class KnowledgeRepository {
  Future<List<KnowledgeEntry>> fetchAll();
  Future<void> saveVersion({
    KnowledgeEntry? previous,
    required String source,
    required String author,
    required String concept,
    required String intendedUse,
    required KnowledgeEvidenceStatus evidenceStatus,
    required String limitations,
  });
  Future<void> archive(String id);
}

class SupabaseKnowledgeRepository implements KnowledgeRepository {
  SupabaseKnowledgeRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<List<KnowledgeEntry>> fetchAll() async {
    final data = await _client
        .from('communication_knowledge')
        .select()
        .order('created_at', ascending: false);
    return data.map(KnowledgeEntry.fromJson).toList();
  }

  @override
  Future<void> saveVersion(
      {KnowledgeEntry? previous,
      required String source,
      required String author,
      required String concept,
      required String intendedUse,
      required KnowledgeEvidenceStatus evidenceStatus,
      required String limitations}) async {
    await _client.rpc('admin_create_knowledge_version', params: {
      'p_previous_id': previous?.id,
      'p_source': source,
      'p_author': author,
      'p_concept': concept,
      'p_intended_use': intendedUse,
      'p_evidence_status': evidenceStatus.databaseValue,
      'p_limitations': limitations,
    });
  }

  @override
  Future<void> archive(String id) async {
    await _client
        .from('communication_knowledge')
        .update({'active': false}).eq('id', id);
  }
}
