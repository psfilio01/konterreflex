enum HistoryItemKind { session, realLifeCase }

class HistoryItem {
  const HistoryItem(
      {required this.id,
      required this.kind,
      required this.title,
      required this.createdAt,
      this.completedAt});
  final String id;
  final HistoryItemKind kind;
  final String title;
  final DateTime createdAt;
  final DateTime? completedAt;
}
