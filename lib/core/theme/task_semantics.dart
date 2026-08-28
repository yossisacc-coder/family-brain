import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../domain/models/task_item.dart';
import 'app_colors.dart';

class TaskSemantics {
  static String statusLabel(AppLocalizations l10n, TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => l10n.pending,
      TaskStatus.inProgress => l10n.inProgress,
      TaskStatus.completed => l10n.completed,
    };
  }

  static String priorityLabel(AppLocalizations l10n, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => l10n.low,
      TaskPriority.normal => l10n.normal,
      TaskPriority.high => l10n.high,
      TaskPriority.urgent => l10n.urgent,
    };
  }

  static IconData statusIcon(TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => Icons.radio_button_unchecked,
      TaskStatus.inProgress => Icons.timelapse_rounded,
      TaskStatus.completed => Icons.check_circle_outline,
    };
  }

  static IconData priorityIcon(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => Icons.low_priority_rounded,
      TaskPriority.normal => Icons.flag_outlined,
      TaskPriority.high => Icons.outlined_flag,
      TaskPriority.urgent => Icons.priority_high_rounded,
    };
  }

  static Color statusColor(TaskStatus status, {Color? muted}) {
    return switch (status) {
      TaskStatus.pending => muted ?? AppColors.textMuted,
      TaskStatus.inProgress => AppColors.success,
      TaskStatus.completed => AppColors.completed,
    };
  }

  static Color priorityColor(TaskPriority priority, {Color? primary, Color? muted}) {
    return switch (priority) {
      TaskPriority.low => muted ?? AppColors.textMuted,
      TaskPriority.normal => primary ?? AppColors.primary,
      TaskPriority.high => AppColors.high,
      TaskPriority.urgent => AppColors.urgent,
    };
  }

  static Color accentFor(TaskItem task, {Color? primary}) {
    if (task.isTrashed) return AppColors.trash;
    if (task.status == TaskStatus.completed) return AppColors.completed;
    if (task.status == TaskStatus.inProgress) return AppColors.success;
    if (task.isUrgent) return AppColors.urgent;
    if (task.isHigh || task.isOverdue()) return AppColors.high;
    return switch (task.kind) {
      InformationKind.event => AppColors.homeEvents,
      InformationKind.reminder => AppColors.homeReminders,
      InformationKind.task => AppColors.homeTasks,
      InformationKind.list => AppColors.homeFamily,
      InformationKind.information => primary ?? AppColors.primary,
    };
  }
}
