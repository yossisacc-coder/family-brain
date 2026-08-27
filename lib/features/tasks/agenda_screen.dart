import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

enum AgendaKind { events, reminders }

/// Filtered Events or Reminders list. Each item is a saved TaskItem, so
/// "Open related task" reuses the existing task details screen.
class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key, required this.kind});

  final AgendaKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tasksAsync = ref.watch(familyTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];
    final isEvents = kind == AgendaKind.events;

    return Scaffold(
      appBar: AppBar(title: Text(isEvents ? l10n.events : l10n.reminders)),
      body: tasksAsync.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyTasksProvider),
        ),
        data: (all) {
          final items = all
              .where((task) => user == null || task.isVisibleTo(user.id))
              .where((task) => isEvents ? _isEvent(task) : _isReminder(task))
              .toList()
            ..sort((a, b) {
              final aTime = isEvents
                  ? (a.dueDate ?? a.reminderAt ?? a.createdAt)
                  : (a.reminderAt ?? a.dueDate ?? a.createdAt);
              final bTime = isEvents
                  ? (b.dueDate ?? b.reminderAt ?? b.createdAt)
                  : (b.reminderAt ?? b.dueDate ?? b.createdAt);
              return aTime.compareTo(bTime);
            });

          if (items.isEmpty) {
            return EmptyState(
              title: isEvents ? l10n.noEvents : l10n.noReminders,
              message: isEvents ? l10n.noEventsMessage : l10n.noRemindersMessage,
              icon: isEvents
                  ? Icons.event_outlined
                  : Icons.notifications_none_rounded,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = items[index];
              return _AgendaRow(
                task: task,
                members: members,
                openLabel: l10n.openRelatedTask,
                onOpenTask: () => context.push('/tasks/${task.id}'),
              );
            },
          );
        },
      ),
    );
  }

  static bool _isEvent(TaskItem task) {
    return task.kind == InformationKind.event || task.dueDate != null;
  }

  static bool _isReminder(TaskItem task) {
    return task.kind == InformationKind.reminder || task.hasReminder;
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.task,
    required this.members,
    required this.openLabel,
    required this.onOpenTask,
  });

  final TaskItem task;
  final List<AppUser> members;
  final String openLabel;
  final VoidCallback onOpenTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskCard(
          task: task,
          members: members,
          onTap: onOpenTask,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: Key('open-related-task-${task.id}'),
            onPressed: onOpenTask,
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            label: Text(openLabel),
          ),
        ),
      ],
    );
  }
}
