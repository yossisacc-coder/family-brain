import '../../domain/models/task_item.dart';

/// Simple on-device answers about stored family information.
class FamilyBrainAsk {
  static String answer({
    required String question,
    required List<TaskItem> visibleTasks,
    required DateTime now,
    String languageCode = 'en',
  }) {
    final q = question.trim().toLowerCase();
    if (q.isEmpty) {
      return languageCode == 'he'
          ? 'כתבו שאלה על המשימות, הרשימות או מה שקורה במשפחה.'
          : 'Ask about tasks, lists, or what is happening in the family.';
    }

    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final open = visibleTasks.where((task) => task.isOpen).toList();

    final wantsBuy = RegExp(
      r'buy|shopping|list|grocer|לקנות|קניות|רשימה',
      unicode: true,
    ).hasMatch(q);
    final wantsToday = RegExp(r'today|היום', unicode: true).hasMatch(q);
    final wantsTomorrow = RegExp(r'tomorrow|מחר', unicode: true).hasMatch(q);
    final wantsReminders = RegExp(r'remind|תזכור', unicode: true).hasMatch(q);

    Iterable<TaskItem> pick = open;
    if (wantsBuy) {
      pick = open.where(
        (task) =>
            task.kind == InformationKind.list ||
            RegExp(r'buy|milk|shop|קני', unicode: true)
                .hasMatch(task.title.toLowerCase()),
      );
    } else if (wantsReminders) {
      pick = open.where((task) => task.hasReminder);
    } else if (wantsTomorrow) {
      pick = open.where((task) => _onDay(task, tomorrow));
    } else if (wantsToday) {
      pick = open.where((task) => _onDay(task, today) || task.isOverdue(now));
    }

    final items = pick.take(8).toList();
    if (items.isEmpty) {
      return languageCode == 'he'
          ? 'אין מידע מתאים שמור כרגע.'
          : 'Nothing matching is stored yet.';
    }

    final lines = items.map((task) {
      final extra = <String>[];
      if (task.dueDate != null) {
        extra.add(_shortDate(task.dueDate!));
      }
      if (task.kind == InformationKind.list && (task.notes ?? '').isNotEmpty) {
        extra.add(task.notes!.split('\n').join(', '));
      }
      return extra.isEmpty ? '• ${task.title}' : '• ${task.title} (${extra.join(' · ')})';
    });

    final header = languageCode == 'he' ? 'Family Brain מצא:' : 'Family Brain found:';
    return '$header\n${lines.join('\n')}';
  }

  static bool _onDay(TaskItem task, DateTime day) {
    final due = task.dueDate;
    if (due != null) {
      return due.year == day.year && due.month == day.month && due.day == day.day;
    }
    final reminder = task.reminderAt;
    if (reminder != null) {
      return reminder.year == day.year &&
          reminder.month == day.month &&
          reminder.day == day.day;
    }
    return false;
  }

  static String _shortDate(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final hasTime = value.hour != 0 || value.minute != 0;
    final date = '${value.day}/${value.month}';
    return hasTime ? '$date $hh:$mm' : date;
  }
}
