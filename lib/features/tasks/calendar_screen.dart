import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selected = DateTime.now();

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tasksAsync = ref.watch(familyTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendar)),
      body: tasksAsync.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyTasksProvider),
        ),
        data: (all) {
          final tasks = all
              .where((task) => user == null || task.isVisibleTo(user.id))
              .where((task) => task.dueDate != null)
              .toList();
          final selected = _dateOnly(_selected);
          final forDay = tasks.where((task) {
            return _dateOnly(task.dueDate!) == selected;
          }).toList();

          return Column(
            children: [
              CalendarDatePicker(
                initialDate: _selected,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (value) => setState(() => _selected = value),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? EmptyState(
                        title: l10n.noCalendarTasks,
                        message: l10n.noCalendarMessage,
                        actionLabel: l10n.addFirstTask,
                        onAction: () => context.push('/tasks/new'),
                        icon: Icons.calendar_today_outlined,
                      )
                    : forDay.isEmpty
                        ? EmptyState(
                            title: l10n.noCalendarTasks,
                            message: l10n.noCalendarMessage,
                            icon: Icons.event_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: forDay.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final task = forDay[index];
                              return TaskCard(
                                task: task,
                                members: members,
                                onTap: () => context.push('/tasks/${task.id}'),
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
}
