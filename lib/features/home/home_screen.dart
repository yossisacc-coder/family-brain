import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            final reminders =
                open.where((task) => task.hasReminder).toList();
            final events = open.where((task) => task.dueDate != null).toList();
            final today = _todayItems(open);

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                children: [
                  AppHeader(
                    title: _greeting(l10n, user.name),
                    subtitle: l10n.appTitle,
                    unreadCount: unread,
                    onNotifications: () => context.push('/notifications'),
                    onSettings: () => context.go('/app/settings'),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.membersLabel,
                        value: members.length,
                        icon: Icons.groups_outlined,
                        color: AppColors.primary,
                        background: AppColors.primarySoft,
                        onTap: () => context.go('/app/family'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.tasks,
                        value: open.length,
                        icon: Icons.check_circle_outline,
                        color: AppColors.action,
                        background: AppColors.actionSoft,
                        onTap: () => context.go('/app/tasks'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.reminders,
                        value: reminders.length,
                        icon: Icons.alarm_outlined,
                        color: AppColors.success,
                        background: AppColors.successSoft,
                        onTap: () => context.push('/tasks/calendar'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.events,
                        value: events.length,
                        icon: Icons.event_outlined,
                        color: AppColors.primaryDark,
                        background: AppColors.surface,
                        onTap: () => context.push('/tasks/calendar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  AppSectionHeader(title: l10n.quickAccess),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.calendar,
                          onTap: () => context.push('/tasks/calendar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.checklist_rounded,
                          label: l10n.tasks,
                          onTap: () => context.go('/app/tasks'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.person_outline,
                          label: l10n.mySpace,
                          onTap: () => context.push('/space/personal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.groups_outlined,
                          label: l10n.familySpace,
                          onTap: () => context.push('/space/family'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ComposerCard(
                    controller: _composer,
                    onSubmit: () => _submitComposer(context, l10n),
                    onComingSoon: () => _comingSoon(context, l10n),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  AppSectionHeader(
                    title: l10n.todayActivity,
                    actionLabel: l10n.seeAllTasks,
                    onAction: () => context.go('/app/tasks'),
                  ),
                  if (today.isEmpty)
                    EmptyState(
                      title: l10n.noUpcoming,
                      message: l10n.emptyTasksMessage,
                      actionLabel: l10n.addFirstTask,
                      onAction: () => context.push('/tasks/new'),
                      icon: Icons.wb_sunny_outlined,
                    )
                  else
                    ...today.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TaskCard(
                          task: task,
                          members: members,
                          compact: true,
                          onTap: () => context.push('/tasks/${task.id}'),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _FamilyMembersRow(
                    members: members,
                    currentUserId: user.id,
                    familyName: family?.name ?? l10n.currentFamily,
                    onViewFamily: () => context.go('/app/family'),
                    onAdd: () => context.go('/app/family'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<TaskItem> _todayItems(List<TaskItem> open) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matches = open.where((task) {
      if (task.dueDate != null) {
        final due = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (due == today || task.isOverdue(now)) return true;
      }
      if (task.reminderAt != null) {
        final reminder = DateTime(
          task.reminderAt!.year,
          task.reminderAt!.month,
          task.reminderAt!.day,
        );
        if (reminder == today) return true;
      }
      return task.isUrgent;
    }).toList();
    matches.sort((a, b) {
      final aTime = a.dueDate ?? a.reminderAt ?? a.createdAt;
      final bTime = b.dueDate ?? b.reminderAt ?? b.createdAt;
      return aTime.compareTo(bTime);
    });
    return matches.take(4).toList();
  }

  void _comingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  void _submitComposer(BuildContext context, AppLocalizations l10n) {
    final text = _composer.text.trim();
    context.push('/tasks/new', extra: {'title': text});
    _composer.clear();
  }

  String _greeting(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning(name);
    if (hour < 17) return l10n.greetingAfternoon(name);
    return l10n.greetingEvening(name);
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.onSubmit,
    required this.onComingSoon,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primary.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.sendToFamilyBrain,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addToFamilyBrainHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: l10n.tellFamilyBrain,
              filled: true,
              fillColor: AppColors.card,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: l10n.attachInformation,
                onPressed: onComingSoon,
                icon: const Icon(Icons.attach_file_outlined),
              ),
              IconButton(
                tooltip: l10n.voiceInput,
                onPressed: onComingSoon,
                icon: const Icon(Icons.mic_none_rounded),
              ),
              IconButton(
                tooltip: l10n.askAi,
                onPressed: onComingSoon,
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
              const Spacer(),
              IconButton.filled(
                tooltip: l10n.sendToFamilyBrain,
                onPressed: onSubmit,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FamilyMembersRow extends StatelessWidget {
  const _FamilyMembersRow({
    required this.members,
    required this.currentUserId,
    required this.familyName,
    required this.onViewFamily,
    required this.onAdd,
  });

  final List<AppUser> members;
  final String currentUserId;
  final String familyName;
  final VoidCallback onViewFamily;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      onTap: onViewFamily,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.family,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      familyName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.viewFamily,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.action,
                    ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.action,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == members.length) {
                  return _MemberAvatar(
                    label: l10n.addFamilyMember,
                    onTap: onAdd,
                    isAdd: true,
                  );
                }
                final member = members[index];
                return _MemberAvatar(
                  label: member.id == currentUserId
                      ? l10n.you
                      : member.name.split(' ').first,
                  initial: member.name,
                  onTap: () => context.push('/family/members/${member.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.label,
    required this.onTap,
    this.initial,
    this.isAdd = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? initial;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final letter = (initial == null || initial!.isEmpty)
        ? '+'
        : initial!.characters.first.toUpperCase();
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.icon,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  isAdd ? AppColors.card : AppColors.primarySoft,
              foregroundColor: AppColors.primaryDark,
              child: isAdd
                  ? const Icon(Icons.add_rounded, color: AppColors.primary)
                  : Text(letter),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
