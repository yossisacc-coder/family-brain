import 'dart:async';

import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';

class TrashUndoRequest {
  const TrashUndoRequest({required this.task, required this.repo, this.onUndo});

  final TaskItem task;
  final TaskRepository repo;
  final VoidCallback? onUndo;
}

final trashUndoRequestProvider = StateProvider<TrashUndoRequest?>(
  (ref) => null,
);

/// Shared trash/undo behavior for task list and details.
class TaskTrash {
  static const undoDuration = Duration(seconds: 3);
  static const slotHold = Duration(milliseconds: 50);
  static const undoButtonKey = Key('task-trash-undo');

  static Timer? _timer;
  static Timer? _releaseTimer;
  static StateController<TrashUndoRequest?>? _controller;
  static TrashUndoRequest? _pending;
  static bool _busy = false;
  static int? _gesturePointer;
  static bool _undoCompleted = false;

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

  static void dismiss([WidgetRef? ref]) {
    _timer?.cancel();
    _timer = null;
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _pending = null;
    _busy = false;
    _gesturePointer = null;
    _undoCompleted = false;
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
    required TaskRepository repo,
    VoidCallback? onUndo,
  }) {
    _timer?.cancel();
    _releaseTimer?.cancel();
    _busy = false;
    _gesturePointer = null;
    _undoCompleted = false;
    final request = TrashUndoRequest(task: task, repo: repo, onUndo: onUndo);
    _pending = request;
    final controller = ref.read(trashUndoRequestProvider.notifier);
    _controller = controller;
    controller.state = request;
    _timer = Timer(undoDuration, () {
      if (!identical(_pending, request)) return;
      _pending = null;
      if (identical(_controller, controller) && controller.mounted) {
        controller.state = null;
      }
    });
  }

  static void beginUndoGesture(int pointer) {
    _gesturePointer = pointer;
  }

  static void endUndoGesture(int pointer, [WidgetRef? ref]) {
    if (_gesturePointer != null && _gesturePointer != pointer) return;
    _gesturePointer = null;
    if (_undoCompleted) {
      _scheduleDismiss(ref);
    }
  }

  static void _scheduleDismiss([WidgetRef? ref]) {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(slotHold, () => dismiss(ref));
  }

  static Future<void> undo([WidgetRef? ref]) async {
    final request = _pending ?? ref?.read(trashUndoRequestProvider);
    if (request == null || _busy) return;
    _busy = true;
    _pending = null;
    _timer?.cancel();
    _timer = null;
    try {
      await request.repo.restoreTask(request.task.copyWith(clearDeleted: true));
    } catch (_) {
      // Restore is best-effort; still unhide the list row.
    } finally {
      request.onUndo?.call();
      _undoCompleted = true;
      // Do not collapse the banner while the same pointer is still down.
      if (_gesturePointer == null) {
        _scheduleDismiss(ref);
      }
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
    showUndo(ref: ref, task: task, repo: repo, onUndo: onUndo);
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
    return Listener(
      onPointerDown: (event) {
        TaskTrash.beginUndoGesture(event.pointer);
        TaskTrash.undo(ref);
      },
      onPointerUp: (event) => TaskTrash.endUndoGesture(event.pointer, ref),
      onPointerCancel: (event) => TaskTrash.endUndoGesture(event.pointer, ref),
      child: Material(
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
                Semantics(
                  button: true,
                  label: l10n.undo,
                  child: Text(
                    l10n.undo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
