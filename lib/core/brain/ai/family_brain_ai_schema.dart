import '../../../domain/models/task_item.dart';
import '../family_brain_parser.dart';
import '../priority_from_language.dart';
import 'family_brain_context.dart';

/// Wire names for the provider-independent Family Brain AI response.
///
/// Providers (Gemini today, others later) must produce this JSON:
///
/// ```json
/// {
///   "version": 1,
///   "sourceText": "Remind me to call Dad tomorrow at 4",
///   "clarification": null,
///   "actions": [
///     {
///       "type": "create_reminder",
///       "title": "Call Dad",
///       "date": "2026-08-25",
///       "time": "16:00",
///       "priority": "urgent",
///       "assignee": "Dad",
///       "space": "family",
///       "confidence": 0.9
///     }
///   ]
/// }
/// ```
///
/// Action `type` values:
/// create_task, update_task, complete_task, create_event, update_event,
/// create_reminder, create_list_item, update_list_item,
/// identify_family_member, determine_priority, determine_date, determine_time,
/// ask_for_clarification, conversational_response.
///
/// Gemini does not apply these. Family Brain validates them, then the
/// Action Engine writes application data.
enum FamilyBrainAiActionType {
  createTask('create_task'),
  updateTask('update_task'),
  completeTask('complete_task'),
  createEvent('create_event'),
  updateEvent('update_event'),
  createReminder('create_reminder'),
  createListItem('create_list_item'),
  updateListItem('update_list_item'),
  identifyFamilyMember('identify_family_member'),
  determinePriority('determine_priority'),
  determineDate('determine_date'),
  determineTime('determine_time'),
  askForClarification('ask_for_clarification'),
  conversationalResponse('conversational_response');

  const FamilyBrainAiActionType(this.wireName);
  final String wireName;

  static FamilyBrainAiActionType? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }

  bool get writesData =>
      this == createTask ||
      this == updateTask ||
      this == completeTask ||
      this == createEvent ||
      this == updateEvent ||
      this == createReminder ||
      this == createListItem ||
      this == updateListItem;
}

/// One provider-independent instruction for Family Brain.
class FamilyBrainAiAction {
  const FamilyBrainAiAction({
    required this.type,
    this.targetId,
    this.title,
    this.description,
    this.date,
    this.time,
    this.reminderTime,
    this.hasDueTime = false,
    this.priority,
    this.status,
    this.space,
    this.assigneeName,
    this.assigneeId,
    this.listItems = const [],
    this.location,
    this.message,
    this.confidence,
    this.explanation,
    this.kind,
    this.lowConfidence = false,
    this.imagePath,
  });

  final FamilyBrainAiActionType type;

  /// Existing app item id for update/complete.
  final String? targetId;
  final String? title;
  final String? description;

  /// `YYYY-MM-DD` when known.
  final String? date;

  /// `HH:MM` 24h when known.
  final String? time;
  final String? reminderTime;
  final bool hasDueTime;

  /// `low` | `normal` | `high` | `urgent`
  final String? priority;

  /// `pending` | `inProgress` | `completed`
  final String? status;

  /// `family` | `personal`
  final String? space;
  final String? assigneeName;
  final String? assigneeId;
  final List<String> listItems;
  final String? location;

  /// Clarification or conversational text.
  final String? message;
  final double? confidence;
  final String? explanation;

  /// Optional entity hint: task | event | reminder | list | information
  final String? kind;
  final bool lowConfidence;

  /// Local attachment path. Not sent to providers.
  final String? imagePath;

