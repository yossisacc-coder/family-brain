import '../models/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  Future<void> addNotification(AppNotification notification);

  Future<void> markRead(String notificationId);

  Future<void> markAllRead(String userId);

  Future<void> deleteNotification(String notificationId);

  Future<void> clearNotifications(String userId);
}
