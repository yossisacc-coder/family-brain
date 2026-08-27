import '../models/task_item.dart';

abstract class TaskRepository {
  Stream<List<TaskItem>> watchFamilyTasks(String familyId);

  Stream<List<TaskItem>> watchTrashedTasks(String familyId);

  Future<TaskItem> createTask(TaskItem task);

  Future<TaskItem> updateTask(TaskItem task);

  Future<TaskItem> moveToTrash(TaskItem task);

  Future<TaskItem> restoreTask(TaskItem task);

  Future<void> permanentlyDelete(String taskId);

  Future<void> emptyTrash(String familyId);
}
