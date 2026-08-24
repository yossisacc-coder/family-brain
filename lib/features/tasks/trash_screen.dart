import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(trashedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trash),
        actions: [
          IconButton(
            tooltip: l10n.emptyTrash,
            onPressed: () => _emptyTrash(context, ref, l10n),
            icon: const Icon(Icons.delete_forever_outlined),
          ),
        ],
      ),
      body: async.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(trashedTasksProvider),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return EmptyState(
              title: l10n.noTrashYet,
              message: l10n.noTrashMessage,
              icon: Icons.delete_outline,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  onTap: () => context.push('/tasks/${task.id}'),
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.trash,
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(color: AppColors.trash),
                  ),
                  subtitle: Text(
                    task.deletedAt == null
                        ? l10n.trash
                        : DateFormat.yMMMd().add_jm().format(task.deletedAt!),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: l10n.restoreTask,
                        onPressed: () => _restore(context, ref, task, l10n),
                        icon: const Icon(Icons.restore_rounded),
                      ),
                      IconButton(
                        tooltip: l10n.permanentlyDelete,
                        onPressed: () =>
                            _permanentlyDelete(context, ref, task, l10n),
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) async {
    await ref.read(taskRepositoryProvider).restoreTask(task);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.taskRestored)),
    );
  }

  Future<void> _permanentlyDelete(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permanentlyDeleteTitle),
        content: Text(l10n.permanentlyDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.permanentlyDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(taskRepositoryProvider).permanentlyDelete(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.taskDeletedForever)),
    );
  }

  Future<void> _emptyTrash(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final family = ref.read(currentFamilyProvider).valueOrNull;
    if (family == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.emptyTrashTitle),
        content: Text(l10n.emptyTrashMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.emptyTrash),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(taskRepositoryProvider).emptyTrash(family.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.trashEmptied)),
    );
  }
}
