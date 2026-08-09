import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/admin/knowledge/data/knowledge_repository.dart';
import 'package:konterreflex/src/admin/knowledge/domain/knowledge_entry.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>(
  (ref) => SupabaseKnowledgeRepository(ref.watch(supabaseClientProvider)),
);
final knowledgeEntriesProvider = FutureProvider<List<KnowledgeEntry>>(
  (ref) => ref.watch(knowledgeRepositoryProvider).fetchAll(),
);
