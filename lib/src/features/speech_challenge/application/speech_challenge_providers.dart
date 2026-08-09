import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/data/speech_challenge_repository.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';

final speechChallengeRepositoryProvider = Provider<SpeechChallengeRepository>(
  (ref) => SupabaseSpeechChallengeRepository(ref.watch(supabaseClientProvider)),
);

final challengeSetsProvider = FutureProvider<List<ChallengeSet>>(
  (ref) => ref.watch(speechChallengeRepositoryProvider).fetchActiveSets(),
);
