import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _col.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final items =
          snap.docs.map((doc) => AppNotification.fromMap(doc.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  @override
  Future<void> addNotification(AppNotification notification) {
    return _col.doc(notification.id).set(notification.toMap());
  }

  @override
  Future<void> markRead(String notificationId) {
    return _col.doc(notificationId).set({
      'read': true,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markAllRead(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
