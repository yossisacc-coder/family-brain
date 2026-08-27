import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/appearance.dart';
import '../../data/providers.dart';
import 'appearance_controller.dart';
import 'locale_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.publicMode = false});

  final bool publicMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final appearance = ref.watch(appearanceControllerProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final family = ref.watch(currentFamilyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (!publicMode && user != null)
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.notifications),
              subtitle: Text(l10n.notificationsHint),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              onTap: () => context.push('/notifications'),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.language,
            style: Theme.of(context).textTheme.titleMedium,
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
            const SizedBox(height: 20),
            Text(
              l10n.account,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.signedInAs(user.phone)),
              subtitle: Text(user.name),
            ),
            OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: Text(l10n.signOut),
            ),
          ],
          if (family != null) ...[
            const SizedBox(height: 24),
            Text(
              l10n.familySettings,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(family.name),
              subtitle: Text(l10n.leaveFamily),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              onTap: () => context.go('/app/family'),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.appearance,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appearanceHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<AppearanceMode>(
            segments: [
              ButtonSegment(
                value: AppearanceMode.professional,
                label: Text(l10n.appearanceProfessional),
              ),
              ButtonSegment(
                value: AppearanceMode.colorful,
                label: Text(l10n.appearanceColorful),
              ),
            ],
            selected: {appearance},
            onSelectionChanged: (value) {
              ref
                  .read(appearanceControllerProvider.notifier)
                  .setMode(value.first);
            },
          ),
          const SizedBox(height: 6),
          Text(
            appearance == AppearanceMode.professional
                ? l10n.appearanceProfessionalHint
                : l10n.appearanceColorfulHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          if (!publicMode) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.trash),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              onTap: () => context.push('/tasks/trash'),
            ),
          ],
          if (AppConfig.useLocalDemo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.actionSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.demoModeLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.demoModeSettings,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            l10n.about,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
