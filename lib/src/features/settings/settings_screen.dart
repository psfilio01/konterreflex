import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/localization/localization_providers.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deletePermanently),
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
      SnackBar(content: Text(l10n.deleteAccountError)),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    await ref
        .read(authActionControllerProvider.notifier)
        .updateAppLanguage(language);
    if (!context.mounted) return;
    if (ref.read(authActionControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.languageSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final action = ref.watch(authActionControllerProvider);
    final language = ref.watch(appLanguageProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(l10n.appLanguageTitle),
            subtitle: Text(l10n.appLanguageSubtitle),
            trailing: DropdownButton<AppLanguage>(
              value: language,
              onChanged: action.isLoading
                  ? null
                  : (value) {
                      if (value != null && value != language) {
                        _changeLanguage(context, ref, value);
                      }
                    },
              items: [
                DropdownMenuItem(
                  value: AppLanguage.german,
                  child: Text(l10n.languageGerman),
                ),
                DropdownMenuItem(
                  value: AppLanguage.english,
                  child: Text(l10n.languageEnglish),
                ),
              ],
            ),
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l10n.privacyStorageTitle),
            subtitle: Text(l10n.privacyStorageSubtitle),
            onTap: () => context.pushNamed(AppRoute.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(l10n.historyDeleteTitle),
            onTap: () => context.pushNamed(AppRoute.history),
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.subscriptionAccessTitle),
            subtitle: Text(l10n.subscriptionAccessSubtitle),
            onTap: () => context.pushNamed(AppRoute.subscription),
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            enabled: !action.isLoading,
            onTap: () =>
                ref.read(authActionControllerProvider.notifier).signOut(),
          ),
          const Divider(height: 40),
          Text(l10n.accountSection,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(l10n.deleteAccountTitle),
            subtitle: Text(l10n.deleteAccountSubtitle),
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
