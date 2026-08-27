enum TaskType { personal, family }

enum TaskPriority { low, normal, high, urgent }

enum TaskStatus { pending, inProgress, completed }

/// Structured information Family Brain can save. Stored on [TaskItem]
/// so existing task/calendar/today surfaces keep working.
enum InformationKind { task, event, reminder, list, information }

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
    this.kind = InformationKind.task,
    this.assigneeId,
    this.dueDate,
    this.hasDueTime = false,
    this.notes,
    this.reminderAt,
    this.deletedAt,
  });

  final String id;
  final String familyId;
  final String creatorId;
  final String title;
  final InformationKind kind;
  final String? assigneeId;
  final TaskType type;
  final DateTime? dueDate;
  final bool hasDueTime;
  final TaskPriority priority;
  final String? notes;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderAt;
  final DateTime? deletedAt;

  bool get isTrashed => deletedAt != null;
  bool get isOpen => !isTrashed && status != TaskStatus.completed;
  bool get isUrgent => priority == TaskPriority.urgent && isOpen;
  bool get isHigh => priority == TaskPriority.high && isOpen;
  bool get hasReminder => reminderAt != null && !isTrashed;

  /// Personal tasks stay in My Space and are hidden from other members.
  bool isVisibleTo(String userId) {
    if (type == TaskType.family) return true;
    return creatorId == userId || assigneeId == userId;
  }

  bool isDueSoon([DateTime? now]) {
    if (dueDate == null || !isOpen) return false;
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(dueDate!);
    return !due.isAfter(today.add(const Duration(days: 1)));
  }

  bool isOverdue([DateTime? now]) {
    if (dueDate == null || !isOpen) return false;
    final current = now ?? DateTime.now();
    if (hasDueTime) {
      return dueDate!.isBefore(current);
    }
    return _dateOnly(dueDate!).isBefore(_dateOnly(current));
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  TaskItem copyWith({
    String? title,
    InformationKind? kind,
    String? assigneeId,
    bool clearAssignee = false,
    TaskType? type,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? hasDueTime,
    TaskPriority? priority,
    String? notes,
    TaskStatus? status,
    DateTime? updatedAt,
    DateTime? reminderAt,
    bool clearReminder = false,
    DateTime? deletedAt,
    bool clearDeleted = false,
  }) {
    return TaskItem(
      id: id,
      familyId: familyId,
      creatorId: creatorId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      type: type ?? this.type,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      hasDueTime: clearDueDate ? false : (hasDueTime ?? this.hasDueTime),
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'creatorId': creatorId,
      'title': title,
      'kind': kind.name,
      'assigneeId': assigneeId,
      'type': type.name,
      'dueDate': dueDate?.toIso8601String(),
      'hasDueTime': hasDueTime,
      'priority': priority.name,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id']?.toString() ?? '',
      familyId: map['familyId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      kind: InformationKind.values.firstWhere(
        (value) => value.name == map['kind'],
        orElse: () => InformationKind.task,
      ),
      assigneeId: map['assigneeId'] as String?,
      type: TaskType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TaskType.family,
      ),
      dueDate: _parseDate(map['dueDate']),
      hasDueTime: map['hasDueTime'] == true,
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == map['priority'],
        orElse: () => TaskPriority.normal,
      ),
      notes: map['notes'] as String?,
      status: TaskStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      reminderAt: _parseDate(map['reminderAt']),
      deletedAt: _parseDate(map['deletedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }
}
