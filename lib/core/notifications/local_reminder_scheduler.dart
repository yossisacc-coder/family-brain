import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/task_item.dart';

typedef ReminderTap = void Function(String taskId);

/// Schedules OS local notifications for reminder times.
class LocalReminderScheduler {
  LocalReminderScheduler._();

  static final plugin = FlutterLocalNotificationsPlugin();
  static ReminderTap? onTap;
  static var _ready = false;

  static Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) onTap?.call(id);
      },
    );
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> sync(TaskItem task) async {
    if (!_ready) {
      try {
        await initialize();
      } catch (error) {
        debugPrint('Local reminders unavailable: $error');
        return;
      }
    }
    final when = task.reminderAt ??
        (task.kind == InformationKind.reminder ? task.dueDate : null);
    final key = task.id.hashCode.abs() % 100000000;
    await plugin.cancel(key);
    if (when == null || !task.isOpen) return;
    if (!when.isAfter(DateTime.now().add(const Duration(seconds: 15)))) return;
    try {
      await plugin.zonedSchedule(
        key,
        'Family Brain',
        task.title,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'family_brain_reminders',
            'Family Brain reminders',
            channelDescription: 'Reminders for family events and tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );
    } catch (error) {
      debugPrint('Could not schedule exact reminder, using inexact: $error');
      try {
        await plugin.zonedSchedule(
          key,
          'Family Brain',
          task.title,
          tz.TZDateTime.from(when, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'family_brain_reminders',
              'Family Brain reminders',
              channelDescription: 'Reminders for family events and tasks',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      } catch (fallbackError) {
        debugPrint('Reminder schedule failed: $fallbackError');
      }
    }
  }

  static DateTime? scheduledTime(TaskItem task) {
    return task.reminderAt ??
        (task.kind == InformationKind.reminder ? task.dueDate : null);
  }
}
