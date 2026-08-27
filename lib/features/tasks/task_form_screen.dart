import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/notifications/local_reminder_scheduler.dart';
import '../../core/theme/task_semantics.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';
import '../../domain/models/family_activity.dart';
import '../../domain/models/task_item.dart';
import '../activity/record_activity.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId, this.initialTitle});

  final String? taskId;
  final String? initialTitle;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  TaskType _type = TaskType.family;
  TaskPriority _priority = TaskPriority.normal;
  TaskStatus _status = TaskStatus.pending;
  String? _assigneeId;
  DateTime? _dueDate;
  bool _hasDueTime = false;
  DateTime? _reminderAt;
  bool _loading = false;
  bool _hydrated = false;
  String? _error;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialTitle?.trim();
    if (seed != null && seed.isNotEmpty) {
      _title.text = seed;
    }
  }

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
    _status = task.status;
    _assigneeId = task.assigneeId;
    _dueDate = task.dueDate;
    _hasDueTime = task.hasDueTime;
    _reminderAt = task.reminderAt;
  }

  String _formatDate(DateTime value) {
    final date = DateFormat.yMMMd().format(value);
    if (!_hasDueTime) return date;
    return '$date · ${DateFormat.jm().format(value)}';
  }

  Future<void> _pickDueDate() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _dueDate ?? DateTime.now(),
      helpText: l10n.pickDate,
      cancelText: l10n.cancel,
    );
    if (picked == null || !mounted) return;
    var next = DateTime(picked.year, picked.month, picked.day);
    if (_hasDueTime && _dueDate != null) {
      next = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueDate!.hour,
        _dueDate!.minute,
      );
    }
    setState(() => _dueDate = next);
  }

  Future<void> _pickDueTime() async {
    final l10n = AppLocalizations.of(context);
    final initial = TimeOfDay.fromDateTime(_dueDate ?? DateTime.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: l10n.pickTime,
      cancelText: l10n.cancel,
    );
    if (picked == null || _dueDate == null || !mounted) return;
    setState(() {
      _hasDueTime = true;
      _dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context);
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _reminderAt ?? _dueDate ?? DateTime.now(),
      helpText: l10n.pickDate,
      cancelText: l10n.cancel,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
      helpText: l10n.pickTime,
      cancelText: l10n.cancel,
    );
    if (time == null || !mounted) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    final family = ref.read(currentFamilyProvider).valueOrNull;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = l10n.titleRequired);
      return;
    }
    if (user == null || family == null) {
      setState(() => _error = l10n.errorUnavailable);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
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
        hasDueTime: _dueDate != null && _hasDueTime,
        priority: _priority,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        status: _status,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        reminderAt: _reminderAt,
        deletedAt: existing?.deletedAt,
      );
      final repo = ref.read(taskRepositoryProvider);
      final saved = existing == null
          ? await repo.createTask(task)
          : await repo.updateTask(task);
      await LocalReminderScheduler.sync(saved);
      final service = ref.read(notificationServiceProvider);
      if (saved.assigneeId != null && saved.assigneeId != user.id) {
        await service.notifyTaskAssigned(
          task: saved,
          actor: user,
          title: l10n.newTaskAssigned,
          message: saved.title,
        );
      }
      if (existing == null) {
        await recordFamilyActivity(
          ref,
          type: ActivityType.taskCreated,
          summary: saved.title,
          task: saved,
        );
      } else {
        await recordFamilyActivity(
          ref,
          type: ActivityType.taskEdited,
          summary: saved.title,
          task: saved,
        );
        if (existing.assigneeId != saved.assigneeId) {
          await recordFamilyActivity(
            ref,
            type: ActivityType.taskAssigned,
            summary: saved.title,
            task: saved,
          );
        }
      }
      if (saved.reminderAt != null && saved.reminderAt != existing?.reminderAt) {
        await recordFamilyActivity(
          ref,
          type: ActivityType.reminderSet,
          summary: saved.title,
          task: saved,
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
      if (!mounted) return;
      ref.invalidate(familyTasksProvider);
      context.go('/app/home');
      AppNotice.showAfterNavigation(l10n.taskSaved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.errorUnavailable);
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
      final existing =
          tasks.where((task) => task.id == widget.taskId).firstOrNull;
      if (existing != null) _hydrate(existing);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTask : l10n.createTask),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        key: const Key('task-edit-form'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.taskTitle,
              hintText: l10n.taskTitleHint,
              errorText: _error,
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
          Text(l10n.taskType, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskType>(
            segments: [
              ButtonSegment(
                value: TaskType.personal,
                label: Text(l10n.personal),
                icon: const Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: TaskType.family,
                label: Text(l10n.familyType),
                icon: const Icon(Icons.groups_outlined),
              ),
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
          DropdownButtonFormField<TaskStatus>(
            // ignore: deprecated_member_use
            value: _status,
            decoration: InputDecoration(labelText: l10n.changeStatus),
            items: [
              for (final status in TaskStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(TaskSemantics.statusLabel(l10n, status)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskPriority>(
            // ignore: deprecated_member_use
            value: _priority,
            decoration: InputDecoration(labelText: l10n.priority),
            items: [
              for (final priority in TaskPriority.values)
                DropdownMenuItem(
                  value: priority,
                  child: Text(TaskSemantics.priorityLabel(l10n, priority)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dueDate),
            subtitle: Text(
              _dueDate == null ? l10n.none : _formatDate(_dueDate!),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDueDate,
          ),
          if (_dueDate != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dueTime),
              value: _hasDueTime,
              onChanged: (value) async {
                if (value) {
                  await _pickDueTime();
                  if (!_hasDueTime && mounted) {
                    setState(() => _hasDueTime = false);
                  }
                } else {
                  setState(() {
                    _hasDueTime = false;
                    _dueDate = DateTime(
                      _dueDate!.year,
                      _dueDate!.month,
                      _dueDate!.day,
                    );
                  });
                }
              },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.optionalReminder),
            subtitle: Text(
              _reminderAt == null
                  ? l10n.noReminder
                  : DateFormat.yMMMd().add_jm().format(_reminderAt!),
            ),
            value: _reminderAt != null,
            onChanged: (value) async {
              if (value) {
                await _pickReminder();
              } else {
                setState(() => _reminderAt = null);
              }
            },
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.save,
            loading: _loading,
            onPressed: _save,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => context.pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
