class BrainActivityEntry {
  const BrainActivityEntry({
    required this.originalText,
    required this.summary,
    required this.createdAt,
  });

  final String originalText;
  final String summary;
  final DateTime createdAt;
}

/// In-memory recent understanding history (not a chat log).
class BrainActivityLog {
  static final List<BrainActivityEntry> entries = [];

  static void record(String originalText, List<String> kinds) {
    final summary = kinds.isEmpty
        ? 'Saved'
        : kinds.length == 1
            ? '${kinds.first} created'
            : '${kinds.length} items: ${kinds.join(', ')}';
    entries.insert(
      0,
      BrainActivityEntry(
        originalText: originalText,
        summary: summary,
        createdAt: DateTime.now(),
      ),
    );
    if (entries.length > 8) {
      entries.removeRange(8, entries.length);
    }
  }
}
