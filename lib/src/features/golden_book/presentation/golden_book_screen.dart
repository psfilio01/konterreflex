import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/golden_book/application/golden_book_providers.dart';
import 'package:konterreflex/src/features/golden_book/domain/golden_book_entry.dart';

class GoldenBookScreen extends ConsumerStatefulWidget {
  const GoldenBookScreen({super.key});

  @override
  ConsumerState<GoldenBookScreen> createState() => _GoldenBookScreenState();
}

class _GoldenBookScreenState extends ConsumerState<GoldenBookScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(goldenBookEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Golden Book')),
      body: SafeArea(
        child: entries.when(
          data: (all) {
            final categories = all
                .map((entry) => entry.category)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();
            final query = _query.toLowerCase().trim();
            final visible = all.where((entry) {
              final matchesCategory =
                  _category == null || entry.category == _category;
              final haystack =
                  '${entry.phrase} ${entry.category ?? ''} ${entry.note ?? ''}'
                      .toLowerCase();
              return matchesCategory &&
                  (query.isEmpty || haystack.contains(query));
            }).toList();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText: 'Formulierungen durchsuchen'),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      FilterChip(
                          label: const Text('Alle'),
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null)),
                      for (final category in categories)
                        FilterChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                        'Noch keine passenden Formulierungen. Speichere Favoriten direkt aus deinem Training.',
                        textAlign: TextAlign.center),
                  ),
                for (final entry in visible) _EntryCard(entry: entry),
              ],
            );
          },
          error: (_, __) => const Center(
              child: Text('Dein Golden Book konnte nicht geladen werden.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});
  final GoldenBookEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('„${entry.phrase}“',
                        style: Theme.of(context).textTheme.titleMedium),
                    if (entry.category != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(entry.category!,
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                    if (entry.sourceSessionId != null)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xs),
                        child: Text('Aus einer Trainingseinheit',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eintrag löschen',
                onPressed: () async {
                  await ref.read(goldenBookRepositoryProvider).delete(entry.id);
                  ref.invalidate(goldenBookEntriesProvider);
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      );
}
