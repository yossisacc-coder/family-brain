import '../models/task_item.dart';

abstract class TaskRepository {
  Stream<List<TaskItem>> watchFamilyTasks(String familyId);

  Future<TaskItem> createTask(TaskItem task);

  Future<TaskItem> updateTask(TaskItem task);
}
