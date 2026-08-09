import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/billing/billing_providers.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    final provider = ref.watch(billingProviderProvider);
    final action = ref.watch(billingActionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Abo und Zugriff')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          entitlement.when(
            data: (value) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          value.isPremium
                              ? 'Konterreflex Pro'
                              : 'Kostenloser Zugriff',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(value.isPremium
                          ? 'Dein Pro-Zugriff ist serverseitig bestätigt.'
                          : 'Freie Nutzung und Grenzen werden serverseitig konfiguriert.'),
                      if (value.validUntil != null)
                        Text(
                            'Aktueller Zeitraum bis ${MaterialLocalizations.of(context).formatCompactDate(value.validUntil!.toLocal())}'),
                    ]),
              ),
            ),
            error: (_, __) =>
                const Text('Der Zugriff konnte nicht geladen werden.'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: AppSpacing.lg),
          provider.when(
            data: (billing) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (billing.canPurchase)
                  FilledButton(
                      onPressed: action.isLoading
                          ? null
                          : () => ref
                              .read(billingActionProvider.notifier)
                              .purchase(),
                      child: const Text('Pro freischalten')),
                if (billing.canManage)
                  OutlinedButton(
                      onPressed: action.isLoading
                          ? null
                          : () =>
                              ref.read(billingActionProvider.notifier).manage(),
                      child: const Text('Abo verwalten')),
                OutlinedButton.icon(
                    onPressed: action.isLoading
                        ? null
                        : () =>
                            ref.read(billingActionProvider.notifier).restore(),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Käufe wiederherstellen')),
                TextButton(
                    onPressed: action.isLoading
                        ? null
                        : () =>
                            ref.read(billingActionProvider.notifier).refresh(),
                    child: const Text('Zugriff aktualisieren')),
              ],
            ),
            error: (_, __) => const Text(
                'Für diese Plattform ist noch kein Kaufkanal eingerichtet. Du kannst deinen Zugriff trotzdem aktualisieren.'),
            loading: () => const LinearProgressIndicator(),
          ),
          if (action.hasError)
            const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                    'Die Abrechnung konnte nicht abgeschlossen werden. Es wurde kein Zugriff lokal freigeschaltet.')),
          const SizedBox(height: AppSpacing.lg),
          const Text(
              'Der verfügbare Kaufweg hängt von Plattform, Region und Store-Regeln ab. Ein erfolgreicher Bezahlbildschirm allein schaltet keine Funktionen frei.'),
        ],
      ),
    );
  }
}
