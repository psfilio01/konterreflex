import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_capture_service.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_repository.dart';
import 'package:konterreflex/src/features/golden_book/domain/golden_book_entry.dart';

final goldenBookRepositoryProvider = Provider<GoldenBookRepository>(
  (ref) => SupabaseGoldenBookRepository(ref.watch(supabaseClientProvider)),
);

final goldenBookCaptureProvider = Provider<GoldenBookCaptureService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GoldenBookCaptureService(
    ai: SupabaseAiGateway(
      client,
      language: ref.watch(appLanguageProvider),
    ),
    repository: ref.watch(goldenBookRepositoryProvider),
    directSaveCategory: ref.watch(appLocalizationsProvider).personalFavorite,
  );
});

final goldenBookEntriesProvider = FutureProvider<List<GoldenBookEntry>>(
  (ref) => ref.watch(goldenBookRepositoryProvider).fetchEntries(),
);
