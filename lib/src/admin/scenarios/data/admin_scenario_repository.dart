import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AdminScenarioRepository {
  Future<List<AdminScenario>> fetchAll();
  Future<String> saveDraft(AdminScenario scenario);
  Future<void> review(List<String> ids, AdminScenarioStatus status,
      {String? reason, String? batchId});
  Future<void> audit(
      {required String action,
      required List<String> scenarioIds,
      String? batchId,
      Map<String, dynamic> detail = const {}});
}

class SupabaseAdminScenarioRepository implements AdminScenarioRepository {
  SupabaseAdminScenarioRepository(this._client);
  final SupabaseClient _client;
  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw const AuthException('Authentication required.'));

  static const selection =
      'id,title,category,moderator_intro,trigger_statement,underlying_intent,evaluation_focus,status,source,scenario_characters(id,name,description,voice_id,sort_order),scenario_turns(character_id,body,stage_direction,sort_order)';

  @override
  Future<List<AdminScenario>> fetchAll() async {
    final data = await _client
        .from('scenarios')
        .select(selection)
        .order('updated_at', ascending: false);
    return data.map(AdminScenario.fromJson).toList();
  }

  @override
  Future<String> saveDraft(AdminScenario scenario) async {
    final payload = {
      'title': scenario.title.trim(),
      'category': scenario.category.trim(),
      'moderator_intro': scenario.moderatorIntro.trim(),
      'trigger_statement': scenario.triggerStatement.trim(),
      'underlying_intent': scenario.underlyingIntent.trim(),
      'evaluation_focus': scenario.evaluationFocus,
      'status': 'draft',
      'source': scenario.source,
      'created_by': _userId,
    };
    final Map<String, dynamic> saved;
    if (scenario.id == null) {
      saved =
          await _client.from('scenarios').insert(payload).select('id').single();
    } else {
      saved = await _client
          .from('scenarios')
          .update(payload)
          .eq('id', scenario.id!)
          .select('id')
          .single();
      await _client
          .from('scenario_turns')
          .delete()
          .eq('scenario_id', scenario.id!);
      await _client
          .from('scenario_characters')
          .delete()
          .eq('scenario_id', scenario.id!);
    }
    final id = saved['id'] as String;
    final actorIds = <String, String>{};
    for (var index = 0; index < scenario.characters.length; index++) {
      final actor = scenario.characters[index];
      final row = await _client
          .from('scenario_characters')
          .insert({
            'scenario_id': id,
            'name': actor.name.trim(),
            'description': actor.description.trim(),
            'voice_id': actor.voiceId,
            'sort_order': index,
          })
          .select('id')
          .single();
      actorIds[actor.name] = row['id'] as String;
    }
    if (scenario.turns.isNotEmpty) {
      await _client.from('scenario_turns').insert([
        for (var index = 0; index < scenario.turns.length; index++)
          {
            'scenario_id': id,
            'character_id': actorIds[scenario.turns[index].characterName],
            'body': scenario.turns[index].body.trim(),
            'stage_direction': scenario.turns[index].stageDirection.trim(),
            'sort_order': index,
          }
      ]);
    }
    await audit(
        action: scenario.id == null ? 'create_draft' : 'edit_to_draft',
        scenarioIds: [id]);
    return id;
  }

  @override
  Future<void> review(List<String> ids, AdminScenarioStatus status,
      {String? reason, String? batchId}) async {
    if (ids.isEmpty || status == AdminScenarioStatus.draft) return;
    await _client
        .from('scenarios')
        .update({'status': status.name}).inFilter('id', ids);
    await audit(
        action: status.name,
        scenarioIds: ids,
        batchId: batchId,
        detail: {if (reason != null) 'reason': reason});
  }

  @override
  Future<void> audit(
      {required String action,
      required List<String> scenarioIds,
      String? batchId,
      Map<String, dynamic> detail = const {}}) async {
    await _client.from('admin_scenario_audit').insert({
      'actor_id': _userId,
      'action': action,
      'scenario_ids': scenarioIds,
      if (batchId != null) 'batch_id': batchId,
      'detail': detail,
    });
  }
}
