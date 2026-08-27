import 'dart:async';

import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/routing/root_keys.dart';
import 'core/share/share_intake_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/local_reminder_scheduler.dart';
import 'core/widgets/phone_shell.dart';
import 'core/widgets/undo_host.dart';
import 'data/providers.dart';
import 'features/settings/accent_controller.dart';
import 'features/settings/appearance_controller.dart';
import 'features/settings/locale_controller.dart';

class FamilyBrainApp extends ConsumerStatefulWidget {
  const FamilyBrainApp({super.key});

  @override
  ConsumerState<FamilyBrainApp> createState() => _FamilyBrainAppState();
}

class _FamilyBrainAppState extends ConsumerState<FamilyBrainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(shareIntakeControllerProvider.notifier).bind());
    });
  }

  @override
  Widget build(BuildContext context) {
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
    ref.listen(shareIntakeControllerProvider, (previous, share) {
      if (share == null) return;
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user?.hasFamily != true) return;
      final path = router.routeInformationProvider.value.uri.path;
      if (path == '/brain/confirm' || path == '/app/home') return;
      router.go('/app/home');
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
