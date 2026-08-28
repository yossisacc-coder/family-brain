import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/appearance.dart';
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

          final markedDays = <DateTime>{};
          for (final task in dated) {
            if (!task.isTrashed &&
                (user == null || task.isVisibleTo(user.id))) {
              if (task.dueDate != null) {
                markedDays.add(CalendarDayQuery.dateOnly(task.dueDate!));
              }
              if (task.reminderAt != null) {
                markedDays.add(CalendarDayQuery.dateOnly(task.reminderAt!));
              }
            }
          }

          return Column(
            children: [
              _FamilyMonthCalendar(
                selected: _selected,
                markedDays: markedDays,
                onSelect: (value) => setState(() => _selected = value),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.calendarItemsForDay,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            children: [
                              for (final group in _groupsForDay(l10n, forDay)) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    group.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: context.palette.textMuted,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                for (var i = 0; i < group.items.length; i++) ...[
                                  TaskCard(
                                    key: Key(
                                      'open-related-task-${group.items[i].id}',
                                    ),
                                    task: group.items[i],
                                    members: members,
                                    onTap: () => context
                                        .push('/tasks/${group.items[i].id}'),
                                  ),
                                  if (i != group.items.length - 1)
                                    const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 12),
                              ],
                            ],
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

  List<({String label, List<TaskItem> items})> _groupsForDay(
    AppLocalizations l10n,
    List<TaskItem> forDay,
  ) {
    final events = forDay
        .where((task) => task.kind == InformationKind.event)
        .toList();
    final reminders = forDay
        .where((task) => task.kind == InformationKind.reminder || task.hasReminder)
        .where((task) => task.kind != InformationKind.event)
        .toList();
    final tasks = forDay
        .where(
          (task) =>
              task.kind != InformationKind.event &&
              task.kind != InformationKind.reminder &&
              !reminders.contains(task),
        )
        .toList();
    return [
      if (events.isNotEmpty) (label: l10n.calendarGroupEvents, items: events),
      if (tasks.isNotEmpty) (label: l10n.calendarGroupTasks, items: tasks),
      if (reminders.isNotEmpty)
        (label: l10n.calendarGroupReminders, items: reminders),
    ];
  }
}

class _FamilyMonthCalendar extends StatelessWidget {
  const _FamilyMonthCalendar({
    required this.selected,
    required this.markedDays,
    required this.onSelect,
  });

  final DateTime selected;
  final Set<DateTime> markedDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final month = DateTime(selected.year, selected.month);
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7; // Monday-first
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = CalendarDayQuery.dateOnly(DateTime.now());
    final selectedDay = CalendarDayQuery.dateOnly(selected);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(month);
    final weekdays = List.generate(7, (i) {
      final day = DateTime(2023, 1, 2 + i); // Monday
      return DateFormat.E(locale).format(day);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                    onPressed: () => onSelect(DateTime(month.year, month.month - 1, 1)),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSelect(today),
                    child: Text(l10n.calendarToday),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                    onPressed: () => onSelect(DateTime(month.year, month.month + 1, 1)),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final label in weekdays)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (var row = 0; row < 6; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: _dayCell(
                            context,
                            index: row * 7 + col,
                            startOffset: startOffset,
                            daysInMonth: daysInMonth,
                            month: month,
                            today: today,
                            selectedDay: selectedDay,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(
    BuildContext context, {
    required int index,
    required int startOffset,
    required int daysInMonth,
    required DateTime month,
    required DateTime today,
    required DateTime selectedDay,
  }) {
    final palette = context.palette;
    final dayNum = index - startOffset + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 40);
    }
    final date = DateTime(month.year, month.month, dayNum);
    final isSelected = date == selectedDay;
    final isToday = date == today;
    final hasItems = markedDays.contains(date);
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => onSelect(date),
      child: SizedBox(
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primary
                    : isToday
                        ? palette.primarySoft
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$dayNum',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? palette.onPrimary
                          : isToday
                              ? palette.primary
                              : palette.text,
                    ),
              ),
            ),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasItems
                    ? (isSelected ? palette.onPrimary : palette.homeEvents)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
