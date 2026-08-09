import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Entitlement {
  const Entitlement(
      {required this.tier, required this.source, this.validUntil});
  factory Entitlement.fromJson(Map<String, dynamic> json) => Entitlement(
        tier: json['tier'] as String,
        source: json['source'] as String,
        validUntil: json['valid_until'] == null
            ? null
            : DateTime.parse(json['valid_until'] as String),
      );
  final String tier;
  final String source;
  final DateTime? validUntil;
  bool get isPremium => tier == 'pro' || tier == 'admin';
}

abstract interface class EntitlementRepository {
  Future<Entitlement> fetch();
}

class SupabaseEntitlementRepository implements EntitlementRepository {
  SupabaseEntitlementRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<Entitlement> fetch() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Authentication required.');
    final data = await _client
        .from('entitlements')
        .select('tier,source,valid_until')
        .eq('user_id', userId)
        .single();
    return Entitlement.fromJson(data);
  }
}

enum BillingChannel { stripe, store }

class BillingChannelConfig {
  const BillingChannelConfig(this.values);
  factory BillingChannelConfig.fromJson(Map<String, dynamic> json) =>
      BillingChannelConfig(
        json.map((key, value) => MapEntry(key,
            value == 'stripe' ? BillingChannel.stripe : BillingChannel.store)),
      );
  final Map<String, BillingChannel> values;
  BillingChannel forCurrentPlatform() {
    final key = kIsWeb
        ? 'web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.iOS => 'ios',
            TargetPlatform.android => 'android',
            _ => 'other',
          };
    return values[key] ?? BillingChannel.store;
  }
}

abstract interface class BillingProvider {
  bool get canPurchase;
  bool get canManage;
  Future<void> startPurchase();
  Future<void> openManagement();
  Future<void> restore();
}

abstract interface class BillingBackend {
  Future<String> createCheckout();
  Future<String> createPortal();
}

class SupabaseBillingBackend implements BillingBackend {
  SupabaseBillingBackend(this._client);
  final SupabaseClient _client;
  @override
  Future<String> createCheckout() => _sessionUrl('create-checkout-session');
  @override
  Future<String> createPortal() => _sessionUrl('create-customer-portal');
  Future<String> _sessionUrl(String function) async {
    final response = await _client.functions.invoke(function);
    if (response.status < 200 ||
        response.status >= 300 ||
        response.data is! Map ||
        response.data['url'] is! String) {
      throw StateError('Billing session could not be created.');
    }
    return response.data['url'] as String;
  }
}

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class StripeBillingProvider implements BillingProvider {
  StripeBillingProvider(
      {required BillingBackend backend, ExternalUrlLauncher? launch})
      : _backend = backend,
        _launch = launch ??
            ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));
  final BillingBackend _backend;
  final ExternalUrlLauncher _launch;
  @override
  bool get canPurchase => true;
  @override
  bool get canManage => true;
  @override
  Future<void> startPurchase() => _open(_backend.createCheckout);
  @override
  Future<void> openManagement() => _open(_backend.createPortal);
  @override
  Future<void> restore() async {}
  Future<void> _open(Future<String> Function() create) async {
    final uri = Uri.parse(await create());
    if (uri.scheme != 'https' || !await _launch(uri)) {
      throw StateError('Billing page could not be opened.');
    }
  }
}

abstract interface class StorePurchaseAdapter {
  Future<void> purchasePro();
  Future<void> restorePurchases();
  Future<void> openSubscriptionManagement();
}

class StoreBillingProvider implements BillingProvider {
  StoreBillingProvider([this._adapter]);
  final StorePurchaseAdapter? _adapter;
  @override
  bool get canPurchase => _adapter != null;
  @override
  bool get canManage => _adapter != null;
  @override
  Future<void> startPurchase() => _required.purchasePro();
  @override
  Future<void> openManagement() => _required.openSubscriptionManagement();
  @override
  Future<void> restore() => _adapter?.restorePurchases() ?? Future.value();
  StorePurchaseAdapter get _required =>
      _adapter ??
      (throw StateError('Store billing is not configured for this build.'));
}

class BillingProviderRegistry {
  const BillingProviderRegistry({required this.stripe, required this.store});
  final BillingProvider stripe;
  final BillingProvider store;
  BillingProvider forChannel(BillingChannel channel) =>
      channel == BillingChannel.stripe ? stripe : store;
}
