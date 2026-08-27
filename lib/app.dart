import 'dart:async';

import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/routing/root_keys.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/local_reminder_scheduler.dart';
import 'core/widgets/phone_shell.dart';
import 'core/widgets/undo_host.dart';
import 'data/providers.dart';
import 'features/settings/accent_controller.dart';
import 'features/settings/appearance_controller.dart';
import 'features/settings/locale_controller.dart';

class FamilyBrainApp extends ConsumerWidget {
  const FamilyBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final appearance = ref.watch(appearanceControllerProvider);
    final accent = ref.watch(accentControllerProvider);
    final router = ref.watch(routerProvider);
    ref.listen(currentUserProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null) {
        ref.read(notificationServiceProvider).initializePush(user);
      }
    });
    ref.listen(familyTasksProvider, (previous, next) {
      final tasks = next.valueOrNull;
      if (tasks != null) {
        unawaited(LocalReminderScheduler.syncAll(tasks));
      }
    });

    return MaterialApp.router(
      title: 'Family Brain',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: AppTheme.light(locale, appearance: appearance, accent: accent),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return PhoneShell(
          child: UndoHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
