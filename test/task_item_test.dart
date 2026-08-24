import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskItem task({
    TaskPriority priority = TaskPriority.normal,
    TaskStatus status = TaskStatus.pending,
    TaskType type = TaskType.family,
    DateTime? dueDate,
    DateTime? reminderAt,
    DateTime? deletedAt,
    String creatorId = 'u',
    String? assigneeId,
    bool hasDueTime = false,
  }) {
    return TaskItem(
      id: '1',
      familyId: 'f',
      creatorId: creatorId,
      title: 'Buy milk',
      type: type,
      priority: priority,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      dueDate: dueDate,
      hasDueTime: hasDueTime,
      reminderAt: reminderAt,
      deletedAt: deletedAt,
      assigneeId: assigneeId,
    );
  }

  test('urgent open tasks are marked urgent', () {
    expect(task(priority: TaskPriority.urgent).isUrgent, isTrue);
    expect(
      task(priority: TaskPriority.urgent, status: TaskStatus.completed).isUrgent,
      isFalse,
    );
  });

  test('high priority is separate from urgent and status', () {
    final high = task(priority: TaskPriority.high);
    expect(high.isHigh, isTrue);
    expect(high.isUrgent, isFalse);
    expect(high.status, TaskStatus.pending);
  });

  test('overdue only applies to open tasks', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(task(dueDate: yesterday).isOverdue(), isTrue);
    expect(
      task(dueDate: yesterday, status: TaskStatus.completed).isOverdue(),
      isFalse,
    );
    expect(
      task(dueDate: yesterday, deletedAt: DateTime.now()).isOverdue(),
      isFalse,
    );
  });

  test('trashed tasks leave the open list but keep history fields', () {
    final trashed = task(deletedAt: DateTime(2026, 8, 24));
    expect(trashed.isTrashed, isTrue);
    expect(trashed.isOpen, isFalse);
    expect(trashed.copyWith(clearDeleted: true).isTrashed, isFalse);
  });

  test('personal tasks stay private to creator or assignee', () {
    final personal = task(
      type: TaskType.personal,
      creatorId: 'maya',
      assigneeId: 'maya',
    );
    expect(personal.isVisibleTo('maya'), isTrue);
    expect(personal.isVisibleTo('alex'), isFalse);
    expect(task(type: TaskType.family).isVisibleTo('alex'), isTrue);
  });

  test('reminders round-trip and stay distinct from notifications', () {
    final reminder = DateTime(2026, 8, 25, 18);
    final original = task(
      priority: TaskPriority.high,
      reminderAt: reminder,
      hasDueTime: true,
      dueDate: reminder,
    );
    final copy = TaskItem.fromMap(original.toMap());
    expect(copy.reminderAt, reminder);
    expect(copy.hasReminder, isTrue);
    expect(copy.hasDueTime, isTrue);
    expect(copy.priority, TaskPriority.high);
    expect(copy.deletedAt, isNull);
  });

  test('legacy maps without new fields still load', () {
    final copy = TaskItem.fromMap({
      'id': 'legacy',
      'familyId': 'f',
      'creatorId': 'u',
      'title': 'Old task',
      'type': 'family',
      'priority': 'urgent',
      'status': 'pending',
      'createdAt': '2026-01-01T00:00:00.000',
      'updatedAt': '2026-01-01T00:00:00.000',
    });
    expect(copy.hasDueTime, isFalse);
    expect(copy.reminderAt, isNull);
    expect(copy.deletedAt, isNull);
    expect(copy.priority, TaskPriority.urgent);
  });
}
