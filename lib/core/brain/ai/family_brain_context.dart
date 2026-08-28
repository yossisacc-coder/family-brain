import '../../../domain/models/app_user.dart';
import '../../../domain/models/task_item.dart';
import '../civil_datetime.dart';

/// Compact family member sent to an AI provider. No extra profile data.
class FamilyBrainMemberRef {
  const FamilyBrainMemberRef({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, String> toJson() => {'id': id, 'name': name};

  factory FamilyBrainMemberRef.fromAppUser(AppUser user) {
    return FamilyBrainMemberRef(id: user.id, name: user.name);
  }
}

/// Compact existing-item snapshot. Only id/title/kind/status/date.
class FamilyBrainItemRef {
  const FamilyBrainItemRef({
    required this.id,
    required this.title,
    required this.kind,
    this.status,
    this.dueDate,
  });

  final String id;
  final String title;
  final String kind;
  final String? status;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        if (status != null) 'status': status,
        if (dueDate != null) 'dueDate': dueDate,
      };

  factory FamilyBrainItemRef.fromTask(TaskItem task) {
    return FamilyBrainItemRef(
      id: task.id,
      title: task.title,
      kind: task.kind.name,
      status: task.status.name,
      dueDate: task.dueDate?.toIso8601String(),
    );
  }
}

/// Family Brain owns this context. Providers receive only relevant slices.
class FamilyBrainContext {
  const FamilyBrainContext({
    required this.now,
    this.language = 'en',
    this.members = const [],
    this.currentUser,
    this.tasks = const [],
    this.events = const [],
    this.reminders = const [],
    this.lists = const [],
    this.source,
  });

  final DateTime now;
  final String language;
  final List<FamilyBrainMemberRef> members;
  final FamilyBrainMemberRef? currentUser;
  final List<FamilyBrainItemRef> tasks;
  final List<FamilyBrainItemRef> events;
  final List<FamilyBrainItemRef> reminders;
  final List<FamilyBrainItemRef> lists;
  final String? source;

  List<FamilyBrainItemRef> get catalog => [
        ...tasks,
        ...events,
        ...reminders,
        ...lists,
      ];

  factory FamilyBrainContext.fromApp({
    required DateTime now,
    String language = 'en',
    List<AppUser> members = const [],
    List<TaskItem> items = const [],
    AppUser? currentUser,
    String? source,
  }) {
    final open = items.where((item) => item.isOpen).take(24).toList();
    return FamilyBrainContext(
      now: now,
      language: language,
      members: [
        for (final member in members) FamilyBrainMemberRef.fromAppUser(member),
      ],
      currentUser: currentUser == null
          ? null
          : FamilyBrainMemberRef.fromAppUser(currentUser),
      tasks: [
        for (final item in open)
          if (item.kind == InformationKind.task) FamilyBrainItemRef.fromTask(item),
      ],
      events: [
        for (final item in open)
          if (item.kind == InformationKind.event) FamilyBrainItemRef.fromTask(item),
      ],
      reminders: [
        for (final item in open)
          if (item.kind == InformationKind.reminder) FamilyBrainItemRef.fromTask(item),
      ],
      lists: [
        for (final item in open)
          if (item.kind == InformationKind.list) FamilyBrainItemRef.fromTask(item),
      ],
      source: source,
    );
  }

  /// Payload for the current gateway. Omits empty collections.
  Map<String, dynamic> toProviderPayload() {
    return {
      'now': CivilDateTime.localStamp(now),
      'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      'language': language,
      'members': [for (final member in members) member.toJson()],
      if (currentUser != null) 'currentUser': currentUser!.toJson(),
      if (tasks.isNotEmpty) 'tasks': [for (final item in tasks) item.toJson()],
      if (events.isNotEmpty)
        'events': [for (final item in events) item.toJson()],
      if (reminders.isNotEmpty)
        'reminders': [for (final item in reminders) item.toJson()],
      if (lists.isNotEmpty) 'lists': [for (final item in lists) item.toJson()],
      if (source != null && source!.isNotEmpty) 'source': source,
    };
  }
}
