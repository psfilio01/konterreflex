import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konto endgültig löschen?'),
        content: const Text(
          'Dein Profil und alle persönlichen Trainingsdaten werden dauerhaft gelöscht. Das lässt sich nicht rückgängig machen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authActionControllerProvider.notifier).deleteAccount();
    if (!context.mounted || !ref.read(authActionControllerProvider).hasError) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Das Konto konnte nicht gelöscht werden.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(authActionControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Datenschutz & Speicherung'),
            subtitle: const Text('Aufbewahrung und Produktanalyse steuern'),
            onTap: () => context.pushNamed(AppRoute.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Verlauf und Daten löschen'),
            onTap: () => context.pushNamed(AppRoute.history),
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Abo und Zugriff'),
            subtitle:
                const Text('Status prüfen, wiederherstellen oder verwalten'),
            onTap: () => context.pushNamed(AppRoute.subscription),
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Abmelden'),
            enabled: !action.isLoading,
            onTap: () =>
                ref.read(authActionControllerProvider.notifier).signOut(),
          ),
          const Divider(height: 40),
          Text('Konto', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Konto und Daten löschen'),
            subtitle: const Text('Dauerhaft und nicht rückgängig zu machen'),
            enabled: !action.isLoading,
            onTap: () => _confirmDeletion(context, ref),
          ),
          if (action.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
