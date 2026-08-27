import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/appearance.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/family_member_item.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final familyAsync = ref.watch(currentFamilyProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final tasks = ref.watch(familyTasksProvider).valueOrNull ?? const [];
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyMembers)),
      body: familyAsync.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(currentFamilyProvider),
        ),
        data: (family) {
          if (family == null) {
            return EmptyState(
              title: l10n.emptyMembers,
              message: l10n.familySetupSubtitle,
            );
          }
          return membersAsync.when(
            loading: () => LoadingView(label: l10n.loading),
            error: (_, _) => ErrorView(
              message: l10n.errorUnavailable,
              retryLabel: l10n.retry,
              onRetry: () => ref.invalidate(familyMembersProvider),
            ),
            data: (members) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    l10n.familyOverview,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    family.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.membersSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.memberCount(members.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.openFamilyTasks}: ${tasks.where((task) => task.type == TaskType.family && task.isOpen).length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.sharedFamilyInfo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.privateSpaceHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: family.inviteCode),
                      );
                      if (context.mounted) {
                        AppNotice.show(context, l10n.copied);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.palette.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.inviteCodeLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  family.inviteCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.copy_rounded, color: context.palette.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.inviteMember,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.inviteMemberMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(l10n.familySpace),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => context.push('/space/family'),
                  ),
                  const SizedBox(height: 8),
                  if (members.isEmpty)
                    EmptyState(
                      title: l10n.emptyMembers,
                      message: l10n.membersSubtitle,
                    )
                  else
                    ...members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FamilyMemberItem(
                          member: member,
                          openTaskCount: FamilyMemberItem.openCountFor(
                            member.id,
                            tasks,
                          ),
                          isCurrentUser: member.id == user?.id,
                          youLabel: l10n.you,
                          onTap: () =>
                              context.push('/family/members/${member.id}'),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
