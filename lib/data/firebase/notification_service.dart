import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/app_notification.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/user_repository.dart';

class NotificationService {
  NotificationService({
    required NotificationRepository notifications,
    required UserRepository users,
  })  : _notifications = notifications,
        _users = users;

  final NotificationRepository _notifications;
  final UserRepository _users;
  final _uuid = const Uuid();

  Future<void> initializePush(AppUser user) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await messaging.getToken();
      if (token != null && token != user.fcmToken) {
        await _users.saveUser(user.copyWith(fcmToken: token));
      }
    } catch (error) {
      debugPrint('Push notifications unavailable: $error');
    }
  }

  Future<void> notifyTaskAssigned({
    required TaskItem task,
    required AppUser actor,
    required String title,
    required String message,
  }) async {
    if (task.assigneeId == null || task.assigneeId == actor.id) return;
    await _notifications.addNotification(
      AppNotification(
        id: _uuid.v4(),
        userId: task.assigneeId!,
        familyId: task.familyId,
        type: NotificationType.taskAssigned,
        title: title,
        message: message,
        read: false,
        createdAt: DateTime.now(),
        taskId: task.id,
      ),
    );
  }

  Future<void> notifyTaskCompleted({
    required TaskItem task,
    required AppUser actor,
    required List<String> memberIds,
    required String title,
    required String message,
  }) async {
    final recipients = memberIds.where((id) => id != actor.id);
    for (final userId in recipients) {
      await _notifications.addNotification(
        AppNotification(
          id: _uuid.v4(),
          userId: userId,
          familyId: task.familyId,
          type: NotificationType.taskCompleted,
          title: title,
          message: message,
          read: false,
          createdAt: DateTime.now(),
          taskId: task.id,
        ),
      );
    }
  }

  Future<void> notifyDueTomorrow({
    required TaskItem task,
    required String title,
    required String message,
  }) async {
    if (task.assigneeId == null) return;
    await _notifications.addNotification(
      AppNotification(
        id: _uuid.v4(),
        userId: task.assigneeId!,
        familyId: task.familyId,
        type: NotificationType.taskDueTomorrow,
        title: title,
        message: message,
        read: false,
        createdAt: DateTime.now(),
        taskId: task.id,
      ),
    );
  }

  Future<void> scanDueTomorrow({
    required List<TaskItem> tasks,
    required String title,
    required String message,
  }) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final target = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    for (final task in tasks) {
      if (task.dueDate == null || !task.isOpen || task.assigneeId == null) {
        continue;
      }
      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      if (due == target) {
        await notifyDueTomorrow(
          task: task,
          title: title,
          message: message,
        );
      }
    }
  }
}
