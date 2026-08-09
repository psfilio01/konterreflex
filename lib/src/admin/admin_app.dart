import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/admin/scenarios/application/admin_scenario_providers.dart';
import 'package:konterreflex/src/admin/scenarios/presentation/admin_scenario_studio.dart';
import 'package:konterreflex/src/core/theme/app_theme.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/presentation/sign_in_screen.dart';

class KonterreflexAdminApp extends StatelessWidget {
  const KonterreflexAdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Konterreflex Szenario-Studio',
        theme: AppTheme.light(),
        home: const AdminGate(),
      );
}

class AdminGate extends ConsumerWidget {
  const AdminGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SignInScreen(),
      data: (user) {
        if (user == null) return const SignInScreen();
        return ref.watch(adminAccessProvider).when(
              loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator())),
              error: (_, __) => const _AccessDenied(),
              data: (allowed) =>
                  allowed ? const AdminScenarioStudio() : const _AccessDenied(),
            );
      },
    );
  }
}

class _AccessDenied extends ConsumerWidget {
  const _AccessDenied();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 56),
              const SizedBox(height: 16),
              Text('Kein Admin-Zugriff',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                  'Dieses Szenario-Studio ist nur für freigeschaltete Admin-Konten verfügbar.'),
              const SizedBox(height: 20),
              OutlinedButton(
                  onPressed: () =>
                      ref.read(authActionControllerProvider.notifier).signOut(),
                  child: const Text('Abmelden')),
            ],
          ),
        ),
      );
}
