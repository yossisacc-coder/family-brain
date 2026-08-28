import '../../../domain/models/app_user.dart';
import '../family_brain_intent.dart';
import '../family_brain_parser.dart';
import 'ai_provider.dart';
import 'family_brain_ai_schema.dart';
import 'family_brain_context.dart';

/// On-device parser exposed through the same [AiProvider] interface.
class LocalFallbackAdapter implements AiProvider {
  const LocalFallbackAdapter();

  @override
  String get id => 'local_fallback';

  @override
  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    final text = input.text.trim();
    if (FamilyBrainIntent.isDelete(text)) {
      final target = FamilyBrainIntent.matchRef(text, context.catalog);
      return FamilyBrainAiResponse(
        providerId: id,
        sourceText: input.text,
        clarification: FamilyBrainAiValidator.deletePrompt(
          context.language,
          target?.title,
        ),
        actions: [
          FamilyBrainAiAction(
            type: FamilyBrainAiActionType.askForClarification,
            targetId: target?.id,
            title: target?.title,
            message: FamilyBrainAiValidator.deletePrompt(
              context.language,
              target?.title,
            ),
          ),
          if (target != null)
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.deleteTask,
              targetId: target.id,
              title: target.title,
            ),
        ],
      );
    }

    if (FamilyBrainIntent.isListQuery(text)) {
      final reminders = FamilyBrainIntent.isRemindersQuery(text);
      return FamilyBrainAiResponse(
        providerId: id,
        sourceText: input.text,
        actions: [
          FamilyBrainAiAction(
            type: reminders
                ? FamilyBrainAiActionType.listReminders
                : FamilyBrainAiActionType.listTasks,
          ),
        ],
      );
    }

    if (FamilyBrainIntent.isUpdate(text)) {
      final target = FamilyBrainIntent.matchRef(text, context.catalog);
      if (target == null) {
        return FamilyBrainAiResponse(
          providerId: id,
          sourceText: input.text,
          clarification: context.language == 'he'
              ? 'איזו משימה לעדכן?'
              : 'Which task should I update?',
          actions: [
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.askForClarification,
              message: context.language == 'he'
                  ? 'איזו משימה לעדכן?'
                  : 'Which task should I update?',
            ),
          ],
        );
      }
      final parsed = FamilyBrainParser.parse(
        text,
        now: context.now,
        members: [
          for (final member in context.members)
            AppUser(
              id: member.id,
              name: member.name,
              phone: '',
              language: context.language,
              createdAt: context.now,
            ),
        ],
      );
      final draft = parsed.draft;
      return FamilyBrainAiResponse(
        providerId: id,
        sourceText: input.text,
        actions: [
          FamilyBrainAiAction(
            type: FamilyBrainAiActionType.updateTask,
            targetId: target.id,
            title: draft?.title ?? target.title,
            date: draft?.dueDate == null
                ? null
                : draft!.dueDate!.toIso8601String().split('T').first,
            time: draft != null && draft.hasDueTime
                ? '${draft.dueDate!.hour.toString().padLeft(2, '0')}:${draft.dueDate!.minute.toString().padLeft(2, '0')}'
                : null,
            assigneeId: draft?.assigneeId,
            assigneeName: draft?.assigneeName,
          ),
        ],
      );
    }

    final drafts = FamilyBrainParser.parseAll(
      input.text,
      now: context.now,
      members: [
        for (final member in context.members)
          AppUser(
            id: member.id,
            name: member.name,
            phone: '',
            language: context.language,
            createdAt: context.now,
          ),
      ],
      currentUser: context.currentUser == null
          ? null
          : AppUser(
              id: context.currentUser!.id,
              name: context.currentUser!.name,
              phone: '',
              language: context.language,
              createdAt: context.now,
            ),
      imagePath: input.imagePath,
    );
    final missing = drafts.any(
      (draft) => draft.explanation == FamilyBrainParser.missingDateTimeKey,
    );
    return FamilyBrainAiResponse.fromDrafts(
      drafts,
      providerId: id,
      sourceText: input.text,
      clarification: missing
          ? (context.language == 'he'
              ? 'חסרים תאריך ושעה. אפשר לשמור כפריט כללי, או להוסיף מתי זה אמור לקרות.'
              : 'I\'m missing the date and time. I can keep this as a general item, or you can add when it should happen.')
          : null,
    );
  }
}
