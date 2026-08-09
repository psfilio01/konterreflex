import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/ai/ai_gateway.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_capture_service.dart';
import 'package:konterreflex/src/features/golden_book/data/golden_book_repository.dart';
import 'package:konterreflex/src/features/golden_book/domain/golden_book_entry.dart';

void main() {
  test(
      'voice reference saves the exact resolved phrase with its source session',
      () async {
    final repository = _Repository();
    final service =
        GoldenBookCaptureService(ai: _Ai(extracted), repository: repository);

    final result = await service.resolveCommand(
      command: 'Speicher den Satz.',
      conversationContext: {
        'feedback_alternatives': ['Ich beende den Gedanken kurz.']
      },
      sourceSessionId: 'session-1',
    );

    expect(result.entry?.phrase, 'Ich beende den Gedanken kurz.');
    expect(repository.sourceSessionId, 'session-1');
  });

  test('ambiguous reference asks instead of saving a guessed phrase', () async {
    final repository = _Repository();
    final service =
        GoldenBookCaptureService(ai: _Ai(ambiguous), repository: repository);

    final result = await service.resolveCommand(
      command: 'Speicher das.',
      conversationContext: {
        'feedback_alternatives': ['Eins', 'Zwei']
      },
    );

    expect(result.saved, isFalse);
    expect(result.clarificationQuestion, 'Welchen der beiden Sätze meinst du?');
    expect(repository.saved, isFalse);
  });
}

const extracted = {
  'status': 'extracted',
  'phrase': 'Ich beende den Gedanken kurz.',
  'category': 'Grenzen',
  'source_reference': 'Feedback-Alternative',
  'clarification_question': '',
};
const ambiguous = {
  'status': 'needs_clarification',
  'phrase': '',
  'category': '',
  'source_reference': '',
  'clarification_question': 'Welchen der beiden Sätze meinst du?',
};

class _Ai implements AiGateway {
  _Ai(this.data);
  final Map<String, dynamic> data;
  @override
  Future<AiGatewayResult> invoke(
          {required String task,
          required Map<String, dynamic> payload}) async =>
      AiGatewayResult(
          data: data,
          provider: 'mock',
          model: 'mock',
          promptVersion: 'golden_book_extract_v1');
}

class _Repository implements GoldenBookRepository {
  bool saved = false;
  String? sourceSessionId;
  @override
  Future<List<GoldenBookEntry>> fetchEntries() async => [];
  @override
  Future<GoldenBookEntry> save(
      {required String phrase,
      String? category,
      String? note,
      String? sourceSessionId,
      Map<String, dynamic> modelMeta = const {}}) async {
    saved = true;
    this.sourceSessionId = sourceSessionId;
    return GoldenBookEntry(
        id: 'entry-1',
        phrase: phrase,
        category: category,
        note: note,
        sourceSessionId: sourceSessionId,
        createdAt: DateTime(2026));
  }

  @override
  Future<void> delete(String id) async {}
}
