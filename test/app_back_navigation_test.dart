import 'package:family_brain/core/routing/app_back_navigation.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/routing/app_back_button_binder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppBackNavigation.resolve', () {
    test('pops when a previous in-app route exists', () {
      final decision = AppBackNavigation.resolve(
        canPop: true,
        path: '/notifications',
      );
      expect(decision.action, AppBackAction.pop);
    });

    test('returns to Home from Tasks, Family, and Settings tabs', () {
      for (final path in AppBackNavigation.shellTabs) {
        final decision = AppBackNavigation.resolve(
          canPop: false,
          path: path,
        );
        expect(decision.action, AppBackAction.go, reason: path);
        expect(decision.location, '/app/home', reason: path);
      }
    });

    test('exits only from root Home', () {
      final decision = AppBackNavigation.resolve(
        canPop: false,
        path: '/app/home',
      );
      expect(decision.action, AppBackAction.exit);
    });

    test('uses a parent route when overlay stack is empty', () {
      expect(
        AppBackNavigation.fallbackLocation('/notifications'),
        '/app/home',
      );
      expect(
        AppBackNavigation.fallbackLocation('/tasks/new'),
        '/app/tasks',
      );
      expect(
        AppBackNavigation.fallbackLocation('/tasks/demo-task-milk'),
        '/app/tasks',
      );
      expect(
        AppBackNavigation.fallbackLocation('/tasks/demo-task-milk/edit'),
        '/tasks/demo-task-milk',
      );
    });
  });

  testWidgets('Android back pops overlays then returns to Home', (tester) async {
    final router = GoRouter(
      initialLocation: '/app/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppBackButtonBinder(child: child);
          },
          routes: [
            GoRoute(
              path: '/app/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home screen')),
            ),
            GoRoute(
              path: '/app/tasks',
              builder: (context, state) =>
                  const Scaffold(body: Text('Tasks screen')),
            ),
            GoRoute(
              path: '/app/family',
              builder: (context, state) =>
                  const Scaffold(body: Text('Family members screen')),
            ),
            GoRoute(
              path: '/app/settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings screen')),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) =>
                  const Scaffold(body: Text('Notifications screen')),
            ),
            GoRoute(
              path: '/tasks/new',
              builder: (context, state) =>
                  const Scaffold(body: Text('Create task screen')),
            ),
            GoRoute(
              path: '/tasks/:id',
              builder: (context, state) =>
                  const Scaffold(body: Text('Task details screen')),
            ),
            GoRoute(
              path: '/tasks/:id/edit',
              builder: (context, state) =>
                  const Scaffold(body: Text('Edit task screen')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);

    router.go('/app/family');
    await tester.pumpAndSettle();
    expect(find.text('Family members screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);

    router.go('/app/tasks');
    await tester.pumpAndSettle();
    router.push('/tasks/demo-1');
    await tester.pumpAndSettle();
    expect(find.text('Task details screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Tasks screen'), findsOneWidget);

    router.push('/tasks/new');
    await tester.pumpAndSettle();
    expect(find.text('Create task screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Tasks screen'), findsOneWidget);

    router.go('/app/settings');
    await tester.pumpAndSettle();
    expect(find.text('Settings screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);

    router.push('/notifications');
    await tester.pumpAndSettle();
    expect(find.text('Notifications screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);

    router.push('/tasks/demo-1');
    await tester.pumpAndSettle();
    router.push('/tasks/demo-1/edit');
    await tester.pumpAndSettle();
    expect(find.text('Edit task screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Task details screen'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isFalse);
    expect(find.text('Home screen'), findsOneWidget);
  });
}
