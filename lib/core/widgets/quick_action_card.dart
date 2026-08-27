import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.iconBackground,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBackground;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final fg = emphasized ? Colors.white : (iconColor ?? AppColors.primary);
    final bg = emphasized ? AppColors.primary : AppColors.card;
    return Material(
      color: bg,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: emphasized ? AppColors.primary : AppColors.border,
            ),
            boxShadow: emphasized ? null : AppShadows.card,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: emphasized
                        ? Colors.white.withValues(alpha: 0.18)
                        : (iconBackground ?? AppColors.primarySoft),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: emphasized ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null && subtitle != label) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: emphasized
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textMuted,
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
