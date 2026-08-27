import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/local_reminder_scheduler.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/appearance.dart';
import '../../core/theme/task_semantics.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/task_trash.dart';
import '../../data/providers.dart';
import '../../domain/models/family_activity.dart';
import '../../domain/models/task_item.dart';
import '../activity/record_activity.dart';

class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(familyTasksProvider);
    final trashAsync = ref.watch(trashedTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    final task = [
      ...?tasksAsync.valueOrNull,
      ...?trashAsync.valueOrNull,
    ].where((item) => item.id == taskId).firstOrNull;
    if (task == null) {
      if (tasksAsync.isLoading || trashAsync.isLoading) {
        return Scaffold(body: LoadingView(label: l10n.loading));
      }
      if (tasksAsync.hasError || trashAsync.hasError) {
        return Scaffold(
          body: ErrorView(
            message: l10n.errorUnavailable,
            retryLabel: l10n.retry,
            onRetry: () {
              ref.invalidate(familyTasksProvider);
              ref.invalidate(trashedTasksProvider);
            },
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(l10n.taskDetails)),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }
    final assignee =
        members.where((member) => member.id == task.assigneeId).firstOrNull;
    final creator =
        members.where((member) => member.id == task.creatorId).firstOrNull;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetails),
        actions: [
          if (!task.isTrashed)
            IconButton(
              tooltip: l10n.edit,
              onPressed: () => context.push('/tasks/${task.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        key: const Key('task-details-view'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            task.title,
            key: const Key('task-details-title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (task.notes != null && task.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              task.notes!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.4,
                    color: palette.textMuted,
                  ),
            ),
          ],
          const SizedBox(height: 18),
          _DetailsCard(
            children: [
              _labeledValue(
                context,
                l10n.changeStatus,
                TaskSemantics.statusLabel(l10n, task.status),
                icon: TaskSemantics.statusIcon(task.status),
                color: TaskSemantics.statusColor(
                  task.status,
                  muted: palette.textMuted,
                ),
              ),
              _labeledValue(
                context,
                l10n.priority,
                TaskSemantics.priorityLabel(l10n, task.priority),
                icon: TaskSemantics.priorityIcon(task.priority),
                color: TaskSemantics.priorityColor(
                  task.priority,
                  primary: palette.primary,
                  muted: palette.textMuted,
                ),
              ),
              _labeledValue(
                context,
                l10n.dueDate,
                task.dueDate == null
                    ? l10n.noDueDate
                    : (task.hasDueTime
                            ? DateFormat.yMMMd().add_jm()
                            : DateFormat.yMMMd())
                        .format(task.dueDate!.toLocal()),
                icon: Icons.event_outlined,
              ),
              _labeledValue(
                context,
                l10n.assignee,
                assignee?.name ?? l10n.unassigned,
                icon: Icons.person_outline,
              ),
              _labeledValue(
                context,
                l10n.taskType,
                task.type == TaskType.personal ? l10n.personal : l10n.familyType,
                icon: task.type == TaskType.personal
                    ? Icons.person_outline
                    : Icons.groups_outlined,
                last: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const Key('task-details-more'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              iconColor: palette.primary,
              collapsedIconColor: palette.textMuted,
              title: Text(
                l10n.moreDetails,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.primary,
                    ),
              ),
              children: [
                _labeledValue(
                  context,
                  l10n.brainType,
                  switch (task.kind) {
                    InformationKind.task => l10n.kindTask,
                    InformationKind.event => l10n.kindEvent,
                    InformationKind.reminder => l10n.kindReminder,
                    InformationKind.list => l10n.kindList,
                    InformationKind.information => l10n.kindInformation,
                  },
                  icon: switch (task.kind) {
                    InformationKind.event => Icons.event_outlined,
                    InformationKind.reminder => Icons.alarm_outlined,
                    InformationKind.list => Icons.list_alt_rounded,
                    InformationKind.information => Icons.info_outline_rounded,
                    InformationKind.task => Icons.task_alt_rounded,
                  },
                ),
                _labeledValue(
                  context,
                  l10n.reminder,
                  task.reminderAt == null
                      ? l10n.noReminder
                      : DateFormat.yMMMd().add_jm().format(task.reminderAt!),
                  icon: Icons.alarm_outlined,
                ),
                _labeledValue(
                  context,
                  l10n.createdBy,
                  '${creator?.name ?? l10n.unassigned} · ${DateFormat.yMMMd().format(task.createdAt)}',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (task.isTrashed) ...[
            PrimaryButton(
              label: l10n.restoreTask,
              icon: Icons.restore_rounded,
              onPressed: () => _restore(context, ref, task, l10n),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _permanentlyDelete(context, ref, task, l10n),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.permanentlyDelete),
            ),
          ] else ...[
            if (task.status != TaskStatus.completed)
              PrimaryButton(
                label: l10n.markCompleted,
                icon: Icons.check_rounded,
                onPressed: () => _complete(context, ref, task, l10n),
              )
            else
              PrimaryButton(
                label: l10n.reopenTask,
                icon: Icons.replay_rounded,
                onPressed: () => _reopen(context, ref, task, l10n),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/tasks/${task.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.edit),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _confirmDelete(context, ref, task, l10n),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.deleteTask),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labeledValue(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? color,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? context.palette.textMuted),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color ?? context.palette.text,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final family = ref.read(currentFamilyProvider).valueOrNull;
    final updated = await ref.read(taskRepositoryProvider).updateTask(
          task.copyWith(status: TaskStatus.completed, updatedAt: DateTime.now()),
        );
    await LocalReminderScheduler.sync(updated);
    if (user != null && family != null) {
      await ref.read(notificationServiceProvider).notifyTaskCompleted(
            task: updated,
            actor: user,
            memberIds: family.memberIds,
            title: l10n.taskCompletedNotif(user.name, updated.title),
            message: updated.title,
          );
    }
    await recordFamilyActivity(
      ref,
      type: ActivityType.taskCompleted,
      summary: updated.title,
      task: updated,
    );
    if (!context.mounted) return;
    context.pop();
    AppNotice.showAfterNavigation(l10n.taskCompleted);
  }

  Future<void> _reopen(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) async {
    await ref.read(taskRepositoryProvider).updateTask(
          task.copyWith(
            status: TaskStatus.pending,
            updatedAt: DateTime.now(),
          ),
        );
    await LocalReminderScheduler.sync(
      task.copyWith(status: TaskStatus.pending, updatedAt: DateTime.now()),
    );
    if (!context.mounted) return;
    AppNotice.show(context, l10n.taskReopened);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) {
    return TaskTrash.confirmAndMove(
      context: context,
      ref: ref,
      task: task,
      l10n: l10n,
      popAfter: true,
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) async {
    await ref.read(taskRepositoryProvider).restoreTask(task);
    await recordFamilyActivity(
      ref,
      type: ActivityType.taskRestored,
      summary: task.title,
      task: task,
    );
    if (!context.mounted) return;
    context.pop();
    AppNotice.showAfterNavigation(l10n.taskRestored);
  }

  Future<void> _permanentlyDelete(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permanentlyDeleteTitle),
        content: Text(l10n.permanentlyDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.permanentlyDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await LocalReminderScheduler.cancel(task.id);
    await ref.read(taskRepositoryProvider).permanentlyDelete(task.id);
    if (!context.mounted) return;
    context.pop();
    AppNotice.showAfterNavigation(l10n.taskDeletedForever);
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.card,
      borderRadius: AppRadii.card,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          border: Border.all(color: context.palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
