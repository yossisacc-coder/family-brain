enum TaskType { personal, family }

enum TaskPriority { normal, urgent }

enum TaskStatus { pending, inProgress, completed }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.familyId,
    required this.creatorId,
    required this.title,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.dueDate,
    this.notes,
  });

  final String id;
  final String familyId;
  final String creatorId;
  final String title;
  final String? assigneeId;
  final TaskType type;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String? notes;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status != TaskStatus.completed;
  bool get isUrgent => priority == TaskPriority.urgent && isOpen;

  bool isDueSoon([DateTime? now]) {
    if (dueDate == null || !isOpen) return false;
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(dueDate!);
    return !due.isAfter(today.add(const Duration(days: 1)));
  }

  bool isOverdue([DateTime? now]) {
    if (dueDate == null || !isOpen) return false;
    return _dateOnly(dueDate!).isBefore(_dateOnly(now ?? DateTime.now()));
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  TaskItem copyWith({
    String? title,
    String? assigneeId,
    bool clearAssignee = false,
    TaskType? type,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskPriority? priority,
    String? notes,
    TaskStatus? status,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id,
      familyId: familyId,
      creatorId: creatorId,
      title: title ?? this.title,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      type: type ?? this.type,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'creatorId': creatorId,
      'title': title,
      'assigneeId': assigneeId,
      'type': type.name,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      familyId: map['familyId'] as String,
      creatorId: map['creatorId'] as String,
      title: map['title'] as String? ?? '',
      assigneeId: map['assigneeId'] as String?,
      type: TaskType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TaskType.family,
      ),
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? ''),
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == map['priority'],
        orElse: () => TaskPriority.normal,
      ),
      notes: map['notes'] as String?,
      status: TaskStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
