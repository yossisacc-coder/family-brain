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

class SpaceScreen extends ConsumerWidget {
  const SpaceScreen({super.key, required this.personal});

  final bool personal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tasksAsync = ref.watch(familyTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(personal ? l10n.mySpace : l10n.familySpace),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addTask),
      ),
      body: tasksAsync.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyTasksProvider),
        ),
        data: (all) {
          final tasks = all.where((task) {
            if (personal) {
              if (user == null) return false;
              return task.type == TaskType.personal && task.isVisibleTo(user.id);
            }
            return task.type == TaskType.family;
          }).toList();

          if (tasks.isEmpty) {
            return EmptyState(
              title: personal ? l10n.noMySpaceTasks : l10n.noFamilySpaceTasks,
              message:
                  personal ? l10n.noMySpaceMessage : l10n.noFamilySpaceMessage,
              actionLabel: l10n.addFirstTask,
              onAction: () => context.push('/tasks/new'),
              icon: personal ? Icons.person_outline : Icons.groups_outlined,
            );
          }

          return Column(
            children: [
              if (personal)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    l10n.privateSpaceHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      members: members,
                      onTap: () => context.push('/tasks/${task.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
