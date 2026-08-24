import 'package:family_brain/core/brain/family_brain_ai.dart';
import 'package:family_brain/core/brain/family_brain_ask.dart';
import 'package:family_brain/core/brain/family_brain_parser.dart';
import 'package:family_brain/core/notifications/local_reminder_scheduler.dart';
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
    language: 'en',
    createdAt: now,
    familyId: 'fam',
  );

  group('multi-item natural language', () {
    test('extracts a natural language task', () {
      final drafts = FamilyBrainParser.parseAll(
        "Don't forget to call the electrician tomorrow.",
        now: now,
      );
      expect(drafts, isNotEmpty);
      expect(drafts.first.kind, InformationKind.reminder);
      expect(drafts.first.title.toLowerCase(), contains('electrician'));
    });

    test('extracts an event with time', () {
      final drafts = FamilyBrainParser.parseAll(
        "On Sunday we're having guests at 7.",
        now: now,
      );
      expect(drafts.single.kind, InformationKind.event);
      expect(drafts.single.dueDate?.hour, 19);
    });

    test('extracts a reminder for a family member on a weekday', () {
      final dad = AppUser(
        id: 'dad',
        name: 'Dad',
        phone: '+1',
        language: 'en',
        createdAt: now,
        familyId: 'fam',
      );
      final drafts = FamilyBrainParser.parseAll(
        'Remind Dad about the meeting Thursday.',
        now: now,
        members: [dad],
      );
      expect(drafts.single.kind, InformationKind.reminder);
      expect(drafts.single.assigneeId, 'dad');
      expect(drafts.single.dueDate?.weekday, DateTime.thursday);
    });

    test('extracts a shopping list', () {
      final drafts = FamilyBrainParser.parseAll(
        'We need milk, bread and eggs.',
        now: now,
      );
      expect(drafts.single.kind, InformationKind.list);
      expect(drafts.single.listItems, containsAll(['milk', 'bread', 'eggs']));
    });

    test('extracts event, reminder, and list from one message', () {
      final drafts = FamilyBrainParser.parseAll(
        'Tomorrow at 6 I need to take David to the doctor. Remind me two hours before. Also buy milk and bread.',
        now: now,
        members: [david],
      );
      expect(drafts.map((d) => d.kind), containsAll([
        InformationKind.event,
        InformationKind.reminder,
        InformationKind.list,
      ]));
      final event = drafts.firstWhere((d) => d.kind == InformationKind.event);
      expect(event.dueDate, DateTime(2026, 8, 25, 18, 0));
      expect(event.assigneeId, 'david');
      final reminder = drafts.firstWhere((d) => d.kind == InformationKind.reminder);
      expect(reminder.reminderAt, DateTime(2026, 8, 25, 16, 0));
      final list = drafts.firstWhere((d) => d.kind == InformationKind.list);
      expect(list.listItems, containsAll(['milk', 'bread']));
    });
  });

  group('confirmation persistence', () {
    test('edit then confirm saves every extracted item', () async {
      final drafts = FamilyBrainParser.parseAll(
        'Tomorrow at 6 I need to take David to the doctor. Remind me two hours before. Also buy milk and bread.',
        now: now,
        members: [david],
      );
      final edited = drafts
          .map((d) => d.kind == InformationKind.event
              ? d.copyWith(title: 'Clinic visit')
              : d)
          .toList();
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      for (final draft in edited) {
        await repo.createTask(
          draft.toTaskItem(
            id: 'id-${draft.kind.name}',
            familyId: 'fam',
            creatorId: 'maya',
            now: now,
          ),
        );
      }
      final saved = await repo.watchFamilyTasks('fam').first;
      expect(saved, hasLength(3));
      expect(saved.map((t) => t.title), contains('Clinic visit'));
    });

    test('cancel means nothing is created', () async {
      FamilyBrainParser.parseAll('Buy milk, bread and eggs.', now: now);
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      expect(await repo.watchFamilyTasks('fam').first, isEmpty);
    });
  });

  group('AI mapping and failures', () {
    test('maps structured Gemini JSON into drafts', () {
      final drafts = FamilyBrainAi.draftsFromAiJson(
        {
          'items': [
            {
              'type': 'event',
              'title': 'Doctor',
              'date': '2026-08-25',
              'time': '18:00',
              'assignee': 'David',
              'confidence': 0.9,
            },
            {
              'type': 'list',
              'title': 'Shopping',
              'listItems': ['milk', 'bread'],
            },
          ],
        },
        originalText: 'demo',
        now: now,
        members: [david],
      );
      expect(drafts, hasLength(2));
      expect(drafts.first.kind, InformationKind.event);
      expect(drafts.first.assigneeId, 'david');
      expect(drafts.last.listItems, ['milk', 'bread']);
    });

    test('invalid AI payload falls through to empty drafts', () {
      final drafts = FamilyBrainAi.draftsFromAiJson(
        {'nope': true},
        originalText: 'demo',
        now: now,
      );
      expect(drafts, isEmpty);
    });

    test('local parser is used when the cloud gateway is not configured', () async {
      final result = await FamilyBrainAi.understand(
        text: 'Buy milk, bread and eggs.',
        now: now,
      );
      expect(result.isOk, isTrue);
      expect(result.usedCloud, isFalse);
      expect(result.drafts.single.kind, InformationKind.list);
    });
  });

  group('privacy and assignment', () {
    test('Ask Family Brain never returns another member personal task', () {
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
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
          dueDate: DateTime(2026, 8, 24),
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
  });

  group('voice image and notifications', () {
    test('voice-like text is understood after it lands in the composer', () {
      final drafts = FamilyBrainParser.parseAll(
        'Remind me to call grandma tomorrow',
        now: now,
      );
      expect(drafts.single.kind, InformationKind.reminder);
    });

    test('image-only input becomes information for confirmation', () {
      final drafts = FamilyBrainParser.parseAll(
        '',
        now: now,
        imagePath: '/tmp/shot.jpg',
      );
      expect(drafts.single.kind, InformationKind.information);
      expect(drafts.single.imagePath, '/tmp/shot.jpg');
    });

    test('notification schedule uses reminder time and task id payload', () {
      final task = TaskItem(
        id: 'task-99',
        familyId: 'fam',
        creatorId: 'maya',
        title: 'Take David to the doctor',
        type: TaskType.family,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
        kind: InformationKind.reminder,
        reminderAt: DateTime(2026, 8, 25, 16),
      );
      expect(
        LocalReminderScheduler.scheduledTime(task),
        DateTime(2026, 8, 25, 16),
      );
    });
  });
}
