import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/billing/billing.dart';

void main() {
  test('only server entitlement data grants premium access', () {
    expect(
        const Entitlement(tier: 'free', source: 'default').isPremium, isFalse);
    expect(const Entitlement(tier: 'pro', source: 'stripe').isPremium, isTrue);
    expect(const Entitlement(tier: 'admin', source: 'role').isPremium, isTrue);
  });

  test('Stripe adapter opens only the server-created HTTPS checkout URL',
      () async {
    final backend = _Backend();
    Uri? opened;
    final provider = StripeBillingProvider(
      backend: backend,
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );
    await provider.startPurchase();
    expect(backend.checkoutCalls, 1);
    expect(opened, Uri.parse('https://checkout.stripe.test/session'));
  });

  test(
      'store adapter remains independent of Stripe and can refresh without a configured SDK',
      () async {
    final provider = StoreBillingProvider();
    expect(provider.canPurchase, isFalse);
    await provider.restore();
    expect(provider.startPurchase, throwsStateError);
  });
}

class _Backend implements BillingBackend {
  int checkoutCalls = 0;
  @override
  Future<String> createCheckout() async {
    checkoutCalls += 1;
    return 'https://checkout.stripe.test/session';
  }

  @override
  Future<String> createPortal() async => 'https://billing.stripe.test/portal';
}
