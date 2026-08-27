enum ActivityType {
  taskCreated,
  taskCompleted,
  taskEdited,
  taskDeleted,
  taskRestored,
  taskAssigned,
  aiCreated,
  shareReceived,
  reminderSet,
}

class FamilyActivity {
  const FamilyActivity({
    required this.id,
    required this.familyId,
    required this.actorId,
    required this.actorName,
    required this.type,
    required this.summary,
    required this.createdAt,
    this.detail,
    this.taskId,
    this.taskTitle,
    this.assigneeId,
    this.personal = false,
  });

  final String id;
  final String familyId;
  final String actorId;
  final String actorName;
  final ActivityType type;
  final String summary;
  final DateTime createdAt;
  final String? detail;
  final String? taskId;
  final String? taskTitle;
  final String? assigneeId;
  final bool personal;

  bool isVisibleTo(String viewerId) {
    if (!personal) return true;
    return actorId == viewerId || assigneeId == viewerId;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'actorId': actorId,
      'actorName': actorName,
      'type': type.name,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'detail': detail,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'assigneeId': assigneeId,
      'personal': personal,
    };
  }

  factory FamilyActivity.fromMap(Map<String, dynamic> map) {
    return FamilyActivity(
      id: map['id'] as String,
      familyId: map['familyId'] as String? ?? '',
      actorId: map['actorId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      type: ActivityType.values.where((value) => value.name == map['type']).firstOrNull ??
          ActivityType.taskCreated,
      summary: map['summary'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      detail: map['detail'] as String?,
      taskId: map['taskId'] as String?,
      taskTitle: map['taskTitle'] as String?,
      assigneeId: map['assigneeId'] as String?,
      personal: map['personal'] as bool? ?? false,
    );
  }
}
