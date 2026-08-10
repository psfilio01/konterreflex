import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/history/application/history_providers.dart';
import 'package:konterreflex/src/features/history/domain/history_item.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.historyTitle)),
        body: ref.watch(historyItemsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(context.l10n.historyLoadError)),
              data: (items) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(context.l10n.historyPrivacyBody),
                  const SizedBox(height: AppSpacing.lg),
                  if (items.isEmpty)
                    Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(context.l10n.noHistoryEntries,
                            textAlign: TextAlign.center)),
                  for (final item in items)
                    Card(
                      child: ListTile(
                        leading: Icon(item.kind == HistoryItemKind.realLifeCase
                            ? Icons.replay_rounded
                            : Icons.forum_outlined),
                        title: Text(item.title),
                        subtitle: Text(
                            '${MaterialLocalizations.of(context).formatMediumDate(item.createdAt.toLocal())}${item.completedAt == null ? context.l10n.notCompletedSuffix : ''}'),
                        trailing: IconButton(
                            tooltip: context.l10n.deleteEntry,
                            onPressed: () => _delete(context, ref, item),
                            icon: const Icon(Icons.delete_outline_rounded)),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                      onPressed: () => context.pushNamed(AppRoute.goldenBook),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: Text(context.l10n.manageGoldenBook)),
                ],
              ),
            ),
      );

  Future<void> _delete(
      BuildContext context, WidgetRef ref, HistoryItem item) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(context.l10n.deleteEntryDialogTitle),
              content: Text(item.kind == HistoryItemKind.realLifeCase
                  ? context.l10n.deleteRealLifeHistoryBody
                  : context.l10n.deleteSessionHistoryBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.cancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.delete))
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
