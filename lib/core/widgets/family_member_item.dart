import 'package:flutter/material.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/appearance.dart';

class FamilyMemberItem extends StatelessWidget {
  const FamilyMemberItem({
    super.key,
    required this.member,
    required this.openTaskCount,
    required this.isCurrentUser,
    required this.youLabel,
    this.onTap,
    this.showPhone = false,
  });

  final AppUser member;
  final int openTaskCount;
  final bool isCurrentUser;
  final String youLabel;
  final VoidCallback? onTap;
  final bool showPhone;

  @override
  Widget build(BuildContext context) {
    final initial = member.name.isEmpty ? '?' : member.name.characters.first;
    final palette = context.palette;
    return Material(
      color: AppColors.card,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: palette.primarySoft,
                foregroundColor: palette.primaryDark,
                child: Text(initial.toUpperCase()),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUser ? '${member.name} ($youLabel)' : member.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (showPhone) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$openTaskCount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.primary,
                    ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static int openCountFor(String userId, List<TaskItem> tasks) {
    return tasks
        .where(
          (task) =>
              task.assigneeId == userId &&
              task.isOpen &&
              task.type == TaskType.family,
        )
        .length;
  }
}
