import 'dart:async';

import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class TrashUndoRequest {
  const TrashUndoRequest({required this.task, this.onUndo});

  final TaskItem task;
  final VoidCallback? onUndo;
}

final trashUndoRequestProvider = StateProvider<TrashUndoRequest?>((ref) => null);

/// Shared trash/undo behavior for task list and details.
class TaskTrash {
  static const undoDuration = Duration(seconds: 3);
  static const undoButtonKey = Key('task-trash-undo');

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

  static StateController<TrashUndoRequest?>? _controller;

  static void dismiss([WidgetRef? ref]) {
    _timer?.cancel();
    _timer = null;
    final controller =
        ref?.read(trashUndoRequestProvider.notifier) ?? _controller;
    if (controller != null && controller.mounted) {
      controller.state = null;
    }
    _controller = null;
  }

  static void showUndo({
    required WidgetRef ref,
    required TaskItem task,
    VoidCallback? onUndo,
  }) {
    _timer?.cancel();
    final controller = ref.read(trashUndoRequestProvider.notifier);
    _controller = controller;
    controller.state = TrashUndoRequest(task: task, onUndo: onUndo);
    _timer = Timer(undoDuration, () {
      if (identical(_controller, controller) && controller.mounted) {
        controller.state = null;
      }
    });
  }

  static Future<void> undo(WidgetRef ref) async {
    final request = ref.read(trashUndoRequestProvider);
    if (request == null) return;
    _timer?.cancel();
    _timer = null;
    try {
      await ref.read(taskRepositoryProvider).restoreTask(request.task);
    } finally {
      request.onUndo?.call();
      dismiss(ref);
    }
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
    showUndo(ref: ref, task: task, onUndo: onUndo);
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

/// In-tree Undo banner so it cannot be covered by nested scaffolds or the FAB.
class TrashUndoBar extends ConsumerWidget {
  const TrashUndoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(trashUndoRequestProvider);
    if (request == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFF323232),
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: TaskTrash.undoButtonKey,
        onTap: () => TaskTrash.undo(ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.taskMovedToTrash,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Text(
                l10n.undo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
