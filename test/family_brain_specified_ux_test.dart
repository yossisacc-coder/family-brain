import 'package:family_brain/core/brain/voice_listen_patience.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/theme/app_accent.dart';
import 'package:family_brain/core/theme/appearance.dart';
import 'package:family_brain/data/providers.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:family_brain/features/home/home_screen.dart';
import 'package:family_brain/features/settings/accent_controller.dart';
import 'package:family_brain/features/settings/settings_screen.dart';
import 'package:family_brain/features/tasks/task_details_screen.dart';
import 'package:family_brain/features/tasks/task_form_screen.dart';
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

  TaskItem sampleTask() {
    return TaskItem(
      id: 'task-1',
      familyId: 'fam',
      creatorId: alex.id,
      title: 'Buy milk',
      notes: 'Two bottles',
      kind: InformationKind.event,
      assigneeId: maya.id,
      type: TaskType.family,
      dueDate: DateTime(2026, 8, 27, 10),
      hasDueTime: true,
      reminderAt: DateTime(2026, 8, 27, 9),
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Override> homeOverrides() {
    return [
      currentUserProvider.overrideWith((ref) => Stream.value(alex)),
      familyTasksProvider.overrideWith((ref) => Stream.value([sampleTask()])),
      familyMembersProvider.overrideWith((ref) => Future.value([alex, maya])),
      unreadCountProvider.overrideWith((ref) => 0),
    ];
  }

  List<Override> taskOverrides() {
    return [
      currentUserProvider.overrideWith((ref) => Stream.value(alex)),
      familyTasksProvider.overrideWith((ref) => Stream.value([sampleTask()])),
      trashedTasksProvider.overrideWith((ref) => Stream.value(const [])),
      familyMembersProvider.overrideWith((ref) => Future.value([alex, maya])),
    ];
  }

  ThemeData testTheme() {
    final palette = FamilyBrainPalette.of(AppearanceMode.colorful);
    return ThemeData(
      useMaterial3: true,
      colorScheme: palette.colorScheme,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
    );
  }

  Future<void> pumpHome(WidgetTester tester, {required Locale locale}) async {
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
          theme: testTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('voice listening uses patient pause and listen timeouts', () {
    expect(VoiceListenPatience.pauseFor, const Duration(seconds: 6));
    expect(VoiceListenPatience.listenFor, const Duration(seconds: 90));
    expect(VoiceListenPatience.silenceTimeout, const Duration(seconds: 6));
    expect(VoiceListenPatience.watchdog, const Duration(seconds: 90));
    expect(VoiceListenPatience.pauseFor.inSeconds, greaterThanOrEqualTo(5));
    expect(VoiceListenPatience.listenFor.inSeconds, greaterThanOrEqualTo(45));
  });

  test('app color selection persists in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AccentController();
    await controller.setAccent(AppAccent.teal);
    expect(controller.state, AppAccent.teal);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AccentController.key), 'teal');
  });

  test('selected app color becomes palette primary', () {
    final purple = FamilyBrainPalette.of(
      AppearanceMode.colorful,
      accent: AppAccent.purple,
    );
    final teal = FamilyBrainPalette.of(
      AppearanceMode.colorful,
      accent: AppAccent.teal,
    );
    final professional = FamilyBrainPalette.of(
      AppearanceMode.professional,
      accent: AppAccent.blue,
    );
    expect(purple.primary, AppAccent.purple.color);
    expect(teal.primary, AppAccent.teal.color);
    expect(
      professional.primary,
      isNot(
        equals(
          FamilyBrainPalette.of(
            AppearanceMode.professional,
            accent: AppAccent.purple,
          ).primary,
        ),
      ),
    );
    expect(professional.background, isNot(equals(teal.background)));
    expect(professional.card, isNot(equals(teal.card)));
  });

  testWidgets('Home send button is disabled when empty and sends typed text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(
          path: '/brain/confirm',
          builder: (_, _) => const Scaffold(body: Text('Confirm drafts')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: homeOverrides(),
        child: MaterialApp.router(
          locale: const Locale('en'),
          theme: testTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('home-ai-input'));
    final send = find.byKey(const Key('home-ai-send'));
    expect(field, findsOneWidget);
    expect(send, findsOneWidget);
    expect(tester.widget<InkWell>(send).onTap, isNull);

    await tester.enterText(field, 'Buy milk tomorrow');
    await tester.pump();
    expect(find.text('Buy milk tomorrow'), findsOneWidget);
    expect(tester.widget<InkWell>(send).onTap, isNotNull);

    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.text(l10n.brainProcessing).evaluate().isNotEmpty ||
          find.text('Confirm drafts').evaluate().isNotEmpty ||
          find.text(l10n.brainUnclear).evaluate().isNotEmpty ||
          find.text(l10n.errorUnavailable).evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('Hebrew Home send button stays at the end of the RTL row', (
    tester,
  ) async {
    await pumpHome(tester, locale: const Locale('he'));
    final field = find.byKey(const Key('home-ai-input'));
    await tester.enterText(field, 'לקנות חלב');
    await tester.pump();
    final sendBox = tester.getRect(find.byKey(const Key('home-ai-send')));
    final fieldBox = tester.getRect(field);
    expect(sendBox.center.dx, lessThan(fieldBox.center.dx));
    expect(tester.getSize(find.byKey(const Key('home-ai-send'))).width, 48);
    expect(tester.getSize(find.byKey(const Key('home-ai-send'))).height, 48);
  });

  testWidgets('Task details shows labeled fields and no chips', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: taskOverrides(),
        child: MaterialApp(
          locale: const Locale('en'),
          theme: testTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TaskDetailsScreen(taskId: 'task-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-details-view')), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text(l10n.changeStatus), findsOneWidget);
    expect(find.text(l10n.priority), findsOneWidget);
    expect(find.text(l10n.dueDate), findsOneWidget);
    expect(find.text(l10n.assignee), findsOneWidget);
    expect(find.text(l10n.moreDetails), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('Task edit form uses labeled fields instead of chips', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: taskOverrides(),
        child: MaterialApp(
          locale: const Locale('en'),
          theme: testTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TaskFormScreen(taskId: 'task-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-edit-form')), findsOneWidget);
    expect(find.text(l10n.taskTitle), findsOneWidget);
    expect(find.text(l10n.changeStatus), findsWidgets);
    expect(find.text(l10n.priority), findsWidgets);
    expect(find.byType(DropdownButtonFormField<TaskStatus>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<TaskPriority>), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('Settings App Color swatches change the stored accent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          theme: testTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(publicMode: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.appColor), findsOneWidget);
    expect(find.byKey(const Key('app-color-teal')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('app-color-teal')));
    await tester.tap(find.byKey(const Key('app-color-teal')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AccentController.key), 'teal');
  });
}
