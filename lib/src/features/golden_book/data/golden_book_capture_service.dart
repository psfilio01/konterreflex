import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_repository.dart';
import 'package:konterreflex/src/features/golden_book/domain/golden_book_entry.dart';

class GoldenBookCaptureService {
  GoldenBookCaptureService(
      {required AiGateway ai, required GoldenBookRepository repository})
      : _ai = ai,
        _repository = repository;

  final AiGateway _ai;
  final GoldenBookRepository _repository;

  Future<GoldenBookCaptureResult> resolveCommand({
    required String command,
    required Map<String, dynamic> conversationContext,
    String? sourceSessionId,
  }) async {
    final result = await _ai.invoke(task: 'golden_book.extract', payload: {
      'spoken_command': command,
      'conversation_context': conversationContext,
    });
    final extraction = GoldenBookExtraction.fromGateway(
      data: result.data,
      provider: result.provider,
      model: result.model,
      promptVersion: result.promptVersion,
    );
    if (extraction.status == GoldenBookExtractionStatus.needsClarification) {
      return GoldenBookCaptureResult(
          clarificationQuestion: extraction.clarificationQuestion);
    }
    final entry = await _repository.save(
      phrase: extraction.phrase,
      category: extraction.category,
      note: extraction.sourceReference,
      sourceSessionId: sourceSessionId,
      modelMeta: {
        'provider': extraction.provider,
        'model': extraction.model,
        'prompt_version': extraction.promptVersion,
      },
    );
    return GoldenBookCaptureResult(entry: entry);
  }

  Future<GoldenBookEntry> saveDirect(String phrase,
          {String? sourceSessionId}) =>
      _repository.save(
          phrase: phrase,
          category: 'Persönlicher Favorit',
          sourceSessionId: sourceSessionId);
}
