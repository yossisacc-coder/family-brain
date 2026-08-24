import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

class BrainDraft {
  const BrainDraft({
    required this.kind,
    required this.title,
    required this.originalText,
    this.dueDate,
    this.hasDueTime = false,
    this.reminderAt,
    this.assigneeId,
    this.assigneeName,
    this.listItems = const [],
    this.lowConfidence = false,
  });

  final InformationKind kind;
  final String title;
  final String originalText;
  final DateTime? dueDate;
  final bool hasDueTime;
  final DateTime? reminderAt;
  final String? assigneeId;
  final String? assigneeName;
  final List<String> listItems;
  final bool lowConfidence;

  String get notes {
    if (listItems.isEmpty) return originalText;
    return listItems.join('\n');
  }

  BrainDraft copyWith({
    InformationKind? kind,
    String? title,
    DateTime? dueDate,
    bool? hasDueTime,
    bool clearDueDate = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    String? assigneeId,
    String? assigneeName,
    bool clearAssignee = false,
    List<String>? listItems,
    bool? lowConfidence,
  }) {
    return BrainDraft(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      originalText: originalText,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      hasDueTime: clearDueDate ? false : (hasDueTime ?? this.hasDueTime),
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      assigneeName: clearAssignee ? null : (assigneeName ?? this.assigneeName),
      listItems: listItems ?? this.listItems,
      lowConfidence: lowConfidence ?? this.lowConfidence,
    );
  }

  TaskItem toTaskItem({
    required String id,
    required String familyId,
    required String creatorId,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    DateTime? reminder = reminderAt;
    if (kind == InformationKind.reminder && reminder == null) {
      reminder = dueDate ?? stamp.add(const Duration(hours: 1));
    }
    return TaskItem(
      id: id,
      familyId: familyId,
      creatorId: creatorId,
      title: title.trim().isEmpty ? originalText.trim() : title.trim(),
      kind: kind,
      type: TaskType.family,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: stamp,
      updatedAt: stamp,
      assigneeId: assigneeId,
      dueDate: dueDate,
      hasDueTime: hasDueTime,
      notes: notes,
      reminderAt: reminder,
    );
  }
}

class BrainParseResult {
  const BrainParseResult.ok(this.draft) : error = null;
  const BrainParseResult.error(this.error) : draft = null;

  final BrainDraft? draft;
  final String? error;

  bool get isOk => draft != null;
}

/// On-device Family Brain parser. No network / LLM.
class FamilyBrainParser {
  static const emptyInput = 'empty';
  static const unclearInput = 'unclear';

  static BrainParseResult parse(
    String raw, {
    required DateTime now,
    List<AppUser> members = const [],
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const BrainParseResult.error(emptyInput);
    }
    if (text.length < 2) {
      return const BrainParseResult.error(unclearInput);
    }

    final lower = text.toLowerCase();
    final person = _matchPerson(text, members);
    final when = _extractWhen(text, now);
    final items = _extractListItems(text);
    final kind = _kind(lower, items: items, hasTime: when.hasTime, hasDate: when.date != null);

    var title = _titleFor(kind, text, items);
    if (title.isEmpty) {
      return const BrainParseResult.error(unclearInput);
    }

    DateTime? reminder;
    if (kind == InformationKind.reminder) {
      reminder = when.date ?? now.add(const Duration(hours: 1));
    }

    return BrainParseResult.ok(
      BrainDraft(
        kind: kind,
        title: title,
        originalText: text,
        dueDate: when.date,
        hasDueTime: when.hasTime,
        reminderAt: reminder,
        assigneeId: person?.id,
        assigneeName: person?.name,
        listItems: kind == InformationKind.list ? items : const [],
        lowConfidence: kind == InformationKind.task &&
            when.date == null &&
            items.length < 2 &&
            !_hasActionVerb(lower),
      ),
    );
  }

  static InformationKind _kind(
    String lower, {
    required List<String> items,
    required bool hasTime,
    required bool hasDate,
  }) {
    final listCue = RegExp(
      r'\b(buy|get|pick up|need|shopping|list|grocer|קנו|לקנות|רשימה|קניות)\b',
      unicode: true,
    ).hasMatch(lower);
    if (items.length >= 3 || (listCue && items.length >= 2)) {
      return InformationKind.list;
    }

    final remindCue = RegExp(
      r'\b(remind|reminder|don.?t forget|תזכיר|תזכורת|לא לשכוח)\b',
      unicode: true,
    ).hasMatch(lower);
    if (remindCue) return InformationKind.reminder;

    final eventCue = RegExp(
      r'\b(doctor|appointment|meeting|birthday|party|event|calendar|'
      r'רופא|תור|פגישה|יום הולדת|אירוע)\b',
      unicode: true,
    ).hasMatch(lower);
    if (eventCue || (hasDate && hasTime)) return InformationKind.event;

    return InformationKind.task;
  }

