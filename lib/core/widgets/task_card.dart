import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../theme/app_colors.dart';
import '../theme/task_semantics.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.members = const [],
    this.compact = false,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final List<AppUser> members;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assignee = members.where((m) => m.id == task.assigneeId).firstOrNull;
    final dueLabel = _dueLabel(l10n, task);
    final accent = TaskSemantics.accentFor(task);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: task.isUrgent
                  ? AppColors.urgent.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: task.status == TaskStatus.completed
                                ? AppColors.completed
                                : null,
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(
                          context,
                          task.type == TaskType.personal
                              ? l10n.personal
                              : l10n.familyType,
                          icon: task.type == TaskType.personal
                              ? Icons.person_outline
                              : Icons.groups_outlined,
                        ),
                        _chip(
                          context,
                          TaskSemantics.statusLabel(l10n, task.status),
                          icon: TaskSemantics.statusIcon(task.status),
                          color: TaskSemantics.statusColor(task.status),
                        ),
                        _chip(
                          context,
                          TaskSemantics.priorityLabel(l10n, task.priority),
                          icon: TaskSemantics.priorityIcon(task.priority),
                          color: TaskSemantics.priorityColor(task.priority),
                        ),
                        if (assignee != null)
                          _chip(context, assignee.name, icon: Icons.person_outline),
                        if (dueLabel != null)
                          _chip(
                            context,
                            dueLabel,
                            icon: Icons.event_outlined,
                            color: task.isOverdue() ? AppColors.high : null,
                          ),
                        if (task.hasReminder)
                          _chip(
                            context,
                            l10n.reminder,
                            icon: Icons.alarm_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label, {
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textMuted).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? AppColors.textMuted),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color ?? AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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
}
