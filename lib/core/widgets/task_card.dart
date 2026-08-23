import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../theme/app_colors.dart';

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
              color: task.isUrgent ? AppColors.urgent.withValues(alpha: 0.35) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 46,
                decoration: BoxDecoration(
                  color: task.isUrgent
                      ? AppColors.urgent
                      : task.status == TaskStatus.completed
                          ? AppColors.success
                          : AppColors.primary,
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
                        ),
                        _chip(context, _statusLabel(l10n, task.status)),
                        if (assignee != null) _chip(context, assignee.name),
                        if (dueLabel != null) _chip(context, dueLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => l10n.pending,
      TaskStatus.inProgress => l10n.inProgress,
      TaskStatus.completed => l10n.completed,
    };
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