  static bool _hasActionVerb(String lower) {
    return RegExp(
      r'\b(take|call|finish|clean|pay|send|book|pick|make|do|'
      r'קח|התקשר|גמור|נקה|שלם)\b',
      unicode: true,
    ).hasMatch(lower);
  }

  static String _titleFor(
    InformationKind kind,
    String text,
    List<String> items,
  ) {
    if (kind == InformationKind.list) {
      if (items.isNotEmpty) {
        return items.length <= 3
            ? items.join(', ')
            : 'Shopping list';
      }
      return 'List';
    }
    var cleaned = text;
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(tomorrow|today|tonight|yesterday|מחרתיים|מחר|היום|הערב)\b',
        caseSensitive: false,
        unicode: true,
      ),
      ' ',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(at|@|בשעה|ב־|ב-)\s*\d{1,2}(:\d{2})?\s*(a\.?m\.?|p\.?m\.?)?',
        caseSensitive: false,
        unicode: true,
      ),
      ' ',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{1,2}:\d{2}\b'),
      ' ',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(remind me to|remind me|reminder to|don.?t forget to|please)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[,.\-:;]+'), '').trim();
    if (cleaned.isEmpty) return text.trim();
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static AppUser? _matchPerson(String text, List<AppUser> members) {
    final lower = text.toLowerCase();
    for (final member in members) {
      final parts = member.name
          .split(RegExp(r'\s+'))
          .where((part) => part.length > 1)
          .toList();
      for (final part in parts) {
        if (lower.contains(part.toLowerCase())) return member;
      }
      if (lower.contains(member.name.toLowerCase())) return member;
    }
    return null;
  }

  static List<String> _extractListItems(String text) {
    var working = text.trim();
    working = working.replaceFirst(
      RegExp(
        r'^(buy|get|pick up|need|we need|shopping list:?|list:?|קנו|לקנות)\s+',
        caseSensitive: false,
        unicode: true,
      ),
      '',
    );
    if (!working.contains(',') &&
        !working.contains(' and ') &&
        !working.contains(' ו') &&
        !working.contains(' ו־')) {
      return const [];
    }
    working = working.replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ',');
    working = working.replaceAll(RegExp(r'\s+ו־?\s+', unicode: true), ',');
    return working
        .split(',')
        .map((item) => item.trim().replaceAll(RegExp(r'[.!?]+$'), ''))
        .where((item) => item.length > 1)
        .toList();
  }

  static ({DateTime? date, bool hasTime}) _extractWhen(String text, DateTime now) {
    final lower = text.toLowerCase();
    DateTime day = DateTime(now.year, now.month, now.day);
    var hasDate = false;

    if (RegExp(r'\b(today|tonight|היום|הערב)\b', unicode: true).hasMatch(lower)) {
      hasDate = true;
    } else if (RegExp(r'\b(tomorrow|מחר)\b', unicode: true).hasMatch(lower) &&
        !lower.contains('מחרתיים')) {
      day = day.add(const Duration(days: 1));
      hasDate = true;
    } else if (RegExp(r'\bמחרתיים\b', unicode: true).hasMatch(lower)) {
      day = day.add(const Duration(days: 2));
      hasDate = true;
    }

    final time = _extractTime(lower);
    if (time == null) {
      return (date: hasDate ? day : null, hasTime: false);
    }
    final dated = DateTime(day.year, day.month, day.day, time.$1, time.$2);
    return (date: dated, hasTime: true);
  }

  static (int, int)? _extractTime(String lower) {
    final hm = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(lower);
    if (hm != null) {
      return (int.parse(hm.group(1)!), int.parse(hm.group(2)!));
    }
    final ampm = RegExp(r'\b(\d{1,2})\s*(a\.?m\.?|p\.?m\.?)\b').firstMatch(lower);
    if (ampm != null) {
      var hour = int.parse(ampm.group(1)!);
      final mer = ampm.group(2)!.toLowerCase();
      if (mer.startsWith('p') && hour < 12) hour += 12;
      if (mer.startsWith('a') && hour == 12) hour = 0;
      return (hour, 0);
    }
    return null;
  }
}
