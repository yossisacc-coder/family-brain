import 'package:flutter/material.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../theme/app_colors.dart';

class FamilyMemberItem extends StatelessWidget {
  const FamilyMemberItem({
    super.key,
    required this.member,
    required this.openTaskCount,
    required this.isCurrentUser,
    required this.youLabel,
    this.onTap,
  });

  final AppUser member;
  final int openTaskCount;
  final bool isCurrentUser;
  final String youLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = member.name.isEmpty ? '?' : member.name.characters.first;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primaryDark,
                child: Text(initial.toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUser ? '${member.name} ($youLabel)' : member.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '$openTaskCount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
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
