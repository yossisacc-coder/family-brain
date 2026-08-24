import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_notification_repository.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/domain/models/app_notification.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskItem sampleTask() {
    return TaskItem(
      id: 'task-1',
      familyId: 'family-1',
      creatorId: 'alex',
      title: 'Buy milk',
      type: TaskType.family,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: DateTime(2026, 8, 24),
      updatedAt: DateTime(2026, 8, 24),
    );
  }

  test('trashed tasks leave the active list and can be restored', () async {
    final store = LocalJsonStore(persist: false);
    final repo = LocalTaskRepository(store);
    final task = sampleTask();
    await repo.createTask(task);

    expect((await repo.watchFamilyTasks('family-1').first).single.id, 'task-1');
    expect(await repo.watchTrashedTasks('family-1').first, isEmpty);

    await repo.moveToTrash(task);
    expect(await repo.watchFamilyTasks('family-1').first, isEmpty);
    expect((await repo.watchTrashedTasks('family-1').first).single.isTrashed, isTrue);

    await repo.restoreTask(task);
    expect((await repo.watchFamilyTasks('family-1').first).single.isTrashed, isFalse);
    expect(await repo.watchTrashedTasks('family-1').first, isEmpty);
  });

  test('completed tasks remain in the active list and can be reopened', () async {
    final store = LocalJsonStore(persist: false);
    final repo = LocalTaskRepository(store);
    final task = sampleTask();
    await repo.createTask(task);
    await repo.updateTask(task.copyWith(status: TaskStatus.completed));
    final completed = await repo.watchFamilyTasks('family-1').first;
    expect(completed.single.status, TaskStatus.completed);
    expect(completed.single.isOpen, isFalse);

    await repo.updateTask(completed.single.copyWith(status: TaskStatus.pending));
    expect(
      (await repo.watchFamilyTasks('family-1').first).single.status,
      TaskStatus.pending,
    );
  });

  test('permanent delete and empty trash remove tasks from storage', () async {
    final store = LocalJsonStore(persist: false);
    final repo = LocalTaskRepository(store);
    final first = sampleTask();
    final second = TaskItem(
      id: 'task-2',
      familyId: 'family-1',
      creatorId: 'alex',
      title: 'Call grandma',
      type: TaskType.personal,
      priority: TaskPriority.high,
      status: TaskStatus.completed,
      createdAt: DateTime(2026, 8, 24),
      updatedAt: DateTime(2026, 8, 24),
    );
    await repo.createTask(first);
    await repo.createTask(second);
    await repo.moveToTrash(first);
    await repo.moveToTrash(second);

    await repo.permanentlyDelete('task-1');
    expect(store.tasks.containsKey('task-1'), isFalse);
    expect(store.tasks.containsKey('task-2'), isTrue);

    await repo.emptyTrash('family-1');
    expect(store.tasks, isEmpty);
  });

  test('deleting a notification does not delete the related task', () async {
    final store = LocalJsonStore(persist: false);
    final tasks = LocalTaskRepository(store);
    final notifications = LocalNotificationRepository(store);
    final task = sampleTask();
    await tasks.createTask(task);
    await notifications.addNotification(
      AppNotification(
        id: 'n1',
        userId: 'alex',
        familyId: 'family-1',
        type: NotificationType.taskAssigned,
        title: 'Assigned',
        message: task.title,
        read: false,
        createdAt: DateTime(2026, 8, 24),
        taskId: task.id,
      ),
    );

    await notifications.deleteNotification('n1');
    expect(await notifications.watchUserNotifications('alex').first, isEmpty);
    expect((await tasks.watchFamilyTasks('family-1').first).single.id, task.id);
  });
}
