import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

/// Shared trash/undo behavior for task list and details.
class TaskTrash {
  static const undoDuration = Duration(seconds: 3);

  static Future<bool> confirm(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTaskTitle),
        content: Text(l10n.deleteTaskMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.moveToTrash),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static SnackBar undoSnackBar({
    required AppLocalizations l10n,
    required VoidCallback onUndo,
  }) {
    return SnackBar(
      content: Text(l10n.taskMovedToTrash),
      duration: undoDuration,
      persist: false,
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: onUndo,
      ),
    );
  }

  static Future<void> move({
    required BuildContext context,
    required WidgetRef ref,
    required TaskItem task,
    required AppLocalizations l10n,
    bool returnToTasks = false,
    VoidCallback? onUndo,
  }) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.moveToTrash(task);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        undoSnackBar(
          l10n: l10n,
          onUndo: () {
            onUndo?.call();
            repo.restoreTask(task);
          },
        ),
      );
    if (returnToTasks) {
      context.go('/app/tasks');
    }
  }

  static Future<void> confirmAndMove({
    required BuildContext context,
    required WidgetRef ref,
    required TaskItem task,
    required AppLocalizations l10n,
    bool returnToTasks = false,
    VoidCallback? onUndo,
  }) async {
    if (!await confirm(context, l10n) || !context.mounted) return;
    await move(
      context: context,
      ref: ref,
      task: task,
      l10n: l10n,
      returnToTasks: returnToTasks,
      onUndo: onUndo,
    );
  }
}
