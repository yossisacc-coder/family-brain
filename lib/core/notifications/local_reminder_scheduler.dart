import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/task_item.dart';

typedef ReminderTap = void Function(String taskId);

/// OS local notifications for reminder date/time.
///
/// Exact alarms are used only when the platform reports they are allowed.
/// Otherwise notifications are scheduled inexactly — never claimed as exact.
class LocalReminderScheduler {
  LocalReminderScheduler._();

  static const channelId = 'family_brain_reminders';
  static const channelName = 'Family Brain reminders';
  static const channelDescription = 'Reminders for family events and tasks';
  static const _idsKey = 'family_brain.reminder_notification_ids';
  static const _grace = Duration(seconds: 15);

  static final plugin = FlutterLocalNotificationsPlugin();
  static ReminderTap? onTap;
  static var _ready = false;
  static var _idsLoaded = false;
  static var _askedPermissions = false;
  static final Map<String, int> _ids = {};
  static bool? _exactAllowed;

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
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
    await _refreshExactPermission(androidPlugin);
    await _loadIds();
    _ready = true;
  }

  static Future<void> ensureReady() async {
    if (_ready) return;
    try {
      await initialize();
    } catch (error) {
      debugPrint('Local reminders unavailable: $error');
    }
  }

  static Future<void> requestPermissionsIfNeeded() async {
    await ensureReady();
    if (_askedPermissions) return;
    _askedPermissions = true;
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    final enabled = await androidPlugin.areNotificationsEnabled() ?? true;
    if (!enabled) {
      await androidPlugin.requestNotificationsPermission();
    }
    await _refreshExactPermission(androidPlugin);
    if (_exactAllowed != true) {
      await androidPlugin.requestExactAlarmsPermission();
      await _refreshExactPermission(androidPlugin);
    }
  }

  static Future<void> _refreshExactPermission(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) {
      _exactAllowed = false;
      return;
    }
    try {
      _exactAllowed = await androidPlugin.canScheduleExactNotifications();
    } catch (_) {
      _exactAllowed = false;
    }
  }

  static bool get usesExactAlarms => _exactAllowed == true;

  static AndroidScheduleMode scheduleMode({bool? exactAllowed}) {
    final allowed = exactAllowed ?? _exactAllowed ?? false;
    return allowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static DateTime? scheduledTime(TaskItem task) {
    return task.reminderAt ??
        (task.kind == InformationKind.reminder ? task.dueDate : null);
  }

  static bool isValidScheduleTime(DateTime? when) {
    if (when == null) return false;
    if (when.year < 2000 || when.year > 2100) return false;
    return true;
  }

  static bool shouldSchedule(TaskItem task, [DateTime? now]) {
    if (!task.isOpen) return false;
    final when = scheduledTime(task);
    if (!isValidScheduleTime(when)) return false;
    return when!.isAfter((now ?? DateTime.now()).add(_grace));
  }

  static int notificationIdFor(String taskId) {
    final existing = _ids[taskId];
    if (existing != null) return existing;
    var hash = taskId.hashCode.abs() % 2147483647;
    if (hash == 0) hash = 1;
    final used = _ids.values.toSet();
    while (used.contains(hash)) {
      hash = (hash + 1) % 2147483647;
      if (hash == 0) hash = 1;
    }
    _ids[taskId] = hash;
    return hash;
  }

  static Future<void> sync(TaskItem task) async {
    await ensureReady();
    if (!_ready) return;
    if (shouldSchedule(task)) {
      await requestPermissionsIfNeeded();
    }
    final key = notificationIdFor(task.id);
    await plugin.cancel(key);
    if (!shouldSchedule(task)) {
      await _persistIds();
      return;
    }
    final when = scheduledTime(task)!;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final zoned = tz.TZDateTime.from(when, tz.local);
    try {
      await plugin.zonedSchedule(
        key,
        'Family Brain',
        task.title,
        zoned,
        details,
        androidScheduleMode: scheduleMode(),
        payload: task.id,
      );
    } catch (error) {
      debugPrint('Reminder schedule failed, retrying inexact: $error');
      _exactAllowed = false;
      try {
        await plugin.zonedSchedule(
          key,
          'Family Brain',
          task.title,
          zoned,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      } catch (fallbackError) {
        debugPrint('Reminder schedule failed: $fallbackError');
      }
    }
    await _persistIds();
  }

  static Future<void> cancel(String taskId) async {
    await ensureReady();
    if (!_ready) return;
    final key = _ids[taskId] ?? notificationIdFor(taskId);
    await plugin.cancel(key);
    await _persistIds();
  }

  static Future<void> syncAll(List<TaskItem> tasks) async {
    await ensureReady();
    if (!_ready) return;
    final seen = <String>{};
    for (final task in tasks) {
      seen.add(task.id);
      await sync(task);
    }
    final stale = _ids.keys.where((id) => !seen.contains(id)).toList();
    for (final id in stale) {
      final key = _ids[id];
      if (key != null) {
        await plugin.cancel(key);
      }
    }
    await _persistIds();
  }

  static Future<void> _loadIds() async {
    if (_idsLoaded) return;
    _idsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_idsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          final id = int.tryParse('$value');
          if (id != null) _ids['$key'] = id;
        });
      }
    } catch (error) {
      debugPrint('Could not load reminder notification ids: $error');
    }
  }

  static Future<void> _persistIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_idsKey, jsonEncode(_ids));
    } catch (_) {}
  }

  @visibleForTesting
  static void debugReset() {
    _ids.clear();
    _idsLoaded = false;
    _ready = false;
    _askedPermissions = false;
    _exactAllowed = null;
  }

  @visibleForTesting
  static void debugSeedId(String taskId, int notificationId) {
    _ids[taskId] = notificationId;
    _idsLoaded = true;
  }

  @visibleForTesting
  static Map<String, int> debugIds() => Map.unmodifiable(_ids);
}
