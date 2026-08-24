import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
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
    final assignee = members.where((m) => m.id == task.assigneeId).firstOrNull;
    final dueLabel = _dueLabel(l10n, task);
    final accent = TaskSemantics.accentFor(task);
    final completed = task.status == TaskStatus.completed;

    return Material(
      color: AppColors.card,
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
                  : AppColors.border,
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
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          label: TaskSemantics.statusLabel(l10n, task.status),
                          icon: TaskSemantics.statusIcon(task.status),
                          color: TaskSemantics.statusColor(task.status),
                        ),
                        _MetaChip(
                          label: TaskSemantics.priorityLabel(l10n, task.priority),
                          icon: TaskSemantics.priorityIcon(task.priority),
                          color: TaskSemantics.priorityColor(task.priority),
                        ),
                        if (dueLabel != null)
                          _MetaChip(
                            label: dueLabel,
                            icon: Icons.event_outlined,
                            color: task.isOverdue() ? AppColors.urgent : AppColors.textMuted,
                          ),
                        if (task.kind != InformationKind.task)
                          _MetaChip(
                            label: _kindLabel(l10n, task.kind),
                            icon: switch (task.kind) {
                              InformationKind.event => Icons.event_outlined,
                              InformationKind.reminder => Icons.alarm_outlined,
                              InformationKind.list => Icons.list_alt_rounded,
                              InformationKind.task => Icons.task_alt_rounded,
                            },
                          ),
                        if (assignee != null)
                          _MetaChip(
                            label: assignee.name,
                            icon: Icons.person_outline,
                          ),
                        if (!compact)
                          _MetaChip(
                            label: task.type == TaskType.personal
                                ? l10n.personal
                                : l10n.familyType,
                            icon: task.type == TaskType.personal
                                ? Icons.person_outline
                                : Icons.groups_outlined,
                          ),
                        if (task.hasReminder)
                          _MetaChip(
                            label: l10n.reminder,
                            icon: Icons.alarm_outlined,
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
                  color: AppColors.textMuted,
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
    if (due == today) return l10n.today;
    if (due == today.add(const Duration(days: 1))) return l10n.dueTomorrow;
    return '${due.day}/${due.month}';
  }

  String _kindLabel(AppLocalizations l10n, InformationKind kind) {
    return switch (kind) {
      InformationKind.task => l10n.kindTask,
      InformationKind.event => l10n.kindEvent,
      InformationKind.reminder => l10n.kindReminder,
      InformationKind.list => l10n.kindList,
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.10),
        borderRadius: AppRadii.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
