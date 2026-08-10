import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/billing/billing_providers.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    final provider = ref.watch(billingProviderProvider);
    final action = ref.watch(billingActionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.subscriptionAccessTitle)),
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
                              : context.l10n.freeAccess,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(value.isPremium
                          ? context.l10n.premiumConfirmed
                          : context.l10n.freeAccessBody),
                      if (value.validUntil != null)
                        Text(context.l10n.currentPeriodUntil(
                          MaterialLocalizations.of(context)
                              .formatCompactDate(value.validUntil!.toLocal()),
                        )),
                    ]),
              ),
            ),
            error: (_, __) => Text(context.l10n.accessLoadError),
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
                      child: Text(context.l10n.unlockPro)),
                if (billing.canManage)
                  OutlinedButton(
                      onPressed: action.isLoading
                          ? null
                          : () =>
                              ref.read(billingActionProvider.notifier).manage(),
                      child: Text(context.l10n.manageSubscription)),
                OutlinedButton.icon(
                    onPressed: action.isLoading
                        ? null
                        : () =>
                            ref.read(billingActionProvider.notifier).restore(),
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(context.l10n.restorePurchases)),
                TextButton(
                    onPressed: action.isLoading
                        ? null
                        : () =>
                            ref.read(billingActionProvider.notifier).refresh(),
                    child: Text(context.l10n.refreshAccess)),
              ],
            ),
            error: (_, __) => Text(context.l10n.billingChannelMissing),
            loading: () => const LinearProgressIndicator(),
          ),
          if (action.hasError)
            Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(context.l10n.billingError)),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.billingDisclaimer),
        ],
      ),
    );
  }
}
