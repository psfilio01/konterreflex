import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/history/data/history_repository.dart';
import 'package:konterreflex/src/features/history/domain/history_item.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => SupabaseHistoryRepository(
    ref.watch(supabaseClientProvider),
    strings: ref.watch(appLocalizationsProvider),
  ),
);
final historyItemsProvider = FutureProvider<List<HistoryItem>>(
  (ref) => ref.watch(historyRepositoryProvider).fetch(),
);
