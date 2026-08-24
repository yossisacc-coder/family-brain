import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/task_card.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class MemberDetailsScreen extends ConsumerWidget {
  const MemberDetailsScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final membersAsync = ref.watch(familyMembersProvider);
    final tasksAsync = ref.watch(familyTasksProvider);

    return membersAsync.when(
      loading: () => Scaffold(body: LoadingView(label: l10n.loading)),
      error: (_, _) => Scaffold(
        body: ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyMembersProvider),
        ),
      ),
      data: (members) {
        final member = members.where((item) => item.id == memberId).firstOrNull;
        if (member == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.memberDetails)),
            body: Center(child: Text(l10n.errorGeneric)),
          );
        }
        final isYou = member.id == user?.id;
        final showPhone = member.phoneVisibleTo(user?.id ?? '');

        return Scaffold(
          appBar: AppBar(title: Text(l10n.memberDetails)),
          body: tasksAsync.when(
            loading: () => LoadingView(label: l10n.loading),
            error: (_, _) => ErrorView(
              message: l10n.errorUnavailable,
              retryLabel: l10n.retry,
              onRetry: () => ref.invalidate(familyTasksProvider),
            ),
            data: (all) {
              final familyTasks = all
                  .where(
                    (task) =>
                        task.type == TaskType.family &&
                        task.assigneeId == member.id,
                  )
                  .toList();
              final personalTasks = isYou
                  ? all
                      .where(
                        (task) =>
                            task.type == TaskType.personal &&
                            task.isVisibleTo(member.id),
                      )
                      .toList()
                  : const <TaskItem>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primaryDark,
                        child: Text(
                          member.name.isEmpty
                              ? '?'
                              : member.name.characters.first.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isYou
                                  ? '${member.name} (${l10n.you})'
                                  : member.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              showPhone ? member.phone : l10n.phoneNotShared,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _comingSoon(context, l10n),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.messageMember),
                      ),
                      if (showPhone)
                        OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                          onPressed: () => _comingSoon(context, l10n),
                          icon: const Icon(Icons.call_outlined),
                          label: Text(l10n.callMember),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push('/space/family'),
                        icon: const Icon(Icons.folder_shared_outlined),
                        label: Text(l10n.sharedWithMember),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.memberAssignedTasks,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (familyTasks.isEmpty)
                    EmptyState(
                      title: l10n.noFamilySpaceTasks,
                      message: l10n.noFamilySpaceMessage,
                    )
                  else
                    ...familyTasks.map(
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
                  if (isYou) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.mySpace,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (personalTasks.isEmpty)
                      EmptyState(
                        title: l10n.noMySpaceTasks,
                        message: l10n.noMySpaceMessage,
                      )
                    else
                      ...personalTasks.map(
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
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.privateSpaceHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _comingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.comingSoon)),
    );
  }
}
