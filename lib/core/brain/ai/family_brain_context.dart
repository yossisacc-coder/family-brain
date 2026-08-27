import '../../../domain/models/app_user.dart';
import '../../../domain/models/task_item.dart';

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
    this.tasks = const [],
    this.events = const [],
    this.reminders = const [],
    this.lists = const [],
    this.recentUserTexts = const [],
    this.lastEvent,
  });

  final DateTime now;
  final String language;
  final List<FamilyBrainMemberRef> members;
  final List<FamilyBrainItemRef> tasks;
  final List<FamilyBrainItemRef> events;
  final List<FamilyBrainItemRef> reminders;
  final List<FamilyBrainItemRef> lists;
  final List<String> recentUserTexts;
  final FamilyBrainItemRef? lastEvent;

  factory FamilyBrainContext.fromApp({
    required DateTime now,
    String language = 'en',
    List<AppUser> members = const [],
    List<TaskItem> items = const [],
    List<String> recentUserTexts = const [],
    FamilyBrainItemRef? lastEvent,
  }) {
    return FamilyBrainContext(
      now: now,
      language: language,
      members: [for (final member in members) FamilyBrainMemberRef.fromAppUser(member)],
      tasks: [
        for (final item in items)
          if (item.kind == InformationKind.task) FamilyBrainItemRef.fromTask(item),
      ],
      events: [
        for (final item in items)
          if (item.kind == InformationKind.event) FamilyBrainItemRef.fromTask(item),
      ],
      reminders: [
        for (final item in items)
          if (item.kind == InformationKind.reminder) FamilyBrainItemRef.fromTask(item),
      ],
      lists: [
        for (final item in items)
          if (item.kind == InformationKind.list) FamilyBrainItemRef.fromTask(item),
      ],
      recentUserTexts: recentUserTexts,
      lastEvent: lastEvent,
    );
  }

  /// Payload for the current gateway. Omits empty collections.
  Map<String, dynamic> toProviderPayload() {
    return {
      'now': now.toIso8601String(),
      'language': language,
      'members': [for (final member in members) member.toJson()],
      if (tasks.isNotEmpty)
        'tasks': [for (final item in tasks.take(8)) item.toJson()],
      if (events.isNotEmpty)
        'events': [for (final item in events.take(8)) item.toJson()],
      if (reminders.isNotEmpty)
        'reminders': [for (final item in reminders.take(8)) item.toJson()],
      if (lists.isNotEmpty)
        'lists': [for (final item in lists.take(8)) item.toJson()],
      if (recentUserTexts.isNotEmpty) 'recent': recentUserTexts,
      if (lastEvent != null) 'lastEvent': lastEvent!.toJson(),
    };
  }
}
