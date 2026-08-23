import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskItem task({
    TaskPriority priority = TaskPriority.normal,
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
  }) {
    return TaskItem(
      id: '1',
      familyId: 'f',
      creatorId: 'u',
      title: 'Buy milk',
      type: TaskType.family,
      priority: priority,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      dueDate: dueDate,
    );
  }

  test('urgent open tasks are marked urgent', () {
    expect(task(priority: TaskPriority.urgent).isUrgent, isTrue);
    expect(
      task(priority: TaskPriority.urgent, status: TaskStatus.completed).isUrgent,
      isFalse,
    );
  });

  test('overdue only applies to open tasks', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(task(dueDate: yesterday).isOverdue(), isTrue);
    expect(
      task(dueDate: yesterday, status: TaskStatus.completed).isOverdue(),
      isFalse,
    );
  });

  test('round-trips through a map', () {
    final original = task(priority: TaskPriority.urgent);
    final copy = TaskItem.fromMap(original.toMap());
    expect(copy.title, original.title);
    expect(copy.priority, TaskPriority.urgent);
    expect(copy.type, TaskType.family);
  });
}
