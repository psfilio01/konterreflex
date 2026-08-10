import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/real_life/domain/real_life_case.dart';

abstract interface class RealLifeAiService {
  Future<RealLifeExtraction> extract(String transcript);

  Future<RealLifeReconstruction> reconstruct({
    required String caseId,
    required RealLifeExtraction extraction,
    bool similarVariation = false,
  });
}

class GatewayRealLifeAiService implements RealLifeAiService {
  GatewayRealLifeAiService(
    this._ai, {
    this.scenarioTitle = 'Deine echte Situation',
    this.scenarioCategory = 'Echte Situation',
  });

  final AiGateway _ai;
  final String scenarioTitle;
  final String scenarioCategory;

  @override
  Future<RealLifeExtraction> extract(String transcript) async {
    final result = await _ai.invoke(
      task: 'real_life.extract',
      payload: {'spoken_account': transcript},
    );
    return RealLifeExtraction.fromJson(result.data);
  }

  @override
  Future<RealLifeReconstruction> reconstruct({
    required String caseId,
    required RealLifeExtraction extraction,
    bool similarVariation = false,
  }) async {
    final result = await _ai.invoke(
      task: 'real_life.reconstruct',
      payload: {
        'case': extraction.toJson(),
        'variation_requested': similarVariation,
      },
    );
    return RealLifeReconstruction.fromJson(
      result.data,
      id: caseId,
      title: scenarioTitle,
      category: scenarioCategory,
    );
  }
}
