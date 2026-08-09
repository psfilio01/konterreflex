import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/admin/scenarios/application/admin_scenario_providers.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:konterreflex/src/core/audio/just_audio_playback_queue.dart';
import 'package:konterreflex/src/core/audio/supabase_speech_gateway.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

class AdminScenarioStudio extends ConsumerStatefulWidget {
  const AdminScenarioStudio({super.key});
  @override
  ConsumerState<AdminScenarioStudio> createState() =>
      _AdminScenarioStudioState();
}

class _AdminScenarioStudioState extends ConsumerState<AdminScenarioStudio> {
  AdminScenarioStatus? _status = AdminScenarioStatus.draft;
  String? _category;
  String _query = '';
  final _selected = <String>{};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final scenarios = ref.watch(adminScenariosProvider);
    final voiceOptions = ref.watch(actorVoiceOptionsProvider).valueOrNull ??
        const <ActorVoiceOption>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konterreflex · Szenario-Studio'),
        actions: [
          IconButton(
              tooltip: 'Aktualisieren',
              onPressed: () => ref.invalidate(adminScenariosProvider),
              icon: const Icon(Icons.refresh_rounded)),
          IconButton(
              tooltip: 'Abmelden',
              onPressed: () =>
                  ref.read(authActionControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: scenarios.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Admin-Daten konnten nicht geladen werden.')),
        data: (all) {
          final categories =
              all.map((scenario) => scenario.category).toSet().toList()..sort();
          final query = _query.toLowerCase().trim();
          final visible = all.where((scenario) {
            return (_status == null || scenario.status == _status) &&
                (_category == null || scenario.category == _category) &&
                (query.isEmpty ||
                    '${scenario.title} ${scenario.triggerStatement}'
                        .toLowerCase()
                        .contains(query));
          }).toList();
          return Column(
            children: [
              _Toolbar(
                status: _status,
                category: _category,
                categories: categories,
                selectedCount: _selected.length,
                busy: _busy,
                onStatus: (value) => setState(() => _status = value),
                onCategory: (value) => setState(() => _category = value),
                onQuery: (value) => setState(() => _query = value),
                onCreate: () => _edit(null, voiceOptions),
                onGenerate: _generate,
                onReview: _review,
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child:
                            Text('Keine Szenarien in dieser Review-Ansicht.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final scenario = visible[index];
                          return _ScenarioReviewCard(
                            scenario: scenario,
                            selected: scenario.id != null &&
                                _selected.contains(scenario.id),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _selected.add(scenario.id!);
                              } else {
                                _selected.remove(scenario.id);
                              }
                            }),
                            onEdit: () => _edit(scenario, voiceOptions),
                            onPreview: () => _preview(scenario),
                            onReview: (status) =>
                                _review(status, ids: [scenario.id!]),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
      AdminScenario? scenario, List<ActorVoiceOption> voices) async {
    final result = await showDialog<AdminScenario>(
        context: context,
        builder: (_) =>
            _ScenarioEditorDialog(scenario: scenario, voices: voices));
    if (result == null) return;
    await _run(() async {
      await ref.read(adminScenarioRepositoryProvider).saveDraft(result);
      ref.invalidate(adminScenariosProvider);
    });
  }

  Future<void> _generate() async {
    final request = TextEditingController();
    final count = TextEditingController(text: '10');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entwürfe als Batch erzeugen'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: request,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Thematische Anforderung',
                      hintText: 'z. B. schwierige Rückfragen in Teamrunden')),
              const SizedBox(height: AppSpacing.md),
              TextField(
                  controller: count,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Anzahl · 1 bis 50')),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                  'Alle Ergebnisse landen ausschließlich als Entwurf in der Review-Warteschlange.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Entwürfe erzeugen')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = int.tryParse(count.text) ?? 0;
    if (request.text.trim().isEmpty || amount < 1 || amount > 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Bitte Anforderung und eine Anzahl zwischen 1 und 50 angeben.')));
      }
      return;
    }
    await _run(() async {
      await ref
          .read(adminScenarioGenerationProvider)
          .generateDrafts(request: request.text.trim(), count: amount);
      _status = AdminScenarioStatus.draft;
      ref.invalidate(adminScenariosProvider);
    });
  }

  Future<void> _review(AdminScenarioStatus status, {List<String>? ids}) async {
    final targets = ids ?? _selected.toList();
    if (targets.isEmpty) return;
    await _run(() async {
      await ref.read(adminScenarioRepositoryProvider).review(targets, status);
      _selected.removeAll(targets);
      ref.invalidate(adminScenariosProvider);
    });
  }

  Future<void> _preview(AdminScenario scenario) async {
    await _run(() async {
      final queue = JustAudioPlaybackQueue();
      final speech = SupabaseSpeechGateway(ref.read(supabaseClientProvider));
      try {
        for (final line in scenario.toTrainingScenario().speechLines) {
          await queue.enqueue(await speech.synthesize(line));
        }
        await queue.playAll();
      } finally {
        await queue.dispose();
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Die Admin-Aktion konnte nicht abgeschlossen werden.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar(
      {required this.status,
      required this.category,
      required this.categories,
      required this.selectedCount,
      required this.busy,
      required this.onStatus,
      required this.onCategory,
      required this.onQuery,
      required this.onCreate,
      required this.onGenerate,
      required this.onReview});
  final AdminScenarioStatus? status;
  final String? category;
  final List<String> categories;
  final int selectedCount;
  final bool busy;
  final ValueChanged<AdminScenarioStatus?> onStatus;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String> onQuery;
  final VoidCallback onCreate;
  final VoidCallback onGenerate;
  final ValueChanged<AdminScenarioStatus> onReview;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                  width: 240,
                  child: TextField(
                      onChanged: onQuery,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          labelText: 'Review durchsuchen'))),
              DropdownButton<AdminScenarioStatus?>(
                  value: status,
                  hint: const Text('Alle Status'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Alle Status')),
                    for (final value in AdminScenarioStatus.values)
                      DropdownMenuItem(
                          value: value, child: Text(_statusLabel(value)))
                  ],
                  onChanged: onStatus),
              DropdownButton<String?>(
                  value: category,
                  hint: const Text('Alle Kategorien'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Alle Kategorien')),
                    for (final value in categories)
                      DropdownMenuItem(value: value, child: Text(value))
                  ],
                  onChanged: onCategory),
              FilledButton.icon(
                  onPressed: busy ? null : onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Neu')),
              OutlinedButton.icon(
                  onPressed: busy ? null : onGenerate,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('KI-Batch')),
              if (selectedCount > 0) ...[
                Text('$selectedCount gewählt'),
                TextButton(
                    onPressed: () => onReview(AdminScenarioStatus.active),
                    child: const Text('Freigeben')),
                TextButton(
                    onPressed: () => onReview(AdminScenarioStatus.rejected),
                    child: const Text('Ablehnen')),
                TextButton(
                    onPressed: () => onReview(AdminScenarioStatus.archived),
                    child: const Text('Archivieren')),
              ],
              if (busy)
                const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      );
}

class _ScenarioReviewCard extends StatelessWidget {
  const _ScenarioReviewCard(
      {required this.scenario,
      required this.selected,
      required this.onSelected,
      required this.onEdit,
      required this.onPreview,
      required this.onReview});
  final AdminScenario scenario;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final ValueChanged<AdminScenarioStatus> onReview;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ExpansionTile(
          leading: Checkbox(
              value: selected,
              onChanged: (value) => onSelected(value ?? false)),
          title: Text(scenario.title),
          subtitle: Text(
              '${scenario.category} · ${_statusLabel(scenario.status)} · ${scenario.source}'),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(scenario.moderatorIntro)),
            const SizedBox(height: AppSpacing.sm),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Impuls: ${scenario.triggerStatement}',
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.sm),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Soziale Funktion (als Arbeitshypothese): ${scenario.underlyingIntent}')),
            const SizedBox(height: AppSpacing.md),
            for (final turn in scenario.turns)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${turn.characterName}: ${turn.body}')),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Stimmen abspielen')),
                OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Bearbeiten')),
                if (scenario.status != AdminScenarioStatus.active)
                  FilledButton(
                      onPressed: () => onReview(AdminScenarioStatus.active),
                      child: const Text('Freigeben')),
                TextButton(
                    onPressed: () => onReview(AdminScenarioStatus.rejected),
                    child: const Text('Ablehnen')),
                TextButton(
                    onPressed: () => onReview(AdminScenarioStatus.archived),
                    child: const Text('Archivieren')),
              ],
            ),
          ],
        ),
      );
}

