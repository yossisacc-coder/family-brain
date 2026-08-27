import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/appearance.dart';
import '../../data/providers.dart';
import 'accent_controller.dart';
import 'appearance_controller.dart';
import 'locale_controller.dart';
import 'reminder_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.publicMode = false});

  final bool publicMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final locale = ref.watch(localeControllerProvider);
    final appearance = ref.watch(appearanceControllerProvider);
    final accent = ref.watch(accentControllerProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final family = ref.watch(currentFamilyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        key: const Key('settings-list'),
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
                  color: palette.textMuted,
                ),
          ),
          const SizedBox(height: 10),
          _AppearanceChoice(
            mode: AppearanceMode.soft,
            selected: appearance,
            label: l10n.appearanceSoft,
            hint: l10n.appearanceSoftHint,
            onSelect: (mode) => ref
                .read(appearanceControllerProvider.notifier)
                .setMode(mode),
          ),
          _AppearanceChoice(
            mode: AppearanceMode.professional,
            selected: appearance,
            label: l10n.appearanceProfessional,
            hint: l10n.appearanceProfessionalHint,
            onSelect: (mode) => ref
                .read(appearanceControllerProvider.notifier)
                .setMode(mode),
          ),
          _AppearanceChoice(
            mode: AppearanceMode.colorful,
            selected: appearance,
            label: l10n.appearanceColorful,
            hint: l10n.appearanceColorfulHint,
            onSelect: (mode) => ref
                .read(appearanceControllerProvider.notifier)
                .setMode(mode),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reminderNotifications),
            subtitle: Text(l10n.reminderNotificationsHint),
            value: ref.watch(reminderSettingsControllerProvider),
            onChanged: (value) {
              ref
                  .read(reminderSettingsControllerProvider.notifier)
                  .setEnabled(value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.appColor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appColorHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final option in AppAccent.values)
                _AppColorSwatch(
                  accent: option,
                  label: option.label(l10n),
                  selected: option == accent,
                  onTap: () {
                    ref
                        .read(accentControllerProvider.notifier)
                        .setAccent(option);
                  },
                ),
            ],
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
                color: palette.primarySoft,
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
                          color: palette.textMuted,
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
                  color: palette.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.version(AppConfig.version),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceChoice extends StatelessWidget {
  const _AppearanceChoice({
    required this.mode,
    required this.selected,
    required this.label,
    required this.hint,
    required this.onSelect,
  });

  final AppearanceMode mode;
  final AppearanceMode selected;
  final String label;
  final String hint;
  final ValueChanged<AppearanceMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSelected = mode == selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? palette.primarySoft : palette.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key('appearance-${mode.name}'),
          onTap: () => onSelect(mode),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? palette.primary : palette.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppColorSwatch extends StatelessWidget {
  const _AppColorSwatch({
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('app-color-${accent.name}'),
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.palette.text : Colors.white,
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.color.withValues(alpha: 0.28),
                    blurRadius: selected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
