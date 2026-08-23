enum NotificationType { taskAssigned, taskCompleted, taskDueTomorrow }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.taskId,
  });

  final String id;
  final String userId;
  final String familyId;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? taskId;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
      taskId: taskId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'familyId': familyId,
      'type': type.name,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'taskId': taskId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      familyId: map['familyId'] as String,
      type: NotificationType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => NotificationType.taskAssigned,
      ),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      taskId: map['taskId'] as String?,
    );
  }
}
