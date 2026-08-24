import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final tasksAsync = ref.watch(familyTasksProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final unread = ref.watch(unreadCountProvider);

    return userAsync.when(
      loading: () => LoadingView(label: l10n.loading),
      error: (_, _) => ErrorView(
        message: l10n.errorUnavailable,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (user) {
        if (user == null) return LoadingView(label: l10n.loading);
        return tasksAsync.when(
          loading: () => LoadingView(label: l10n.loading),
          error: (_, _) => ErrorView(
            message: l10n.errorUnavailable,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(familyTasksProvider),
          ),
          data: (all) {
            final family = familyAsync.valueOrNull;
            final members = membersAsync.valueOrNull ?? const [];
            final tasks =
                all.where((task) => task.isVisibleTo(user.id)).toList();
            final open = tasks.where((task) => task.isOpen).toList();
            final urgent = tasks.where((task) => task.isUrgent).toList();
            final mine =
                open.where((task) => task.assigneeId == user.id).toList();
            final done = tasks
                .where((task) => task.status == TaskStatus.completed)
                .take(3)
                .toList();
            final preview = [
              ...urgent,
              ...mine.where((task) => !urgent.contains(task)),
              ...open.where(
                (task) => !urgent.contains(task) && !mine.contains(task),
              ),
            ].take(4).toList();

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AppHeader(
                    title: _greeting(l10n, user.name),
                    subtitle: family?.name ?? l10n.currentFamily,
                    unreadCount: unread,
                    onNotifications: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.needsAttention,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.openTasks,
                        value: open.length,
                        color: AppColors.primaryDark,
                        background: AppColors.primarySoft,
                        onTap: () => context.go('/app/tasks'),
                      ),
                      const SizedBox(width: 8),
                      StatCard(
                        label: l10n.urgentTasks,
                        value: urgent.length,
                        color: AppColors.urgent,
                        background: AppColors.urgentSoft,
                        onTap: () => context.go('/app/tasks'),
                      ),
                      const SizedBox(width: 8),
                      StatCard(
                        label: l10n.myTasks,
                        value: mine.length,
                        color: AppColors.success,
                        background: AppColors.successSoft,
                        onTap: () => context.push('/space/personal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.recentlyCompleted,
                        value: done.length,
                        color: AppColors.completed,
                        background: AppColors.card,
                        onTap: () => context.go('/app/tasks'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.quickActions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          label: l10n.addTask,
                          icon: Icons.add_rounded,
                          emphasized: true,
                          onTap: () => context.push('/tasks/new'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickActionCard(
                          label: l10n.viewTasks,
                          icon: Icons.checklist_rounded,
                          onTap: () => context.go('/app/tasks'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickActionCard(
                          label: l10n.familyMembers,
                          icon: Icons.groups_rounded,
                          onTap: () => context.go('/app/family'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.jumpTo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _JumpTile(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.calendar,
                    onTap: () => context.push('/tasks/calendar'),
                  ),
                  _JumpTile(
                    icon: Icons.person_outline,
                    label: l10n.mySpace,
                    onTap: () => context.push('/space/personal'),
                  ),
                  _JumpTile(
                    icon: Icons.groups_outlined,
                    label: l10n.familySpace,
                    onTap: () => context.push('/space/family'),
                  ),
                  _JumpTile(
                    icon: Icons.notifications_outlined,
                    label: l10n.notifications,
                    badge: unread,
                    onTap: () => context.push('/notifications'),
                  ),
                  _JumpTile(
                    icon: Icons.settings_outlined,
                    label: l10n.goToSettings,
                    onTap: () => context.go('/app/settings'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.upcomingTasks,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/app/tasks'),
                        child: Text(l10n.seeAllTasks),
                      ),
                    ],
                  ),
                  if (preview.isEmpty)
                    EmptyState(
                      title: l10n.noTasksYet,
                      message: l10n.emptyTasksMessage,
                      actionLabel: l10n.addFirstTask,
                      onAction: () => context.push('/tasks/new'),
                      icon: Icons.spa_outlined,
                    )
                  else
                    ...preview.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskCard(
                          task: task,
                          members: members,
                          compact: true,
                          onTap: () => context.push('/tasks/${task.id}'),
                        ),
                      ),
                    ),
                  if (preview.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.noUpcoming,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _greeting(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning(name);
    if (hour < 17) return l10n.greetingAfternoon(name);
    return l10n.greetingEvening(name);
  }
}

class _JumpTile extends StatelessWidget {
  const _JumpTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: AppColors.card,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0)
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.info,
                child: Text(
                  '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
