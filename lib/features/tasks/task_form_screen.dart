import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  TaskType _type = TaskType.family;
  TaskPriority _priority = TaskPriority.normal;
  String? _assigneeId;
  DateTime? _dueDate;
  bool _loading = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(TaskItem task) {
    if (_hydrated) return;
    _hydrated = true;
    _title.text = task.title;
    _notes.text = task.notes ?? '';
    _type = task.type;
    _priority = task.priority;
    _assigneeId = task.assigneeId;
    _dueDate = task.dueDate;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    final family = ref.read(currentFamilyProvider).valueOrNull;
    if (user == null || family == null || _title.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      final existing = widget.taskId == null
          ? null
          : ref
              .read(familyTasksProvider)
              .valueOrNull
              ?.where((task) => task.id == widget.taskId)
              .firstOrNull;
      final now = DateTime.now();
      final task = TaskItem(
        id: existing?.id ?? const Uuid().v4(),
        familyId: family.id,
        creatorId: existing?.creatorId ?? user.id,
        title: _title.text.trim(),
        assigneeId: _assigneeId,
        type: _type,
        dueDate: _dueDate,
        priority: _priority,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        status: existing?.status ?? TaskStatus.pending,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      final repo = ref.read(taskRepositoryProvider);
      final saved = existing == null
          ? await repo.createTask(task)
          : await repo.updateTask(task);
      final service = ref.read(notificationServiceProvider);
      if (saved.assigneeId != null && saved.assigneeId != user.id) {
        await service.notifyTaskAssigned(
          task: saved,
          actor: user,
          title: l10n.newTaskAssigned,
          message: saved.title,
        );
      }
      if (saved.isDueSoon()) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final due = saved.dueDate;
        if (due != null &&
            DateTime(due.year, due.month, due.day) ==
                DateTime(tomorrow.year, tomorrow.month, tomorrow.day)) {
          await service.notifyDueTomorrow(
            task: saved,
            title: l10n.taskDueTomorrow,
            message: saved.title,
          );
        }
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];
    final tasks = ref.watch(familyTasksProvider).valueOrNull ?? const [];
    if (widget.taskId != null) {
      final existing = tasks.where((task) => task.id == widget.taskId).firstOrNull;
      if (existing != null) _hydrate(existing);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskId == null ? l10n.createTask : l10n.editTask),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.taskTitle,
              hintText: l10n.taskTitleHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.taskType, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskType>(
            segments: [
              ButtonSegment(value: TaskType.personal, label: Text(l10n.personal)),
              ButtonSegment(value: TaskType.family, label: Text(l10n.familyType)),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            // ignore: deprecated_member_use
            value: _assigneeId,
            decoration: InputDecoration(labelText: l10n.assignee),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.unassigned)),
              ...members.map(
                (member) => DropdownMenuItem(
                  value: member.id,
                  child: Text(member.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _assigneeId = value),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dueDate),
            subtitle: Text(
              _dueDate == null
                  ? l10n.none
                  : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: _dueDate ?? DateTime.now(),
                helpText: l10n.pickDate,
                cancelText: l10n.cancel,
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          const SizedBox(height: 8),
          Text(l10n.priority, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskPriority>(
            segments: [
              ButtonSegment(value: TaskPriority.normal, label: Text(l10n.normal)),
              ButtonSegment(value: TaskPriority.urgent, label: Text(l10n.urgent)),
            ],
            selected: {_priority},
            onSelectionChanged: (value) => setState(() => _priority = value.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected) &&
                        _priority == TaskPriority.urgent
                    ? AppColors.urgent
                    : null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.notes,
              hintText: l10n.notesHint,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.save,
            loading: _loading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