String _statusLabel(AdminScenarioStatus status) => switch (status) {
      AdminScenarioStatus.draft => 'Entwurf',
      AdminScenarioStatus.active => 'Aktiv',
      AdminScenarioStatus.rejected => 'Abgelehnt',
      AdminScenarioStatus.archived => 'Archiviert',
    };

class _ScenarioEditorDialog extends StatefulWidget {
  const _ScenarioEditorDialog({required this.scenario, required this.voices});
  final AdminScenario? scenario;
  final List<ActorVoiceOption> voices;
  @override
  State<_ScenarioEditorDialog> createState() => _ScenarioEditorDialogState();
}

class _ScenarioEditorDialogState extends State<_ScenarioEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _intro;
  late final TextEditingController _trigger;
  late final TextEditingController _intent;
  late final TextEditingController _focus;
  late final List<_CharacterFields> _characters;
  late final List<_TurnFields> _turns;

  @override
  void initState() {
    super.initState();
    final scenario = widget.scenario;
    _title = TextEditingController(text: scenario?.title);
    _category = TextEditingController(text: scenario?.category);
    _intro = TextEditingController(text: scenario?.moderatorIntro);
    _trigger = TextEditingController(text: scenario?.triggerStatement);
    _intent = TextEditingController(text: scenario?.underlyingIntent);
    _focus = TextEditingController(text: scenario?.evaluationFocus.join(', '));
    _characters = (scenario?.characters ??
            const [AdminCharacter(name: '', description: '')])
        .map(_CharacterFields.fromCharacter)
        .toList();
    _turns = (scenario?.turns ??
            const [AdminTurn(characterName: '', body: '', stageDirection: '')])
        .map(_TurnFields.fromTurn)
        .toList();
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _category,
      _intro,
      _trigger,
      _intent,
      _focus
    ]) {
      controller.dispose();
    }
    for (final value in _characters) {
      value.dispose();
    }
    for (final value in _turns) {
      value.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 820),
          child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          widget.scenario == null
                              ? 'Szenario anlegen'
                              : 'Szenario bearbeiten',
                          style: Theme.of(context).textTheme.headlineSmall))),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _title,
                              decoration:
                                  const InputDecoration(labelText: 'Titel'))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: TextField(
                              controller: _category,
                              decoration: const InputDecoration(
                                  labelText: 'Kategorie')))
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                        controller: _intro,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Kurze Moderation')),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                        controller: _trigger,
                        decoration: const InputDecoration(
                            labelText: 'Entscheidender Satz')),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                        controller: _intent,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText:
                                'Soziale Funktion als vorsichtige Hypothese')),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                        controller: _focus,
                        decoration: const InputDecoration(
                            labelText:
                                'Qualitative Fokuspunkte · kommagetrennt')),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Figuren und Stimmen',
                        style: Theme.of(context).textTheme.titleLarge),
                    for (var index = 0; index < _characters.length; index++)
                      _characterRow(index),
                    TextButton.icon(
                        onPressed: () => setState(
                            () => _characters.add(_CharacterFields.empty())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Figur hinzufügen')),
                    const SizedBox(height: AppSpacing.md),
                    Text('Gesprochene Abfolge',
                        style: Theme.of(context).textTheme.titleLarge),
                    for (var index = 0; index < _turns.length; index++)
                      _turnRow(index),
                    TextButton.icon(
                        onPressed: () =>
                            setState(() => _turns.add(_TurnFields.empty())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Satz hinzufügen')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen')),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                      onPressed: _submit,
                      child: const Text('Als Entwurf speichern'))
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _characterRow(int index) {
    final value = _characters[index];
    final voiceIds = {
      if (value.voiceId != null) value.voiceId!,
      ...widget.voices.map((voice) => voice.id)
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(children: [
        Expanded(
            child: TextField(
                controller: value.name,
                decoration: const InputDecoration(labelText: 'Name'))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: TextField(
                controller: value.description,
                decoration: const InputDecoration(labelText: 'Rolle'))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: DropdownButtonFormField<String?>(
                value: value.voiceId,
                decoration: const InputDecoration(labelText: 'Actor Voice'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Standard')),
                  for (final id in voiceIds)
                    DropdownMenuItem(
                        value: id,
                        child: Text(widget.voices
                                .where((voice) => voice.id == id)
                                .firstOrNull
                                ?.label ??
                            id))
                ],
                onChanged: (voice) => setState(() => value.voiceId = voice))),
        IconButton(
            onPressed: _characters.length == 1
                ? null
                : () => setState(() {
                      value.dispose();
                      _characters.removeAt(index);
                    }),
            icon: const Icon(Icons.remove_circle_outline)),
      ]),
    );
  }

  Widget _turnRow(int index) {
    final value = _turns[index];
    final names = _characters
        .map((item) => item.name.text.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (!names.contains(value.characterName) && names.isNotEmpty) {
      value.characterName = names.first;
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(children: [
        SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
                value: names.contains(value.characterName)
                    ? value.characterName
                    : null,
                decoration: const InputDecoration(labelText: 'Stimme'),
                items: [
                  for (final name in names)
                    DropdownMenuItem(value: name, child: Text(name))
                ],
                onChanged: (name) =>
                    setState(() => value.characterName = name ?? ''))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: TextField(
                controller: value.body,
                decoration:
                    const InputDecoration(labelText: 'Gesprochener Satz'))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: TextField(
                controller: value.direction,
                decoration:
                    const InputDecoration(labelText: 'Regiehinweis optional'))),
        IconButton(
            onPressed: _turns.length == 1
                ? null
                : () => setState(() {
                      value.dispose();
                      _turns.removeAt(index);
                    }),
            icon: const Icon(Icons.remove_circle_outline)),
      ]),
    );
  }

  void _submit() {
    final characters = _characters
        .map((value) => AdminCharacter(
            name: value.name.text.trim(),
            description: value.description.text.trim(),
            voiceId: value.voiceId))
        .where((value) => value.name.isNotEmpty)
        .toList();
    final turns = _turns
        .map((value) => AdminTurn(
            characterName: value.characterName,
            body: value.body.text.trim(),
            stageDirection: value.direction.text.trim()))
        .where((value) => value.body.isNotEmpty)
        .toList();
    if (_title.text.trim().isEmpty ||
        _category.text.trim().isEmpty ||
        _intro.text.trim().isEmpty ||
        characters.isEmpty ||
        turns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Titel, Kategorie, Moderation, Figur und gesprochener Satz sind erforderlich.')));
      return;
    }
    Navigator.pop(
        context,
        AdminScenario(
          id: widget.scenario?.id,
          title: _title.text.trim(),
          category: _category.text.trim(),
          moderatorIntro: _intro.text.trim(),
          triggerStatement: _trigger.text.trim(),
          underlyingIntent: _intent.text.trim(),
          evaluationFocus: _focus.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
          characters: characters,
          turns: turns,
          status: AdminScenarioStatus.draft,
          source: widget.scenario?.source ?? 'manual',
        ));
  }
}

class _CharacterFields {
  _CharacterFields(this.name, this.description, this.voiceId);
  factory _CharacterFields.fromCharacter(AdminCharacter value) =>
      _CharacterFields(TextEditingController(text: value.name),
          TextEditingController(text: value.description), value.voiceId);
  factory _CharacterFields.empty() =>
      _CharacterFields(TextEditingController(), TextEditingController(), null);
  final TextEditingController name;
  final TextEditingController description;
  String? voiceId;
  void dispose() {
    name.dispose();
    description.dispose();
  }
}

class _TurnFields {
  _TurnFields(this.characterName, this.body, this.direction);
  factory _TurnFields.fromTurn(AdminTurn value) => _TurnFields(
      value.characterName,
      TextEditingController(text: value.body),
      TextEditingController(text: value.stageDirection));
  factory _TurnFields.empty() =>
      _TurnFields('', TextEditingController(), TextEditingController());
  String characterName;
  final TextEditingController body;
  final TextEditingController direction;
  void dispose() {
    body.dispose();
    direction.dispose();
  }
}
