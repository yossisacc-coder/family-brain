/// End-of-speech patience for Family Brain voice input.
///
/// These values are passed to the existing speech_to_text engine. They do not
/// replace or rewrite the recognizer. Short pauses must not cut the user off.
class VoiceListenPatience {
  const VoiceListenPatience._();

  /// Silence allowed before the engine may treat speech as finished.
  /// Previously 2 seconds, which interrupted natural conversation.
  static const pauseFor = Duration(seconds: 6);

  /// Maximum continuous listen session. Previously 8 seconds.
  static const listenFor = Duration(seconds: 90);

  /// App-level silence timeout; matches [pauseFor] so a short pause is ignored.
  static const silenceTimeout = Duration(seconds: 6);

  /// Session watchdog; matches [listenFor].
  static const watchdog = Duration(seconds: 90);

  /// Sound level that counts as continued speech and resets silence patience.
  /// speech_to_text reports roughly 0–10 on Android; 0.4 still catches quiet speech.
  static const speakingLevel = 0.4;
}
