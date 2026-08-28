import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import 'ai/family_brain_context.dart';
import 'assignment_resolver.dart';
import 'priority_from_language.dart';

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
    this.imagePath,
    this.description,
    this.location,
    this.explanation,
    this.personal = false,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.pending,
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
  final String? imagePath;
  final String? description;
  final String? location;
  final String? explanation;
  final bool personal;
  final TaskPriority priority;
  final TaskStatus status;

  String get notes {
    final parts = <String>[];
    if (description != null && description!.trim().isNotEmpty) {
      parts.add(description!.trim());
    }
    if (listItems.isNotEmpty) {
      parts.add(listItems.join('\n'));
    } else if (originalText.trim().isNotEmpty && parts.isEmpty) {
      parts.add(originalText.trim());
    }
    if (location != null && location!.trim().isNotEmpty) {
      parts.add(location!.trim());
    }
    if (imagePath != null && imagePath!.isNotEmpty) {
      parts.add(imagePath!);
    }
    return parts.join('\n');
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
    String? imagePath,
    bool clearImage = false,
    String? description,
    String? location,
    String? explanation,
    bool? personal,
    TaskPriority? priority,
    TaskStatus? status,
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
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      description: description ?? this.description,
      location: location ?? this.location,
      explanation: explanation ?? this.explanation,
      personal: personal ?? this.personal,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  TaskItem toTaskItem({
    required String id,
    required String familyId,
    required String creatorId,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    return TaskItem(
      id: id,
      familyId: familyId,
      creatorId: creatorId,
      title: title.trim().isEmpty ? originalText.trim() : title.trim(),
      kind: kind,
      type: personal ? TaskType.personal : TaskType.family,
      priority: priority,
      status: status,
      createdAt: stamp,
      updatedAt: stamp,
      assigneeId: assigneeId,
      dueDate: dueDate,
      hasDueTime: hasDueTime,
      notes: notes,
      reminderAt: reminderAt,
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
  static bool _he(String text, String word) {
    return RegExp(
      '(?:^|[^\\u0590-\\u05FF])${RegExp.escape(word)}(?:\$|[^\\u0590-\\u05FF])',
      unicode: true,
    ).hasMatch(text);
  }

  static const emptyInput = 'empty';
  static const unclearInput = 'unclear';
  static const missingDateTimeKey = 'missing_date_time';

  static bool hasTemporalCue(String text) {
    if (text.trim().isEmpty) return false;
    final when = _extractWhen(text, DateTime.now());
    return when.date != null || when.hasTime;
  }

  static BrainParseResult parse(
    String raw, {
    required DateTime now,
    List<AppUser> members = const [],
    AppUser? currentUser,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const BrainParseResult.error(emptyInput);
    }
    if (text.length < 2) {
      return const BrainParseResult.error(unclearInput);
    }

    final lower = text.toLowerCase();
    final assignment = _assignment(text, members, currentUser);
    final when = _extractWhen(text, now);
    final items = _extractListItems(text);
    final kind = _kind(lower, items: items, hasTime: when.hasTime, hasDate: when.date != null);

    var title = _titleFor(kind, text, items);
    if (title.isEmpty) {
      return const BrainParseResult.error(unclearInput);
    }

    final hebrewDontForget = RegExp(r'אל תשכח', unicode: true).hasMatch(text);
    final resolvedKind = hebrewDontForget && kind == InformationKind.reminder
        ? InformationKind.task
        : kind;
    DateTime? reminder;
    if (resolvedKind == InformationKind.reminder && when.date != null) {
      reminder = when.date;
    }
    final missingWhen = (resolvedKind == InformationKind.reminder ||
            resolvedKind == InformationKind.event) &&
        when.date == null;

    return BrainParseResult.ok(
      BrainDraft(
        kind: resolvedKind,
        title: title,
        originalText: text,
        dueDate: when.date,
        hasDueTime: when.hasTime,
        reminderAt: reminder,
        assigneeId: assignment.assigneeId,
        assigneeName: assignment.assigneeName,
        listItems: kind == InformationKind.list ? items : const [],
        lowConfidence: missingWhen ||
            (kind == InformationKind.task &&
                when.date == null &&
                items.length < 2 &&
                !_hasActionVerb(lower)) ||
            assignment.ambiguous,
        explanation: missingWhen ? missingDateTimeKey : null,
        personal: assignment.personal,
        priority: PriorityFromLanguage.infer(text),
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
          r'\b(buy|get|pick up|need|shopping|list|grocer)\b',
        ).hasMatch(lower) ||
        _he(lower, 'קנו') ||
        _he(lower, 'לקנות') ||
        _he(lower, 'רשימה') ||
        _he(lower, 'קניות');
    if (items.length >= 3 || (listCue && items.length >= 2)) {
      return InformationKind.list;
    }

    final remindCue = (RegExp(
              r"\b(remind|reminder|don.?t forget|remember to)\b",
            ).hasMatch(lower) ||
            _he(lower, 'תזכיר') ||
            _he(lower, 'תזכורת')) &&
        !_he(lower, 'אל תשכח');
    if (remindCue) return InformationKind.reminder;

    final eventCue = RegExp(
          r'\b(doctor|appointment|meeting|birthday|party|event|calendar|guests)\b',
        ).hasMatch(lower) ||
        _he(lower, 'רופא') ||
        _he(lower, 'תור') ||
        _he(lower, 'פגישה') ||
        _he(lower, 'יום הולדת') ||
        _he(lower, 'אירוע') ||
        _he(lower, 'אורחים');
    final calling = RegExp(r'\bcall\b').hasMatch(lower) ||
        _he(lower, 'התקשר') ||
        _he(lower, 'להתקשר');
    if ((eventCue && !calling) || (hasDate && hasTime && eventCue && !calling)) {
      return InformationKind.event;
    }

    return InformationKind.task;
  }

  static bool _hasActionVerb(String lower) {
    return RegExp(
      r'\b(take|call|finish|clean|pay|send|book|pick|make|do|'
      r'קח|התקשר|להתקשר|גמור|נקה|שלם|תסדר|לטפל)\b',
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
        r'\b(tomorrow|today|tonight|yesterday|מחרתיים|מחר בערב|מחר בבוקר|מחר|היום|הערב|בבוקר|בערב)\b',
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
      RegExp(
        r'ב(?:שעה\s+)?(אחת|שתיים|שתים|שלוש|ארבע|חמש|שש|שבע|שמונה|תשע|עשר)',
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
        r'\b(remind me to|remind me|reminder to|don.?t forget to|please|'
        r'אל תשכח|תזכיר לי|יש לנו|זה ממש דחוף|זה דחוף|וגם צריך|צריך)\b',
        caseSensitive: false,
        unicode: true,
      ),
      ' ',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[,.\-:;]+'), '').trim();
    if (cleaned.isEmpty) return text.trim();
    if (RegExp(r'[\u0590-\u05FF]').hasMatch(cleaned[0])) return cleaned;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static AssignmentDecision _assignment(
    String text,
    List<AppUser> members,
    AppUser? currentUser,
  ) {
    return AssignmentResolver.resolve(
      text: text,
      members: [
        for (final member in members) FamilyBrainMemberRef.fromAppUser(member),
      ],
      currentUser:
          currentUser == null ? null : FamilyBrainMemberRef.fromAppUser(currentUser),
    );
  }

  static List<String> _extractListItems(String text) {
    var working = text.trim();
    working = working.replaceFirst(
      RegExp(
        r'^(buy|get|pick up|need|we need|shopping list:?|list:?|קנו|לקנות|צריך לקנות)\s+',
        caseSensitive: false,
        unicode: true,
      ),
      '',
    );
    final prompted = RegExp(
      r'buy|get|pick up|need|shopping|list|לקנות|קנו|רשימה|קניות',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(text);
    final hasJoin = working.contains(',') ||
        working.contains(' and ') ||
        RegExp(r'\s+ו', unicode: true).hasMatch(working);
    final hebrewGoods = working.contains('חלב') ||
        working.contains('לחם') ||
        working.contains('ביצ');
    if (!prompted && !hebrewGoods) {
      final hebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(working);
      if (hebrew || !hasJoin) return const [];
    }
    if (!hasJoin && !hebrewGoods) {
      return const [];
    }
    working = working.replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ',');
    working = working.replaceAll(RegExp(r'\s+ו־?\s*', unicode: true), ',');
    working = working.replaceAll(RegExp(r'וזה דחוף|זה דחוף', unicode: true), '');
    Iterable<String> parts = working.split(',');
    if (hebrewGoods) {
      parts = parts.expand((item) => item.trim().split(RegExp(r'\s+')));
    }
    var items = parts
        .map((item) => item.trim().replaceAll(RegExp(r'[.!?]+$'), ''))
        .where((item) => item.length > 1)
        .where(
          (item) => !RegExp(
            r'^(buy|get|need|also|we|to|לקנות|צריך|וגם|גם)$',
            caseSensitive: false,
            unicode: true,
          ).hasMatch(item),
        )
        .toList();
    if (hebrewGoods) {
      const keep = {'חלב', 'לחם', 'ביצים', 'ביצה'};
      items = items.where(keep.contains).toList();
    }
    return items;
  }

  static ({DateTime? date, bool hasTime}) _extractWhen(String text, DateTime now) {
    final lower = text.toLowerCase();
    DateTime day = DateTime(now.year, now.month, now.day);
    var hasDate = false;
    var hasTime = false;
    DateTime? dated;

    final inHours = RegExp(
      r'(?:בעוד|עוד)\s+(שעה|שעתיים|(\d+)\s*שעות)',
      unicode: true,
    ).firstMatch(text);
    final inHoursEn = RegExp(r'\bin\s+(\d+)\s+hours?\b').firstMatch(lower);
    if (inHours != null) {
      final token = inHours.group(1)!;
      final hours = token == 'שעה'
          ? 1
          : token == 'שעתיים'
              ? 2
              : int.tryParse(inHours.group(2) ?? '') ?? 1;
      dated = now.add(Duration(hours: hours));
      return (date: dated, hasTime: true);
    }
    if (inHoursEn != null) {
      dated = now.add(Duration(hours: int.parse(inHoursEn.group(1)!)));
      return (date: dated, hasTime: true);
    }

    if (_he(text, 'מחרתיים') || _he(text, 'בעוד יומיים')) {
      day = day.add(const Duration(days: 2));
      hasDate = true;
    } else if (RegExp(r'\b(today|tonight|this evening)\b').hasMatch(lower) ||
        _he(text, 'היום') ||
        _he(text, 'הערב') ||
        _he(text, 'בהקדם') ||
        _he(text, 'עד הערב')) {
      hasDate = true;
    } else if ((RegExp(r'\btomorrow\b').hasMatch(lower) ||
            _he(text, 'מחר') ||
            _he(text, 'עד מחר')) &&
        !_he(text, 'מחרתיים')) {
      day = day.add(const Duration(days: 1));
      hasDate = true;
    } else if (RegExp(r'\bnext week\b').hasMatch(lower) ||
        text.contains('שבוע הבא') ||
        text.contains('בשבוע הבא')) {
      day = day.add(const Duration(days: 7));
      hasDate = true;
    } else {
      final weekday = _nextWeekday(lower, now);
      if (weekday != null) {
        day = weekday;
        hasDate = true;
      }
    }

    var time = _extractTime(text);
    if (time == null) {
      if (RegExp(r'בבוקר|tomorrow morning', unicode: true).hasMatch(lower)) {
        time = (9, 0);
      } else if (RegExp(
        r'בערב|הערב|עד הערב|tonight|this evening',
        unicode: true,
      ).hasMatch(lower)) {
        time = (19, 0);
      }
    }
    if (time == null) {
      return (date: hasDate ? day : null, hasTime: false);
    }
    hasTime = true;
    dated = DateTime(day.year, day.month, day.day, time.$1, time.$2);
    return (date: dated, hasTime: hasTime);
  }

  static (int, int)? _extractTime(String text) {
    final lower = text.toLowerCase();
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
    final at = RegExp(r'\b(?:at|@|בשעה)\s*(\d{1,2})\b').firstMatch(lower);
    if (at != null) {
      var hour = int.parse(at.group(1)!);
      final evening = RegExp(
        r'\b(tonight|this evening|evening|tonight|pm)\b|בערב|הערב',
        unicode: true,
      ).hasMatch(lower);
      final morning = RegExp(r'\b(morning|a\.?m\.?)\b|בבוקר', unicode: true)
          .hasMatch(lower);
      if (evening && hour >= 1 && hour <= 11) hour += 12;
      if (!evening && !morning && hour >= 1 && hour <= 7) hour += 12;
      return (hour, 0);
    }
    const words = {
      'אחת': 1,
      'שתים': 2,
      'שתיים': 2,
      'שלוש': 3,
      'ארבע': 4,
      'חמש': 5,
      'שש': 6,
      'שבע': 7,
      'שמונה': 8,
      'תשע': 9,
      'עשר': 10,
    };
    for (final entry in words.entries) {
      if (RegExp('ב(?:שעה\\s+)?${entry.key}', unicode: true).hasMatch(text)) {
        var hour = entry.value;
        final morning = RegExp(r'בבוקר', unicode: true).hasMatch(text);
        if (!morning && hour >= 1 && hour <= 10) hour += 12;
        return (hour, 0);
      }
    }
    return null;
  }

  /// Split one natural message into tasks, events, reminders, and lists.
  static List<BrainDraft> parseAll(
    String raw, {
    required DateTime now,
    List<AppUser> members = const [],
    AppUser? currentUser,
    String? imagePath,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      if (imagePath == null) return const [];
      return [
        BrainDraft(
          kind: InformationKind.information,
          title: 'Photo',
          originalText: '',
          imagePath: imagePath,
          lowConfidence: true,
        ),
      ];
    }

    final lower = text.toLowerCase();
    final eventCue = RegExp(
          r'doctor|appointment|meeting|guests|birthday|party|event|school|trip',
        ).hasMatch(lower) ||
        _he(text, 'רופא') ||
        _he(text, 'תור') ||
        _he(text, 'פגישה') ||
        _he(text, 'אורחים');
    final listSlice = _listSlice(text);
    final listItems = _extractListItems(listSlice.isEmpty ? text : listSlice);
    final listCue = listItems.length >= 2;
    final hoursBefore = _hoursBefore(lower, text);
    final remindCue = hoursBefore != null ||
        ((RegExp(r'\b(remind|reminder|don.?t forget)\b').hasMatch(lower) ||
                _he(text, 'תזכיר')) &&
            !_he(text, 'אל תשכח'));
    final leadingRemind = RegExp(
      r"^(remind|don't forget|dont forget|תזכיר)",
      caseSensitive: false,
      unicode: true,
    ).hasMatch(text);

    if ((eventCue && listCue) ||
        (listCue && remindCue) ||
        (eventCue && remindCue && !leadingRemind)) {
      return _parseCompound(
        text: text,
        now: now,
        members: members,
        currentUser: currentUser,
        imagePath: imagePath,
        eventCue: eventCue,
        listItems: listItems,
        remindCue: remindCue,
        hoursBefore: hoursBefore,
      );
    }

    final one = parse(text, now: now, members: members, currentUser: currentUser);
    if (!one.isOk || one.draft == null) return const [];
    return [one.draft!.copyWith(imagePath: imagePath)];
  }

  static List<BrainDraft> _parseCompound({
    required String text,
    required DateTime now,
    required List<AppUser> members,
    required AppUser? currentUser,
    required String? imagePath,
    required bool eventCue,
    required List<String> listItems,
    required bool remindCue,
    required int? hoursBefore,
  }) {
    final drafts = <BrainDraft>[];
    final assignment = _assignment(text, members, currentUser);
    final when = _extractWhen(text, now);
    final person = assignment.hasAssignee
        ? AppUser(
            id: assignment.assigneeId!,
            name: assignment.assigneeName ?? assignment.assigneeId!,
            phone: '',
            language: 'en',
            createdAt: now,
          )
        : null;

    if (eventCue) {
      drafts.add(
        BrainDraft(
          kind: InformationKind.event,
          title: _eventTitle(text, person),
          originalText: text,
          dueDate: when.date,
          hasDueTime: when.hasTime,
          assigneeId: assignment.assigneeId,
          assigneeName: assignment.assigneeName,
          imagePath: imagePath,
          personal: assignment.personal,
          priority: PriorityFromLanguage.infer(text),
          lowConfidence: when.date == null,
          explanation: when.date == null ? missingDateTimeKey : null,
        ),
      );
    }

    if (remindCue) {
      DateTime? at;
      var hasTime = when.hasTime;
      if (hoursBefore != null && when.date != null) {
        at = when.date!.subtract(Duration(hours: hoursBefore));
        hasTime = true;
      } else {
        final remindText = _remindSlice(text);
        final remindWhen = _extractWhen(remindText, now);
        at = remindWhen.date ?? when.date;
        hasTime = remindWhen.hasTime || when.hasTime;
      }
      final remindPerson = _assignment(_remindSlice(text), members, currentUser);
      drafts.add(
        BrainDraft(
          kind: InformationKind.reminder,
          title: eventCue
              ? (drafts.isNotEmpty ? drafts.first.title : _titleFor(InformationKind.reminder, text, const []))
              : _titleFor(InformationKind.reminder, _remindSlice(text), const []),
          originalText: text,
          dueDate: at,
          hasDueTime: hasTime,
          reminderAt: at,
          assigneeId: remindPerson.assigneeId ?? assignment.assigneeId,
          assigneeName: remindPerson.assigneeName ?? assignment.assigneeName,
          personal: remindPerson.personal || assignment.personal,
          priority: PriorityFromLanguage.infer(text),
          lowConfidence: at == null,
          explanation: at == null ? missingDateTimeKey : null,
        ),
      );
    }

    if (listItems.length >= 2) {
      drafts.add(
        BrainDraft(
          kind: InformationKind.list,
          title: listItems.length <= 3 ? listItems.join(', ') : 'Shopping list',
          originalText: text,
          listItems: listItems,
          personal: assignment.personal,
          priority: PriorityFromLanguage.infer(text),
        ),
      );
    }

    return drafts.isEmpty
        ? [
            parse(text, now: now, members: members, currentUser: currentUser).draft ??
                BrainDraft(
                  kind: InformationKind.task,
                  title: text,
                  originalText: text,
                ),
          ]
        : drafts;
  }

  static String _eventTitle(String text, AppUser? person) {
    final lower = text.toLowerCase();
    final hebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(text);
    if (lower.contains('doctor') || lower.contains('רופא') || lower.contains('תור')) {
      if (hebrew) return 'תור לרופא';
      if (person != null) return 'Take ${person.name} to the doctor';
      return 'Doctor appointment';
    }
    if (lower.contains('guest') || lower.contains('אורח')) return 'Guests';
    if (lower.contains('meeting') || lower.contains('פגישה')) return 'Meeting';
    if (lower.contains('birthday')) return 'Birthday';
    return _titleFor(InformationKind.event, text, const []);
  }

  static String _listSlice(String text) {
    final match = RegExp(
      r'\b(?:also\s+)?(?:buy|get|need to buy|we need)\b(.*)$|'
      r'(?:וגם\s+)?(?:צריך\s+)?לקנות\s+(.*)$',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return (match?.group(1) ?? match?.group(2))?.trim() ?? '';
  }

  static String _remindSlice(String text) {
    final match = RegExp(
      r'\b(remind.+)$|תזכיר.+$',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return match?.group(0) ?? text;
  }

  static int? _hoursBefore(String lower, [String? original]) {
    final numeric = RegExp(r'(\d+)\s+hours?\s+before').firstMatch(lower);
    if (numeric != null) return int.parse(numeric.group(1)!);
    if (RegExp(r'\btwo\s+hours?\s+before\b').hasMatch(lower)) return 2;
    if (RegExp(r'\bone\s+hours?\s+before\b').hasMatch(lower)) return 1;
    final source = original ?? lower;
    if (RegExp(r'שעתיים לפני', unicode: true).hasMatch(source)) return 2;
    if (RegExp(r'שעה לפני', unicode: true).hasMatch(source)) return 1;
    return null;
  }

  static DateTime? _nextWeekday(String lower, DateTime now) {
    const names = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
      'יום שני': DateTime.monday,
      'ביום שני': DateTime.monday,
      'יום שלישי': DateTime.tuesday,
      'ביום שלישי': DateTime.tuesday,
      'יום רביעי': DateTime.wednesday,
      'ביום רביעי': DateTime.wednesday,
      'יום חמישי': DateTime.thursday,
      'ביום חמישי': DateTime.thursday,
      'יום שישי': DateTime.friday,
      'ביום שישי': DateTime.friday,
      'שבת': DateTime.saturday,
      'יום ראשון': DateTime.sunday,
      'ביום ראשון': DateTime.sunday,
    };
    for (final entry in names.entries) {
      final hebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(entry.key);
      final nextPrefixed = !hebrew &&
          RegExp('\\bnext\\s+${entry.key}\\b').hasMatch(lower);
      final hit = hebrew
          ? lower.contains(entry.key)
          : nextPrefixed || RegExp('\\b${entry.key}\\b').hasMatch(lower);
      if (!hit) continue;
      var day = DateTime(now.year, now.month, now.day);
      while (day.weekday != entry.value) {
        day = day.add(const Duration(days: 1));
      }
      final today = DateTime(now.year, now.month, now.day);
      if (!day.isAfter(today)) {
        day = day.add(const Duration(days: 7));
      } else if (nextPrefixed && day.isAfter(today)) {
        day = day.add(const Duration(days: 7));
      }
      return day;
    }
    return null;
  }
}
