import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(familyTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    return tasksAsync.when(
      loading: () => Scaffold(body: LoadingView(label: l10n.loading)),
      error: (_, _) => Scaffold(
        body: ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyTasksProvider),
        ),
      ),
      data: (tasks) {
        final task = tasks.where((item) => item.id == taskId).firstOrNull;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.taskDetails)),
            body: Center(child: Text(l10n.errorGeneric)),
          );
        }
        final assignee =
            members.where((member) => member.id == task.assigneeId).firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.taskDetails),
            actions: [
              IconButton(
                onPressed: () => context.push('/tasks/${task.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              _row(context, l10n.changeStatus, _status(l10n, task.status)),
              _row(
                context,
                l10n.assignee,
                assignee?.name ?? l10n.unassigned,
              ),
              _row(
                context,
                l10n.dueDate,
                task.dueDate == null
                    ? l10n.noDueDate
                    : '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
              ),
              _row(
                context,
                l10n.priority,
                task.priority == TaskPriority.urgent ? l10n.urgent : l10n.normal,
              ),
              _row(
                context,
                l10n.taskType,
                task.type == TaskType.personal ? l10n.personal : l10n.familyType,
              ),
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.notes, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(task.notes!),
              ],
              const SizedBox(height: 24),
              Text(l10n.changeStatus, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(_status(l10n, status)),
                    selected: task.status == status,
                    onSelected: (_) => _updateStatus(
                      ref,
                      task,
                      status,
                      l10n,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (task.status != TaskStatus.completed)
                PrimaryButton(
                  label: l10n.markCompleted,
                  icon: Icons.check_rounded,
                  onPressed: () => _updateStatus(
                    ref,
                    task,
                    TaskStatus.completed,
                    l10n,
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.push('/tasks/${task.id}/edit'),
                child: Text(l10n.edit),
              ),
            ],
          ),
        );
      },
    );
  }

  String _status(AppLocalizations l10n, TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => l10n.pending,
      TaskStatus.inProgress => l10n.inProgress,
      TaskStatus.completed => l10n.completed,
    };
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    WidgetRef ref,
    TaskItem task,
    TaskStatus status,
    AppLocalizations l10n,
  ) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final family = ref.read(currentFamilyProvider).valueOrNull;
    final updated = await ref.read(taskRepositoryProvider).updateTask(
          task.copyWith(status: status, updatedAt: DateTime.now()),
        );
    if (status == TaskStatus.completed && user != null && family != null) {
      await ref.read(notificationServiceProvider).notifyTaskCompleted(
            task: updated,
            actor: user,
            memberIds: family.memberIds,
            title: l10n.taskCompletedNotif(user.name, updated.title),
            message: updated.title,
          );
    }
  }
}
