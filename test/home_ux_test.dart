import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/widgets/quick_action_card.dart';
import 'package:family_brain/core/widgets/stat_card.dart';
import 'package:family_brain/features/tasks/calendar_screen.dart';
import 'package:family_brain/data/providers.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:family_brain/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 8, 27, 9);
  final alex = AppUser(
    id: 'alex',
    name: 'Alex',
    phone: '+10000000001',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
  );
  final maya = AppUser(
    id: 'maya',
    name: 'Maya',
    phone: '+10000000002',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
  );

  List<TaskItem> sampleTasks() {
    final clock = DateTime.now();
    final day = DateTime(clock.year, clock.month, clock.day);
    return [
      TaskItem(
        id: 'event-1',
        familyId: 'fam',
        creatorId: alex.id,
        title: 'Teacher meeting',
        kind: InformationKind.event,
        assigneeId: maya.id,
        type: TaskType.family,
        dueDate: DateTime(day.year, day.month, day.day, 10),
        hasDueTime: true,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'event-2',
        familyId: 'fam',
        creatorId: alex.id,
        title: 'Soccer practice',
        kind: InformationKind.event,
        assigneeId: alex.id,
        type: TaskType.family,
        dueDate: DateTime(day.year, day.month, day.day, 16, 30),
        hasDueTime: true,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'event-3',
        familyId: 'fam',
        creatorId: maya.id,
        title: 'Family dinner',
        kind: InformationKind.event,
        type: TaskType.family,
        dueDate: DateTime(day.year, day.month, day.day, 19),
        hasDueTime: true,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'reminder-1',
        familyId: 'fam',
        creatorId: alex.id,
        title: 'Pack bottles',
        kind: InformationKind.reminder,
        assigneeId: alex.id,
        type: TaskType.family,
        reminderAt: DateTime(day.year, day.month, day.day, 15, 30),
        priority: TaskPriority.high,
        notes: 'Bring two bottles',
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task-extra',
        familyId: 'fam',
        creatorId: alex.id,
        title: 'Buy milk',
        type: TaskType.family,
        assigneeId: alex.id,
        dueDate: day.add(const Duration(days: 1)),
        reminderAt: day.add(const Duration(days: 1, hours: 18)),
        priority: TaskPriority.urgent,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<Override> homeOverrides() {
    return [
      currentUserProvider.overrideWith((ref) => Stream.value(alex)),
      familyTasksProvider.overrideWith((ref) => Stream.value(sampleTasks())),
      familyMembersProvider.overrideWith((ref) async => [alex, maya]),
      unreadCountProvider.overrideWith((ref) => 0),
    ];
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    required Locale locale,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: homeOverrides(),
        child: MaterialApp(
          locale: locale,
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('English Home uses English labels with no leftover Hebrew', (
    tester,
  ) async {
    await pumpHome(tester, locale: const Locale('en'));
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(find.text(l10n.quickAccessCalendar), findsOneWidget);
    expect(find.text(l10n.sendToFamilyBrain), findsOneWidget);
    expect(find.text(l10n.quickAccessTasks), findsNothing);
    expect(find.text(l10n.quickAccessMySpace), findsOneWidget);
    expect(find.text(l10n.quickAccessFamilySpace), findsOneWidget);
    expect(find.text(l10n.seeAllTasks), findsOneWidget);
    expect(find.text(l10n.tellFamilyBrain), findsOneWidget);
    expect(find.text(l10n.statEventsToday), findsOneWidget);
    expect(find.text(l10n.statPendingTasks), findsOneWidget);
    expect(find.text(l10n.todayActivity), findsOneWidget);
    expect(find.text('לוח שנה'), findsNothing);
    expect(find.text('המרחב שלי'), findsNothing);
    expect(find.text('הצג הכל'), findsNothing);

    final hebrew = RegExp(r'[\u0590-\u05FF]');
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    for (final value in texts) {
      if (value == null) continue;
      expect(hebrew.hasMatch(value), isFalse, reason: value);
    }
  });

  testWidgets('Hebrew Home uses Hebrew labels with no leftover English chrome', (
    tester,
  ) async {
    await pumpHome(tester, locale: const Locale('he'));
    final l10n = lookupAppLocalizations(const Locale('he'));

    expect(find.text(l10n.quickAccessCalendar), findsOneWidget);
    expect(find.text(l10n.sendToFamilyBrain), findsOneWidget);
    expect(find.text(l10n.quickAccessMySpace), findsOneWidget);
    expect(find.text(l10n.quickAccessFamilySpace), findsOneWidget);
    expect(find.text(l10n.seeAllTasks), findsOneWidget);
    expect(find.text(l10n.tellFamilyBrain), findsOneWidget);
    expect(find.text('Calendar'), findsNothing);
    expect(find.text('My Space'), findsNothing);
    expect(find.text('Family Space'), findsNothing);
    expect(find.text('Show all'), findsNothing);
    expect(find.text('Send to Family Brain'), findsNothing);
    expect(find.text('Quick access'), findsNothing);
  });

  testWidgets('Home shows a compact day list and keeps remaining tasks behind Show all', (
    tester,
  ) async {
    await pumpHome(tester, locale: const Locale('en'));

    expect(find.text('Teacher meeting'), findsOneWidget);
    expect(find.text('Soccer practice'), findsOneWidget);
    expect(find.text('Pack bottles'), findsOneWidget);
    expect(find.text('Family dinner'), findsNothing);
    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('Bring two bottles'), findsNothing);
    expect(find.text('Show all'), findsOneWidget);
    await tester.tap(find.byTooltip('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Family dinner'), findsOneWidget);
  });

  testWidgets('Quick Access cards stay compact on a phone viewport', (
    tester,
  ) async {
    await pumpHome(tester, locale: const Locale('en'));
    final size = tester.getSize(find.byType(QuickActionCard).first);
    expect(size.height, lessThan(72));
  });

  testWidgets('Events list can open the related task details screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/tasks/events',
      routes: [
        GoRoute(
          path: '/tasks/events',
          builder: (context, state) =>
              const CalendarScreen(focus: CalendarFocus.events),
        ),
        GoRoute(
          path: '/tasks/:id',
          builder: (context, state) => Scaffold(
            body: Text('Task details ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: homeOverrides(),
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Teacher meeting'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-related-task-event-1')));
    await tester.pumpAndSettle();
    expect(find.text('Task details event-1'), findsOneWidget);
  });

  testWidgets('Reminders list can open the related task details screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/tasks/reminders',
      routes: [
        GoRoute(
          path: '/tasks/reminders',
          builder: (context, state) =>
              const CalendarScreen(focus: CalendarFocus.reminders),
        ),
        GoRoute(
          path: '/tasks/:id',
          builder: (context, state) => Scaffold(
            body: Text('Task details ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: homeOverrides(),
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pack bottles'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-related-task-reminder-1')));
    await tester.pumpAndSettle();
    expect(find.text('Task details reminder-1'), findsOneWidget);
  });

  testWidgets('Home AI composer accepts Hebrew and English typing', (
    tester,
  ) async {
    await pumpHome(tester, locale: const Locale('en'));
    final field = find.byKey(const Key('home-ai-input'));
    expect(field, findsOneWidget);
    await tester.tap(field);
    await tester.enterText(field, 'שלום hello');
    await tester.pump();
    expect(find.text('שלום hello'), findsOneWidget);
    await tester.enterText(field, 'Buy milk');
    await tester.pump();
    expect(find.text('Buy milk'), findsOneWidget);
  });

  testWidgets('Hebrew Home AI composer still accepts typing', (tester) async {
    await pumpHome(tester, locale: const Locale('he'));
    final field = find.byKey(const Key('home-ai-input'));
    await tester.tap(field);
    await tester.enterText(field, 'לקנות חלב');
    await tester.pump();
    expect(find.text('לקנות חלב'), findsOneWidget);
  });

  testWidgets('Home stat cards share the same height', (tester) async {
    await pumpHome(tester, locale: const Locale('en'));
    final sizes = tester
        .renderObjectList<RenderBox>(find.byType(StatCard))
        .map((box) => box.size)
        .toList();
    expect(sizes.length, 4);
    for (final size in sizes) {
      expect(size.height, StatCard.height);
    }
  });
}
