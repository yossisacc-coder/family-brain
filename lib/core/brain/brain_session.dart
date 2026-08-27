import '../../domain/models/task_item.dart';
import 'ai/family_brain_context.dart';
import 'family_brain_parser.dart';

/// Short in-memory conversation context for Family Brain.
///
/// This is not a chat redesign. It only remembers the last few user inputs
/// and the last understood event so a follow-up such as "remind me two hours
/// before" can attach to the previous event.
class BrainSession {
  static String? lastUserText;
  static List<BrainDraft> lastDrafts = const [];
  static FamilyBrainItemRef? lastEvent;
  static final List<String> recentUserTexts = [];

  static const maxTurns = 6;

  static void remember({
    required String text,
    required List<BrainDraft> drafts,
  }) {
    lastUserText = text;
    lastDrafts = List.of(drafts);
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      recentUserTexts.add(trimmed);
      if (recentUserTexts.length > maxTurns) {
        recentUserTexts.removeRange(0, recentUserTexts.length - maxTurns);
      }
    }
    for (final draft in drafts.reversed) {
      if (draft.kind == InformationKind.event && draft.dueDate != null) {
        lastEvent = FamilyBrainItemRef(
          id: '',
          title: draft.title,
          kind: 'event',
          dueDate: draft.dueDate!.toIso8601String(),
        );
        break;
      }
    }
  }

  static void rememberSaved(List<TaskItem> items) {
    for (final item in items.reversed) {
      if (item.kind == InformationKind.event && item.dueDate != null) {
        lastEvent = FamilyBrainItemRef.fromTask(item);
        break;
      }
    }
  }

  static List<String> recentForProvider() =>
      List.unmodifiable(recentUserTexts);

  static void debugReset() {
    lastUserText = null;
    lastDrafts = const [];
    lastEvent = null;
    recentUserTexts.clear();
  }
}
