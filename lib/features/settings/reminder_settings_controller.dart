import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/local_reminder_scheduler.dart';

class ReminderSettingsController extends StateNotifier<bool> {
  ReminderSettingsController() : super(true) {
    _load();
  }

  static const key = 'family_brain.reminder_notifications';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(key);
    if (stored != null) {
      state = stored;
      LocalReminderScheduler.notificationsEnabled = stored;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    LocalReminderScheduler.notificationsEnabled = enabled;
    LocalReminderScheduler.invalidateSyncCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }
}

final reminderSettingsControllerProvider =
    StateNotifierProvider<ReminderSettingsController, bool>((ref) {
  return ReminderSettingsController();
});
