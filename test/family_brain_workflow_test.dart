import 'package:family_brain/core/brain/family_brain_ask.dart';
import 'package:family_brain/core/brain/family_brain_parser.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/routing/app_back_navigation.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/data/providers.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:family_brain/features/brain/brain_confirm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('FamilyBrainParser', () {
    test('rejects empty input', () {
      final result = FamilyBrainParser.parse('  ', now: now);
      expect(result.isOk, isFalse);
      expect(result.error, FamilyBrainParser.emptyInput);
    });

    test('understands a dated event with person and time', () {
      final result = FamilyBrainParser.parse(
        'Tomorrow at 5 PM take David to the doctor.',
        now: now,
        members: [david],
      );
      expect(result.isOk, isTrue);
      final draft = result.draft!;
      expect(draft.kind, InformationKind.event);
      expect(draft.title.toLowerCase(), contains('david'));
      expect(draft.title.toLowerCase(), contains('doctor'));
      expect(draft.dueDate, DateTime(2026, 8, 25, 17, 0));
      expect(draft.hasDueTime, isTrue);
      expect(draft.assigneeId, 'david');
    });

    test('understands a shopping list', () {
      final result = FamilyBrainParser.parse(
        'Buy milk, bread and eggs.',
        now: now,
      );
      expect(result.draft!.kind, InformationKind.list);
      expect(result.draft!.listItems, containsAll(['milk', 'bread', 'eggs']));
    });

    test('understands a reminder', () {
      final result = FamilyBrainParser.parse(
        'Remind me to call grandma tomorrow',
        now: now,
      );
      expect(result.draft!.kind, InformationKind.reminder);
      expect(result.draft!.title.toLowerCase(), contains('grandma'));
      expect(result.draft!.reminderAt, isNotNull);
    });

    test('defaults ordinary requests to a task', () {
      final result = FamilyBrainParser.parse(
        'Finish the homework',
        now: now,
      );
      expect(result.draft!.kind, InformationKind.task);
      expect(result.draft!.title.toLowerCase(), contains('homework'));
    });

    test('keeps an attached photo on the draft for confirmation', () {
      final parsed = FamilyBrainParser.parse('Finish the homework', now: now);
      final draft = parsed.draft!.copyWith(imagePath: '/tmp/photo.jpg');
      expect(draft.imagePath, '/tmp/photo.jpg');
      expect(draft.notes, contains('/tmp/photo.jpg'));
    });

    test('edit then save persists through the existing task repository', () async {
      final parsed = FamilyBrainParser.parse(
        'Tomorrow at 5 PM take David to the doctor.',
        now: now,
        members: [david],
      ).draft!;
      final edited = parsed.copyWith(title: 'Take David to clinic');
      final store = LocalJsonStore(persist: false);
      final repo = LocalTaskRepository(store);
      final saved = await repo.createTask(
        edited.toTaskItem(
          id: 'brain-1',
          familyId: 'fam',
          creatorId: 'maya',
          now: now,
        ),
      );
      expect(saved.title, 'Take David to clinic');
      expect(saved.kind, InformationKind.event);
      final again = await repo.watchFamilyTasks('fam').first;
      expect(again.single.id, 'brain-1');
    });

    test('cancel means nothing is created', () async {
      final store = LocalJsonStore(persist: false);
      final repo = LocalTaskRepository(store);
      FamilyBrainParser.parse('Buy milk, bread and eggs.', now: now);
      final tasks = await repo.watchFamilyTasks('fam').first;
      expect(tasks, isEmpty);
    });
  });

  group('FamilyBrainAsk', () {
    test('answers what is due today without exposing other personal tasks', () {
      final visible = [
        TaskItem(
          id: '1',
          familyId: 'fam',
          creatorId: 'maya',
          title: 'School pickup',
          kind: InformationKind.task,
          type: TaskType.family,
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
          dueDate: DateTime(2026, 8, 24, 15),
          hasDueTime: true,
        ),
        TaskItem(
          id: '2',
          familyId: 'fam',
          creatorId: 'alex',
          title: 'Secret errand',
          kind: InformationKind.task,
          type: TaskType.personal,
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
          dueDate: DateTime(2026, 8, 24),
        ),
      ].where((task) => task.isVisibleTo('maya')).toList();

      final answer = FamilyBrainAsk.answer(
        question: 'What tasks are due today?',
        visibleTasks: visible,
        now: now,
      );
      expect(answer, contains('School pickup'));
      expect(answer, isNot(contains('Secret errand')));
    });

    test('answers shopping questions from lists', () {
      final answer = FamilyBrainAsk.answer(
        question: 'What do we need to buy?',
        visibleTasks: [
          TaskItem(
            id: 'l',
            familyId: 'fam',
            creatorId: 'maya',
            title: 'milk, bread, eggs',
            kind: InformationKind.list,
            type: TaskType.family,
            priority: TaskPriority.normal,
            status: TaskStatus.pending,
            createdAt: now,
            updatedAt: now,
            notes: 'milk\nbread\neggs',
          ),
        ],
        now: now,
      );
      expect(answer.toLowerCase(), contains('milk'));
    });
  });

  test('back from Brain screens returns to Home', () {
    expect(AppBackNavigation.fallbackLocation('/brain/confirm'), '/app/home');
    expect(AppBackNavigation.fallbackLocation('/brain/ask'), '/app/home');
  });

  testWidgets('confirm screen stays visible when the draft extra is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BrainConfirmScreen(),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm screen reads the pending draft from provider', (
    tester,
  ) async {
    final draft = FamilyBrainParser.parse(
      'Finish the homework',
      now: now,
    ).draft!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingBrainDraftsProvider.overrideWith((ref) => [draft]),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BrainConfirmScreen(),
        ),
      ),
    );
    expect(find.text('Finish the homework'), findsWidgets);
    expect(find.text('Confirm'), findsOneWidget);
  });
}
