import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/billing/billing_providers.dart';

class PremiumEntitlementGate extends ConsumerWidget {
  const PremiumEntitlementGate(
      {required this.child, required this.locked, super.key});
  final Widget child;
  final Widget locked;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(entitlementProvider).when(
            data: (entitlement) => entitlement.isPremium ? child : locked,
            error: (_, __) => locked,
            loading: () => const Center(child: CircularProgressIndicator()),
          );
}
