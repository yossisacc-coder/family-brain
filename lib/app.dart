import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/phone_shell.dart';
import 'data/providers.dart';
import 'features/settings/locale_controller.dart';

class FamilyBrainApp extends ConsumerWidget {
  const FamilyBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(routerProvider);
    ref.listen(currentUserProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null) {
        ref.read(notificationServiceProvider).initializePush(user);
      }
    });

    return MaterialApp.router(
      title: 'Family Brain',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: AppTheme.light(locale),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return PhoneShell(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
