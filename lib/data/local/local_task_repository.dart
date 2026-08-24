import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import 'local_json_store.dart';

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._store);

  final LocalJsonStore _store;

  @override
  Stream<List<TaskItem>> watchFamilyTasks(String familyId) async* {
    yield _list(familyId, trashed: false);
    await for (final _ in _store.changes) {
      yield _list(familyId, trashed: false);
    }
  }

  @override
  Stream<List<TaskItem>> watchTrashedTasks(String familyId) async* {
    yield _list(familyId, trashed: true);
    await for (final _ in _store.changes) {
      yield _list(familyId, trashed: true);
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

  @override
  Future<TaskItem> moveToTrash(TaskItem task) {
    return updateTask(
      task.copyWith(deletedAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  @override
  Future<TaskItem> restoreTask(TaskItem task) async {
    final stored = _store.tasks[task.id];
    final map = stored != null
        ? Map<String, dynamic>.from(stored)
        : task.toMap();
    map['deletedAt'] = null;
    map['updatedAt'] = DateTime.now().toIso8601String();
    _store.tasks[task.id] = map;
    await _store.commit();
    final restored = _store.tasks[task.id];
    if (restored == null) return task.copyWith(clearDeleted: true);
    return TaskItem.fromMap(restored);
  }

  @override
  Future<void> permanentlyDelete(String taskId) async {
    _store.tasks.remove(taskId);
    await _store.commit();
  }

  @override
  Future<void> emptyTrash(String familyId) async {
    final ids = _list(familyId, trashed: true).map((task) => task.id).toList();
    for (final id in ids) {
      _store.tasks.remove(id);
    }
    await _store.commit();
  }

  List<TaskItem> _list(String familyId, {required bool trashed}) {
    return _store.tasks.values
        .map(TaskItem.fromMap)
        .where((task) => task.familyId == familyId && task.isTrashed == trashed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
