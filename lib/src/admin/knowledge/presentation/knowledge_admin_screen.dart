import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/admin/knowledge/application/knowledge_providers.dart';
import 'package:konterreflex/src/admin/knowledge/domain/knowledge_entry.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';

class KnowledgeAdminScreen extends ConsumerWidget {
  const KnowledgeAdminScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(knowledgeEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kommunikationswissen'), actions: [
        IconButton(
            tooltip: 'Neuer Eintrag',
            onPressed: () => _edit(context, ref, null),
            icon: const Icon(Icons.add_rounded)),
      ]),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Die Wissensbasis konnte nicht geladen werden.')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text(
                'Quellen, Evidenzstatus und Grenzen bleiben explizit. Änderungen erzeugen eine neue, nachvollziehbare Version.'),
            const SizedBox(height: AppSpacing.lg),
            for (final entry in items)
              Card(
                child: ExpansionTile(
                  enabled: entry.active,
                  title: Text(entry.concept),
                  subtitle: Text(
                      '${entry.author} · ${entry.evidenceStatus.label} · Version ${entry.version}${entry.active ? '' : ' · archiviert'}'),
                  childrenPadding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _Fact(label: 'Quelle', value: entry.source),
                    _Fact(
                        label: 'Vorgesehene Nutzung', value: entry.intendedUse),
                    _Fact(label: 'Grenzen', value: entry.limitations),
                    if (entry.evidenceStatus ==
                        KnowledgeEvidenceStatus.historical)
                      const _Fact(
                          label: 'Hinweis',
                          value:
                              'Historische Theorie ist kein moderner empirischer Konsens.'),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton(
                          onPressed: () => _edit(context, ref, entry),
                          child: const Text('Neue Version erstellen')),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                          onPressed: () async {
                            await ref
                                .read(knowledgeRepositoryProvider)
                                .archive(entry.id);
                            ref.invalidate(knowledgeEntriesProvider);
                          },
                          child: const Text('Archivieren')),
                    ]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, KnowledgeEntry? previous) async {
    final source = TextEditingController(text: previous?.source);
    final author = TextEditingController(text: previous?.author);
    final concept = TextEditingController(text: previous?.concept);
    final use = TextEditingController(text: previous?.intendedUse);
    final limits = TextEditingController(text: previous?.limitations);
    var evidence =
        previous?.evidenceStatus ?? KnowledgeEvidenceStatus.empiricalSupported;
    final saved = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: Text(previous == null
                      ? 'Wissenseintrag anlegen'
                      : 'Neue Wissensversion'),
                  content: SizedBox(
                      width: 620,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: source,
                            decoration: const InputDecoration(
                                labelText:
                                    'Quelle · Titel, Publikation oder URL')),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                            controller: author,
                            decoration:
                                const InputDecoration(labelText: 'Autor:in')),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                            controller: concept,
                            decoration:
                                const InputDecoration(labelText: 'Konzept')),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                            controller: use,
                            maxLines: 2,
                            decoration: const InputDecoration(
                                labelText: 'Vorgesehene Nutzung')),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField(
                            value: evidence,
                            decoration: const InputDecoration(
                                labelText: 'Evidenzstatus'),
                            items: [
                              for (final value
                                  in KnowledgeEvidenceStatus.values)
                                DropdownMenuItem(
                                    value: value, child: Text(value.label))
                            ],
                            onChanged: (value) =>
                                setState(() => evidence = value!)),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                            controller: limits,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Grenzen und Unsicherheit')),
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Abbrechen')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Version speichern'))
                  ],
                )));
    if (saved != true) return;
    if ([source, author, concept, use, limits]
        .any((controller) => controller.text.trim().isEmpty)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Alle Wissensfelder sind erforderlich.')));
      }
      return;
    }
    await ref.read(knowledgeRepositoryProvider).saveVersion(
        previous: previous,
        source: source.text.trim(),
        author: author.text.trim(),
        concept: concept.text.trim(),
        intendedUse: use.text.trim(),
        evidenceStatus: evidence,
        limitations: limits.text.trim());
    ref.invalidate(knowledgeEntriesProvider);
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(value)
                ])),
      );
}
