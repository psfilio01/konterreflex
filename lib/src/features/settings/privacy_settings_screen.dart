import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/settings/application/privacy_preferences_providers.dart';
import 'package:konterreflex/src/features/settings/data/privacy_preferences_repository.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Datenschutz & Speicherung')),
        body: ref.watch(privacyPreferencesProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text(
                      'Datenschutzeinstellungen konnten nicht geladen werden.')),
              data: (preferences) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text('Sprachaufnahmen',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                      'Standardmäßig wird Audio nur zur Transkription verarbeitet und nicht dauerhaft gespeichert.'),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    value: preferences.recordingRetentionDays,
                    decoration: const InputDecoration(
                        labelText:
                            'Aufbewahrung für künftige optionale Aufnahmen'),
                    items: const [
                      DropdownMenuItem(
                          value: 0, child: Text('Nie dauerhaft speichern')),
                      DropdownMenuItem(value: 7, child: Text('7 Tage')),
                      DropdownMenuItem(value: 30, child: Text('30 Tage')),
                      DropdownMenuItem(value: 90, child: Text('90 Tage')),
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
                    title: const Text('Datensparsame Produktanalyse erlauben'),
                    subtitle: const Text(
                        'Nur feste Funnel- und Feature-Ereignisse. Keine Transkripte, Audiodaten oder Formulierungen.'),
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

  Future<void> _save(WidgetRef ref, PrivacyPreferences value) async {
    await ref.read(privacyPreferencesRepositoryProvider).save(value);
    ref.invalidate(privacyPreferencesProvider);
  }
}
