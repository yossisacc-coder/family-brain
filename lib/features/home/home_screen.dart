import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';

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
            final urgent = tasks.where((task) => task.isUrgent).toList();
            final mine =
                open.where((task) => task.assigneeId == user.id).toList();
            final preview = [
              ...urgent,
              ...mine.where((task) => !urgent.contains(task)),
              ...open.where(
                (task) => !urgent.contains(task) && !mine.contains(task),
              ),
            ].take(3).toList();

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
                  const SizedBox(height: 16),
                  Text(
                    l10n.needsAttention,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  _ComposerCard(
                    controller: _composer,
                    onSubmit: () => _submitComposer(context, l10n),
                    onComingSoon: () => _comingSoon(context, l10n),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.jumpTo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _JumpChip(
                        icon: Icons.checklist_rounded,
                        label: l10n.viewTasks,
                        onTap: () => context.go('/app/tasks'),
                      ),
                      _JumpChip(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.calendar,
                        onTap: () => context.push('/tasks/calendar'),
                      ),
                      _JumpChip(
                        icon: Icons.person_outline,
                        label: l10n.mySpace,
                        onTap: () => context.push('/space/personal'),
                      ),
                      _JumpChip(
                        icon: Icons.groups_outlined,
                        label: l10n.familySpace,
                        onTap: () => context.push('/space/family'),
                      ),
                      _JumpChip(
                        icon: Icons.notifications_outlined,
                        label: l10n.notifications,
                        badge: unread,
                        onTap: () => context.push('/notifications'),
                      ),
                      _JumpChip(
                        icon: Icons.settings_outlined,
                        label: l10n.goToSettings,
                        onTap: () => context.go('/app/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FamilyMembersRow(
                    members: members,
                    currentUserId: user.id,
                    onAdd: () => context.go('/app/family'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.todayActivity,
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
                ],
              ),
            );
          },
        );
      },
    );
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
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addToFamilyBrain,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.addToFamilyBrainHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 4),
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
                  tooltip: l10n.addToFamilyBrain,
                  onPressed: onSubmit,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMembersRow extends StatelessWidget {
  const _FamilyMembersRow({
    required this.members,
    required this.currentUserId,
    required this.onAdd,
  });

  final List<AppUser> members;
  final String currentUserId;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.familyMembers,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
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
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpChip extends StatelessWidget {
  const _JumpChip({
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
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badge > 0) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 8,
              backgroundColor: AppColors.info,
              child: Text(
                '$badge',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      onPressed: onTap,
      backgroundColor: AppColors.card,
      side: const BorderSide(color: AppColors.border),
    );
  }
}
