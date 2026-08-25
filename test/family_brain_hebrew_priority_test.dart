import 'package:family_brain/core/brain/family_brain_ai.dart';
import 'package:family_brain/core/brain/family_brain_ask.dart';
import 'package:family_brain/core/brain/family_brain_parser.dart';
import 'package:family_brain/core/brain/priority_from_language.dart';
import 'package:family_brain/core/brain/speech_locale.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 24, 10, 0);
  final david = AppUser(
    id: 'david',
    name: 'David',
    phone: '+10000000000',
    language: 'he',
    createdAt: now,
    familyId: 'fam',
  );

  test('Hebrew natural-language task', () {
    final drafts = FamilyBrainParser.parseAll(
      'אל תשכח להתקשר לחשמלאי מחר.',
      now: now,
    );
    expect(drafts, isNotEmpty);
    expect(drafts.first.kind, InformationKind.task);
    expect(drafts.first.title, contains('חשמלאי'));
    expect(drafts.first.dueDate, DateTime(2026, 8, 25));
  });

  test('Hebrew voice language selection prefers he-IL', () {
    expect(
      SpeechLocalePicker.resolve(
        appLanguageCode: 'he',
        availableIds: ['en_US', 'he_IL', 'en_GB'],
      ),
      'he_IL',
    );
    expect(
      SpeechLocalePicker.resolve(
        appLanguageCode: 'he',
        availableIds: ['en_US'],
      ),
      isNull,
    );
  });

  test('English voice still prefers an English locale', () {
    expect(
      SpeechLocalePicker.resolve(
        appLanguageCode: 'en',
        availableIds: ['he_IL', 'en_US'],
      ),
      'en_US',
    );
    expect(
      SpeechLocalePicker.isHebrewId('en_US'),
      isFalse,
    );
  });

  test('urgent task maps to urgent priority', () {
    expect(
      PriorityFromLanguage.infer('זה דחוף, צריך להתקשר לרופא היום.'),
      TaskPriority.urgent,
    );
    final drafts = FamilyBrainParser.parseAll(
      'זה דחוף, צריך להתקשר לרופא היום.',
      now: now,
    );
    expect(drafts.first.priority, TaskPriority.urgent);
  });

  test('important task maps to high priority', () {
    expect(
      PriorityFromLanguage.infer('חשוב שתטפל בזה היום.'),
      TaskPriority.high,
    );
    final drafts = FamilyBrainParser.parseAll(
      'חשוב שתטפל בזה היום.',
      now: now,
    );
    expect(drafts.first.priority, TaskPriority.high);
    expect(drafts.first.dueDate?.day, 24);
  });

  test('ordinary errand maps to normal priority', () {
    expect(PriorityFromLanguage.infer('צריך לקנות חלב.'), TaskPriority.normal);
    final drafts = FamilyBrainParser.parseAll('צריך לקנות חלב.', now: now);
    expect(drafts.first.priority, TaskPriority.normal);
  });

  test('low-urgency wording maps to low priority', () {
    expect(
      PriorityFromLanguage.infer('כשיהיה זמן תסדר את המחסן.'),
      TaskPriority.low,
    );
    final drafts = FamilyBrainParser.parseAll(
      'כשיהיה זמן תסדר את המחסן.',
      now: now,
    );
    expect(drafts.first.priority, TaskPriority.low);
    expect(drafts.first.kind, InformationKind.task);
  });

  test('Hebrew natural date', () {
    final tomorrowMorning = FamilyBrainParser.parseAll(
      'מחר בבוקר',
      now: now,
    );
    expect(tomorrowMorning.first.dueDate, DateTime(2026, 8, 25, 9, 0));
    final thursday = FamilyBrainParser.parseAll(
      'ביום חמישי צריך להתקשר',
      now: now,
    );
    expect(thursday.first.dueDate?.weekday, DateTime.thursday);
    final inTwoHours = FamilyBrainParser.parseAll(
      'עוד שעתיים להתקשר',
      now: now,
    );
    expect(inTwoHours.first.dueDate, DateTime(2026, 8, 24, 12, 0));
  });

  test('Hebrew natural time', () {
    final drafts = FamilyBrainParser.parseAll(
      'יש לנו מחר בשש תור לרופא.',
      now: now,
    );
    expect(drafts.single.kind, InformationKind.event);
    expect(drafts.single.title, contains('רופא'));
    expect(drafts.single.dueDate, DateTime(2026, 8, 25, 18, 0));
    expect(drafts.single.hasDueTime, isTrue);
  });

  test('multiple items in one Hebrew message', () {
    final drafts = FamilyBrainParser.parseAll(
      'מחר בשש יש לנו רופא, תזכיר לי שעתיים לפני, וגם צריך לקנות חלב ולחם וזה דחוף.',
      now: now,
    );
    expect(
      drafts.map((d) => d.kind),
      containsAll([
        InformationKind.event,
        InformationKind.reminder,
        InformationKind.list,
      ]),
    );
    expect(drafts.every((d) => d.priority == TaskPriority.urgent), isTrue);
    final event = drafts.firstWhere((d) => d.kind == InformationKind.event);
    expect(event.dueDate, DateTime(2026, 8, 25, 18, 0));
    final reminder = drafts.firstWhere((d) => d.kind == InformationKind.reminder);
    expect(reminder.reminderAt, DateTime(2026, 8, 25, 16, 0));
    final list = drafts.firstWhere((d) => d.kind == InformationKind.list);
    expect(list.listItems, containsAll(['חלב', 'לחם']));
  });

  test('confirmation flow persists priority date time type and assignee', () async {
    final drafts = FamilyBrainParser.parseAll(
      'זה ממש דחוף, תזכיר לי להתקשר לדוד היום בארבע.',
      now: now,
    );
    expect(drafts.single.kind, InformationKind.reminder);
    expect(drafts.single.priority, TaskPriority.urgent);
    expect(drafts.single.dueDate, DateTime(2026, 8, 24, 16, 0));
    final repo = LocalTaskRepository(LocalJsonStore(persist: false));
    final saved = drafts.single.toTaskItem(
      id: 'he-1',
      familyId: 'fam',
      creatorId: 'maya',
      now: now,
    );
    await repo.createTask(saved);
    final loaded = await repo.watchFamilyTasks('fam').first;
    expect(loaded.single.priority, TaskPriority.urgent);
    expect(loaded.single.kind, InformationKind.reminder);
    expect(loaded.single.dueDate, DateTime(2026, 8, 24, 16, 0));
    expect(loaded.single.hasDueTime, isTrue);
    expect(loaded.single.reminderAt, DateTime(2026, 8, 24, 16, 0));
  });

  test('existing local fallback still parses without the gateway', () async {
    final result = await FamilyBrainAi.understand(
      text: 'Buy milk, bread and eggs.',
      now: now,
      backendUrl: '',
    );
    expect(result.usedCloud, isFalse);
    expect(result.drafts.single.kind, InformationKind.list);
  });

  test('existing privacy behavior hides personal tasks from Ask', () {
    final visible = [
      TaskItem(
        id: '1',
        familyId: 'fam',
        creatorId: 'maya',
        title: 'School pickup',
        type: TaskType.family,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
        dueDate: DateTime(2026, 8, 24, 15),
      ),
      TaskItem(
        id: '2',
        familyId: 'fam',
        creatorId: 'alex',
        title: 'Secret errand',
        type: TaskType.personal,
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    ].where((task) => task.isVisibleTo('maya')).toList();
    final answer = FamilyBrainAsk.answer(
      question: 'What do I need to do today?',
      visibleTasks: visible,
      now: now,
    );
    expect(answer, contains('School pickup'));
    expect(answer, isNot(contains('Secret errand')));
  });

  test('structured AI JSON priority is used after confirm', () {
    final drafts = FamilyBrainAi.draftsFromAiJson(
      {
        'items': [
          {
            'type': 'task',
            'title': 'להתקשר לרופא',
            'date': '2026-08-24',
            'time': '16:00',
            'priority': 'urgent',
            'assignee': 'David',
          },
        ],
      },
      originalText: 'demo',
      now: now,
      members: [david],
    );
    expect(drafts.single.priority, TaskPriority.urgent);
    expect(drafts.single.assigneeId, 'david');
    expect(drafts.single.dueDate, DateTime(2026, 8, 24, 16, 0));
    final task = drafts.single.toTaskItem(
      id: 'ai-1',
      familyId: 'fam',
      creatorId: 'maya',
      now: now,
    );
    expect(task.priority, TaskPriority.urgent);
    expect(task.assigneeId, 'david');
  });

  test('E2E Hebrew reminder preserves text, tomorrow 16:00, urgent', () async {
    const text = 'זה דחוף, תזכיר לי להתקשר לאבא מחר בשעה ארבע.';
    final drafts = FamilyBrainParser.parseAll(text, now: now);
    expect(drafts, isNotEmpty);
    expect(drafts.single.kind, InformationKind.reminder);
    expect(drafts.single.originalText, contains('אבא'));
    expect(drafts.single.title, contains('אבא'));
    expect(drafts.single.dueDate, DateTime(2026, 8, 25, 16, 0));
    expect(drafts.single.hasDueTime, isTrue);
    expect(drafts.single.priority, TaskPriority.urgent);
    final saved = drafts.single.toTaskItem(
      id: 'e2e-he',
      familyId: 'fam',
      creatorId: 'maya',
      now: now,
    );
    final repo = LocalTaskRepository(LocalJsonStore(persist: false));
    await repo.createTask(saved);
    final loaded = await repo.watchFamilyTasks('fam').first;
    expect(loaded.single.kind, InformationKind.reminder);
    expect(loaded.single.priority, TaskPriority.urgent);
    expect(loaded.single.dueDate, DateTime(2026, 8, 25, 16, 0));
    expect(loaded.single.hasDueTime, isTrue);
    expect(loaded.single.reminderAt, DateTime(2026, 8, 25, 16, 0));
  });

  test('E2E English reminder is semantically the same and urgent', () {
    final drafts = FamilyBrainParser.parseAll(
      "Remind me to call Dad tomorrow at 4 PM. It's urgent.",
      now: now,
    );
    expect(drafts, isNotEmpty);
    expect(drafts.single.kind, InformationKind.reminder);
    expect(drafts.single.dueDate, DateTime(2026, 8, 25, 16, 0));
    expect(drafts.single.hasDueTime, isTrue);
    expect(drafts.single.priority, TaskPriority.urgent);
  });
}