  FamilyBrainAiAction copyWith({
    String? targetId,
    String? title,
    String? date,
    String? time,
    String? reminderTime,
    bool? hasDueTime,
    String? priority,
    String? status,
    String? space,
    String? assigneeName,
    String? assigneeId,
    List<String>? listItems,
    String? message,
    String? kind,
    bool? lowConfidence,
    String? imagePath,
  }) {
    return FamilyBrainAiAction(
      type: type,
      targetId: targetId ?? this.targetId,
      title: title ?? this.title,
      description: description,
      date: date ?? this.date,
      time: time ?? this.time,
      reminderTime: reminderTime ?? this.reminderTime,
      hasDueTime: hasDueTime ?? this.hasDueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      space: space ?? this.space,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeId: assigneeId ?? this.assigneeId,
      listItems: listItems ?? this.listItems,
      location: location,
      message: message ?? this.message,
      confidence: confidence,
      explanation: explanation,
      kind: kind ?? this.kind,
      lowConfidence: lowConfidence ?? this.lowConfidence,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.wireName,
      if (targetId != null) 'targetId': targetId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (reminderTime != null) 'reminderTime': reminderTime,
      if (hasDueTime) 'hasDueTime': true,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (space != null) 'space': space,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (assigneeName != null) 'assignee': assigneeName,
      if (listItems.isNotEmpty) 'listItems': listItems,
      if (location != null) 'location': location,
      if (message != null) 'message': message,
      if (confidence != null) 'confidence': confidence,
      if (explanation != null) 'explanation': explanation,
      if (kind != null) 'kind': kind,
      if (lowConfidence) 'lowConfidence': true,
    };
  }

  static FamilyBrainAiAction? fromJson(Map<dynamic, dynamic> json) {
    final type = FamilyBrainAiActionType.tryParse(json['type']?.toString());
    if (type == null) return null;
    final listItems = <String>[
      if (json['listItems'] is List)
        for (final entry in json['listItems'] as List)
          if (entry.toString().trim().isNotEmpty) entry.toString().trim(),
      if (json['items'] is List && json['listItems'] is! List)
        for (final entry in json['items'] as List)
          if (entry.toString().trim().isNotEmpty) entry.toString().trim(),
    ];
    final assignee = json['assignee'] ?? json['assigneeName'];
    final confidence = json['confidence'];
    return FamilyBrainAiAction(
      type: type,
      targetId: json['targetId']?.toString(),
      title: _text(json['title'] ?? json['listName']),
      description: _text(json['description']),
      date: _text(json['date']),
      time: _text(json['time']),
      reminderTime: _text(json['reminderTime'] ?? json['reminder']),
      hasDueTime: json['hasDueTime'] == true || json['time'] != null,
      priority: _text(json['priority']),
      status: _text(json['status']),
      space: _text(json['space']),
      assigneeName: assignee?.toString(),
      assigneeId: _text(json['assigneeId']),
      listItems: listItems,
      location: _text(json['location']),
      message: _text(json['message'] ?? json['clarification']),
      confidence: confidence is num ? confidence.toDouble() : null,
      explanation: _text(json['explanation'] ?? json['context']),
      kind: _text(json['kind'] ?? json['entity']),
      lowConfidence: json['lowConfidence'] == true ||
          (confidence is num && confidence < 0.55),
    );
  }

  InformationKind get informationKind {
    final hinted = (kind ?? '').toLowerCase();
    return switch (hinted) {
      'event' => InformationKind.event,
      'reminder' => InformationKind.reminder,
      'list' => InformationKind.list,
      'information' || 'note' || 'info' => InformationKind.information,
      'task' => InformationKind.task,
      _ => switch (type) {
          FamilyBrainAiActionType.createEvent ||
          FamilyBrainAiActionType.updateEvent =>
            InformationKind.event,
          FamilyBrainAiActionType.createReminder => InformationKind.reminder,
          FamilyBrainAiActionType.createListItem ||
          FamilyBrainAiActionType.updateListItem =>
            InformationKind.list,
          _ => InformationKind.task,
        },
    };
  }

  DateTime? dueAt(DateTime now) => combineDateTime(date, time, now);

  DateTime? reminderAt(DateTime now) {
    final at = combineDateTime(date, reminderTime, now);
    if (at != null) return at;
    if (type == FamilyBrainAiActionType.createReminder) return dueAt(now);
    return null;
  }

  BrainDraft? toDraft({
    required String originalText,
    required DateTime now,
  }) {
    if (type != FamilyBrainAiActionType.createTask &&
        type != FamilyBrainAiActionType.createEvent &&
        type != FamilyBrainAiActionType.createReminder &&
        type != FamilyBrainAiActionType.createListItem) {
      return null;
    }
    final resolvedTitle = (title ?? '').trim();
    if (resolvedTitle.isEmpty && listItems.isEmpty) return null;
    return BrainDraft(
      kind: informationKind,
      title: resolvedTitle.isEmpty ? listItems.join(', ') : resolvedTitle,
      originalText: originalText,
      dueDate: dueAt(now),
      hasDueTime: hasDueTime || time != null,
      reminderAt: reminderAt(now),
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      listItems: listItems,
      lowConfidence: lowConfidence,
      description: description,
      location: location,
      explanation: explanation,
      personal: space == 'personal' || space == 'private',
      priority: PriorityFromLanguage.tryParse(priority) ?? TaskPriority.normal,
      imagePath: imagePath,
    );
  }

