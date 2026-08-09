import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/billing/billing.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>(
  (ref) => SupabaseEntitlementRepository(ref.watch(supabaseClientProvider)),
);

final entitlementProvider = FutureProvider<Entitlement>(
  (ref) => ref.watch(entitlementRepositoryProvider).fetch(),
);

final billingChannelProvider = FutureProvider<BillingChannel>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('app_config')
      .select('value')
      .eq('key', 'billing_channels')
      .single();
  return BillingChannelConfig.fromJson(
          Map<String, dynamic>.from(data['value'] as Map))
      .forCurrentPlatform();
});

final billingProviderProvider = FutureProvider<BillingProvider>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final channel = await ref.watch(billingChannelProvider.future);
  return BillingProviderRegistry(
    stripe: StripeBillingProvider(backend: SupabaseBillingBackend(client)),
    store: StoreBillingProvider(),
  ).forChannel(channel);
});

final billingActionProvider =
    NotifierProvider<BillingActionController, AsyncValue<void>>(
        BillingActionController.new);

class BillingActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> purchase() => _run((provider) => provider.startPurchase());
  Future<void> manage() => _run((provider) => provider.openManagement());
  Future<void> restore() => _run((provider) => provider.restore());
  Future<void> refresh() async {
    ref.invalidate(entitlementProvider);
    await ref.read(entitlementProvider.future);
  }

  Future<void> _run(
      Future<void> Function(BillingProvider provider) action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final provider = await ref.read(billingProviderProvider.future);
      await action(provider);
      ref.invalidate(entitlementProvider);
    });
  }
}
