import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/analytics/privacy_analytics.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

final privacyAnalyticsProvider = Provider<PrivacyAnalytics>(
  (ref) => SupabasePrivacyAnalytics(ref.watch(supabaseClientProvider)),
);
