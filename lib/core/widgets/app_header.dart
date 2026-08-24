import 'package:flutter/material.dart';

import 'package:family_brain/core/l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_section_header.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onNotifications,
    this.unreadCount = 0,
    this.onSettings,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNotifications;
  final int unreadCount;
  final VoidCallback? onSettings;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppBrandMark(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        trailing ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderIcon(
                  tooltip: AppLocalizations.of(context).notifications,
                  onPressed: onNotifications,
                  icon: Icons.notifications_none_rounded,
                  badge: unreadCount,
                ),
                if (onSettings != null)
                  _HeaderIcon(
                    tooltip: AppLocalizations.of(context).settings,
                    onPressed: onSettings!,
                    icon: Icons.settings_outlined,
                  ),
              ],
            ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.badge = 0,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.touch,
      height: AppSpacing.touch,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, color: AppColors.text),
          ),
          if (badge > 0)
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 6,
              top: 6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.urgent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
