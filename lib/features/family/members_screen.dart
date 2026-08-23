import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/family_member_item.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/providers.dart';

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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    family.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.membersSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.copied)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
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
                          const Icon(Icons.copy_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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
