import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';

import '../../core/theme/appearance.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

/// Lightweight Home timeline row: title, assignee, and time only.
/// Full task fields stay on Task Details.
class HomeDayTask extends StatelessWidget {
  const HomeDayTask({
    super.key,
    required this.task,
    required this.members,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final TaskItem task;
  final List<AppUser> members;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final assignee = members.where((m) => m.id == task.assigneeId).firstOrNull;
    final accent = _accentFor(context, task);
    final time = _timeLabel(task);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 46,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        time ?? '',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 2,
                              color: isFirst
                                  ? Colors.transparent
                                  : palette.border,
                            ),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 2,
                              color: isLast
                                  ? Colors.transparent
                                  : palette.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _MiniAvatar(name: assignee?.name ?? l10n.everyone),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  assignee?.name.split(' ').first ??
                                      l10n.everyone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_kindIcon(task.kind), color: accent, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _timeLabel(TaskItem task) {
    if (task.dueDate != null && task.hasDueTime) {
      return _hhmm(task.dueDate!);
    }
    if (task.reminderAt != null) {
      return _hhmm(task.reminderAt!);
    }
    return null;
  }

  static String _hhmm(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static Color _accentFor(BuildContext context, TaskItem task) {
    return switch (task.kind) {
      InformationKind.event => context.palette.homeEvents,
      InformationKind.task => context.palette.homeTasks,
      InformationKind.reminder => context.palette.homeReminders,
      InformationKind.list => context.palette.homeFamily,
      InformationKind.information => context.palette.primary,
    };
  }

  static IconData _kindIcon(InformationKind kind) {
    return switch (kind) {
      InformationKind.event => Icons.calendar_today_rounded,
      InformationKind.task => Icons.check_circle_outline_rounded,
      InformationKind.reminder => Icons.notifications_none_rounded,
      InformationKind.list => Icons.list_alt_rounded,
      InformationKind.information => Icons.info_outline_rounded,
    };
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 8,
      backgroundColor: context.palette.primarySoft,
      foregroundColor: context.palette.primaryDark,
      child: Text(
        letter,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}
