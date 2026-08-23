import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import 'local_json_store.dart';

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._store);

  final LocalJsonStore _store;

  @override
  Stream<List<TaskItem>> watchFamilyTasks(String familyId) async* {
    yield _list(familyId);
    await for (final _ in _store.changes) {
      yield _list(familyId);
    }
  }

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    _store.tasks[task.id] = task.toMap();
    await _store.commit();
    return task;
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    _store.tasks[task.id] = task.toMap();
    await _store.commit();
    return task;
  }

  List<TaskItem> _list(String familyId) {
    return _store.tasks.values
        .map(TaskItem.fromMap)
        .where((task) => task.familyId == familyId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
