enum KnowledgeEvidenceStatus {
  empiricalSupported,
  mixed,
  practiceBased,
  historical,
  speculative
}

extension KnowledgeEvidenceStatusValue on KnowledgeEvidenceStatus {
  String get databaseValue => switch (this) {
        KnowledgeEvidenceStatus.empiricalSupported => 'empirical_supported',
        KnowledgeEvidenceStatus.mixed => 'mixed',
        KnowledgeEvidenceStatus.practiceBased => 'practice_based',
        KnowledgeEvidenceStatus.historical => 'historical',
        KnowledgeEvidenceStatus.speculative => 'speculative',
      };
  String get label => switch (this) {
        KnowledgeEvidenceStatus.empiricalSupported => 'Empirisch gestützt',
        KnowledgeEvidenceStatus.mixed => 'Gemischte Evidenz',
        KnowledgeEvidenceStatus.practiceBased => 'Praxisbasiert',
        KnowledgeEvidenceStatus.historical => 'Historische Theorie',
        KnowledgeEvidenceStatus.speculative => 'Spekulativ',
      };
}

class KnowledgeEntry {
  const KnowledgeEntry({
    required this.id,
    required this.logicalId,
    required this.version,
    required this.source,
    required this.author,
    required this.concept,
    required this.intendedUse,
    required this.evidenceStatus,
    required this.limitations,
    required this.active,
  });
  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) => KnowledgeEntry(
        id: json['id'] as String,
        logicalId: json['logical_id'] as String,
        version: json['version'] as int,
        source: json['source'] as String,
        author: json['author'] as String,
        concept: json['concept'] as String,
        intendedUse: json['intended_use'] as String,
        evidenceStatus: KnowledgeEvidenceStatus.values.firstWhere(
            (value) => value.databaseValue == json['evidence_status']),
        limitations: json['limitations'] as String,
        active: json['active'] as bool,
      );
  final String id;
  final String logicalId;
  final int version;
  final String source;
  final String author;
  final String concept;
  final String intendedUse;
  final KnowledgeEvidenceStatus evidenceStatus;
  final String limitations;
  final bool active;
}