  static DateTime? combineDateTime(dynamic date, dynamic time, DateTime now) {
    DateTime? day;
    if (date is String && date.isNotEmpty) {
      day = DateTime.tryParse(date);
    }
    if (time is String && time.isNotEmpty) {
      final parts = time.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final base = day ?? DateTime(now.year, now.month, now.day);
      return DateTime(base.year, base.month, base.day, hour, minute);
    }
    return day;
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

/// Normalized Family Brain AI response. Same shape for every provider.
class FamilyBrainAiResponse {
  const FamilyBrainAiResponse({
    this.version = 1,
    this.providerId = '',
    this.sourceText = '',
    this.clarification,
    this.actions = const [],
  });

  final int version;
  final String providerId;
  final String sourceText;
  final String? clarification;
  final List<FamilyBrainAiAction> actions;

  bool get hasCreateActions => actions.any(
        (action) =>
            action.type == FamilyBrainAiActionType.createTask ||
            action.type == FamilyBrainAiActionType.createEvent ||
            action.type == FamilyBrainAiActionType.createReminder ||
            action.type == FamilyBrainAiActionType.createListItem,
      );

  String? get conversationText {
    for (final action in actions) {
      if (action.type == FamilyBrainAiActionType.conversationalResponse &&
          (action.message ?? '').trim().isNotEmpty) {
        return action.message;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (providerId.isNotEmpty) 'provider': providerId,
      if (sourceText.isNotEmpty) 'sourceText': sourceText,
      'clarification': clarification,
      'actions': [for (final action in actions) action.toJson()],
    };
  }

  static FamilyBrainAiResponse fromJson(
    Map<dynamic, dynamic> json, {
    String providerId = '',
    String sourceText = '',
  }) {
    final rawActions = json['actions'];
    final actions = <FamilyBrainAiAction>[];
    if (rawActions is List) {
      for (final item in rawActions) {
        if (item is! Map) continue;
        final action = FamilyBrainAiAction.fromJson(item);
        if (action != null) actions.add(action);
      }
    }
    final clarification = FamilyBrainAiAction._text(
      json['clarification'] ?? json['message'],
    );
    if (clarification != null &&
        !actions.any((a) => a.type == FamilyBrainAiActionType.askForClarification)) {
      actions.add(
        FamilyBrainAiAction(
          type: FamilyBrainAiActionType.askForClarification,
          message: clarification,
        ),
      );
    }
    return FamilyBrainAiResponse(
      version: json['version'] is num ? (json['version'] as num).toInt() : 1,
      providerId: FamilyBrainAiAction._text(json['provider']) ?? providerId,
      sourceText: FamilyBrainAiAction._text(json['sourceText']) ?? sourceText,
      clarification: clarification,
      actions: actions,
    );
  }

  List<BrainDraft> toDrafts({
    required String originalText,
    required DateTime now,
  }) {
    final drafts = <BrainDraft>[];
    for (final action in actions) {
      final draft = action.toDraft(originalText: originalText, now: now);
      if (draft != null) drafts.add(draft);
    }
    return drafts;
  }

  factory FamilyBrainAiResponse.fromDrafts(
    List<BrainDraft> drafts, {
    String providerId = '',
    String sourceText = '',
    String? clarification,
  }) {
    return FamilyBrainAiResponse(
      providerId: providerId,
      sourceText: sourceText.isEmpty && drafts.isNotEmpty
          ? drafts.first.originalText
          : sourceText,
      clarification: clarification,
      actions: [
        for (final draft in drafts) _actionFromDraft(draft),
        if (clarification != null && clarification.trim().isNotEmpty)
          FamilyBrainAiAction(
            type: FamilyBrainAiActionType.askForClarification,
            message: clarification.trim(),
          ),
      ],
    );
  }

  static FamilyBrainAiAction _actionFromDraft(BrainDraft draft) {
    final type = switch (draft.kind) {
      InformationKind.event => FamilyBrainAiActionType.createEvent,
      InformationKind.reminder => FamilyBrainAiActionType.createReminder,
      InformationKind.list => FamilyBrainAiActionType.createListItem,
      InformationKind.information => FamilyBrainAiActionType.createTask,
      InformationKind.task => FamilyBrainAiActionType.createTask,
    };
    return FamilyBrainAiAction(
      type: type,
      title: draft.title,
      description: draft.description,
      date: _dateOnly(draft.dueDate),
      time: draft.hasDueTime ? _timeOnly(draft.dueDate) : null,
      reminderTime: _timeOnly(draft.reminderAt),
      hasDueTime: draft.hasDueTime,
      priority: draft.priority.name,
      space: draft.personal ? 'personal' : 'family',
      assigneeName: draft.assigneeName,
      assigneeId: draft.assigneeId,
      listItems: draft.listItems,
      location: draft.location,
      explanation: draft.explanation,
      kind: draft.kind.name,
      lowConfidence: draft.lowConfidence,
      imagePath: draft.imagePath,
    );
  }

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String? _timeOnly(DateTime? value) {
    if (value == null) return null;
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Family Brain owns domain resolution. Providers only return structured info.
class FamilyBrainAiValidator {
  static FamilyBrainAiResponse resolve(
    FamilyBrainAiResponse raw, {
    required FamilyBrainContext context,
    String originalText = '',
  }) {
    final source = raw.sourceText.isNotEmpty ? raw.sourceText : originalText;
    final actions = <FamilyBrainAiAction>[];
    for (var action in raw.actions) {
      if (action.type == FamilyBrainAiActionType.askForClarification ||
          action.type == FamilyBrainAiActionType.conversationalResponse) {
        if ((action.message ?? raw.clarification ?? '').trim().isEmpty) {
          continue;
        }
        actions.add(action);
        continue;
      }

      if (action.type.writesData &&
          (action.title ?? '').trim().isEmpty &&
          action.listItems.isEmpty &&
          action.type != FamilyBrainAiActionType.completeTask) {
        continue;
      }
      if (action.type == FamilyBrainAiActionType.completeTask &&
          (action.targetId == null || action.targetId!.isEmpty)) {
        continue;
      }
      if ((action.type == FamilyBrainAiActionType.updateTask ||
              action.type == FamilyBrainAiActionType.updateEvent ||
              action.type == FamilyBrainAiActionType.updateListItem) &&
          (action.targetId == null || action.targetId!.isEmpty)) {
        continue;
      }

      final member = _matchMember(
        action.assigneeId,
        action.assigneeName,
        context.members,
      );
      var priority = PriorityFromLanguage.tryParse(action.priority);
      if (priority == null && action.type.writesData) {
        priority = PriorityFromLanguage.infer(
          source.isEmpty ? (action.title ?? '') : source,
        );
      }

      if (action.type == FamilyBrainAiActionType.identifyFamilyMember &&
          member == null) {
        continue;
      }

      actions.add(
        action.copyWith(
          assigneeId: member?.id ?? action.assigneeId,
          assigneeName: member?.name ?? action.assigneeName,
          priority: priority?.name ?? action.priority,
        ),
      );
    }

    return FamilyBrainAiResponse(
      version: raw.version,
      providerId: raw.providerId,
      sourceText: source,
      clarification: raw.clarification,
      actions: actions,
    );
  }

  static FamilyBrainMemberRef? _matchMember(
    String? id,
    String? name,
    List<FamilyBrainMemberRef> members,
  ) {
    if (id != null && id.isNotEmpty) {
      for (final member in members) {
        if (member.id == id) return member;
      }
    }
    if (name == null || name.trim().isEmpty) return null;
    final needle = name.toLowerCase();
    for (final member in members) {
      if (needle.contains(member.name.toLowerCase()) ||
          member.name
              .toLowerCase()
              .split(' ')
              .any((part) => part.isNotEmpty && needle.contains(part))) {
        return member;
      }
    }
    return null;
  }
}
