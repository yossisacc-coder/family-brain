import 'dart:async';

import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

/// Shared trash/undo behavior for task list and details.
class TaskTrash {
  static const undoDuration = Duration(seconds: 3);
  static const undoButtonKey = Key('task-trash-undo');

  static OverlayEntry? _entry;
  static Timer? _timer;

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

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  /// Snackbar-like Undo toast on the root overlay so nested scaffolds, the
  /// bottom nav, and the Add task button cannot cover or steal it.
  static void showUndo({
    BuildContext? context,
    required AppLocalizations l10n,
    required VoidCallback onUndo,
  }) {
    dismiss();
    final overlay = rootNavigatorKey.currentState?.overlay ??
        (context != null && context.mounted
            ? Overlay.maybeOf(context, rootOverlay: true)
            : null);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset + 88,
          child: Material(
            color: const Color(0xFF323232),
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.taskMovedToTrash,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    key: undoButtonKey,
                    onPressed: () {
                      dismiss();
                      onUndo();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primarySoft,
                      minimumSize: const Size(72, 44),
                    ),
                    child: Text(l10n.undo),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(undoDuration, dismiss);
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

    showUndo(
      context: context,
      l10n: l10n,
      onUndo: () {
        onUndo?.call();
        repo.restoreTask(task);
      },
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
