import '../../domain/models/task_item.dart';

/// Infers [TaskPriority] from natural English or Hebrew wording.
class PriorityFromLanguage {
  static TaskPriority infer(String text) {
    final t = text.toLowerCase();
    if (_urgent.hasMatch(t)) return TaskPriority.urgent;
    if (_low.hasMatch(t)) return TaskPriority.low;
    if (_high.hasMatch(t)) return TaskPriority.high;
    return TaskPriority.normal;
  }

  static TaskPriority? tryParse(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'low' || 'נמוך' || 'נמוכה' => TaskPriority.low,
      'normal' || 'medium' || 'רגיל' || 'רגילה' => TaskPriority.normal,
      'high' || 'גבוה' || 'גבוהה' || 'חשוב' => TaskPriority.high,
      'urgent' || 'דחוף' || 'דחופה' => TaskPriority.urgent,
      _ => null,
    };
  }

  static final _urgent = RegExp(
    r"\b(urgent|asap|immediately|right now|emergency)\b|"
    r'ממש דחוף|זה דחוף|דחוף מאוד|\bדחוף\b|מיד\b|עכשיו ממש',
    unicode: true,
  );

  static final _high = RegExp(
    r"\b(important|high priority|need(s)? to (be )?today|make sure)\b|"
    r'חשוב ש|זה חשוב|\bחשוב\b|בהקדם',
    unicode: true,
  );

  static final _low = RegExp(
    r'\b(whenever|no rush|low priority|when you (have|get) time|someday)\b|'
    r'כשיהיה זמן|כשיהיה לך זמן|מתישהו|לא דחוף|אין בהול',
    unicode: true,
  );
}
