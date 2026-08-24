import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

/// Shared trash/undo behavior for task list and details.
class TaskTrash {
  static const undoDuration = Duration(seconds: 3);
  static const undoButtonKey = Key('task-trash-undo');

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
    // Keep Undo inside [content] instead of [SnackBar.action]. In this Flutter
    // version an action makes persist default to true, and nested shell/FAB
    // layouts often steal taps from SnackBarAction.
    return SnackBar(
      content: Row(
        children: [
          Expanded(child: Text(l10n.taskMovedToTrash)),
          TextButton(
            key: undoButtonKey,
            onPressed: onUndo,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 40),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(l10n.undo),
          ),
        ],
      ),
      duration: undoDuration,
      persist: false,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  static ScaffoldMessengerState? _messenger(BuildContext? context) {
    return rootScaffoldMessengerKey.currentState ??
        (context != null && context.mounted
            ? ScaffoldMessenger.maybeOf(context)
            : null);
  }

  static void showUndo({
    BuildContext? context,
    required AppLocalizations l10n,
    required VoidCallback onUndo,
  }) {
    final messenger = _messenger(context);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        undoSnackBar(
          l10n: l10n,
          onUndo: () {
            messenger.hideCurrentSnackBar();
            onUndo();
          },
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

    void restore() {
      onUndo?.call();
      repo.restoreTask(task);
    }

    if (returnToTasks) {
      context.go('/app/tasks');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showUndo(
          context: rootNavigatorKey.currentContext,
          l10n: l10n,
          onUndo: restore,
        );
      });
      return;
    }

    showUndo(context: context, l10n: l10n, onUndo: restore);
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
