import 'package:family_brain/core/notifications/local_reminder_scheduler.dart';
import 'package:family_brain/core/theme/appearance.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:family_brain/features/settings/appearance_controller.dart';
import 'package:family_brain/features/tasks/calendar_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TaskItem task({
  String id = 't1',
  InformationKind kind = InformationKind.task,
  DateTime? due,
  DateTime? reminder,
  TaskStatus status = TaskStatus.pending,
  DateTime? deletedAt,
}) {
  final now = DateTime(2026, 8, 27, 9);
  return TaskItem(
    id: id,
    familyId: 'fam',
    creatorId: 'alex',
    title: id,
    type: TaskType.family,
    kind: kind,
    dueDate: due,
    reminderAt: reminder,
    priority: TaskPriority.normal,
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  setUp(LocalReminderScheduler.debugReset);

  group('CalendarDayQuery', () {
    test('Tuesday selection lists Tuesday items and another day does not', () {
      final tuesday = DateTime(2026, 8, 25);
      final wednesday = DateTime(2026, 8, 26);
      final items = [
        task(id: 'event', kind: InformationKind.event, due: tuesday),
        task(
          id: 'reminder',
          kind: InformationKind.reminder,
          reminder: tuesday.add(const Duration(hours: 15)),
        ),
        task(id: 'later', kind: InformationKind.event, due: wednesday),
      ];

      final tuesdayItems = CalendarDayQuery.itemsForDay(
        tasks: items,
        day: tuesday,
        focus: CalendarFocus.all,
      );
      expect(tuesdayItems.map((item) => item.id), ['event', 'reminder']);

      final wednesdayItems = CalendarDayQuery.itemsForDay(
        tasks: items,
        day: wednesday,
        focus: CalendarFocus.all,
      );
      expect(wednesdayItems.map((item) => item.id), ['later']);
    });

    test('reminder and event focuses keep the existing calendar', () {
      final day = DateTime(2026, 8, 25);
      final items = [
        task(id: 'event', kind: InformationKind.event, due: day),
        task(
          id: 'reminder',
          kind: InformationKind.reminder,
          reminder: day.add(const Duration(hours: 8)),
        ),
        task(id: 'chore', due: day),
      ];
      expect(
        CalendarDayQuery.itemsForDay(
          tasks: items,
          day: day,
          focus: CalendarFocus.events,
        ).map((item) => item.id),
        containsAll(['event', 'chore']),
      );
      expect(
        CalendarDayQuery.itemsForDay(
          tasks: items,
          day: day,
          focus: CalendarFocus.events,
        ).map((item) => item.id),
        isNot(contains('reminder')),
      );
      expect(
        CalendarDayQuery.itemsForDay(
          tasks: items,
          day: day,
          focus: CalendarFocus.reminders,
        ).map((item) => item.id),
        ['reminder'],
      );
    });
  });

  group('LocalReminderScheduler', () {
    test('schedules future reminder times and skips the past', () {
      final now = DateTime(2026, 8, 27, 10);
      final future = task(
        id: 'future',
        kind: InformationKind.reminder,
        reminder: now.add(const Duration(hours: 2)),
      );
      final past = task(
        id: 'past',
        kind: InformationKind.reminder,
        reminder: now.subtract(const Duration(hours: 1)),
      );
      final invalid = task(
        id: 'invalid',
        kind: InformationKind.reminder,
        reminder: DateTime(1800, 1, 1),
      );
      final trashed = task(
        id: 'trashed',
        kind: InformationKind.reminder,
        reminder: now.add(const Duration(hours: 2)),
        deletedAt: now,
      );
      expect(LocalReminderScheduler.shouldSchedule(future, now), isTrue);
      expect(LocalReminderScheduler.shouldSchedule(past, now), isFalse);
      expect(LocalReminderScheduler.shouldSchedule(invalid, now), isFalse);
      expect(LocalReminderScheduler.shouldSchedule(trashed, now), isFalse);
      expect(
        LocalReminderScheduler.scheduledTime(future),
        now.add(const Duration(hours: 2)),
      );
    });

    test('preserves notification ids and does not pretend exact alarms', () {
      LocalReminderScheduler.debugSeedId('keep', 4242);
      expect(LocalReminderScheduler.notificationIdFor('keep'), 4242);
      expect(LocalReminderScheduler.notificationIdFor('keep'), 4242);
      expect(
        LocalReminderScheduler.scheduleMode(exactAllowed: true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
      expect(
        LocalReminderScheduler.scheduleMode(exactAllowed: false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
      expect(LocalReminderScheduler.usesExactAlarms, isFalse);
    });
  });

  test('appearance selection persists', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppearanceController();
    await controller.setMode(AppearanceMode.professional);
    expect(controller.state, AppearanceMode.professional);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.key), 'professional');
  });
}
