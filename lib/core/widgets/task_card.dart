import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/appearance.dart';
import '../theme/task_semantics.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.members = const [],
    this.compact = false,
    this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final List<AppUser> members;
  final bool compact;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final assignee = members.where((m) => m.id == task.assigneeId).firstOrNull;
    final dueLabel = _dueLabel(l10n, task);
    final accent = TaskSemantics.accentFor(task, primary: palette.primary);
    final completed = task.status == TaskStatus.completed;

    return Material(
      color: palette.card,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(
              color: task.isUrgent
                  ? AppColors.urgent.withValues(alpha: 0.35)
                  : palette.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: compact ? 52 : 64,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: completed ? AppColors.completed : null,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (assignee != null)
                          Text(
                            assignee.name.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: palette.textMuted,
                                ),
                          ),
                        if (dueLabel != null)
                          Text(
                            dueLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: task.isOverdue()
                                      ? AppColors.urgent
                                      : palette.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        _StatusBadge(
                          label: TaskSemantics.statusLabel(l10n, task.status),
                          color: TaskSemantics.statusColor(
                            task.status,
                            muted: palette.textMuted,
                          ),
                        ),
                        _StatusBadge(
                          label: TaskSemantics.priorityLabel(l10n, task.priority),
                          color: TaskSemantics.priorityColor(
                            task.priority,
                            primary: palette.primary,
                            muted: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: l10n.deleteTask,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _dueLabel(AppLocalizations l10n, TaskItem task) {
    if (task.dueDate == null) return null;
    if (task.isOverdue()) return l10n.overdue;
    final now = DateTime.now();
    final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    if (due == today) {
      if (task.hasDueTime) {
        final local = task.dueDate!.toLocal();
        return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
      return l10n.today;
    }
    if (due == today.add(const Duration(days: 1))) return l10n.dueTomorrow;
    return '${due.day}/${due.month}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.10),
        borderRadius: AppRadii.chip,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
