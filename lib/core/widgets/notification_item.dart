import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../domain/models/app_notification.dart';
import '../theme/appearance.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDelete,
    this.unreadLabel,
    this.deleteLabel,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? unreadLabel;
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: notification.read ? palette.card : palette.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Icon(
                    switch (notification.type) {
                      NotificationType.taskAssigned =>
                        Icons.assignment_ind_outlined,
                      NotificationType.taskCompleted => Icons.task_alt_rounded,
                      NotificationType.taskDueTomorrow =>
                        Icons.event_available_outlined,
                      NotificationType.familyJoined =>
                        Icons.group_add_outlined,
                      NotificationType.sharedUpdated =>
                        Icons.update_outlined,
                    },
                    color: notification.read
                        ? palette.textMuted
                        : palette.primary,
                  ),
                  if (!notification.read)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: palette.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notification.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                    ),
                    if (!notification.read && unreadLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        unreadLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: deleteLabel ??
                      AppLocalizations.of(context).deleteNotification,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
