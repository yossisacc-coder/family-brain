import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import 'locale_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.publicMode = false});

  final bool publicMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final family = ref.watch(currentFamilyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            l10n.language,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.english)),
              ButtonSegment(value: 'he', label: Text(l10n.hebrew)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (value) {
              ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(Locale(value.first));
            },
          ),
          if (user != null) ...[
            const SizedBox(height: 24),
            Text(
              l10n.signedInAs(user.phone),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (family != null) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.currentFamily}: ${family.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.leaveFamily,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: Text(l10n.signOut),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            l10n.aboutApp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.version(AppConfig.version),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
