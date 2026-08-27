/// Civil (calendar) date/time helpers.
///
/// [DateTime.tryParse] treats `YYYY-MM-DD` as UTC, which shifts the calendar
/// day in local timezones. Family Brain always stores the user's intended
/// local calendar date and clock time.
class CivilDateTime {
  static DateTime? combine(dynamic date, dynamic time, DateTime now) {
    final day = parseDate(date) ?? DateTime(now.year, now.month, now.day);
    final clock = parseTime(time);
    if (clock != null) {
      return DateTime(day.year, day.month, day.day, clock.$1, clock.$2);
    }
    if (parseDate(date) == null) return null;
    return DateTime(day.year, day.month, day.day);
  }

  /// Reads a `YYYY-MM-DD` prefix as a local calendar date. Ignores any
  /// timezone suffix so `2026-08-25T00:00:00.000Z` stays 25 Aug locally.
  static DateTime? parseDate(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  static (int, int)? parseTime(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?').firstMatch(text);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  static String dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String? timeOnly(DateTime? value) {
    if (value == null) return null;
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String localStamp(DateTime now) {
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${dateOnly(now)} ${timeOnly(now)} $sign$hours:$minutes';
  }
}
