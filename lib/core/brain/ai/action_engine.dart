import 'package:uuid/uuid.dart';

import '../../../domain/models/task_item.dart';
import '../../../domain/repositories/task_repository.dart';
import '../family_brain_parser.dart';
import 'family_brain_ai_schema.dart';

/// Applies a validated [FamilyBrainAiResponse] to application data.
///
/// AI output never writes the database or UI. Changing the AI provider
/// does not change this engine.
class ActionEngineResult {
  const ActionEngineResult({
    this.created = const [],
    this.updated = const [],
  });

  final List<TaskItem> created;
  final List<TaskItem> updated;

  List<TaskItem> get written => [...created, ...updated];
}

class ActionEngine {
  ActionEngine({
    required this.repository,
    String Function()? nextId,
  }) : nextId = nextId ?? (() => const Uuid().v4());

  final TaskRepository repository;
  final String Function() nextId;

  Future<ActionEngineResult> apply({
    required FamilyBrainAiResponse response,
    required String familyId,
    required String creatorId,
    DateTime? now,
    List<TaskItem> existing = const [],
  }) async {
    final stamp = now ?? DateTime.now();
    final created = <TaskItem>[];
    final updated = <TaskItem>[];
    final byId = {for (final item in existing) item.id: item};

    for (final action in response.actions) {
      switch (action.type) {
        case FamilyBrainAiActionType.createTask:
        case FamilyBrainAiActionType.createEvent:
        case FamilyBrainAiActionType.createReminder:
        case FamilyBrainAiActionType.createListItem:
          final draft = action.toDraft(
            originalText: response.sourceText,
            now: stamp,
          );
          if (draft == null) continue;
          final task = draft.toTaskItem(
            id: nextId(),
            familyId: familyId,
            creatorId: creatorId,
            now: stamp,
          );
          created.add(await repository.createTask(task));
        case FamilyBrainAiActionType.updateTask:
        case FamilyBrainAiActionType.updateEvent:
        case FamilyBrainAiActionType.updateListItem:
          final current = byId[action.targetId];
          if (current == null) continue;
          final next = _patch(current, action, stamp);
          final saved = await repository.updateTask(next);
          byId[saved.id] = saved;
          updated.add(saved);
        case FamilyBrainAiActionType.completeTask:
          final current = byId[action.targetId];
          if (current == null) continue;
          final next = current.copyWith(
            status: TaskStatus.completed,
            updatedAt: stamp,
          );
          final saved = await repository.updateTask(next);
          byId[saved.id] = saved;
          updated.add(saved);
        case FamilyBrainAiActionType.identifyFamilyMember:
        case FamilyBrainAiActionType.determinePriority:
        case FamilyBrainAiActionType.determineDate:
        case FamilyBrainAiActionType.determineTime:
        case FamilyBrainAiActionType.askForClarification:
        case FamilyBrainAiActionType.conversationalResponse:
          break;
      }
    }

    return ActionEngineResult(created: created, updated: updated);
  }

  Future<ActionEngineResult> applyDrafts({
    required List<BrainDraft> drafts,
    required String familyId,
    required String creatorId,
    DateTime? now,
    List<TaskItem> existing = const [],
  }) {
    return apply(
      response: FamilyBrainAiResponse.fromDrafts(drafts),
      familyId: familyId,
      creatorId: creatorId,
      now: now,
      existing: existing,
    );
  }

  TaskItem _patch(TaskItem current, FamilyBrainAiAction action, DateTime now) {
    final due = action.dueAt(now);
    final reminder = action.reminderAt(now);
    final notes = action.listItems.isNotEmpty
        ? action.listItems.join('\n')
        : action.description;
    return current.copyWith(
      title: (action.title ?? '').trim().isEmpty ? null : action.title!.trim(),
      kind: action.kind == null ? null : action.informationKind,
      assigneeId: action.assigneeId,
      type: action.space == 'personal' || action.space == 'private'
          ? TaskType.personal
          : action.space == 'family'
              ? TaskType.family
              : null,
      dueDate: due,
      hasDueTime: due == null ? null : (action.hasDueTime || action.time != null),
      priority: action.priority == null
          ? null
          : TaskPriority.values.where((p) => p.name == action.priority).firstOrNull,
      notes: notes,
      status: action.status == 'completed'
          ? TaskStatus.completed
          : action.status == 'inProgress'
              ? TaskStatus.inProgress
              : action.status == 'pending'
                  ? TaskStatus.pending
                  : null,
      reminderAt: reminder,
      updatedAt: now,
    );
  }
}
