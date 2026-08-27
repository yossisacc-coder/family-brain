/// Speech locales for Family Brain.
///
/// Do not gate listening on [SpeechToText.locales]. On Android 13+ (Samsung
/// included) that API often queries on-device support only, can omit Hebrew,
/// can hang, and can block [listen] entirely. The working recognizer path is
/// initialize → listen. Hebrew is requested by passing locale IDs; if the
/// engine rejects them, listen again with the device default.
class SpeechLocalePicker {
  const SpeechLocalePicker._();

  static const hebrewIds = ['he_IL', 'he-IL', 'iw_IL', 'iw-IL', 'he', 'iw'];
  static const englishIds = ['en_US', 'en-US', 'en_GB', 'en-GB', 'en'];

  /// Locales to try for [listen], then `null` for the device default.
  ///
  /// Hebrew does not require the app or system UI to be switched to English.
  static List<String?> listenAttempts(String appLanguageCode) {
    if (appLanguageCode.toLowerCase() == 'he') {
      return const ['he_IL', 'iw_IL', 'he', null];
    }
    return const [null];
  }

  static String? resolve({
    required String appLanguageCode,
    required Iterable<String> availableIds,
  }) {
    final available = availableIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (available.isEmpty) return null;

    final preferred = appLanguageCode.toLowerCase() == 'he'
        ? hebrewIds
        : englishIds;

    for (final candidate in preferred) {
      for (final id in available) {
        if (_norm(id) == _norm(candidate)) return id;
      }
    }

    final prefixes = appLanguageCode.toLowerCase() == 'he'
        ? const ['he', 'iw']
        : const ['en'];
    for (final id in available) {
      final lower = _norm(id);
      if (prefixes.any((p) => lower == p || lower.startsWith('${p}_'))) {
        return id;
      }
    }
    return null;
  }

  static bool canListenWithoutPreferredLocale() => true;

  static bool isHebrewId(String id) {
    final lower = _norm(id);
    return lower.startsWith('he') || lower.startsWith('iw');
  }

  static bool isLanguageError(String errorMsg) {
    final msg = errorMsg.toLowerCase();
    return msg.contains('language') ||
        msg.contains('error_client') ||
        msg.contains('error_busy');
  }

  static String _norm(String id) =>
      id.toLowerCase().replaceAll('-', '_').trim();
}
