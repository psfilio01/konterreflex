import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/history/application/history_providers.dart';
import 'package:konterreflex/src/features/history/domain/history_item.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Verlauf')),
        body: ref.watch(historyItemsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Dein Verlauf konnte nicht geladen werden.')),
              data: (items) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const Text(
                      'Hier siehst du nur notwendige Sitzungsdaten. Gesprochene Rohaufnahmen werden standardmäßig nicht dauerhaft gespeichert.'),
                  const SizedBox(height: AppSpacing.lg),
                  if (items.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Text('Noch keine Einträge.',
                            textAlign: TextAlign.center)),
                  for (final item in items)
                    Card(
                      child: ListTile(
                        leading: Icon(item.kind == HistoryItemKind.realLifeCase
                            ? Icons.replay_rounded
                            : Icons.forum_outlined),
                        title: Text(item.title),
                        subtitle: Text(
                            '${MaterialLocalizations.of(context).formatMediumDate(item.createdAt.toLocal())}${item.completedAt == null ? ' · nicht abgeschlossen' : ''}'),
                        trailing: IconButton(
                            tooltip: 'Eintrag löschen',
                            onPressed: () => _delete(context, ref, item),
                            icon: const Icon(Icons.delete_outline_rounded)),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                      onPressed: () => context.pushNamed(AppRoute.goldenBook),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: const Text(
                          'Golden Book verwalten und Einträge löschen')),
                ],
              ),
            ),
      );

  Future<void> _delete(
      BuildContext context, WidgetRef ref, HistoryItem item) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Eintrag löschen?'),
              content: Text(item.kind == HistoryItemKind.realLifeCase
                  ? 'Die echte Situation und zugehörige Wiederholungen werden dauerhaft gelöscht.'
                  : 'Die Sitzung, Antworten und das zugehörige Feedback werden dauerhaft gelöscht.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Löschen'))
              ],
            ));
    if (confirmed != true) return;
    final repository = ref.read(historyRepositoryProvider);
    if (item.kind == HistoryItemKind.realLifeCase) {
      await repository.deleteRealLifeCase(item.id);
    } else {
      await repository.deleteSession(item.id);
    }
    ref.invalidate(historyItemsProvider);
  }
}
