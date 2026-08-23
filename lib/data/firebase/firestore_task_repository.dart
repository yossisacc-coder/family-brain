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
    return _col
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snap) {
      final tasks = snap.docs.map((doc) => TaskItem.fromMap(doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
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
}
