import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'local_json_store.dart';

class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository(this._store);

  final LocalJsonStore _store;

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) async* {
    yield _list(userId);
    await for (final _ in _store.changes) {
      yield _list(userId);
    }
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    _store.notifications[notification.id] = notification.toMap();
    await _store.commit();
  }

  @override
  Future<void> markRead(String notificationId) async {
    final data = _store.notifications[notificationId];
    if (data == null) return;
    data['read'] = true;
    await _store.commit();
  }

  @override
  Future<void> markAllRead(String userId) async {
    for (final data in _store.notifications.values) {
      if (data['userId'] == userId) {
        data['read'] = true;
      }
    }
    await _store.commit();
  }

  List<AppNotification> _list(String userId) {
    return _store.notifications.values
        .map(AppNotification.fromMap)
        .where((item) => item.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
