/// Caps automatic AI/network retries so a failure cannot loop forever.
class AiRetryPolicy {
  static const maxAttempts = 2;

  static Future<T> run<T>(Future<T> Function() action) async {
    Object? last;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        last = error;
        if (attempt >= maxAttempts) rethrow;
      }
    }
    throw last!;
  }
}
