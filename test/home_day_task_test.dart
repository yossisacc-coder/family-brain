import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/widgets/task_card.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:family_brain/features/home/home_day_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 27, 10);
  final david = AppUser(
    id: 'david',
    name: 'David',
    phone: '+10000000000',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
  );

  TaskItem sampleTask() {
    return TaskItem(
      id: 't1',
      familyId: 'fam',
      creatorId: 'alex',
      title: 'Soccer club',
      type: TaskType.family,
      kind: InformationKind.event,
      assigneeId: david.id,
      dueDate: DateTime(2026, 8, 27, 16, 30),
      hasDueTime: true,
      reminderAt: DateTime(2026, 8, 27, 16, 0),
      priority: TaskPriority.urgent,
      notes: 'Bring water bottles',
      status: TaskStatus.inProgress,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('Home day row shows title, assignee, and time only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: HomeDayTask(
            task: sampleTask(),
            members: [david],
            isFirst: true,
            isLast: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Soccer club'), findsOneWidget);
    expect(find.text('David'), findsOneWidget);
    expect(find.text('16:30'), findsOneWidget);
    expect(find.text('Urgent'), findsNothing);
    expect(find.text('In progress'), findsNothing);
    expect(find.text('Bring water bottles'), findsNothing);
    expect(find.text('Reminder'), findsNothing);
    expect(find.text('Overdue'), findsNothing);
  });

  testWidgets('Home day row tap is wired', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeDayTask(
            task: sampleTask(),
            members: [david],
            isFirst: true,
            isLast: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Soccer club'));
    expect(tapped, isTrue);
  });

  testWidgets('Tasks list card still shows full metadata', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TaskCard(
            task: sampleTask(),
            members: [david],
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Soccer club'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('David'), findsOneWidget);
    expect(find.text('Bring water bottles'), findsNothing);
    expect(find.text('Reminder'), findsNothing);
  });
}
