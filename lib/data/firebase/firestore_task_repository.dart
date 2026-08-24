import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('tasks');

  @override
  Stream<List<TaskItem>> watchFamilyTasks(String familyId) {
    return _watch(familyId, trashed: false);
  }

  @override
  Stream<List<TaskItem>> watchTrashedTasks(String familyId) {
    return _watch(familyId, trashed: true);
  }

  Stream<List<TaskItem>> _watch(String familyId, {required bool trashed}) {
    return _col.where('familyId', isEqualTo: familyId).snapshots().map((snap) {
      return snap.docs
          .map((doc) => TaskItem.fromMap(doc.data()))
          .where((task) => task.isTrashed == trashed)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    await _col.doc(task.id).set(task.toMap());
    return task;
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    await _col.doc(task.id).set(task.toMap(), SetOptions(merge: true));
    return task;
  }

  @override
  Future<TaskItem> moveToTrash(TaskItem task) {
    return updateTask(
      task.copyWith(deletedAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  @override
  Future<TaskItem> restoreTask(TaskItem task) {
    return updateTask(
      task.copyWith(clearDeleted: true, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<void> permanentlyDelete(String taskId) {
    return _col.doc(taskId).delete();
  }

  @override
  Future<void> emptyTrash(String familyId) async {
    final snap = await _col.where('familyId', isEqualTo: familyId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final task = TaskItem.fromMap(doc.data());
      if (task.isTrashed) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
