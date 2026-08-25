/// Picks a speech-to-text locale from what the device actually supports.
class SpeechLocalePicker {
  static const hebrewCandidates = [
    'he_IL',
    'he-IL',
    'iw_IL',
    'iw-IL',
    'he',
    'iw',
  ];

  static const englishCandidates = [
    'en_US',
    'en-US',
    'en_GB',
    'en-GB',
    'en_IN',
    'en-IN',
    'en',
  ];

  static String? resolve({
    required String appLanguageCode,
    required Iterable<String> availableIds,
  }) {
    final available = [
      for (final id in availableIds)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (appLanguageCode == 'he') {
      return _firstMatch(hebrewCandidates, available) ??
          _firstWhereLang(available, const ['he', 'iw']);
    }
    return _firstMatch(englishCandidates, available) ??
        _firstWhereLang(available, const ['en']);
  }

  static bool isHebrewId(String id) {
    final lower = id.toLowerCase().replaceAll('-', '_');
    return lower.startsWith('he') || lower.startsWith('iw');
  }

  static String? _firstMatch(List<String> preferred, List<String> available) {
    for (final want in preferred) {
      for (final have in available) {
        if (_norm(have) == _norm(want)) return have;
      }
    }
    return null;
  }

  static String? _firstWhereLang(List<String> available, List<String> prefixes) {
    for (final have in available) {
      final lower = _norm(have);
      if (prefixes.any((p) => lower == p || lower.startsWith('${p}_'))) {
        return have;
      }
    }
    return null;
  }

  static String _norm(String id) =>
      id.toLowerCase().replaceAll('-', '_').trim();
}
