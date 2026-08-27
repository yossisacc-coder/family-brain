import 'dart:convert';
import 'dart:io';

import 'package:family_brain/core/brain/ai/action_engine.dart';
import 'package:family_brain/core/brain/ai/ai_provider.dart';
import 'package:family_brain/core/brain/ai/family_brain_ai_schema.dart';
import 'package:family_brain/core/brain/ai/family_brain_ai_service.dart';
import 'package:family_brain/core/brain/ai/family_brain_context.dart';
import 'package:family_brain/core/brain/ai/gemini_ai_adapter.dart';
import 'package:family_brain/core/brain/ai/local_fallback_adapter.dart';
import 'package:family_brain/core/brain/brain_session.dart';
import 'package:family_brain/core/brain/family_brain_parser.dart';
import 'package:family_brain/core/brain/priority_from_language.dart';
import 'package:family_brain/core/brain/speech_locale.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/notifications/local_reminder_scheduler.dart';
import 'package:family_brain/core/theme/appearance.dart';
import 'package:family_brain/core/widgets/task_trash.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:family_brain/features/settings/appearance_controller.dart';
import 'package:family_brain/features/settings/reminder_settings_controller.dart';
import 'package:family_brain/features/tasks/calendar_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 8, 27, 10);
  final yossi = AppUser(
    id: 'yossi',
    name: 'יוסי',
    phone: '+10000000003',
    language: 'he',
    createdAt: now,
    familyId: 'fam',
  );

  setUp(() {
    BrainSession.debugReset();
    LocalReminderScheduler.debugReset();
  });

  group('localization strings', () {
    test('Hebrew UI strings cover Home, status, priority, and themes', () {
      final he = lookupAppLocalizations(const Locale('he'));
      expect(he.quickAccessCalendar, 'לוח שנה');
      expect(he.quickAccessTasks, 'משימות');
      expect(he.quickAccessMySpace, 'המרחב שלי');
      expect(he.quickAccessFamilySpace, 'מרחב משפחתי');
      expect(he.seeAllTasks, 'הצג הכל');
      expect(he.pending, isNot(contains(RegExp(r'[A-Za-z]'))));
      expect(he.inProgress, isNotEmpty);
      expect(he.completed, isNotEmpty);
      expect(he.low, isNotEmpty);
      expect(he.normal, isNotEmpty);
      expect(he.high, isNotEmpty);
      expect(he.urgent, isNotEmpty);
      expect(he.appearanceSoft, 'רך');
      expect(he.appearanceProfessional, 'מקצועי');
      expect(he.appearanceColorful, 'צבעוני');
      expect(he.addPhoto, 'הוספת תמונה');
      expect(he.tellFamilyBrain, contains('Family Brain'));
      expect(he.quickAccessCalendar, isNot('Calendar'));
    });

    test('English UI strings cover Home, status, priority, and themes', () {
      final en = lookupAppLocalizations(const Locale('en'));
      expect(en.quickAccessCalendar, 'Calendar');
      expect(en.seeAllTasks, 'Show all');
      expect(en.pending, 'Not started');
      expect(en.inProgress, 'In progress');
      expect(en.completed, 'Completed');
      expect(en.low, 'Low');
      expect(en.normal, 'Normal');
      expect(en.high, 'High');
      expect(en.urgent, 'Urgent');
      expect(en.appearanceSoft, 'Soft');
      expect(en.addPhoto, 'Add photo');
      expect(en.quickAccessCalendar, isNot('לוח שנה'));
    });
  });

  group('natural language actions', () {
    test('Yossi leaving at eight becomes a 20:00 scheduled event', () {
      final drafts = FamilyBrainParser.parseAll(
        'יוסי יוצא בשעה שמונה',
        now: now,
        members: [yossi],
        language: 'he',
      );
      expect(drafts, isNotEmpty);
      expect(drafts.single.kind, InformationKind.event);
      expect(drafts.single.assigneeId, 'yossi');
      expect(drafts.single.dueDate, DateTime(2026, 8, 27, 20, 0));
      expect(drafts.single.hasDueTime, isTrue);
      expect(drafts.single.title, contains('יוסי'));
    });

    test('doctor tomorrow at six is an event', () {
      final drafts = FamilyBrainParser.parseAll(
        'יש לי רופא מחר בשש',
        now: now,
        language: 'he',
      );
      expect(drafts.single.kind, InformationKind.event);
      expect(drafts.single.dueDate, DateTime(2026, 8, 28, 18, 0));
    });

    test('shopping milk and bread becomes a list', () {
      final drafts = FamilyBrainParser.parseAll(
        'צריך לקנות חלב ולחם',
        now: now,
        language: 'he',
      );
      expect(drafts.single.kind, InformationKind.list);
      expect(drafts.single.listItems, containsAll(['חלב', 'לחם']));
    });

    test('follow-up reminder two hours before uses the previous event', () {
      final event = FamilyBrainParser.parseAll(
        'יש לי רופא מחר בשש',
        now: now,
        language: 'he',
      ).single;
      final reminder = FamilyBrainParser.parseAll(
        'תזכיר לי שעתיים לפני',
        now: now,
        language: 'he',
        previousDrafts: [event],
        previousEventAt: event.dueDate,
        previousEventTitle: event.title,
      ).single;
      expect(reminder.kind, InformationKind.reminder);
      expect(reminder.reminderAt, DateTime(2026, 8, 28, 16, 0));
      expect(reminder.lowConfidence, isFalse);
    });

    test('ambiguous follow-up reminder does not invent a time', () {
      final drafts = FamilyBrainParser.parseAll(
        'תזכיר לי שעתיים לפני',
        now: now,
        language: 'he',
      );
      expect(drafts.single.kind, InformationKind.reminder);
      expect(drafts.single.lowConfidence, isTrue);
      expect(drafts.single.dueDate, isNull);
    });

    test('priority words are saved onto TaskItem', () {
      expect(PriorityFromLanguage.infer('זה דחוף'), TaskPriority.urgent);
      expect(PriorityFromLanguage.infer('חשוב'), TaskPriority.high);
      expect(PriorityFromLanguage.infer('לא דחוף'), TaskPriority.low);
      expect(PriorityFromLanguage.infer('כשיהיה זמן'), TaskPriority.low);
      expect(PriorityFromLanguage.infer('ordinary errand'), TaskPriority.normal);
      expect(PriorityFromLanguage.infer('urgent please'), TaskPriority.urgent);
      final task = FamilyBrainParser.parseAll(
        'דחוף, יוסי יוצא בשעה שמונה',
        now: now,
        members: [yossi],
        language: 'he',
      ).single.toTaskItem(
        id: 'p1',
        familyId: 'fam',
        creatorId: 'alex',
        now: now,
      );
      expect(task.priority, TaskPriority.urgent);
      expect(task.dueDate?.hour, 20);
    });
  });

  group('AI structured actions and provider abstraction', () {
    test('structured create actions persist through the Action Engine', () async {
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      final response = FamilyBrainAiResponse.fromJson({
        'actions': [
          {
            'type': 'create_event',
            'title': 'יוסי יוצא',
            'date': '2026-08-27',
            'time': '20:00',
            'assigneeId': 'yossi',
            'priority': 'normal',
          },
          {
            'type': 'create_reminder',
            'title': 'יוסי יוצא',
            'date': '2026-08-27',
            'reminderTime': '18:00',
          },
          {
            'type': 'create_list_item',
            'title': 'קניות',
            'listItems': ['חלב', 'לחם'],
          },
        ],
      }, sourceText: 'demo');
      var n = 0;
      final result = await ActionEngine(
        repository: repo,
        nextId: () => 'n-${n++}',
      ).apply(
        response: FamilyBrainAiValidator.resolve(
          response,
          context: FamilyBrainContext.fromApp(now: now, members: [yossi]),
          originalText: 'demo',
        ),
        familyId: 'fam',
        creatorId: 'alex',
        now: now,
      );
      expect(result.created, hasLength(3));
      final saved = await repo.watchFamilyTasks('fam').first;
      expect(saved.map((t) => t.kind), containsAll([
        InformationKind.event,
        InformationKind.reminder,
        InformationKind.list,
      ]));
      expect(
        saved.firstWhere((t) => t.kind == InformationKind.event).dueDate,
        DateTime(2026, 8, 27, 20),
      );
    });

    test('duplicate create of the same event is skipped', () async {
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      var n = 0;
      final engine = ActionEngine(repository: repo, nextId: () => 'd-${n++}');
      final response = const FamilyBrainAiResponse(
        actions: [
          FamilyBrainAiAction(
            type: FamilyBrainAiActionType.createEvent,
            title: 'Doctor',
            date: '2026-08-28',
            time: '18:00',
          ),
          FamilyBrainAiAction(
            type: FamilyBrainAiActionType.createEvent,
            title: 'Doctor',
            date: '2026-08-28',
            time: '18:00',
          ),
        ],
      );
      final result = await engine.apply(
        response: response,
        familyId: 'fam',
        creatorId: 'alex',
        now: now,
      );
      expect(result.created, hasLength(1));
    });

    test('Gemini retry is capped at two attempts then falls back', () async {
      final client = _FlakyThenOfflineClient();
      final service = FamilyBrainAiService(
        provider: GeminiAiAdapter(
          origin: 'https://family-brain-ai.onrender.com',
          client: client,
          timeout: const Duration(milliseconds: 50),
        ),
        fallback: const LocalFallbackAdapter(),
      );
      final result = await service.understandResult(
        input: const FamilyBrainInput(text: 'Buy milk, bread and eggs.'),
        context: FamilyBrainContext(now: now),
      );
      expect(client.attempts, 2);
      expect(result.usedFallback, isTrue);
      expect(result.response.hasCreateActions, isTrue);
    });

    test('a replacement provider still uses the same schema', () async {
      final fake = _NamedProvider();
      final service = FamilyBrainAiService(provider: fake);
      final response = await service.interpret(
        input: const FamilyBrainInput(text: 'demo'),
        context: FamilyBrainContext(now: now),
      );
      expect(response.providerId, 'other');
      expect(response.actions.single.type, FamilyBrainAiActionType.createTask);
    });
  });

  group('calendar, undo, theme, speech, notifications', () {
    test('calendar filters the selected day from real task data', () {
      final tuesday = DateTime(2026, 8, 25, 9);
      final items = [
        TaskItem(
          id: 'a',
          familyId: 'fam',
          creatorId: 'alex',
          title: 'Tuesday event',
          type: TaskType.family,
          kind: InformationKind.event,
          dueDate: tuesday,
          hasDueTime: true,
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 'b',
          familyId: 'fam',
          creatorId: 'alex',
          title: 'Wednesday',
          type: TaskType.family,
          kind: InformationKind.event,
          dueDate: tuesday.add(const Duration(days: 1)),
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(
        CalendarDayQuery.itemsForDay(
          tasks: items,
          day: tuesday,
          focus: CalendarFocus.events,
        ).map((t) => t.id),
        ['a'],
      );
    });

    test('undo timeout stays at 3 seconds', () {
      expect(TaskTrash.undoDuration, const Duration(seconds: 3));
    });

    test('three appearance modes are distinct and persist', () async {
      final soft = FamilyBrainPalette.of(AppearanceMode.soft);
      final professional = FamilyBrainPalette.of(AppearanceMode.professional);
      final colorful = FamilyBrainPalette.of(AppearanceMode.colorful);
      expect(soft.background, isNot(equals(professional.background)));
      expect(soft.background, isNot(equals(colorful.background)));
      expect(professional.background, isNot(equals(colorful.background)));
      expect(soft.background.computeLuminance(), greaterThan(0.8));
      SharedPreferences.setMockInitialValues({});
      final controller = AppearanceController();
      await controller.setMode(AppearanceMode.colorful);
      expect(controller.state, AppearanceMode.colorful);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppearanceController.key), 'colorful');
    });

    test('reminder notification setting is persisted and gates scheduling', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ReminderSettingsController();
      final future = TaskItem(
        id: 'r1',
        familyId: 'fam',
        creatorId: 'alex',
        title: 'Call',
        type: TaskType.family,
        kind: InformationKind.reminder,
        reminderAt: now.add(const Duration(hours: 2)),
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      expect(LocalReminderScheduler.shouldSchedule(future, now), isTrue);
      await controller.setEnabled(false);
      expect(controller.state, isFalse);
      expect(LocalReminderScheduler.notificationsEnabled, isFalse);
      expect(LocalReminderScheduler.shouldSchedule(future, now), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ReminderSettingsController.key), isFalse);
    });

    test('speech locale selection still prefers Hebrew without locales() gating', () {
      expect(
        SpeechLocalePicker.listenAttempts('he'),
        ['he_IL', 'iw_IL', 'he', null],
      );
      expect(SpeechLocalePicker.listenAttempts('en'), [null]);
      expect(SpeechLocalePicker.canListenWithoutPreferredLocale(), isTrue);
      expect(
        SpeechLocalePicker.resolve(
          appLanguageCode: 'he',
          availableIds: const [],
        ),
        isNull,
      );
    });

    test('context payload includes members, items, time, and language only', () {
      final payload = FamilyBrainContext.fromApp(
        now: now,
        language: 'he',
        members: [yossi],
        items: [
          TaskItem(
            id: 't',
            familyId: 'fam',
            creatorId: 'alex',
            title: 'Homework',
            type: TaskType.family,
            priority: TaskPriority.normal,
            status: TaskStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        recentUserTexts: const ['יש לי רופא מחר'],
      ).toProviderPayload();
      expect(payload['language'], 'he');
      expect(payload['members'], isNotEmpty);
      expect(payload['tasks'], isNotEmpty);
      expect(payload['recent'], ['יש לי רופא מחר']);
      expect(jsonEncode(payload), isNot(contains('phone')));
      expect(jsonEncode(payload), isNot(contains('GEMINI')));
    });
  });
}

class _NamedProvider implements AiProvider {
  @override
  String get id => 'other';

  @override
  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    return const FamilyBrainAiResponse(
      providerId: 'other',
      actions: [
        FamilyBrainAiAction(
          type: FamilyBrainAiActionType.createTask,
          title: 'Homework',
        ),
      ],
    );
  }
}

class _FlakyThenOfflineClient extends http.BaseClient {
  var attempts = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    attempts += 1;
    throw const SocketException('offline');
  }
}
