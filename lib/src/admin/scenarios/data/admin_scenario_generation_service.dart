import 'package:konterreflex/src/admin/scenarios/data/admin_scenario_repository.dart';
import 'package:konterreflex/src/admin/scenarios/domain/admin_scenario.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';

class AdminScenarioGenerationService {
  AdminScenarioGenerationService(
      {required AiGateway ai,
      required AdminScenarioRepository repository,
      String Function()? createBatchId})
      : _ai = ai,
        _repository = repository,
        _createBatchId = createBatchId ??
            (() => DateTime.now().microsecondsSinceEpoch.toString());
  final AiGateway _ai;
  final AdminScenarioRepository _repository;
  final String Function() _createBatchId;

  Future<List<String>> generateDrafts(
      {required String request, required int count}) async {
    if (count < 1 || count > 50) {
      throw RangeError('Batch size must be between 1 and 50.');
    }
    final batchId = _createBatchId();
    final ids = <String>[];
    for (var offset = 0; offset < count; offset += 5) {
      final size = count - offset < 5 ? count - offset : 5;
      final results = await Future.wait([
        for (var index = 0; index < size; index++)
          _ai.invoke(task: 'scenario.generate', payload: {
            'request': request,
            'batch': {
              'id': batchId,
              'sequence': offset + index + 1,
              'total': count
            },
            'required_status': 'draft',
          }),
      ]);
      for (final result in results) {
        ids.add(await _repository
            .saveDraft(AdminScenario.fromGateway(result.data)));
      }
    }
    await _repository.audit(
        action: 'generate_batch',
        scenarioIds: ids,
        batchId: batchId,
        detail: {'requested_count': count, 'request': request});
    return ids;
  }
}
