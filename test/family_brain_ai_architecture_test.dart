import 'dart:convert';
import 'dart:io';

import 'package:family_brain/core/brain/ai/action_engine.dart';
import 'package:family_brain/core/brain/ai/ai_provider.dart';
import 'package:family_brain/core/brain/ai/family_brain_ai_schema.dart';
import 'package:family_brain/core/brain/ai/family_brain_ai_service.dart';
import 'package:family_brain/core/brain/ai/family_brain_context.dart';
import 'package:family_brain/core/brain/ai/gemini_ai_adapter.dart';
import 'package:family_brain/core/brain/ai/local_fallback_adapter.dart';
import 'package:family_brain/core/brain/family_brain_ai.dart';
import 'package:family_brain/core/config/app_config.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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
  final context = FamilyBrainContext.fromApp(
    now: now,
    language: 'en',
    members: [david],
  );

  const gatewayFixture = {
    'clarification': null,
    'items': [
      {
        'type': 'task',
        'title': 'Call the electrician',
        'date': '2026-08-25',
        'priority': 'high',
        'confidence': 0.9,
      },
      {
        'type': 'event',
        'title': 'Doctor',
        'date': '2026-08-25',
        'time': '18:00',
        'assignee': 'David',
        'space': 'family',
      },
      {
        'type': 'reminder',
        'title': 'Call Dad',
        'date': '2026-08-25',
        'time': '16:00',
        'priority': 'urgent',
      },
      {
        'type': 'list',
        'title': 'Shopping',
        'listItems': ['milk', 'bread'],
      },
    ],
  };

  const datedSource =
      'Tomorrow at 6 PM take David to the doctor. Remind me to call Dad tomorrow at 4. Need milk and bread.';

  group('normalized Family Brain AI schema', () {
    test('parses canonical JSON into typed actions', () {
      final response = FamilyBrainAiResponse.fromJson({
        'version': 1,
        'actions': [
          {
            'type': 'create_task',
            'title': 'Finish homework',
            'priority': 'normal',
            'space': 'personal',
          },
          {
            'type': 'ask_for_clarification',
            'message': 'Which day?',
          },
          {
            'type': 'conversational_response',
            'message': 'Done.',
          },
        ],
      }, sourceText: 'Finish homework');

      expect(response.actions.map((a) => a.type.wireName), [
        'create_task',
        'ask_for_clarification',
        'conversational_response',
      ]);
      expect(response.toJson()['actions'], isA<List>());
      expect(
        (response.toJson()['actions'] as List).first['type'],
        'create_task',
      );
    });

    test('Family Brain produces the normalized format from Gemini gateway JSON', () {
      final mapped = GeminiAiAdapter.mapGatewayPayload(
        gatewayFixture,
        sourceText: datedSource,
      );
      final resolved = FamilyBrainAiValidator.resolve(
        mapped,
        context: context,
        originalText: datedSource,
      );
      expect(
        resolved.actions.map((a) => a.type.wireName),
        containsAll([
          'create_task',
          'create_event',
          'create_reminder',
          'create_list_item',
        ]),
      );
      final json = resolved.toJson();
      expect(json['actions'], isNotEmpty);
      expect(
        (json['actions'] as List).every((item) => item['type'] is String),
        isTrue,
      );
    });
  });

  group('Gemini adapter', () {
    test('maps gateway/Gemini fixtures into the schema without a live call', () {
      final mapped = GeminiAiAdapter.mapGatewayPayload(
        gatewayFixture,
        sourceText: 'Take David to the doctor',
      );
      expect(mapped.providerId, 'gemini');
      final event = mapped.actions.firstWhere(
        (a) => a.type == FamilyBrainAiActionType.createEvent,
      );
      expect(event.title, 'Doctor');
      expect(event.date, '2026-08-25');
      expect(event.time, '18:00');
      expect(event.assigneeName, 'David');
    });

    test('also accepts already-normalized actions JSON', () {
      final mapped = GeminiAiAdapter.mapGatewayPayload({
        'actions': [
          {'type': 'create_task', 'title': 'Pay the bill'},
        ],
      });
      expect(mapped.actions.single.type, FamilyBrainAiActionType.createTask);
      expect(mapped.actions.single.title, 'Pay the bill');
    });

    test('HTTP adapter posts to /understand and maps the body', () async {
      final client = _FixtureClient(jsonEncode(gatewayFixture));
      final adapter = GeminiAiAdapter(
        origin: 'https://family-brain-ai.onrender.com',
        client: client,
      );
      final response = await adapter.interpret(
        input: const FamilyBrainInput(text: 'Buy milk'),
        context: context,
      );
      expect(client.lastUrl.toString(), endsWith('/understand'));
      expect(client.lastBody, isNot(contains('GEMINI')));
      expect(client.lastBody, isNot(contains('API_KEY')));
      expect(response.hasCreateActions, isTrue);
      expect(
        response.actions.map((a) => a.type),
        contains(FamilyBrainAiActionType.createListItem),
      );
    });

    test('resolves family member names in Family Brain, not the adapter', () {
      final mapped = GeminiAiAdapter.mapGatewayPayload(gatewayFixture);
      expect(
        mapped.actions
            .firstWhere((a) => a.type == FamilyBrainAiActionType.createEvent)
            .assigneeId,
        isNull,
      );
      final resolved = FamilyBrainAiValidator.resolve(
        mapped,
        context: context,
        originalText: datedSource,
      );
      expect(
        resolved.actions
            .firstWhere((a) => a.type == FamilyBrainAiActionType.createEvent)
            .assigneeId,
        'david',
      );
    });
  });

  group('Action Engine', () {
    test('creates tasks, events, reminders, and lists from the schema', () async {
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      var n = 0;
      final engine = ActionEngine(
        repository: repo,
        nextId: () => 'id-${n++}',
      );
      final response = FamilyBrainAiValidator.resolve(
        GeminiAiAdapter.mapGatewayPayload(
          gatewayFixture,
          sourceText: datedSource,
        ),
        context: context,
        originalText: datedSource,
      );
      final result = await engine.apply(
        response: response,
        familyId: 'fam',
        creatorId: 'maya',
        now: now,
      );
      expect(result.created, hasLength(4));
      final saved = await repo.watchFamilyTasks('fam').first;
      expect(
        saved.map((t) => t.kind),
        containsAll([
          InformationKind.task,
          InformationKind.event,
          InformationKind.reminder,
          InformationKind.list,
        ]),
      );
      final event = saved.firstWhere((t) => t.kind == InformationKind.event);
      expect(event.assigneeId, 'david');
      expect(event.dueDate, DateTime(2026, 8, 25, 18, 0));
      final reminder = saved.firstWhere((t) => t.kind == InformationKind.reminder);
      expect(reminder.priority, TaskPriority.urgent);
      final list = saved.firstWhere((t) => t.kind == InformationKind.list);
      expect(list.notes, contains('milk'));
    });

    test('complete_task updates application data without provider knowledge', () async {
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      final existing = TaskItem(
        id: 't1',
        familyId: 'fam',
        creatorId: 'maya',
        title: 'Old task',
        type: TaskType.family,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      await repo.createTask(existing);
      final result = await ActionEngine(repository: repo).apply(
        response: FamilyBrainAiResponse(
          actions: const [
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.completeTask,
              targetId: 't1',
            ),
          ],
        ),
        familyId: 'fam',
        creatorId: 'maya',
        now: now,
        existing: [existing],
      );
      expect(result.updated.single.status, TaskStatus.completed);
    });

    test('clarification and conversation do not write the database', () async {
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      final result = await ActionEngine(repository: repo).apply(
        response: const FamilyBrainAiResponse(
          clarification: 'Which day?',
          actions: [
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.askForClarification,
              message: 'Which day?',
            ),
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.conversationalResponse,
              message: 'I can help with that.',
            ),
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.identifyFamilyMember,
              assigneeName: 'David',
            ),
          ],
        ),
        familyId: 'fam',
        creatorId: 'maya',
        now: now,
      );
      expect(result.written, isEmpty);
      expect(await repo.watchFamilyTasks('fam').first, isEmpty);
    });

    test('delete_task is never written without confirmation', () async {
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      final existing = TaskItem(
        id: 'shop',
        familyId: 'fam',
        creatorId: 'maya',
        title: "David's shopping task",
        type: TaskType.family,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      await repo.createTask(existing);
      final result = await ActionEngine(repository: repo).apply(
        response: const FamilyBrainAiResponse(
          actions: [
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.deleteTask,
              targetId: 'shop',
              title: "David's shopping task",
            ),
          ],
        ),
        familyId: 'fam',
        creatorId: 'maya',
        now: now,
        existing: [existing],
      );
      expect(result.written, isEmpty);
      expect(
        (await repo.watchFamilyTasks('fam').first).single.id,
        'shop',
      );
    });
  });

  group('plug-in provider and fallback', () {
    test('a fake replacement provider still drives the Action Engine', () async {
      final fake = _FakeProvider(
        const FamilyBrainAiResponse(
          providerId: 'fake',
          sourceText: 'Buy milk',
          actions: [
            FamilyBrainAiAction(
              type: FamilyBrainAiActionType.createListItem,
              title: 'Shopping',
              listItems: ['milk'],
            ),
          ],
        ),
      );
      final service = FamilyBrainAiService(provider: fake);
      final response = await service.interpret(
        input: const FamilyBrainInput(text: 'Buy milk'),
        context: context,
      );
      expect(response.providerId, 'fake');
      final repo = LocalTaskRepository(LocalJsonStore(persist: false));
      final written = await ActionEngine(
        repository: repo,
        nextId: () => 'list-1',
      ).apply(
        response: response,
        familyId: 'fam',
        creatorId: 'maya',
        now: now,
      );
      expect(written.created.single.kind, InformationKind.list);
    });

    test('local fallback still works if the gateway is unavailable', () async {
      final result = await FamilyBrainAi.understand(
        text: 'Buy milk, bread and eggs.',
        now: now,
        backendUrl: 'https://family-brain-ai.onrender.com',
        client: _OfflineClient(),
      );
      expect(result.usedFallback, isTrue);
      expect(result.error, 'offline');
      expect(result.drafts.single.kind, InformationKind.list);
    });

    test('Hebrew input still becomes a reminder through the local adapter', () async {
      final service = FamilyBrainAiService(
        fallback: const LocalFallbackAdapter(),
      );
      final response = await service.interpret(
        input: const FamilyBrainInput(
          text: 'זה דחוף, תזכיר לי להתקשר לאבא מחר בשעה ארבע.',
        ),
        context: FamilyBrainContext(now: now, language: 'he'),
      );
      expect(response.hasCreateActions, isTrue);
      expect(
        response.actions.first.type,
        FamilyBrainAiActionType.createReminder,
      );
      expect(response.actions.first.priority, 'urgent');
    });

    test('English input still becomes a reminder through the local adapter', () async {
      final response = await const LocalFallbackAdapter().interpret(
        input: const FamilyBrainInput(
          text: "Remind me to call Dad tomorrow at 4 PM. It's urgent.",
        ),
        context: FamilyBrainContext(now: now),
      );
      expect(response.actions.first.type, FamilyBrainAiActionType.createReminder);
      expect(response.actions.first.priority, 'urgent');
    });

    test('AI_BACKEND_URL remains the public Render origin', () {
      expect(AppConfig.aiBackendUrl, 'https://family-brain-ai.onrender.com');
    });
  });
}

class _FakeProvider implements AiProvider {
  const _FakeProvider(this.response);
  final FamilyBrainAiResponse response;

  @override
  String get id => 'fake';

  @override
  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async =>
      response;
}

class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw const SocketException('offline');
  }
}

class _FixtureClient extends http.BaseClient {
  _FixtureClient(this.body);
  final String body;
  Uri? lastUrl;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    if (request is http.Request) lastBody = request.body;
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([utf8.encode(body)]),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
