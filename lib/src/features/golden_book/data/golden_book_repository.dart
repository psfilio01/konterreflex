import 'package:konterreflex/src/features/golden_book/domain/golden_book_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class GoldenBookRepository {
  Future<List<GoldenBookEntry>> fetchEntries();
  Future<GoldenBookEntry> save({
    required String phrase,
    String? category,
    String? note,
    String? sourceSessionId,
    Map<String, dynamic> modelMeta = const {},
  });
  Future<void> delete(String id);
}

class SupabaseGoldenBookRepository implements GoldenBookRepository {
  SupabaseGoldenBookRepository(this._client);
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required.');
    return id;
  }

  @override
  Future<List<GoldenBookEntry>> fetchEntries() async {
    final data = await _client
        .from('golden_book_entries')
        .select()
        .order('created_at', ascending: false);
    return data.map(GoldenBookEntry.fromJson).toList();
  }

  @override
  Future<GoldenBookEntry> save(
      {required String phrase,
      String? category,
      String? note,
      String? sourceSessionId,
      Map<String, dynamic> modelMeta = const {}}) async {
    final trimmed = phrase.trim();
    if (trimmed.isEmpty) throw const FormatException('Phrase cannot be empty.');
    final data = await _client
        .from('golden_book_entries')
        .upsert({
          'user_id': _userId,
          'phrase': trimmed,
          'category': _nullIfEmpty(category),
          'note': _nullIfEmpty(note),
          'source_session_id': sourceSessionId,
          'model_meta': modelMeta,
        }, onConflict: 'user_id,normalized_phrase')
        .select()
        .single();
    return GoldenBookEntry.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _client
        .from('golden_book_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}

String? _nullIfEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
