import '../../domain/models/task_item.dart';
import 'ai/family_brain_context.dart';

/// On-device intent cues for Voice / text. Does not invent facts.
class FamilyBrainIntent {
  const FamilyBrainIntent._();

  static final _delete = RegExp(
    r"\b(delete|remove|cancel)\b|מחק|למחוק|תמחקי|תסיר",
    unicode: true,
    caseSensitive: false,
  );
  static final _list = RegExp(
    r"\b(what('s| is)? (on )?(my |the )?(today|to-?do|tasks?|reminders?)|"
    r"show (me )?(today|my tasks|the tasks|reminders)|"
    r"list (my |the )?(tasks?|reminders?)|today'?s tasks)\b|"
    r"מה יש היום|המשימות להיום|הצג משימות|איזה משימות",
    unicode: true,
    caseSensitive: false,
  );
  static final _remindersQuery = RegExp(
    r"\b(reminders?|what should I remember)\b|תזכורות",
    unicode: true,
    caseSensitive: false,
  );
  static final _update = RegExp(
    r"\b(move|reschedule|assign|change|update|put)\b|העבר|לשייך|תעדכן|שנה",
    unicode: true,
    caseSensitive: false,
  );
  static final _yes = RegExp(
    r"^(yes|yep|yeah|ok|okay|sure|confirm|do it|please do)[.!]?$|"
    r"^(כן|בטח|אישור|אשרי|תמחק)[.!]?$",
    unicode: true,
    caseSensitive: false,
  );
  static final _no = RegExp(
    r"^(no|nope|cancel|don'?t|stop)[.!]?$|^(לא|בטל|עזוב)[.!]?$",
    unicode: true,
    caseSensitive: false,
  );

  static bool isDelete(String text) => _delete.hasMatch(text.trim());

  static bool isListQuery(String text) => _list.hasMatch(text.trim());

  static bool isRemindersQuery(String text) =>
      _remindersQuery.hasMatch(text.trim()) && isListQuery(text.trim());

  static bool isUpdate(String text) =>
      _update.hasMatch(text.trim()) && !isDelete(text);

  static bool isAffirmative(String text) => _yes.hasMatch(text.trim());

  static bool isNegative(String text) => _no.hasMatch(text.trim());

  static FamilyBrainItemRef? matchRef(
    String text,
    List<FamilyBrainItemRef> items,
  ) {
    if (items.isEmpty) return null;
    final lower = text.toLowerCase();
    FamilyBrainItemRef? best;
    var bestScore = 0;
    for (final item in items) {
      final score = _score(lower, item.title.toLowerCase());
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return bestScore >= 4 ? best : null;
  }

  static TaskItem? matchTask(String text, List<TaskItem> items) {
    if (items.isEmpty) return null;
    final lower = text.toLowerCase();
    TaskItem? best;
    var bestScore = 0;
    for (final item in items) {
      if (!item.isOpen) continue;
      final score = _score(lower, item.title.toLowerCase());
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return bestScore >= 4 ? best : null;
  }

  static int _score(String haystack, String title) {
    if (title.isEmpty) return 0;
    if (haystack.contains(title)) return title.length + 8;
    var score = 0;
    for (final word in title.split(RegExp(r'\s+'))) {
      if (word.length < 3) continue;
      if (haystack.contains(word)) score += word.length;
    }
    return score;
  }
}
