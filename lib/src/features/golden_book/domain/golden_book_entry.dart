class GoldenBookEntry {
  const GoldenBookEntry({
    required this.id,
    required this.phrase,
    required this.createdAt,
    this.category,
    this.note,
    this.sourceSessionId,
  });

  factory GoldenBookEntry.fromJson(Map<String, dynamic> json) =>
      GoldenBookEntry(
        id: json['id'] as String,
        phrase: json['phrase'] as String,
        category: json['category'] as String?,
        note: json['note'] as String?,
        sourceSessionId: json['source_session_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String phrase;
  final String? category;
  final String? note;
  final String? sourceSessionId;
  final DateTime createdAt;
}

enum GoldenBookExtractionStatus { extracted, needsClarification }

class GoldenBookExtraction {
  const GoldenBookExtraction({
    required this.status,
    required this.phrase,
    required this.category,
    required this.sourceReference,
    required this.clarificationQuestion,
    required this.provider,
    required this.model,
    required this.promptVersion,
  });

  factory GoldenBookExtraction.fromGateway({
    required Map<String, dynamic> data,
    required String provider,
    required String model,
    required String promptVersion,
  }) {
    const expected = {
      'status',
      'phrase',
      'category',
      'source_reference',
      'clarification_question'
    };
    if (data.keys.toSet().length != expected.length ||
        !data.keys.toSet().containsAll(expected)) {
      throw const FormatException('Unsupported Golden Book extraction fields.');
    }
    String text(String key) {
      final value = data[key];
      if (value is! String) throw FormatException('$key must be text.');
      return value.trim();
    }

    final rawStatus = text('status');
    final status = switch (rawStatus) {
      'extracted' => GoldenBookExtractionStatus.extracted,
      'needs_clarification' => GoldenBookExtractionStatus.needsClarification,
      _ => throw const FormatException('Unsupported extraction status.'),
    };
    final phrase = text('phrase');
    final clarification = text('clarification_question');
    if (status == GoldenBookExtractionStatus.extracted && phrase.isEmpty) {
      throw const FormatException('An extracted phrase cannot be empty.');
    }
    if (status == GoldenBookExtractionStatus.needsClarification &&
        clarification.isEmpty) {
      throw const FormatException('A clarification question is required.');
    }
    return GoldenBookExtraction(
      status: status,
      phrase: phrase,
      category: text('category'),
      sourceReference: text('source_reference'),
      clarificationQuestion: clarification,
      provider: provider,
      model: model,
      promptVersion: promptVersion,
    );
  }

  final GoldenBookExtractionStatus status;
  final String phrase;
  final String category;
  final String sourceReference;
  final String clarificationQuestion;
  final String provider;
  final String model;
  final String promptVersion;
}

class GoldenBookCaptureResult {
  const GoldenBookCaptureResult({this.entry, this.clarificationQuestion});
  final GoldenBookEntry? entry;
  final String? clarificationQuestion;
  bool get saved => entry != null;
}
