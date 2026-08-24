import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/task_card.dart';
import '../../core/widgets/task_trash.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskStatus? _status;
  String? _memberId;
  TaskType? _type;
  final _hiddenIds = <String>{};
  bool _holdUndoSlot = false;

  void _hideForUndo(String taskId) {
    setState(() => _hiddenIds.add(taskId));
  }

  void _showAfterUndo(String taskId) {
    if (!mounted) return;
    setState(() {
      _hiddenIds.remove(taskId);
      _holdUndoSlot = true;
      _status = null;
      _type = null;
      _memberId = null;
    });
    Future<void>.delayed(TaskTrash.slotHold, () {
      if (mounted) setState(() => _holdUndoSlot = false);
    });
  }

  Future<void> _deleteFromList(TaskItem task, AppLocalizations l10n) async {
    if (!await TaskTrash.confirm(context, l10n) || !mounted) return;
    _hideForUndo(task.id);
    await TaskTrash.move(
      context: context,
      ref: ref,
      task: task,
      l10n: l10n,
      onUndo: () => _showAfterUndo(task.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tasksAsync = ref.watch(familyTasksProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    final pendingUndo = ref.watch(trashUndoRequestProvider) != null;
    final occupyUndoSlot = pendingUndo || _holdUndoSlot;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasks),
        actions: [
          if (pendingUndo)
            TextButton(
              key: const Key('task-trash-undo-appbar'),
              onPressed: () => TaskTrash.undo(ref),
              child: Text(
                l10n.undo,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.calendar,
            onPressed: () => context.push('/tasks/calendar'),
            icon: const Icon(Icons.calendar_today_outlined),
          ),
          IconButton(
            tooltip: l10n.trash,
            onPressed: () => context.push('/tasks/trash'),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: l10n.addTask,
            onPressed: () => context.push('/tasks/new'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (occupyUndoSlot)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: pendingUndo
                  ? const TrashUndoBar()
                  : const SizedBox(height: 52),
            ),
          Expanded(
            child: AbsorbPointer(
              absorbing: occupyUndoSlot,
              child: tasksAsync.when(
                loading: () => LoadingView(label: l10n.loading),
                error: (_, _) => ErrorView(
                  message: l10n.errorUnavailable,
                  retryLabel: l10n.retry,
                  onRetry: () => ref.invalidate(familyTasksProvider),
                ),
                data: (all) {
                  final visible = user == null
                      ? all.where((task) => task.type == TaskType.family)
                      : all.where((task) => task.isVisibleTo(user.id));
                  final filtered = visible.where((task) {
                    if (_hiddenIds.contains(task.id)) return false;
                    if (_status != null && task.status != _status) return false;
                    if (_memberId != null && task.assigneeId != _memberId) {
                      return false;
                    }
                    if (_type != null && task.type != _type) return false;
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      if (!occupyUndoSlot)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              _chip(
                                label: l10n.all,
                                selected:
                                    _status == null &&
                                    _type == null &&
                                    _memberId == null,
                                onTap: () => setState(() {
                                  _status = null;
                                  _type = null;
                                  _memberId = null;
                                }),
                              ),
                              _chip(
                                label: l10n.pending,
                                selected: _status == TaskStatus.pending,
                                onTap: () => setState(
                                  () => _status = TaskStatus.pending,
                                ),
                              ),
                              _chip(
                                label: l10n.inProgress,
                                selected: _status == TaskStatus.inProgress,
                                onTap: () => setState(
                                  () => _status = TaskStatus.inProgress,
                                ),
                              ),
                              _chip(
                                label: l10n.completed,
                                selected: _status == TaskStatus.completed,
                                onTap: () => setState(
                                  () => _status = TaskStatus.completed,
                                ),
                              ),
                              _chip(
                                label: l10n.personalTasks,
                                selected: _type == TaskType.personal,
                                onTap: () =>
                                    setState(() => _type = TaskType.personal),
                              ),
                              _chip(
                                label: l10n.familyTasks,
                                selected: _type == TaskType.family,
                                onTap: () =>
                                    setState(() => _type = TaskType.family),
                              ),
                              ...members.map(
                                (member) => _chip(
                                  label: member.name,
                                  selected: _memberId == member.id,
                                  onTap: () =>
                                      setState(() => _memberId = member.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: filtered.isEmpty
                            ? EmptyState(
                                title: l10n.noTasksYet,
                                message: l10n.emptyTasksMessage,
                                actionLabel: l10n.addFirstTask,
                                onAction: () => context.push('/tasks/new'),
                              )
                            : ListView.separated(
                                key: const PageStorageKey('tasks-list'),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  88,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final task = filtered[index];
                                  return TaskCard(
                                    task: task,
                                    members: members,
                                    onTap: () =>
                                        context.push('/tasks/${task.id}'),
                                    onDelete: () => _deleteFromList(task, l10n),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primarySoft,
        showCheckmark: false,
      ),
    );
  }
}
