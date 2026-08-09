import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/settings/data/privacy_preferences_repository.dart';

final privacyPreferencesRepositoryProvider =
    Provider<PrivacyPreferencesRepository>(
  (ref) =>
      SupabasePrivacyPreferencesRepository(ref.watch(supabaseClientProvider)),
);
final privacyPreferencesProvider = FutureProvider<PrivacyPreferences>(
  (ref) => ref.watch(privacyPreferencesRepositoryProvider).fetch(),
);
