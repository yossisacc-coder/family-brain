import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/family_activity.dart';
import '../../domain/repositories/activity_repository.dart';

class FirestoreActivityRepository implements ActivityRepository {
  FirestoreActivityRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('activity');

  @override
  Stream<List<FamilyActivity>> watchFamilyActivity({
    required String familyId,
    required String viewerId,
  }) {
    return _col.where('familyId', isEqualTo: familyId).snapshots().map((snap) {
      return snap.docs
          .map((doc) => FamilyActivity.fromMap(doc.data()))
          .where((item) => item.isVisibleTo(viewerId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Future<void> addActivity(FamilyActivity activity) {
    return _col.doc(activity.id).set(activity.toMap());
  }

  @override
  Future<void> deleteActivity(String activityId) {
    return _col.doc(activityId).delete();
  }

  @override
  Future<void> clearFamilyActivity(String familyId) async {
    final snap = await _col.where('familyId', isEqualTo: familyId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
