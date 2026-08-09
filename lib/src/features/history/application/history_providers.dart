import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/history/data/history_repository.dart';
import 'package:konterreflex/src/features/history/domain/history_item.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => SupabaseHistoryRepository(ref.watch(supabaseClientProvider)),
);
final historyItemsProvider = FutureProvider<List<HistoryItem>>(
  (ref) => ref.watch(historyRepositoryProvider).fetch(),
);
