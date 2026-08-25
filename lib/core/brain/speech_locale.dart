/// Picks a speech-to-text locale that matches the in-app language.
///
/// Samsung/Google recognizers often omit `he-IL` from [SpeechToText.locales]
/// even when the engine can still transcribe Hebrew using the device default.
/// An empty or missing preferred locale must never be treated as
/// "speech recognition is unavailable".
class SpeechLocalePicker {
  const SpeechLocalePicker._();

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
        ? const ['he_IL', 'he-IL', 'iw_IL', 'iw-IL', 'he', 'iw']
        : const ['en_US', 'en-US', 'en_GB', 'en-GB', 'en'];

    for (final candidate in preferred) {
      for (final id in available) {
        if (id.toLowerCase() == candidate.toLowerCase()) return id;
      }
    }

    final prefix = appLanguageCode.toLowerCase() == 'he' ? 'he' : 'en';
    final iwPrefix = appLanguageCode.toLowerCase() == 'he';
    for (final id in available) {
      final lower = id.toLowerCase();
      if (lower.startsWith('$prefix-') ||
          lower.startsWith('${prefix}_') ||
          lower == prefix) {
        return id;
      }
      if (iwPrefix &&
          (lower.startsWith('iw-') ||
              lower.startsWith('iw_') ||
              lower == 'iw')) {
        return id;
      }
    }
    return null;
  }

  /// Hebrew (or English) can still be dictated when the preferred locale
  /// is not advertised. The OS default recognizer remains usable.
  static bool canListenWithoutPreferredLocale() => true;

  static bool isHebrewId(String id) {
    final lower = id.toLowerCase().replaceAll('-', '_');
    return lower.startsWith('he') || lower.startsWith('iw');
  }
}
