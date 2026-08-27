import 'package:flutter/material.dart';

import 'package:family_brain/core/l10n/app_localizations.dart';

import '../theme/app_spacing.dart';
import '../theme/appearance.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.touch,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _HeaderIcon(
                  tooltip: AppLocalizations.of(context).notifications,
                  onPressed: onNotifications,
                  icon: Icons.notifications_none_rounded,
                  badge: unreadCount,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppBrandMark(size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: trailing ??
                    (onSettings == null
                        ? const SizedBox(
                            width: AppSpacing.touch,
                            height: AppSpacing.touch,
                          )
                        : _HeaderIcon(
                            tooltip: AppLocalizations.of(context).settings,
                            onPressed: onSettings!,
                            icon: Icons.settings_outlined,
                          )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.palette.textMuted,
                height: 1.35,
              ),
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
            icon: Icon(icon, color: context.palette.text, size: 24),
          ),
          if (badge > 0)
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.palette.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
