import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../widgets/app_notice.dart';
import 'app_back_button_binder.dart';
import 'root_keys.dart';
import '../../features/brain/brain_ask_screen.dart';
import '../../features/brain/brain_confirm_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/family/family_setup_screen.dart';
import '../../features/family/member_details_screen.dart';
import '../../features/family/members_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tasks/calendar_screen.dart';
import '../../features/tasks/space_screen.dart';
import '../../features/tasks/task_details_screen.dart';
import '../../features/tasks/task_form_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/tasks/trash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authUidProvider);
      final userAsync = ref.read(currentUserProvider);
      final loc = state.matchedLocation;
      final public = loc == '/welcome' ||
          loc == '/login' ||
          loc == '/otp' ||
          loc == '/settings-public';

      if (auth.isLoading) return null;
      final uid = auth.valueOrNull;
      if (uid == null) return public ? null : '/welcome';

      if (userAsync.isLoading) return null;
      final user = userAsync.valueOrNull;
      if (user == null) return null;

      if (!user.hasFamily) {
        return loc == '/family-setup' ? null : '/family-setup';
      }
      if (public || loc == '/family-setup' || loc == '/') {
        return '/app/home';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppBackButtonBinder(child: child);
        },
        routes: [
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            verificationId: extra['verificationId'] as String? ?? '',
            phone: extra['phone'] as String? ?? '',
            name: extra['name'] as String? ?? '',
            language: extra['language'] as String? ?? 'en',
          );
        },
      ),
      GoRoute(
        path: '/family-setup',
        builder: (context, state) => const FamilySetupScreen(),
      ),
      GoRoute(
        path: '/settings-public',
        builder: (context, state) => const SettingsScreen(publicMode: true),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/brain/confirm',
        builder: (context, state) => const BrainConfirmScreen(),
      ),
      GoRoute(
        path: '/brain/ask',
        builder: (context, state) => const BrainAskScreen(),
      ),
      GoRoute(
        path: '/tasks/new',
        builder: (context, state) {
          final extra = state.extra as Map?;
          return TaskFormScreen(
            initialTitle: extra?['title'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/tasks/calendar',
        builder: (context, state) {
          final extra = state.extra;
          final focus = extra is CalendarFocus ? extra : CalendarFocus.all;
          return CalendarScreen(focus: focus);
        },
      ),
      GoRoute(
        path: '/tasks/events',
        builder: (context, state) =>
            const CalendarScreen(focus: CalendarFocus.events),
      ),
      GoRoute(
        path: '/tasks/reminders',
        builder: (context, state) =>
            const CalendarScreen(focus: CalendarFocus.reminders),
      ),
      GoRoute(
        path: '/tasks/trash',
        builder: (context, state) => const TrashScreen(),
      ),
      GoRoute(
        path: '/space/personal',
        builder: (context, state) => const SpaceScreen(personal: true),
      ),
      GoRoute(
        path: '/space/family',
        builder: (context, state) => const SpaceScreen(personal: false),
      ),
      GoRoute(
        path: '/family/members/:id',
        builder: (context, state) => MemberDetailsScreen(
          memberId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) => TaskDetailsScreen(
          taskId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        builder: (context, state) => TaskFormScreen(
          taskId: state.pathParameters['id'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/app/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/app/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/app/family',
              builder: (context, state) => const MembersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/app/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
        ],
      ),
    ],
  );
  router.routerDelegate.addListener(() {
    AppNotice.onLocation(
      router.routerDelegate.currentConfiguration.uri.toString(),
    );
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authUidProvider, (_, _) => notifyListeners());
    ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }
}
