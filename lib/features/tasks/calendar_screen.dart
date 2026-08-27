import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

enum CalendarFocus { all, events, reminders, tasks }

/// Items on the existing Family Brain calendar for a selected day.
class CalendarDayQuery {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool onDay(TaskItem task, DateTime day) {
    final selected = dateOnly(day);
    if (task.dueDate != null && dateOnly(task.dueDate!) == selected) {
      return true;
    }
    if (task.reminderAt != null && dateOnly(task.reminderAt!) == selected) {
      return true;
    }
    return false;
  }

  static bool matchesFocus(TaskItem task, CalendarFocus focus) {
    return switch (focus) {
      CalendarFocus.all => task.dueDate != null || task.reminderAt != null,
      CalendarFocus.events =>
        task.kind == InformationKind.event || task.dueDate != null,
      CalendarFocus.reminders =>
        task.kind == InformationKind.reminder || task.hasReminder,
      CalendarFocus.tasks =>
        task.kind == InformationKind.task ||
            (task.dueDate != null &&
                task.kind != InformationKind.event &&
                task.kind != InformationKind.reminder),
    };
  }

  static List<TaskItem> itemsForDay({
    required List<TaskItem> tasks,
    required DateTime day,
    required CalendarFocus focus,
    String? userId,
  }) {
    return tasks
        .where((task) => userId == null || task.isVisibleTo(userId))
        .where((task) => !task.isTrashed)
        .where((task) => matchesFocus(task, focus))
        .where((task) => onDay(task, day))
        .toList()
      ..sort((a, b) {
        final aTime = a.dueDate ?? a.reminderAt ?? a.createdAt;
        final bTime = b.dueDate ?? b.reminderAt ?? b.createdAt;
        return aTime.compareTo(bTime);
      });
  }
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.focus = CalendarFocus.all});

  final CalendarFocus focus;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tasksAsync = ref.watch(familyTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      body: tasksAsync.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyTasksProvider),
        ),
        data: (all) {
          final forDay = CalendarDayQuery.itemsForDay(
            tasks: all,
            day: _selected,
            focus: widget.focus,
            userId: user?.id,
          );
          final dated = all.where((task) {
            if (user != null && !task.isVisibleTo(user.id)) return false;
            return CalendarDayQuery.matchesFocus(task, widget.focus);
          }).toList();

          return Column(
            children: [
              CalendarDatePicker(
                initialDate: _selected,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (value) => setState(() => _selected = value),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.calendarItemsForDay,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              Expanded(
                child: dated.isEmpty
                    ? EmptyState(
                        title: _emptyTitle(l10n),
                        message: _emptyMessage(l10n),
                        actionLabel: l10n.addFirstTask,
                        onAction: () => context.push('/tasks/new'),
                        icon: _emptyIcon(),
                      )
                    : forDay.isEmpty
                        ? EmptyState(
                            title: _emptyTitle(l10n),
                            message: _emptyMessage(l10n),
                            icon: Icons.event_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: forDay.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final task = forDay[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TaskCard(
                                    task: task,
                                    members: members,
                                    onTap: () =>
                                        context.push('/tasks/${task.id}'),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton.icon(
                                      key: Key('open-related-task-${task.id}'),
                                      onPressed: () =>
                                          context.push('/tasks/${task.id}'),
                                      icon: const Icon(
                                        Icons.task_alt_rounded,
                                        size: 18,
                                      ),
                                      label: Text(l10n.openRelatedTask),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    return switch (widget.focus) {
      CalendarFocus.events => l10n.events,
      CalendarFocus.reminders => l10n.reminders,
      CalendarFocus.tasks => l10n.tasks,
      CalendarFocus.all => l10n.calendar,
    };
  }

  String _emptyTitle(AppLocalizations l10n) {
    return switch (widget.focus) {
      CalendarFocus.events => l10n.noEvents,
      CalendarFocus.reminders => l10n.noReminders,
      CalendarFocus.tasks => l10n.noCalendarTasks,
      CalendarFocus.all => l10n.noCalendarTasks,
    };
  }

  String _emptyMessage(AppLocalizations l10n) {
    return switch (widget.focus) {
      CalendarFocus.events => l10n.noEventsMessage,
      CalendarFocus.reminders => l10n.noRemindersMessage,
      CalendarFocus.tasks => l10n.noCalendarMessage,
      CalendarFocus.all => l10n.noCalendarMessage,
    };
  }

  IconData _emptyIcon() {
    return switch (widget.focus) {
      CalendarFocus.reminders => Icons.notifications_none_rounded,
      CalendarFocus.tasks => Icons.check_circle_outline_rounded,
      CalendarFocus.events => Icons.event_outlined,
      CalendarFocus.all => Icons.calendar_today_outlined,
    };
  }
}
