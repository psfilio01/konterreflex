import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/features/settings/application/privacy_preferences_providers.dart';
import 'package:konterreflex/src/features/settings/data/privacy_preferences_repository.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyStorageTitle)),
      body: ref.watch(privacyPreferencesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.privacyLoadError)),
            data: (preferences) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(l10n.voiceRecordingsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.voiceRecordingsBody),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<int>(
                  value: preferences.recordingRetentionDays,
                  decoration:
                      InputDecoration(labelText: l10n.recordingRetentionLabel),
                  items: [
                    DropdownMenuItem(value: 0, child: Text(l10n.neverStore)),
                    DropdownMenuItem(value: 7, child: Text(l10n.dayCount(7))),
                    DropdownMenuItem(value: 30, child: Text(l10n.dayCount(30))),
                    DropdownMenuItem(value: 90, child: Text(l10n.dayCount(90))),
                  ],
                  onChanged: (days) => _save(
                      ref,
                      PrivacyPreferences(
                          recordingRetentionDays: days ?? 0,
                          analyticsEnabled: preferences.analyticsEnabled)),
                ),
                const SizedBox(height: AppSpacing.xl),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.analyticsTitle),
                  subtitle: Text(l10n.analyticsBody),
                  value: preferences.analyticsEnabled,
                  onChanged: (enabled) => _save(
                      ref,
                      PrivacyPreferences(
                          recordingRetentionDays:
                              preferences.recordingRetentionDays,
                          analyticsEnabled: enabled)),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _save(WidgetRef ref, PrivacyPreferences value) async {
    await ref.read(privacyPreferencesRepositoryProvider).save(value);
    ref.invalidate(privacyPreferencesProvider);
  }
}
