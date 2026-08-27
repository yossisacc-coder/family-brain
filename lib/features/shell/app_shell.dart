import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/task_trash.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const tasksTabIndex = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final onTasks = navigationShell.currentIndex == tasksTabIndex;
    final pendingUndo = ref.watch(trashUndoRequestProvider) != null;
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: navigationShell,
        floatingActionButton: !onTasks || pendingUndo
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/tasks/new'),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addTask),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.check_circle_outline),
              selectedIcon: const Icon(Icons.check_circle_rounded),
              label: l10n.tasks,
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups_rounded),
              label: l10n.family,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }
}
