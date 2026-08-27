import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
    final accent = TaskSemantics.accentFor(task, primary: palette.primary);
    final completed = task.status == TaskStatus.completed;
    final dueLine = _dueLine(l10n, task);
    final who = assignee?.name ??
        (task.type == TaskType.personal ? l10n.personal : l10n.familyType);
    final scope = task.type == TaskType.personal ? l10n.personal : l10n.familyType;

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
                height: compact ? 56 : 72,
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
                            fontWeight: FontWeight.w800,
                            color: completed ? AppColors.completed : null,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (dueLine != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dueLine,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: task.isOverdue()
                                  ? AppColors.urgent
                                  : palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      assignee == null ? scope : '$who · $scope',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.text,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.changeStatus}: ${TaskSemantics.statusLabel(l10n, task.status)} · ${l10n.priority}: ${TaskSemantics.priorityLabel(l10n, task.priority)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TaskSemantics.priorityColor(
                              task.priority,
                              primary: palette.primary,
                              muted: palette.textMuted,
                            ),
                          ),
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

  String? _dueLine(AppLocalizations l10n, TaskItem task) {
    if (task.dueDate == null) return task.hasReminder ? l10n.reminder : null;
    if (task.isOverdue()) return l10n.overdue;
    final due = task.dueDate!.toLocal();
    final now = DateTime.now();
    final day = DateTime(due.year, due.month, due.day);
    final today = DateTime(now.year, now.month, now.day);
    final dateLabel = day == today
        ? l10n.today
        : day == today.add(const Duration(days: 1))
            ? l10n.dueTomorrow
            : DateFormat.MMMd().format(due);
    if (!task.hasDueTime) return dateLabel;
    return '$dateLabel · ${DateFormat.Hm().format(due)}';
  }
}
